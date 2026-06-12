/*
 * This file is subject to the terms and conditions of the GNU General Public
 * License.  See the file "COPYING" in the main directory of this archive
 * for more details.
 *
 * Copyright (C) 2006-2012 Cavium, Inc.
 *
 * octeon_pci_console uses a protocol for sending and receiving byte streams
 * through in-memory ring buffers.  A pseudo-tty driver/program on a host
 * machine services the buffers over a PCI link.  This implements the client
 * side when the OCTEON SOC is in PCI target mode.  Ported forward from the
 * Cavium SDK (4.9) to the modern tty/timer/console APIs.
 */

#define pr_fmt(fmt) KBUILD_MODNAME ": " fmt

#include <linux/console.h>
#include <linux/tty.h>
#include <linux/tty_driver.h>
#include <linux/tty_flip.h>
#include <linux/module.h>
#include <linux/timer.h>
#include <linux/hrtimer.h>
#include <linux/ktime.h>

#include <asm/byteorder.h>
#include <asm/io.h>

#include <asm/octeon/octeon.h>
#include <asm/octeon/cvmx-bootmem.h>

#define OCTEON_PCI_CONSOLE_BLOCK_NAME	"__pci_console"

struct octeon_pci_console_rings {
#ifdef __BIG_ENDIAN
	u64 input_base_addr;
	volatile u32 input_read_index;
	volatile u32 input_write_index;
	u64 output_base_addr;
	volatile u32 output_read_index;
	volatile u32 output_write_index;
	u32 unused;
	u32 buf_size;
#else /* __LITTLE_ENDIAN */
	u64 input_base_addr;
	volatile u32 input_write_index;
	volatile u32 input_read_index;
	u64 output_base_addr;
	volatile u32 output_write_index;
	volatile u32 output_read_index;
	u32 buf_size;
	u32 unused;
#endif
};

struct octeon_pci_console_desc {
#ifdef __BIG_ENDIAN
	u32 major_version;
	u32 minor_version;
	u32 lock;
	u32 flags;
	u32 num_consoles;
	u32 pad;
#else /* __LITTLE_ENDIAN */
	u32 minor_version;
	u32 major_version;
	u32 flags;
	u32 lock;
	u32 pad;
	u32 num_consoles;
#endif
	/* Array of addresses of struct octeon_pci_console_rings structures */
	u64 console_addr_array[];
};

struct octeon_pci_console {
	struct console con;
	struct tty_driver *ttydrv;
	spinlock_t lock;
	struct octeon_pci_console_rings *rings;
	u8 *input_ring;
	u8 *output_ring;
	struct hrtimer poll_timer;
	struct tty_struct *tty;
	int open_count;
	int index;
	struct tty_port tty_port;
};

#define OCTEON_PCI_CONSOLE_MAX 4
static struct octeon_pci_console opc_array[OCTEON_PCI_CONSOLE_MAX];
static int octeon_pci_console_num = 1;

#ifdef __BIG_ENDIAN
#define copy_to_ring memcpy
#else /* __LITTLE_ENDIAN */
/* console buffers are scrambled for __LITTLE_ENDIAN */
static void copy_to_ring(u8 *dst, const u8 *src, unsigned int n)
{
	while (n) {
		u8 *pd = (u8 *)((unsigned long)dst ^ 7);
		*pd = *src;
		n--;
		dst++;
		src++;
	}
}
#endif

/* Write all the data, spinning while the reader frees buffer space. */
static void octeon_pci_console_lowlevel_write(struct octeon_pci_console *opc,
					      const char *str, unsigned int len)
{
	u32 s = opc->rings->buf_size;

	spin_lock(&opc->lock);
	while (len > 0) {
		u32 r = opc->rings->output_read_index;
		u32 w = opc->rings->output_write_index;
		u32 a = ((s - 1) - (w - r)) % s;
		unsigned int n;

		if (!a)
			continue;
		if (r <= w)
			n = min(a, min(len, s - w));
		else
			n = min(a, min(len, r - w));

		copy_to_ring(opc->output_ring + w, str, n);
		len -= n;
		str += n;
		w = (w + n) % s;
		wmb();
		opc->rings->output_write_index = w;
		wmb();
	}
	spin_unlock(&opc->lock);
}

static void octeon_pci_console_write(struct console *con, const char *str,
				     unsigned int len)
{
	octeon_pci_console_lowlevel_write(con->data, str, len);
}

static u32 octeon_pci_console_output_free(struct octeon_pci_console *opc)
{
	u32 s = opc->rings->buf_size;
	u32 r = opc->rings->output_read_index;
	u32 w = opc->rings->output_write_index;

	return ((s - 1) - (w - r)) % s;
}

