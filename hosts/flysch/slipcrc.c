/* slipcrc: CRC32-checked SLIP bridge between a tun device and a tty.
 * Replaces the kernel SLIP ldisc on the card. Each frame is the IP packet
 * followed by a little-endian CRC32, SLIP-framed. Frames failing CRC are
 * dropped so the lossy/corrupting PCIe-console link becomes ordinary packet
 * loss that TCP retransmits over. Same wire format as guyot's bridge. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <linux/if_tun.h>
#include <sys/select.h>
#include <stdint.h>

#define END 0xC0
#define ESC 0xDB
#define ESC_END 0xDC
#define ESC_ESC 0xDD

static uint32_t crc_tab[256];
static void crc_init(void){
    for (uint32_t i=0;i<256;i++){ uint32_t c=i; for(int k=0;k<8;k++) c = (c&1)?0xEDB88320u^(c>>1):c>>1; crc_tab[i]=c; }
}
static uint32_t crc32(const uint8_t*p,int n){
    uint32_t c=0xFFFFFFFFu; for(int i=0;i<n;i++) c=crc_tab[(c^p[i])&0xFF]^(c>>8); return c^0xFFFFFFFFu;
}

static int tun_alloc(const char*dev){
    int fd=open("/dev/net/tun",O_RDWR); if(fd<0)return -1;
    struct ifreq ifr; memset(&ifr,0,sizeof ifr);
    ifr.ifr_flags=IFF_TUN|IFF_NO_PI;
    strncpy(ifr.ifr_name,dev,IFNAMSIZ-1);
    if(ioctl(fd,TUNSETIFF,&ifr)<0){close(fd);return -1;}
    return fd;
}

int main(int argc,char**argv){
    const char*tundev=argc>1?argv[1]:"octc0";
    const char*ttydev=argc>2?argv[2]:"/dev/ttyPCI1";
    crc_init();
    int tun=tun_alloc(tundev); if(tun<0){perror("tun_alloc");return 1;}
    int tty=open(ttydev,O_RDWR|O_NOCTTY); if(tty<0){perror("open tty");return 1;}
    struct termios t; if(tcgetattr(tty,&t)==0){ cfmakeraw(&t); t.c_cc[VMIN]=1; t.c_cc[VTIME]=0; tcsetattr(tty,TCSANOW,&t); }

    uint8_t rx[8192], frame[2600], pkt[2048], out[5400];
    int flen=0, esc=0;
    fd_set fds; int mx=tun>tty?tun:tty;
    for(;;){
        FD_ZERO(&fds); FD_SET(tun,&fds); FD_SET(tty,&fds);
        if(select(mx+1,&fds,0,0,0)<0){ if(errno==EINTR)continue; break; }
        if(FD_ISSET(tun,&fds)){
            int n=read(tun,pkt,sizeof pkt);
            if(n>0){
                uint32_t c=crc32(pkt,n);
                uint8_t tmp[2052]; memcpy(tmp,pkt,n);
                tmp[n]=c&0xFF; tmp[n+1]=(c>>8)&0xFF; tmp[n+2]=(c>>16)&0xFF; tmp[n+3]=(c>>24)&0xFF;
                int m=n+4, o=0; out[o++]=END;
                for(int i=0;i<m;i++){
                    if(tmp[i]==END){out[o++]=ESC;out[o++]=ESC_END;}
                    else if(tmp[i]==ESC){out[o++]=ESC;out[o++]=ESC_ESC;}
                    else out[o++]=tmp[i];
                }
                out[o++]=END;
                int w=0; while(w<o){ int r=write(tty,out+w,o-w); if(r<=0){ if(errno==EINTR)continue; break;} w+=r; }
            }
        }
        if(FD_ISSET(tty,&fds)){
            int n=read(tty,rx,sizeof rx);
            for(int i=0;i<n;i++){
                uint8_t b=rx[i];
                if(b==END){
                    if(flen>=5){
                        uint32_t got=frame[flen-4]|(frame[flen-3]<<8)|(frame[flen-2]<<16)|((uint32_t)frame[flen-1]<<24);
                        if(crc32(frame,flen-4)==got){ int dl=flen-4; int w=0; while(w<dl){int r=write(tun,frame+w,dl-w); if(r<=0){if(errno==EINTR)continue; break;} w+=r;} }
                    }
                    flen=0; esc=0;
                } else if(esc){
                    if(flen<(int)sizeof frame) frame[flen++]=(b==ESC_END?END:b==ESC_ESC?ESC:b);
                    esc=0;
                } else if(b==ESC){ esc=1; }
                else { if(flen<(int)sizeof frame) frame[flen++]=b; }
            }
        }
    }
    return 0;
}
