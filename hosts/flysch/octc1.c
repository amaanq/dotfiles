// SPDX-License-Identifier: GPL-2.0
/*
 * octc1: virtual point-to-point IP link between the CN7890 card and its PCIe
 * host (guyot) over a fixed shared-memory region in card DRAM. The card maps it
 * natively; the host reaches the same bytes through the SDK BAR window
 * (octeon_remote_read/write_mem, byte-order preserving). Replaces the ~32 KB/s
 * console-SLIP bridge (host->card ~56 MB/s, host reads ~2 MB/s).
 *
 * Header fields are big-endian (card-native) so the host only needs be32 swaps;
 * payload is raw IP. Two circular byte rings of length-prefixed frames: C2H
 * (card->host) and H2C (host->card). Card owns C2H.prod and H2C.cons.
 */
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/io.h>
#include <linux/netdevice.h>
#include <linux/etherdevice.h>
#include <linux/skbuff.h>
#include <linux/kthread.h>
#include <linux/delay.h>
#include <linux/ip.h>
#include <linux/if_arp.h>
#include <linux/slab.h>
#include <asm/octeon/cvmx.h>
#include <asm/octeon/cvmx-pexp-defs.h>
#include <asm/octeon/cvmx-dpi-defs.h>

/*
 * DPI INBOUND DMA (the card-mastered host->card read path). The CN7890's DPI
 * engine reads host RAM over PCIe straight into card DRAM, so H2C no longer needs
 * the host to byte-bang the card BAR (which saturates and crashes the card) nor a
 * CPU read through the SLI mem-access window (whose EP reads return 0 by design).
 *
 * We drive engine 0 directly per the CN78XX HRM instead of the cvmx executive:
 * this kernel's executive has no cn78xx DPI/dma-engine support (no
 * OCTEON_FEATURE_CN78XX_WQE, no cvmx-dma-engine). DPI auto-returns a consumed
 * instruction chunk to an FPA aura ONLY when it follows a chunk's link pointer to
 * advance; we use a single chunk and rewind DPI_DMAX_IBUFF_SADDR to its base while
 * the engine is idle (every DMA is completion-waited, so it always is) before the
 * write index nears the link word -- DPI never follows a link, never frees, so no
 * FPA pool/aura is needed at all.
 *
 * Instruction (cn78xx, engine 0): 2 header words + NFST local (card-DRAM dst) write
 * pointers + one PCIe (host-RAM src) pointer. PT=0 makes DPI clear a completion
 * byte in card DRAM when done; we poll it (uncached, in the WC region) for ordering.
 */
#define DPI_ENGINE	0
#define DPI_CHUNK_WORDS	4096u
#define DPI_HDR_TYPE_INBOUND	1ull
#define DPI_ADDR_MASK	((1ull << 42) - 1)	/* local/ZBW pointer byte-address field is 42 bits */
#define DPI_SEG_MAX	8191u			/* internal pointer size field is 13 bits */
#define DPI_MAX_IWORDS	8u

#define OCTC1_PHYS	0x50000000UL
#define OCTC1_REGION	(8u * 1024 * 1024)
#define OCTC1_MAGIC	0x4f435431u	/* 'OCT1' */
#define OCTC1_HDR	256u
#define OCTC1_RING	((OCTC1_REGION - OCTC1_HDR) / 2)
#define OCTC1_MAXFRAME	9216u
#define OCTC1_PROBE_MAGIC 0x4f435031u	/* 'OCP1' */
#define OCTC1_C2H_OFF	64u
#define OCTC1_PROBE_OFF	128u
#define OCTC1_H2C_OFF	192u

struct octc1_hdr {
	__be32 magic, version;
	__be32 c2h_off, c2h_bytes, c2h_prod, c2h_cons;
	__be32 h2c_off, h2c_bytes, h2c_prod, h2c_cons;
};

/*
 * Fast card->host path: instead of the host slow-reading the card-DRAM C2H ring
 * over the BAR (~0.4 MB/s, latency-bound), the card masters the bus and writes
 * each packet straight into a host-RAM slot ring through the SLI mem-access
 * window (~99 MB/s, posted writes). The host fills these fields (big-endian, via
 * the BAR) with the window setup it derived: cardio = the card-side XKPHYS IO
 * base whose stores land at the host ring's physical address, and the
 * SLI_MEM_ACCESS_SUBIDX register value (ba=phys>>34, esw=1 so the card's native
 * big-endian stores are byte-identical in host memory). Per slot: a desc holding
 * the frame length, and a slot_size buffer. The card owns prod (written into
 * host RAM so the host polls it locally); the host owns hcons (written into card
 * RAM via the BAR so the card reads it locally). ena gates the whole path so
 * octc1 still works over the old card-DRAM ring until the host sets it up.
 */