/* Non-spinning write for the tty/network path: copy what fits and return it so
 * the line discipline applies flow control instead of stalling the TX queue. */
static unsigned int octeon_pci_console_write_room_nb(struct octeon_pci_console *opc,
						     const u8 *str, unsigned int len)
{
	u32 s = opc->rings->buf_size;
	unsigned int written = 0;

	spin_lock(&opc->lock);
	while (len > 0) {
		u32 r = opc->rings->output_read_index;
		u32 w = opc->rings->output_write_index;
		u32 a = ((s - 1) - (w - r)) % s;
		unsigned int n;

		if (!a)
			break;
		if (r <= w)
			n = min(a, min(len, s - w));
		else
			n = min(a, min(len, r - w));

		copy_to_ring(opc->output_ring + w, str, n);
		len -= n;
		str += n;
		written += n;
		w = (w + n) % s;
		wmb();
		opc->rings->output_write_index = w;
		wmb();
	}
	spin_unlock(&opc->lock);
	return written;
}

static struct tty_driver *octeon_pci_console_device(struct console *con,
						    int *index)
{
	struct octeon_pci_console *opc = con->data;

	*index = opc->index;
	return opc->ttydrv;
}

static int octeon_pci_console_setup0(struct octeon_pci_console *opc)
{
	struct octeon_pci_console_desc *opcd;

	if (!opc->rings) {
		const struct cvmx_bootmem_named_block_desc *block_desc =
			cvmx_bootmem_find_named_block(OCTEON_PCI_CONSOLE_BLOCK_NAME);
		if (block_desc == NULL || block_desc->base_addr == 0)
			return -1;

		opcd = phys_to_virt(block_desc->base_addr);
		/* Only version 1.0 of the protocol exists. */
		if (opcd->major_version != 1 || opcd->minor_version != 0)
			return -1;

		if (!opcd->console_addr_array[opc->index])
			return -1;
		opc->rings = phys_to_virt(opcd->console_addr_array[opc->index]);
		spin_lock_init(&opc->lock);
		opc->input_ring = phys_to_virt(opc->rings->input_base_addr);
		opc->output_ring = phys_to_virt(opc->rings->output_base_addr);
	}
	return 0;
}

static int octeon_pci_console_setup(struct console *con, char *arg)
{
	return octeon_pci_console_setup0(con->data) ? -1 : 0;
}

void octeon_pci_console_init(const char *arg)
{
	struct octeon_pci_console *c;
	int idx = 0;

	if (arg && (arg[3] >= '0') && (arg[3] <= '9'))
		sscanf(arg + 3, "%d", &idx);
	if (idx < 0 || idx >= OCTEON_PCI_CONSOLE_MAX)
		idx = 0;

	c = &opc_array[idx];
	c->index = idx;
	strcpy(c->con.name, "pci");
	c->con.write = octeon_pci_console_write;
	c->con.device = octeon_pci_console_device;
	c->con.setup = octeon_pci_console_setup;
	c->con.flags = CON_PRINTBUFFER;
	c->con.data = c;
	register_console(&c->con);
}

/* High-resolution poll of the PCI device for input data. The host can only
 * push bytes into the ring (no doorbell/IRQ), and the old jiffy timer at
 * HZ=100 meant up to 10 ms of latency on every inbound packet — and on every
 * TCP ACK, which throttled throughput. Poll every 100 us in soft-irq context. */
static enum hrtimer_restart octeon_pci_console_read_poll(struct hrtimer *t)
{
	struct octeon_pci_console *opc =
		container_of(t, struct octeon_pci_console, poll_timer);
	struct tty_struct *tty = opc->tty;
	int nr;
	u32 s = opc->rings->buf_size;
	u32 r = opc->rings->input_read_index;
	u32 w = opc->rings->input_write_index;
	u32 a = (w - r) % s;
#ifdef __LITTLE_ENDIAN
	int i;
	u8 buffer[32];
#endif

	while (a > 0) {
		u8 *buf;
		unsigned int n;

		if (r > w)
			n = min(a, s - r);
		else
			n = min(a, w - r);
#ifdef __LITTLE_ENDIAN
		n = min_t(unsigned int, n, sizeof(buffer));
		for (i = 0; i < n; i++) {
			u8 *ps = (u8 *)((unsigned long)(opc->input_ring + r + i) ^ 7);
			buffer[i] = *ps;
		}
		buf = buffer;
#else /* __BIG_ENDIAN */
		buf = opc->input_ring + r;
#endif
		nr = tty_insert_flip_string(tty->port, buf, n);
		if (!nr)
			break;
		r = (r + nr) % s;
		a -= nr;
		tty_flip_buffer_push(tty->port);
	}
	opc->rings->input_read_index = r;
	wmb();

