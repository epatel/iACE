/* Miscellaneous glue code for iACE, copyright (C) 2012 Edward Patel.
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

#include <string.h>

#include "SoundGenerator.h"

#include "ace.rom.h"
#include "frogger.h"

#include "z80.h"

unsigned char mem[65536];
unsigned char *memptr[8] = {
    mem,
    mem+0x2000,
    mem+0x4000,
    mem+0x6000,
    mem+0x8000,
    mem+0xa000,
    mem+0xc000,
    mem+0xe000
};

unsigned char keyboard_get_keyport(int port);
void keyboard_keypress(int aceKey);
void keyboard_keyrelease(int aceKey);
void keyboard_clear();
void get_z80_internal_state(char **ptr, int *len);
void set_z80_internal_state(const char *ptr);

unsigned long tstates=0, tsmax=65000, tsmaxfreq=50;

int memattr[8] = {0,1,1,1,1,1,1,1}; /* 8K RAM Banks */

volatile int interrupted = 0;
int reset_ace = 0;

static NSMutableDictionary *tapes;

void save_p(int _de, int _hl)
{
    char filename[64];
    int i;
    static int firstTime=1;    
    static NSMutableData *_data=nil;
    static NSString *_filename=nil;
    
    if (firstTime) {
        _data = [NSMutableData data];
        
        i=0;
        while (!isspace(mem[_hl+1+i]) && i<10) {
            filename[i]=mem[_hl+1+i];
            i++;
        }
        filename[i++]='.';
        if (mem[8961]) { /* dict or bytes save */
            filename[i++]='b';
            filename[i++]='y';
            filename[i++]='t';
        } else {
            filename[i++]='d';
            filename[i++]='i';
            filename[i++]='c';
        }
        filename[i++]='\0';
        _filename = [NSString stringWithCString:filename encoding:NSUTF8StringEncoding];
        _de++;
        char bytes[2] = {
            _de&0xff,
            (_de>>8)&0xff,
        };
        [_data appendBytes:bytes length:sizeof(bytes)];
        [_data appendBytes:&mem[_hl] length:_de];
        firstTime = 0;
    } else {
        _de++;
        char bytes[2] = {
            _de&0xff,
            (_de>>8)&0xff,
        };
        [_data appendBytes:bytes length:sizeof(bytes)];
        [_data appendBytes:&mem[_hl] length:_de];
        firstTime = 1;
        
        tapes[_filename] = _data;

        NSString *dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        [tapes writeToFile:[dir stringByAppendingString:@"/tapes.dic"] atomically:YES];

        _filename = nil;
        _data = nil;
    }
}

unsigned char empty_bytes[799] = { /* a small screen       */
    0x1a,0x00,0x20,0x6f,             /* will be loaded if    */
    0x74,0x68,0x65,0x72,             /* wanted file can't be */
    0x20,0x20,0x20,0x20,             /* opened */
    0x20,0x00,0x03,0x00,
    0x24,0x20,0x20,0x20,
    0x20,0x20,0x20,0x20,
    0x20,0x20,0x20,0x20,
    0x01,0x03,0x43,0x6f,
    0x75,0x6c,0x64,0x6e,
    0x27,0x74,0x20,0x6c,
    0x6f,0x61,0x64,0x20,
    0x79,0x6f,0x75,0x72,
    0x20,0x66,0x69,0x6c,
    0x65,0x21,0x20,
};

unsigned char empty_dict[] = { /* a small forth program */
    0x1a,0x00,0x00,0x6f,         /* will be loaded if     */
    0x74,0x68,0x65,0x72,         /* wanted file can't be  */
    0x20,0x20,0x20,0x20,         /* opened */
    0x20,0x2a,0x00,0x51,
    0x3c,0x58,0x3c,0x4c,
    0x3c,0x4c,0x3c,0x4f,
    0x3c,0x7b,0x3c,0x20,
    0x2b,0x00,0x52,0x55,
    0xce,0x27,0x00,0x49,
    0x3c,0x03,0xc3,0x0e,
    0x1d,0x0a,0x96,0x13,
    0x18,0x00,0x43,0x6f,
    0x75,0x6c,0x64,0x6e,
    0x27,0x74,0x20,0x6c,
    0x6f,0x61,0x64,0x20,
    0x79,0x6f,0x75,0x72,
    0x20,0x66,0x69,0x6c,
    0x65,0x21,0xb6,0x04,
    0xff,0x00
};