struct octc1_c2h {
	__be32 ena;
	__be32 cardio_hi, cardio_lo;
	__be32 subidx, subval_hi, subval_lo;
	__be32 nslots, slot_size, desc_off, buf_off, prod_off;
	__be32 hcons;
};

/*
 * Fast host->card path via DPI INBOUND DMA. The host writes packets into a slot
 * ring in its OWN RAM and the CARD masters the bus to READ each one with a DPI
 * engine transfer -- no payload crosses the card BAR (those per-packet writes
 * saturate and crash the card) and no CPU read goes through the SLI mem-access
 * window (whose EP reads return 0 by design). Only control words cross the BAR,
 * into card DRAM: cardio_{hi,lo} carry the raw host-physical base of the host slot
 * ring (the DPI source; VT-d off so it maps 1:1); nslots/slot_size size it. prod
 * and the per-slot desc[] (length) live in card DRAM at fixed offsets the host
 * writes; cons lives in card DRAM written by the card and read by the host. The
 * remaining fields are unused. ena gates setup.
 */
struct octc1_h2c {
	__be32 ena;
	__be32 cardio_hi, cardio_lo;
	__be32 subidx, subval_hi, subval_lo;
	__be32 nslots, slot_size, desc_off, buf_off, prod_off;
	__be32 cons_off;
};

/*
 * Empirical probe for the card->host SLI mem-access window. The host pokes a
 * target host-physical address + which SLI subid window to use + a fill pattern;
 * the card configures that SLI_MEM_ACCESS_SUBIDX with ba=phys>>34 and stores the
 * pattern straight into host RAM through the windowed XKPHYS IO address, then
 * writes a completion marker (= trigger) right after the data. Because PCIe
 * keeps posted writes ordered, the host polling that marker in its OWN RAM knows
 * the data landed. subdid (address-side) and subidx (register index) are kept
 * separate so their mapping can be searched without a card rebuild.
 */
struct octc1_probe {
	__be32 magic2;
	__be32 trigger, done, fault;
	__be32 subidx;
	__be32 subval_hi, subval_lo;
	__be32 cardio_hi, cardio_lo;
	__be32 pattern, len, marker_off;
};

struct octc1 {
	void *region;
	struct octc1_hdr *hdr;
	struct octc1_probe *probe;
	struct octc1_c2h *c2hh;
	u32 probe_last;
	u8 *c2h, *h2c;
	u32 ring_bytes;
	struct net_device *ndev;
	struct task_struct *rx_thread;

	bool hc_on;
	u32 hc_ena_last;
	u8 *hc_desc, *hc_buf, *hc_prod;
	u32 hc_nslots, hc_slot_size;
	u32 hc_prodi;
	spinlock_t hc_lock;

	struct octc1_h2c *h2ch;
	bool hd_on;
	u32 hd_ena_last;
	u8 *hd_desc, *hd_prod, *hd_cons;
	u64 hd_host_buf_phys;
	u32 hd_nslots, hd_slot_size;
	u32 hd_consi;

	bool dpi_inited;
	u64 *dpi_chunk;
	u64 dpi_chunk_phys;
	u64 dpi_ibuff;
	u32 dpi_index;
	volatile u8 *dpi_comp;
	u64 dpi_comp_phys;

	u8 *dpi_dbg;
	u32 dpi_seq;
};
static struct octc1 *g;

static inline u32 hdr_rd(__be32 *p) { return be32_to_cpu(READ_ONCE(*p)); }
static inline void hdr_wr(__be32 *p, u32 v) { WRITE_ONCE(*p, cpu_to_be32(v)); }
static inline u32 ring_space(u32 prod, u32 cons, u32 n) { return (n - 1) - ((prod - cons) % n); }
static inline u32 ring_used(u32 prod, u32 cons, u32 n) { return (prod - cons) % n; }

static void ring_write(u8 *ring, u32 n, u32 *pprod, const void *src, u32 len)
{
	u32 prod = *pprod, first = min(len, n - prod);
	memcpy(ring + prod, src, first);
	if (len > first) memcpy(ring, (const u8 *)src + first, len - first);
	*pprod = (prod + len) % n;
}
static void ring_read(u8 *ring, u32 n, u32 *pcons, void *dst, u32 len)
{
	u32 cons = *pcons, first = min(len, n - cons);
	memcpy(dst, ring + cons, first);
	if (len > first) memcpy((u8 *)dst + first, ring, len - first);
	*pcons = (cons + len) % n;
}