	/* Output space may have freed since the last TX; prompt the line
	 * discipline (SLIP) to push more so the network TX queue drains. */
	if (octeon_pci_console_output_free(opc))
		tty_wakeup(tty);

	hrtimer_forward_now(t, ns_to_ktime(100000));
	return HRTIMER_RESTART;
}

static int octeon_pci_console_tty_open(struct tty_struct *tty, struct file *filp)
{
	struct octeon_pci_console *opc = &opc_array[tty->index];

	if (octeon_pci_console_setup0(opc))
		return -ENODEV;

	opc->open_count++;
	if (opc->open_count == 1) {
		opc->tty = tty;
		hrtimer_setup(&opc->poll_timer, octeon_pci_console_read_poll,
			      CLOCK_MONOTONIC, HRTIMER_MODE_REL_SOFT);
		hrtimer_start(&opc->poll_timer, ns_to_ktime(100000),
			      HRTIMER_MODE_REL_SOFT);
	}
	return 0;
}

static void octeon_pci_console_tty_close(struct tty_struct *tty,
					 struct file *filp)
{
	struct octeon_pci_console *opc = &opc_array[tty->index];

	opc->open_count--;
	if (opc->open_count == 0)
		hrtimer_cancel(&opc->poll_timer);
}

static ssize_t octeon_pci_console_tty_write(struct tty_struct *tty,
					    const u8 *buf, size_t count)
{
	return octeon_pci_console_write_room_nb(&opc_array[tty->index], buf, count);
}

static void octeon_pci_console_tty_send_xchar(struct tty_struct *tty, u8 ch)
{
	octeon_pci_console_lowlevel_write(&opc_array[tty->index], &ch, 1);
}

static unsigned int octeon_pci_console_tty_write_room(struct tty_struct *tty)
{
	return octeon_pci_console_output_free(&opc_array[tty->index]);
}

static unsigned int octeon_pci_console_tty_chars_in_buffer(struct tty_struct *tty)
{
	return 0;
}

static const struct tty_operations octeon_pci_tty_ops = {
	.open = octeon_pci_console_tty_open,
	.close = octeon_pci_console_tty_close,
	.write = octeon_pci_console_tty_write,
	.write_room = octeon_pci_console_tty_write_room,
	.send_xchar = octeon_pci_console_tty_send_xchar,
	.chars_in_buffer = octeon_pci_console_tty_chars_in_buffer,
};

static int __init octeon_pci_console_module_init(void)
{
	const struct cvmx_bootmem_named_block_desc *block_desc =
		cvmx_bootmem_find_named_block(OCTEON_PCI_CONSOLE_BLOCK_NAME);
	struct tty_driver *d;
	int r, i;

	if (block_desc && block_desc->base_addr) {
		struct octeon_pci_console_desc *opcd =
			phys_to_virt(block_desc->base_addr);
		if (opcd->major_version == 1 && opcd->minor_version == 0 &&
		    opcd->num_consoles >= 1)
			octeon_pci_console_num =
				min_t(int, opcd->num_consoles,
				      OCTEON_PCI_CONSOLE_MAX);
	}

	d = tty_alloc_driver(octeon_pci_console_num, 0);
	if (IS_ERR(d))
		return PTR_ERR(d);

	for (i = 0; i < octeon_pci_console_num; i++) {
		opc_array[i].index = i;
		opc_array[i].ttydrv = d;
		if (octeon_pci_console_setup0(&opc_array[i])) {
			pr_notice("console %d not created.\n", i);
			r = -ENODEV;
			goto err;
		}
	}
	pr_info("Initialized %d console(s).\n", octeon_pci_console_num);

	d->owner = THIS_MODULE;
	d->driver_name = "octeon_pci_console";
	d->name = "ttyPCI";
	d->type = TTY_DRIVER_TYPE_SERIAL;
	d->subtype = SERIAL_TYPE_NORMAL;
	d->flags = TTY_DRIVER_REAL_RAW;
	d->major = 4;
	d->minor_start = 96;
	d->init_termios = tty_std_termios;
	d->init_termios.c_cflag = B9600 | CS8 | CREAD | HUPCL | CLOCAL;
	tty_set_operations(d, &octeon_pci_tty_ops);
	for (i = 0; i < octeon_pci_console_num; i++) {
		tty_port_init(&opc_array[i].tty_port);
		tty_port_link_device(&opc_array[i].tty_port, d, i);
	}
	r = tty_register_driver(d);
	if (r)
		goto err;

	return 0;
err:
	tty_driver_kref_put(d);
	return r;
}
module_init(octeon_pci_console_module_init);