void load_p(int _de, int _hl)
{
    char filename[64];
    int i;
    static unsigned char *empty_tape;
    static int efp;
    static int firstTime=1;
    static NSData *_data=nil;
    static NSData *_filename=nil;
    static const unsigned char *ptr;

    if (firstTime) {
        i=0;
        while (!isspace(mem[9985+1+i])&&i<10) {
            filename[i]=mem[9985+1+i]; i++;
        }
        filename[i++]='.';
        if (mem[9985]) { /* dict or bytes load */
            filename[i++]='b';
            filename[i++]='y';
            filename[i++]='t';
            empty_tape = empty_bytes;
        } else {
            filename[i++]='d';
            filename[i++]='i';
            filename[i++]='c';
            empty_tape = empty_dict;
        }
        filename[i++]='\0';
        _filename = [NSString stringWithCString:filename encoding:NSUTF8StringEncoding];
        _data = tapes[_filename];
        if (!_data) {
            efp=0;
            _de=empty_tape[efp++];
            _de+=256*empty_tape[efp++];
            memcpy(&mem[_hl],&empty_tape[efp],_de-1); /* -1 -> skip last byte */
            for (i=0;i<_de;i++) /* get memory OK */
                store(_hl+i,fetch(_hl+i));
            efp+=_de;
            for (i=0;i<10;i++)               /* let this file be it! */
                mem[_hl+1+i]=mem[9985+1+i];
            firstTime = 0;
        } else {
            ptr = (const unsigned char*)_data.bytes;
            _de = *ptr++;
            _de += 256*(*ptr++);
            memcpy(&mem[_hl],ptr,_de-1); /* -1 -> skip last byte */
            ptr += _de;
            for (i=0;i<_de;i++) /* get memory OK */
                store(_hl+i,fetch(_hl+i));
            for (i=0;i<10;i++)               /* let this file be it! */
                mem[_hl+1+i]=mem[9985+1+i];
            firstTime = 0;
        }
    } else {
        if (_data) {
            _de = *ptr++;
            _de += 256*(*ptr++);
            memcpy(&mem[_hl],ptr,_de-1); /* -1 -> skip last byte */
            for (i=0;i<_de;i++) /* get memory OK */
                store(_hl+i,fetch(_hl+i));
            _data = nil;
            _filename = nil;
        } else {
            _de=empty_tape[efp++];
            _de+=256*empty_tape[efp++];
            memcpy(&mem[_hl],&empty_tape[efp],_de-1); /* -1 -> skip last byte */
            for (i=0;i<_de;i++) /* get memory OK */
                store(_hl+i,fetch(_hl+i));
        }
        firstTime = 1;
    }
}

void patch_rom(unsigned char *mem)
{
    /* patch the ROM here */
    mem[0x18a7]=0xed; /* for load_p */
    mem[0x18a8]=0xfc;
    mem[0x18a9]=0xc9;
    
    mem[0x1820]=0xed; /* for save_p */
    mem[0x1821]=0xfd;
    mem[0x1822]=0xc9;
}

void load_state()
{
    NSString *cachedir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSDictionary *state = [NSDictionary dictionaryWithContentsOfFile:[cachedir stringByAppendingString:@"/state.mem"]];
    if (state) {
        NSData *z80 = state[@"z80"];
        NSData *memory = state[@"memory"];
        memcpy(mem, memory.bytes, MIN(memory.length, sizeof(mem)));
        set_z80_internal_state(z80.bytes);
    }
}

void save_state()
{
    NSString *cachedir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    
    NSMutableDictionary *state = [NSMutableDictionary dictionary];
    
    char *z80ptr;
    int z80len;
    get_z80_internal_state(&z80ptr, &z80len);
    state[@"z80"] = [NSData dataWithBytes:z80ptr length:z80len];
    state[@"memory"] = [NSData dataWithBytes:mem length:sizeof(mem)];

    [state writeToFile:[cachedir stringByAppendingString:@"/state.mem"] atomically:YES];
}

void setup_iace()
{
    memcpy(mem, ace_rom, ace_rom_len);
    patch_rom(mem);
    memset(mem+8192, 0xff, sizeof(mem)-8192);
    keyboard_clear();

    NSString *docsdir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    tapes = [NSMutableDictionary dictionaryWithContentsOfFile:[docsdir stringByAppendingString:@"/tapes.dic"]];
    if (!tapes) {
        tapes = [NSMutableDictionary dictionary];
        tapes[@"frogger.dic"] = [NSData dataWithBytes:FROGGER_DIC length:FROGGER_DIC_len];
    }
}

static BOOL soundStarted = NO;
static int sound_tsstate = 0;
static SoundGenerator *soundGenerator;

int spooler_read_char();