static void octc1_probe_run(struct octc1 *o)
{
	struct octc1_probe *pr = o->probe;
	u32 subidx = hdr_rd(&pr->subidx);
	u64 subval = ((u64)hdr_rd(&pr->subval_hi) << 32) | hdr_rd(&pr->subval_lo);
	u64 cardio = ((u64)hdr_rd(&pr->cardio_hi) << 32) | hdr_rd(&pr->cardio_lo);
	u32 pattern = hdr_rd(&pr->pattern);
	u32 len = hdr_rd(&pr->len);
	u32 marker_off = hdr_rd(&pr->marker_off);
	u32 full_did = (cardio >> 40) & 0xff;
	u64 fill;
	u32 i;
	volatile u8 *p;

	/* Constrain the target to the PCIe mem-access window (is_io set, did=3
	 * with subdid 0-7 -> full_did 24-31, nothing above bit 48) so a bad host
	 * guess can only ever generate an upstream PCIe write, never clobber a
	 * card CSR or card DRAM. */
	if (subidx < 12 || subidx > 27 || len > (1u << 21) ||
	    marker_off + 4 > (1u << 21) || !((cardio >> 48) & 1) ||
	    (cardio >> 49) || full_did < 24 || full_did > 31) {
		hdr_wr(&pr->fault, 1);
		return;
	}

	cvmx_write_csr(CVMX_PEXP_SLI_MEM_ACCESS_SUBIDX(subidx), subval);
	cvmx_read_csr(CVMX_PEXP_SLI_MEM_ACCESS_SUBIDX(subidx));

	p = cvmx_phys_to_ptr(cardio);
	fill = (pattern & 0xff) * 0x0101010101010101ull;
	for (i = 0; i + 8 <= len; i += 8)
		*(volatile u64 *)(p + i) = fill;
	for (; i < len; i++)
		p[i] = pattern & 0xff;

	CVMX_SYNCW;
	*(volatile u32 *)(p + marker_off) = hdr_rd(&pr->trigger);
	CVMX_SYNCW;
	hdr_wr(&pr->fault, 0);
}

/* esw=1 makes the card's native big-endian stores byte-identical in host RAM, so
 * this is a straight copy; the u64 fast path needs an 8-aligned source. */
static void octc1_to_host(volatile u8 *dst, const u8 *src, u32 len)
{
	while (len >= 8 && !((unsigned long)src & 7)) {
		*(volatile u64 *)dst = *(const u64 *)src;
		dst += 8; src += 8; len -= 8;
	}
	while (len--)
		*dst++ = *src++;
}

/* Record how far DPI bring-up got into a fixed card-DRAM slot the host can BAR-read
 * after a hang: this kernel never clocks DPI, so an unguarded CSR access wedges the
 * core silently (no panic), and the last stage written localises which access. */
#define DPI_DBG_OFF	240u
static inline void dpi_stage(struct octc1 *o, u32 s)
{
	*(volatile __be32 *)((u8 *)o->region + DPI_DBG_OFF) = cpu_to_be32(s);
	CVMX_SYNCW;
}

