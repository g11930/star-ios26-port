#ifndef _SYS_STAR_DISPLAY_H_
#define _SYS_STAR_DISPLAY_H_

/* Read-only SM8350 display survey; enabled by boot-arg star_display_probe=1. */
void star_display_probe(void);

/* Loader/kernel framebuffer ownership contract; no register writes, ever. */
void star_display_handoff(void);
void star_display_milestone(const char *tag);
int  star_display_owner(void);
void star_display_claim(void);

/* s61: read-only mach_msg waiter survey; enabled by boot-arg star_msgprobe=1. */
void star_msgprobe_start(void);

#endif /* _SYS_STAR_DISPLAY_H_ */