unsigned int in(int h, int l)
{
    static int scans_left_before_next = 0;
    
    if (l==0xfe && h==0xfe && !scans_left_before_next) {
        static int x = 0;
        
        if (x) {
            keyboard_clear();
            if (x==0x0a)
                scans_left_before_next = 4;
            x = 0;
        } else {
            x = spooler_read_char();
            if (x) {
                keyboard_keypress(x);
                scans_left_before_next = 4;
            }
        }
        
    } else if (l==0xfe && h==0xfd && scans_left_before_next) {
        scans_left_before_next--;
    }

    if (l==0xfe) {        
        if (!soundStarted && soundGenerator) {
            [soundGenerator deactivateAudioSession];
            soundGenerator = nil;
        }
        soundStarted = NO;
        switch (h) {
            case 0xfe:
                return keyboard_get_keyport(0);
            case 0xfd:
                return keyboard_get_keyport(1);
            case 0xfb:
                return keyboard_get_keyport(2);
            case 0xf7:
                return keyboard_get_keyport(3);
            case 0xef:
                return keyboard_get_keyport(4);
            case 0xdf:
                return keyboard_get_keyport(5);
            case 0xbf:
                return keyboard_get_keyport(6);
            case 0x7f:
                return keyboard_get_keyport(7);
            default:
                return 255;
        }
    }
    return 255;
}

unsigned int out(int h, int l, int a)
{
    if (l==0xfe) {
        if (!soundGenerator) {
            soundGenerator = [[SoundGenerator alloc] init];
            [soundGenerator activateAudioSession];
        }
        soundStarted = YES;
        int dt = tstates-sound_tsstate;
        if (dt < 0)
            dt += tsmax;
        int n = (Float32)dt/(tsmax*tsmaxfreq/22050);
        soundGenerator.periodLength = n;
        sound_tsstate = tstates;
    }
    return 0;
}

void fix_tstates()
{
    static int first_time = 1;
    if (first_time) {
        first_time = 0;
        load_state();
        keyboard_clear();
    }
    static CFAbsoluteTime t0 = 0.0;
    CFAbsoluteTime t1 = CFAbsoluteTimeGetCurrent();
    tstates -= tsmax;
    interrupted = 1;
    NSTimeInterval delay = 0.020 - (t1 - t0);
    t0 = t1;
    if (delay > 0.0)
        [NSThread sleepForTimeInterval:delay]; // ~50Hz
}

void do_interrupt()
{
    if (interrupted == 1) {
        interrupted = 2;
        // Something, or nothing I guess :-S
    }
}

#define hsize 256
#define vsize 192
#define bytes_per_pixel 4

static unsigned char image[hsize*vsize*bytes_per_pixel];

void set_pixel(int x, int y, unsigned int color)
{
    memcpy(&image[(y*hsize+x)*bytes_per_pixel], &color, bytes_per_pixel);
}

void set_image_character(int x, int y, int inv, unsigned char *charbmap)
{
    int color;
    int charbmap_x, charbmap_y;
    unsigned char charbmap_row;
    unsigned char charbmap_row_mask;
    
    for (charbmap_y = 0; charbmap_y < 8; charbmap_y++) {
        charbmap_row = charbmap[charbmap_y];
        
        if (inv)
            charbmap_row ^= 255;
        
        charbmap_row_mask = 0x80;
        
        for (charbmap_x = 0; charbmap_x < 8; charbmap_x++) {
            color = !(charbmap_row & charbmap_row_mask) ? 0x00000000 : 0xffffffff;
            set_pixel(x*8+charbmap_x, y*8+charbmap_y, color);
            charbmap_row_mask >>= 1;
        }
    }
}

BOOL refresh()
{
    unsigned char *video_ram, *charset;
    static unsigned char video_ram_old[32*24];
    int x, y, c;
    
    charset = mem+0x2c00;
    video_ram = mem+0x2400;
    
    if (!memcmp(video_ram, video_ram_old, sizeof(video_ram_old)))
        return YES;
    
    for (y=0; y<24; y++) {
        for (x=0; x<32; x++) {
            c = video_ram[x+y*32];
            video_ram_old[x+y*32] = c;
            set_image_character(x, y, c&0x80, charset + (c&0x7f)*8);
        }
    }
    
    return NO;
}

UIImage *get_screen_image()
{
    if (refresh())
        return nil;
        
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef bitmap = CGBitmapContextCreate(image,
                                                hsize,
                                                vsize,
                                                8,
                                                hsize*bytes_per_pixel,
                                                rgbColorSpace,
                                                kCGImageAlphaNoneSkipLast);
    
    UIGraphicsBeginImageContext(CGSizeMake(hsize*2, vsize*2));
    CGImageRef imageRef = CGBitmapContextCreateImage(bitmap);

    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, vsize*2);
    CGContextSaveGState(context);
    CGContextConcatCTM(context, flipVertical);
    CGContextDrawImage(context, CGRectMake(0, 0, hsize*2, vsize*2), imageRef);
    CGContextRestoreGState(context);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRelease(imageRef);
    CGContextRelease(bitmap);
    CGColorSpaceRelease(rgbColorSpace);
    
    return image;
}