static int octc1_dpi_init(struct octc1 *o)
{
	u32 i;
	u64 ctl_rb;
	size_t bytes = (DPI_CHUNK_WORDS + 32) * sizeof(u64);

	o->dpi_chunk = kzalloc(bytes, GFP_KERNEL);
	if (!o->dpi_chunk)
		return -ENOMEM;
	/* cvmx_ptr_to_phys, not virt_to_phys: on the 64-bit OCTEON kernel these buffers
	 * live in XKPHYS, and virt_to_phys (built for kseg0) yields a bogus address --
	 * which as IBUFF_SADDR makes DPI fetch garbage "instructions" and scribble over
	 * card DRAM. The same applies to every DMA pointer below. */
	o->dpi_chunk_phys = cvmx_ptr_to_phys(o->dpi_chunk);
	/* IBUFF_SADDR carries phys>>7, so the chunk must be 128-byte aligned or DPI
	 * would fetch instructions from a truncated address. */
	if (o->dpi_chunk_phys & 127) {
		pr_warn("octc1: DPI chunk phys 0x%llx not 128B aligned\n",
			(unsigned long long)o->dpi_chunk_phys);
		kfree(o->dpi_chunk);
		o->dpi_chunk = NULL;
		return -EINVAL;
	}
	/* Completion byte lives in the uncached WC region (a single mapping, so no
	 * cacheable alias), paired with PT=1 (no-cache-allocate) writes in the
	 * instruction below. A cacheable flag could read stale after the DMA's ZBW
	 * write -- spinning rx_thread to the 2M timeout on every packet, and worse,
	 * letting the IBUFF rewind fire while the engine isn't actually idle, which
	 * scribbles over card DRAM (corrupting the console + wedging boot). */
	o->dpi_comp = (volatile u8 *)((u8 *)o->h2c + 768);
	o->dpi_comp_phys = OCTC1_PHYS + OCTC1_HDR + OCTC1_RING + 768;
	o->dpi_ibuff = ((u64)DPI_CHUNK_WORDS << 48) |
		       (((o->dpi_chunk_phys >> 7) & ((1ull << 33) - 1)) << 7);
	o->dpi_index = 0;
	o->dpi_dbg = (u8 *)o->h2c + 1024;
	o->dpi_seq = 0;

	/* The PCIe RC-init path that normally clocks DPI never runs on this EP card,
	 * so DPI_CTL[CLK] is off and any DPI read would hang. Force the conditional
	 * clock on with a blind WRITE first (DPI_CTL itself is always-clocked; posted
	 * writes don't stall), then reads are safe. CLK before EN, EN before
	 * DPI_DMA_CONTROL[*_EN] per errata DPI-15368. */
	dpi_stage(o, 1);
	cvmx_write_csr(CVMX_DPI_CTL, 3);	/* clk=1, en=1 */
	dpi_stage(o, 2);
	ctl_rb = cvmx_read_csr(CVMX_DPI_CTL);
	dpi_stage(o, 3);

	for (i = 0; i < 5; i++)
		cvmx_write_csr(CVMX_DPI_ENGX_BUF(i), 2);
	cvmx_write_csr(CVMX_DPI_ENGX_BUF(5), 6);
	dpi_stage(o, 4);

	/* dma_enb=engines 0-4 (bit48), o_mode=1 (bit14: address from the pointer, ES/NS/RO
	 * from this register), o_es=1 (bit15: byte-swap each 64-bit word). The card is
	 * big-endian, so without the swap it reads the host's little-endian byte stream as
	 * BE and lands every u64 byte-reversed -- the mirror of why C2H stores use esw=1. */
	cvmx_write_csr(CVMX_DPI_DMA_CONTROL, (0x1full << 48) | (1ull << 14) | (1ull << 15));
	cvmx_write_csr(CVMX_DPI_DMA_ENGX_EN(5), 0);
	dpi_stage(o, 5);

	cvmx_write_csr(CVMX_DPI_DMAX_IBUFF_SADDR(DPI_ENGINE), o->dpi_ibuff);
	cvmx_read_csr(CVMX_DPI_DMAX_IBUFF_SADDR(DPI_ENGINE));
	dpi_stage(o, 6);

	*(volatile __be32 *)(o->dpi_dbg + 0) = cpu_to_be32(0xDB100006u);
	*(volatile __be64 *)(o->dpi_dbg + 8) = cpu_to_be64(o->dpi_chunk_phys);
	*(volatile __be64 *)(o->dpi_dbg + 16) = cpu_to_be64(o->dpi_ibuff);
	*(volatile __be64 *)(o->dpi_dbg + 24) = cpu_to_be64(ctl_rb);
	CVMX_SYNCW;

	o->dpi_inited = true;
	return 0;
}

/* Card-mastered host->card copy: DPI engine 0 reads len bytes of host RAM (raw
 * PCIe bus address host_phys; VT-d is off so host phys maps 1:1) into card DRAM at
 * dst_phys. Serialized + completion-waited, so the engine is idle on entry and we
 * can rewind IBUFF_SADDR to the chunk base before nearing the link word. */
static int octc1_dpi_inbound(struct octc1 *o, u64 dst_phys, u64 host_phys, u32 len)
{
	u64 *cmd, first[2];
	u32 w = 0, rem = len, off = 0, i, nf = 0;
	int spins;

	if (o->dpi_index + DPI_MAX_IWORDS >= DPI_CHUNK_WORDS - 1) {
		cvmx_write_csr(CVMX_DPI_DMAX_IBUFF_SADDR(DPI_ENGINE), o->dpi_ibuff);
		cvmx_read_csr(CVMX_DPI_DMAX_IBUFF_SADDR(DPI_ENGINE));
		o->dpi_index = 0;
	}
	cmd = o->dpi_chunk + o->dpi_index;

	while (rem) {
		u32 c = min(rem, DPI_SEG_MAX);
		first[nf++] = (1ull << 61) | ((u64)c << 48) | ((dst_phys + off) & DPI_ADDR_MASK);
		off += c; rem -= c;
	}
	/* pt=1 (bit 44): completion ZBW does NOT allocate an L2 line, so the byte lands
	 * in DRAM where the uncached comp poll reads it. */
	cmd[w++] = (DPI_HDR_TYPE_INBOUND << 52) | (1ull << 44) | (1ull << 38) | ((u64)nf << 32);
	cmd[w++] = o->dpi_comp_phys & DPI_ADDR_MASK;
	for (i = 0; i < nf; i++)
		cmd[w++] = first[i];
	cmd[w++] = (u64)len << 48;
	cmd[w++] = host_phys;

	*o->dpi_comp = 0xff;
	CVMX_SYNCWS;
	o->dpi_index += w;
	cvmx_write_csr(CVMX_DPI_DMAX_DBELL(DPI_ENGINE), w);

	{
		int rc = -ETIMEDOUT;
		for (spins = 0; spins < 2000000; spins++) {
			if (READ_ONCE(*o->dpi_comp) == 0) { rc = 0; break; }
			cpu_relax();
		}
		if (o->dpi_seq < 24) {
			u8 *e = o->dpi_dbg + 64 + o->dpi_seq * 64;
			const u8 *got = cvmx_phys_to_ptr(dst_phys);
			*(volatile __be32 *)(e + 0) = cpu_to_be32(o->dpi_seq);
			*(volatile __be32 *)(e + 4) = cpu_to_be32(len);
			*(volatile __be32 *)(e + 8) = cpu_to_be32(rc ? 1u : 0u);
			*(volatile __be64 *)(e + 16) = cpu_to_be64(host_phys);
			*(volatile __be64 *)(e + 24) = cpu_to_be64(dst_phys);
			for (i = 0; i < 32 && i < len; i++)
				e[32 + i] = got[i];
			*(volatile __be32 *)(o->dpi_dbg + 4) = cpu_to_be32(o->dpi_seq + 1);
			CVMX_SYNCW;
		}
		o->dpi_seq++;
		return rc;
	}
}

