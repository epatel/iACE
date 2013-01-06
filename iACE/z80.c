/* Emulation of the Z80 CPU with hooks into the other parts of xace.
 * Copyright (C) 1994 Ian Collier.
 * Z81 changes (C) 1995 Russell Marks.
 * xace changes (C) 1997 Edward Patel.
 * iACE changes (C) 2012 Edward Patel.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <stdio.h>
#include <string.h>

#include "z80.h"

#define parity(a) (partable[a])

unsigned char partable[256] = {
    4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
    0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
    0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
    4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
    0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
    4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
    4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
    0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
    0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
    4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
    4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
    0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
    4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
    0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
    0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
    4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4
};

static struct {
    unsigned char op;
    unsigned char a, f, b, c, d, e, h, l;
    unsigned char r, a1, f1, b1, c1, d1, e1, h1, l1, i, iff1, iff2, im;
    unsigned short pc;
    unsigned short ix, iy, sp;
    unsigned int radjust;
    unsigned char ixoriy, new_ixoriy;
    unsigned char intsample;
} g;

static char savedG[sizeof(g)];

void get_z80_internal_state(char **ptr, int *len)
{
    *ptr = (char*)&savedG;
    *len = sizeof(g);
}

void set_z80_internal_state(const char *ptr)
{
    memcpy(&g, ptr, sizeof(g));
}

void mainloop()
{
    extern unsigned long tstates, tsmax;

#define op g.op
#define a g.a
#define f g.f
#define b g.b
#define c g.c
#define d g.d
#define e g.e
#define h g.h
#define l g.l
#define r g.r
#define a1 g.a1
#define f1 g.f1
#define b1 g.b1
#define c1 g.c1
#define d1 g.d1
#define e1 g.e1
#define h1 g.h1
#define l1 g.l1
#define i g.i
#define iff1 g.iff1
#define iff2 g.iff2
#define im g.im
#define pc g.pc
#define ix g.ix
#define iy g.iy
#define sp g.sp
#define radjust g.radjust
#define ixoriy g.ixoriy
#define new_ixoriy g.new_ixoriy
#define intsample g.intsample
    
    a=f=b=c=d=e=h=l=a1=f1=b1=c1=d1=e1=h1=l1=i=r=iff1=iff2=im=0;
    ixoriy=new_ixoriy=0;
    ix=iy=sp=pc=0;
    tstates=radjust=0;
    
    while (1) {
        ixoriy=new_ixoriy;
        new_ixoriy=0;
        intsample=1;
        op=fetch(pc);
        pc++;
        radjust++;
        
        switch(op) {
#include "z80ops.c"
        }
        
        if (tstates > tsmax) {
            memcpy(&savedG, &g, sizeof(g));
            fix_tstates();
        }
        
        if (interrupted == 1 && intsample && iff1) {
            do_interrupt();
            push2(pc);
            pc=0x38;
            interrupted=0;
        }
        
        if (reset_ace) {
            /* actually a kludge to let us do a reset */
            a=f=b=c=d=e=h=l=a1=f1=b1=c1=d1=e1=h1=l1=i=r=iff1=iff2=im=0;
            ixoriy=new_ixoriy=0;
            ix=iy=sp=pc=0;
            tstates=radjust=0;
            reset_ace = 0;
        }
    }
}