static void octc1_c2h_setup(struct octc1 *o)
{
	struct octc1_c2h *c = o->c2hh;
	u32 subidx = hdr_rd(&c->subidx);
	u64 subval = ((u64)hdr_rd(&c->subval_hi) << 32) | hdr_rd(&c->subval_lo);
	u64 cardio = ((u64)hdr_rd(&c->cardio_hi) << 32) | hdr_rd(&c->cardio_lo);
	u32 full_did = (cardio >> 40) & 0xff;

	if (subidx < 12 || subidx > 27 || !((cardio >> 48) & 1) ||
	    (cardio >> 49) || full_did < 24 || full_did > 31) {
		pr_warn("octc1: bad c2h host window cardio=0x%llx subidx=%u\n",
			(unsigned long long)cardio, subidx);
		return;
	}

	cvmx_write_csr(CVMX_PEXP_SLI_MEM_ACCESS_SUBIDX(subidx), subval);
	cvmx_read_csr(CVMX_PEXP_SLI_MEM_ACCESS_SUBIDX(subidx));

	o->hc_nslots = hdr_rd(&c->nslots);
	o->hc_slot_size = hdr_rd(&c->slot_size);
	o->hc_desc = cvmx_phys_to_ptr(cardio + hdr_rd(&c->desc_off));
	o->hc_buf = cvmx_phys_to_ptr(cardio + hdr_rd(&c->buf_off));
	o->hc_prod = cvmx_phys_to_ptr(cardio + hdr_rd(&c->prod_off));
	o->hc_prodi = 0;
	*(volatile __be32 *)o->hc_prod = cpu_to_be32(0);
	CVMX_SYNCW;
	o->hc_on = true;
	pr_info("octc1: c2h host ring up: %u slots x %u B, cardio=0x%llx\n",
		o->hc_nslots, o->hc_slot_size, (unsigned long long)cardio);
}

/*
 * H2C via DPI: the host writes each packet into its OWN RAM and the card pulls it
 * with a DPI INBOUND DMA, so no payload ever crosses the card BAR (the per-packet
 * BAR data writes are what saturate and crash the card). Only tiny control words
 * live in card DRAM, reached over the BAR: prod + the per-slot desc[] (host-written,
 * card-read) and cons (card-written, host-read). The card learns the host payload
 * region from cardio_{hi,lo}, reused here as the raw host physical base of the host
 * slot ring (a PCIe bus address; VT-d is off so it maps 1:1).
 */
#define OCTC1_DPI_PROD_OFF	0u
#define OCTC1_DPI_CONS_OFF	4u
#define OCTC1_DPI_DESC_OFF	16u

static void octc1_h2c_setup(struct octc1 *o)
{
	struct octc1_h2c *h = o->h2ch;
	u64 host_buf_phys = ((u64)hdr_rd(&h->cardio_hi) << 32) | hdr_rd(&h->cardio_lo);
	u32 nslots = hdr_rd(&h->nslots);
	u32 slot_size = hdr_rd(&h->slot_size);

	if (!host_buf_phys || nslots == 0 || nslots > 1024 ||
	    slot_size < 64 || slot_size > OCTC1_MAXFRAME ||
	    OCTC1_DPI_DESC_OFF + nslots * 4 > OCTC1_RING) {
		pr_warn("octc1: bad h2c dma params buf=0x%llx nslots=%u slot=%u\n",
			(unsigned long long)host_buf_phys, nslots, slot_size);
		return;
	}

	if (!o->dpi_inited && octc1_dpi_init(o)) {
		pr_warn("octc1: DPI init failed; h2c dma not enabled\n");
		return;
	}

	o->hd_host_buf_phys = host_buf_phys;
	o->hd_nslots = nslots;
	o->hd_slot_size = slot_size;
	o->hd_prod = (u8 *)o->h2c + OCTC1_DPI_PROD_OFF;
	o->hd_cons = (u8 *)o->h2c + OCTC1_DPI_CONS_OFF;
	o->hd_desc = (u8 *)o->h2c + OCTC1_DPI_DESC_OFF;
	o->hd_consi = 0;
	/* cons=0 both initialises the consumer and ACKs the host, which spins on cons
	 * flipping from its UINT32_MAX sentinel to 0. */
	*(volatile __be32 *)o->hd_cons = cpu_to_be32(0);
	CVMX_SYNCW;
	o->hd_on = true;
	pr_info("octc1: h2c dma up: %u slots x %u B, host buf 0x%llx\n",
		o->hd_nslots, o->hd_slot_size, (unsigned long long)host_buf_phys);
}

static netdev_tx_t octc1_xmit_host(struct sk_buff *skb, struct net_device *dev)
{
	struct octc1 *o = g;
	u32 len = skb->len, prod, hcons, slot;
	unsigned long flags;

	if (len > o->hc_slot_size) { dev->stats.tx_dropped++; dev_kfree_skb(skb); return NETDEV_TX_OK; }

	spin_lock_irqsave(&o->hc_lock, flags);
	prod = o->hc_prodi;
	hcons = be32_to_cpu(READ_ONCE(o->c2hh->hcons));
	if (prod - hcons >= o->hc_nslots) {
		netif_stop_queue(dev);
		spin_unlock_irqrestore(&o->hc_lock, flags);
		return NETDEV_TX_BUSY;
	}
	slot = prod % o->hc_nslots;
	octc1_to_host(o->hc_buf + (u64)slot * o->hc_slot_size, skb->data, len);
	*(volatile __be32 *)(o->hc_desc + slot * 4) = cpu_to_be32(len);
	CVMX_SYNCW;
	o->hc_prodi = prod + 1;
	*(volatile __be32 *)o->hc_prod = cpu_to_be32(o->hc_prodi);
	CVMX_SYNCW;
	if (o->hc_prodi - hcons >= o->hc_nslots)
		netif_stop_queue(dev);
	spin_unlock_irqrestore(&o->hc_lock, flags);

	dev->stats.tx_packets++;
	dev->stats.tx_bytes += len;
	dev_kfree_skb(skb);
	return NETDEV_TX_OK;
}

static netdev_tx_t octc1_xmit(struct sk_buff *skb, struct net_device *dev)
{
	struct octc1 *o = g;
	u32 n = o->ring_bytes, len = skb->len;
	u32 prod, cons;
	__be32 belen = cpu_to_be32(len);

	if (o->hc_on)
		return octc1_xmit_host(skb, dev);

	prod = hdr_rd(&o->hdr->c2h_prod);
	cons = hdr_rd(&o->hdr->c2h_cons);

	if (len > OCTC1_MAXFRAME) { dev->stats.tx_dropped++; dev_kfree_skb(skb); return NETDEV_TX_OK; }
	/* No room: stop the queue and push back (no drop) so TCP flow-controls to
	 * the host's drain rate instead of collapsing on loss; rx_thread re-wakes. */
	if (ring_space(prod, cons, n) < len + 4) {
		netif_stop_queue(dev);
		cons = hdr_rd(&o->hdr->c2h_cons);
		if (ring_space(prod, cons, n) < len + 4)
			return NETDEV_TX_BUSY;
		netif_wake_queue(dev);
	}
	ring_write(o->c2h, n, &prod, &belen, 4);
	ring_write(o->c2h, n, &prod, skb->data, len);
	smp_wmb();
	hdr_wr(&o->hdr->c2h_prod, prod);
	dev->stats.tx_packets++;
	dev->stats.tx_bytes += len;
	if (ring_space(prod, hdr_rd(&o->hdr->c2h_cons), n) < OCTC1_MAXFRAME + 4)
		netif_stop_queue(dev);
	dev_kfree_skb(skb);
	return NETDEV_TX_OK;
}

static int octc1_rx_thread(void *data)
{
	struct octc1 *o = data;
	u32 n = o->ring_bytes;

	while (!kthread_should_stop()) {
		u32 prod = hdr_rd(&o->hdr->h2c_prod);
		u32 cons = hdr_rd(&o->hdr->h2c_cons);
		__be32 belen;
		u32 len;
		struct sk_buff *skb;
		u32 trig = hdr_rd(&o->probe->trigger);

		if (trig != o->probe_last) {
			o->probe_last = trig;
			octc1_probe_run(o);
			hdr_wr(&o->probe->done, trig);
		}

		{
			u32 ena = hdr_rd(&o->c2hh->ena);
			if (ena != o->hc_ena_last) {
				o->hc_ena_last = ena;
				if (ena)
					octc1_c2h_setup(o);
				else
					o->hc_on = false;
			}
		}

		{
			u32 ena = hdr_rd(&o->h2ch->ena);
			if (ena != o->hd_ena_last) {
				o->hd_ena_last = ena;
				if (ena)
					octc1_h2c_setup(o);
				else
					o->hd_on = false;
			}
		}

		if (netif_queue_stopped(o->ndev)) {
			if (o->hc_on) {
				if (o->hc_prodi - be32_to_cpu(READ_ONCE(o->c2hh->hcons)) < o->hc_nslots - 1)
					netif_wake_queue(o->ndev);
			} else if (ring_space(hdr_rd(&o->hdr->c2h_prod), hdr_rd(&o->hdr->c2h_cons), n) > 2 * (OCTC1_MAXFRAME + 4)) {
				netif_wake_queue(o->ndev);
			}
		}

		/* H2C-DMA: prod and the per-slot desc(=len) live in card DRAM, written by
		 * the host over the BAR; the payload stays in host RAM. The host writes
		 * desc then bumps prod (PCIe-ordered), so a slot below prod has a valid
		 * length. Pull the payload with a DPI INBOUND DMA, then publish cons back
		 * to card DRAM so the host can reuse the slot and account free space. */
		if (o->hd_on) {
			u32 hprod = be32_to_cpu(READ_ONCE(*(volatile __be32 *)o->hd_prod));
			int got = 0;
			while (o->hd_consi != hprod) {
				u32 slot = o->hd_consi % o->hd_nslots;
				u32 dlen = be32_to_cpu(READ_ONCE(*(volatile __be32 *)(o->hd_desc + slot * 4)));
				struct sk_buff *s;

				if (dlen == 0 || dlen > o->hd_slot_size)
					break;
				s = netdev_alloc_skb(o->ndev, dlen);
				if (!s) {
					o->ndev->stats.rx_dropped++;
				} else if (octc1_dpi_inbound(o, cvmx_ptr_to_phys(skb_put(s, dlen)),
						o->hd_host_buf_phys + (u64)slot * o->hd_slot_size, dlen)) {
					o->ndev->stats.rx_errors++;
					kfree_skb(s);
					/* drop this packet but still free the slot, so one bad/slow
					 * DMA can't wedge the whole H2C ring */
				} else {
					skb_reset_network_header(s);
					s->protocol = (s->data[0] >> 4) == 6 ? htons(ETH_P_IPV6) : htons(ETH_P_IP);
					s->dev = o->ndev;
					o->ndev->stats.rx_packets++;
					o->ndev->stats.rx_bytes += dlen;
					netif_rx(s);
				}
				*(volatile __be32 *)(o->hd_desc + slot * 4) = cpu_to_be32(0);
				o->hd_consi++;
				*(volatile __be32 *)o->hd_cons = cpu_to_be32(o->hd_consi);
				CVMX_SYNCW;
				got = 1;
			}
			if (!got)
				usleep_range(50, 150);
			continue;
		}

		if (ring_used(prod, cons, n) < 4) { usleep_range(50, 150); continue; }
		smp_rmb();
		ring_read(o->h2c, n, &cons, &belen, 4);
		len = be32_to_cpu(belen);
		if (len == 0 || len > OCTC1_MAXFRAME) { hdr_wr(&o->hdr->h2c_cons, prod); continue; }
		if (ring_used(prod, hdr_rd(&o->hdr->h2c_cons), n) < len + 4) { usleep_range(50, 150); continue; }

		skb = netdev_alloc_skb(o->ndev, len);
		if (!skb) { o->ndev->stats.rx_dropped++; cons = (cons + len) % n; }
		else {
			ring_read(o->h2c, n, &cons, skb_put(skb, len), len);
			skb_reset_network_header(skb);
			skb->protocol = (skb->data[0] >> 4) == 6 ? htons(ETH_P_IPV6) : htons(ETH_P_IP);
			skb->dev = o->ndev;
			o->ndev->stats.rx_packets++;
			o->ndev->stats.rx_bytes += len;
			netif_rx(skb);
		}
		hdr_wr(&o->hdr->h2c_cons, cons);
	}
	return 0;
}

static int octc1_open(struct net_device *dev) { netif_start_queue(dev); return 0; }
static int octc1_stop(struct net_device *dev) { netif_stop_queue(dev); return 0; }
static const struct net_device_ops octc1_ops = {
	.ndo_open = octc1_open,
	.ndo_stop = octc1_stop,
	.ndo_start_xmit = octc1_xmit,
};

static void octc1_setup(struct net_device *dev)
{
	dev->netdev_ops = &octc1_ops;
	dev->type = ARPHRD_NONE;
	dev->hard_header_len = 0;
	dev->addr_len = 0;
	dev->mtu = 1500;
	dev->min_mtu = 68;
	dev->max_mtu = OCTC1_MAXFRAME - 4;
	dev->tx_queue_len = 1000;
	dev->flags = IFF_POINTOPOINT | IFF_NOARP;
}

static int __init octc1_init(void)
{
	struct octc1 *o;
	int err;

	o = kzalloc(sizeof(*o), GFP_KERNEL);
	if (!o) return -ENOMEM;
	/* Uncached: the host writes the H2C ring + control fields into this card
	 * DRAM over PCIe; a cacheable (WB) mapping lets the card CPU read stale
	 * speculatively-prefetched lines (smp_rmb orders but does not invalidate),
	 * so under the high ACK rate of a TCP download the card sees corrupt ACKs,
	 * never advances its window, and RTO-retransmits at ~1 pkt/s. */
	o->region = memremap(OCTC1_PHYS, OCTC1_REGION, MEMREMAP_WC);
	if (!o->region)
		o->region = memremap(OCTC1_PHYS, OCTC1_REGION, MEMREMAP_WB);
	if (!o->region) { err = -ENOMEM; goto e_free; }
	o->hdr = o->region;
	o->probe = (struct octc1_probe *)((u8 *)o->region + OCTC1_PROBE_OFF);
	o->c2hh = (struct octc1_c2h *)((u8 *)o->region + OCTC1_C2H_OFF);
	o->h2ch = (struct octc1_h2c *)((u8 *)o->region + OCTC1_H2C_OFF);
	o->ring_bytes = OCTC1_RING;
	o->c2h = (u8 *)o->region + OCTC1_HDR;
	o->h2c = (u8 *)o->region + OCTC1_HDR + OCTC1_RING;
	spin_lock_init(&o->hc_lock);

	memset(o->hdr, 0, sizeof(*o->hdr));
	memset(o->probe, 0, sizeof(*o->probe));
	memset(o->c2hh, 0, sizeof(*o->c2hh));
	memset(o->h2ch, 0, sizeof(*o->h2ch));
	hdr_wr(&o->hdr->c2h_off, OCTC1_HDR);
	hdr_wr(&o->hdr->c2h_bytes, OCTC1_RING);
	hdr_wr(&o->hdr->h2c_off, OCTC1_HDR + OCTC1_RING);
	hdr_wr(&o->hdr->h2c_bytes, OCTC1_RING);
	hdr_wr(&o->hdr->version, 1);
	hdr_wr(&o->probe->magic2, OCTC1_PROBE_MAGIC);
	smp_wmb();
	hdr_wr(&o->hdr->magic, OCTC1_MAGIC);

	o->ndev = alloc_netdev(0, "octc1", NET_NAME_UNKNOWN, octc1_setup);
	if (!o->ndev) { err = -ENOMEM; goto e_unmap; }
	err = register_netdev(o->ndev);
	if (err) goto e_efree;

	g = o;
	o->rx_thread = kthread_run(octc1_rx_thread, o, "octc1-rx");
	if (IS_ERR(o->rx_thread)) { err = PTR_ERR(o->rx_thread); g = NULL; goto e_unreg; }

	pr_info("octc1: up; region 0x%lx %uMB, ring %uKB each\n",
		OCTC1_PHYS, OCTC1_REGION >> 20, OCTC1_RING >> 10);
	return 0;

e_unreg:	unregister_netdev(o->ndev);
e_efree:	free_netdev(o->ndev);
e_unmap:	memunmap(o->region);
e_free:		kfree(o);
	return err;
}

static void __exit octc1_exit(void)
{
	struct octc1 *o = g;
	if (!o) return;
	if (o->rx_thread) kthread_stop(o->rx_thread);
	if (o->dpi_inited) {
		cvmx_write_csr(CVMX_DPI_DMAX_IBUFF_SADDR(DPI_ENGINE), 0);
		cvmx_read_csr(CVMX_DPI_DMAX_IBUFF_SADDR(DPI_ENGINE));
	}
	unregister_netdev(o->ndev);
	free_netdev(o->ndev);
	kfree(o->dpi_chunk);
	memunmap(o->region);
	kfree(o);
	g = NULL;
}

module_init(octc1_init);
module_exit(octc1_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("CN7890 card<->host shared-memory virtual IP link");
