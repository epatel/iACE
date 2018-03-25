/* 
 * Copyright (C) 2012 Lawrence Woodman
 * Copyright (C) 2012 Edward Patel
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

#import "ViewController.h"
#import "MyPanGestureRecognizer.h"
#import "AnnotationViewController.h"
#import <QuartzCore/QuartzCore.h>

UIImage *get_screen_image();
extern volatile int interrupted;

static unsigned char keyboard_ports[8];

typedef enum {
    AceKey_none,
    AceKey_DeleteLine, AceKey_InverseVideo, AceKey_Graphics,
    AceKey_Left, AceKey_Down, AceKey_Up, AceKey_Right,
    AceKey_Delete = 0x08,
    AceKey_1 = 0x31, AceKey_2 = 0x32, AceKey_3 = 0x33, AceKey_4 = 0x34,
    AceKey_5 = 0x35, AceKey_6 = 0x36, AceKey_7 = 0x37, AceKey_8 = 0x38,
    AceKey_9 = 0x39, AceKey_0 = 0x30,
    AceKey_exclam = 0x21, AceKey_at = 0x40, AceKey_numbersign = 0x23,
    AceKey_dollar = 0x24, AceKey_percent = 0x25,
    AceKey_Break,
    AceKey_ampersand = 0x26, AceKey_apostrophe = 0x27,
    AceKey_parenleft = 0x28, AceKey_parenright = 0x29,
    AceKey_underscore = 0x5F,
    AceKey_A = 0x41, AceKey_a = 0x61, AceKey_B = 0x42, AceKey_b = 0x62,
    AceKey_C = 0x43, AceKey_c = 0x63, AceKey_D = 0x44, AceKey_d = 0x64,
    AceKey_E = 0x45, AceKey_e = 0x65, AceKey_F = 0x46, AceKey_f = 0x66,
    AceKey_G = 0x47, AceKey_g = 0x67, AceKey_H = 0x48, AceKey_h = 0x68,
    AceKey_I = 0x49, AceKey_i = 0x69, AceKey_J = 0x4A, AceKey_j = 0x6A,
    AceKey_K = 0x4B, AceKey_k = 0x6B, AceKey_L = 0x4C, AceKey_l = 0x6C,
    AceKey_M = 0x4D, AceKey_m = 0x6D, AceKey_N = 0x4E, AceKey_n = 0x6E,
    AceKey_O = 0x4F, AceKey_o = 0x6F, AceKey_P = 0x50, AceKey_p = 0x70,
    AceKey_Q = 0x51, AceKey_q = 0x71, AceKey_R = 0x52, AceKey_r = 0x72,
    AceKey_S = 0x53, AceKey_s = 0x73, AceKey_T = 0x54, AceKey_t = 0x74,
    AceKey_U = 0x55, AceKey_u = 0x75, AceKey_V = 0x56, AceKey_v = 0x76,
    AceKey_W = 0x57, AceKey_w = 0x77, AceKey_X = 0x58, AceKey_x = 0x78,
    AceKey_Y = 0x59, AceKey_y = 0x79, AceKey_Z = 0x5A, AceKey_z = 0x80,
    AceKey_less = 0x3C, AceKey_greater = 0x3E,
    AceKey_bracketleft = 0x5B, AceKey_bracketright = 0x5D,
    AceKey_copyright = 0x60,
    AceKey_semicolon = 0x3B, AceKey_quotedbl = 0x22, AceKey_asciitilde = 0x7E,
    AceKey_bar = 0x7C, AceKey_backslash = 0x5C,
    AceKey_braceleft = 0x7B, AceKey_braceright = 0x7D,
    AceKey_asciicircum = 0x5E,
    AceKey_minus = 0x2D, AceKey_plus = 0x2B, AceKey_equal = 0x3D,
    AceKey_Return = 0x0A,
    AceKey_colon = 0x3A, AceKey_sterling = 0x9C, AceKey_question = 0x3F,
    AceKey_slash = 0x2F, AceKey_asterisk = 0x2A, AceKey_comma = 0x2C,
    AceKey_period = 0x2E,
    AceKey_space = 0x20,
    AceKey_Tab = 0x09
} AceKey;

/* key, keyport_index, and_value, keyport_index, and_value
 * if keyport_index == -1 then no action for that port */
static const int keypress_response[] = {
    AceKey_DeleteLine, 3, 0xfe, 0, 0xfe,
    AceKey_InverseVideo, 3, 0xf7, 0, 0xfe,
    AceKey_Graphics, 4, 0xfd, 0, 0xfe,
    AceKey_Left, 3, 0xef, 0, 0xfe,
    AceKey_Down, 4, 0xf7, 0, 0xfe,
    AceKey_Up, 4, 0xef, 0, 0xfe,
    AceKey_Right, 4, 0xfb, 0, 0xfe,
    AceKey_Delete, 0, 0xfe, 4, 0xfe,
    AceKey_1, 3, 0xfe, -1, 0,
    AceKey_2, 3, 0xfd, -1, 0,
    AceKey_3, 3, 0xfb, -1, 0,
    AceKey_4, 3, 0xf7, -1, 0,
    AceKey_5, 3, 0xef, -1, 0,
    AceKey_6, 4, 0xef, -1, 0,
    AceKey_7, 4, 0xf7, -1, 0,
    AceKey_8, 4, 0xfb, -1, 0,
    AceKey_9, 4, 0xfd, -1, 0,
    AceKey_0, 4, 0xfe, -1, 0,
    AceKey_exclam, 3, 0xfe, 0, 0xfd,
    AceKey_at, 3, 0xfd, 0, 0xfd,
    AceKey_numbersign, 3, 0xfb, 0, 0xfd,
    AceKey_dollar, 3, 0xf7, 0, 0xfd,
    AceKey_percent, 3, 0xef, 0, 0xfd,
    AceKey_Break, 7, 0xfe, 0, 0xfe,     /* Break */
    AceKey_ampersand, 4, 0xef, 0, 0xfd,
    AceKey_apostrophe, 4, 0xf7, 0, 0xfd,
    AceKey_parenleft, 4, 0xfb, 0, 0xfd,
    AceKey_parenright, 4, 0xfd, 0, 0xfd,
    AceKey_underscore, 4, 0xfe, 0, 0xfd,
    AceKey_A, 0, 0xfe, 1, 0xfe,
    AceKey_a, 1, 0xfe, -1, 0,
    AceKey_B, 0, 0xfe, 7, 0xf7,
    AceKey_b, 7, 0xf7, -1, 0,
    AceKey_C, 0, 0xee, -1, 0,
    AceKey_c, 0, 0xef, -1, 0,
    AceKey_D, 0, 0xfe, 1, 0xfb,
    AceKey_d, 1, 0xfb, -1, 0,
    AceKey_E, 0, 0xfe, 2, 0xfb,
    AceKey_e, 2, 0xfb, -1, 0,
    AceKey_F, 0, 0xfe, 1, 0xf7,
    AceKey_f, 1, 0xf7, -1, 0,
    AceKey_G, 0, 0xfe, 1, 0xef,
    AceKey_g, 1, 0xef, -1, 0,
    AceKey_H, 0, 0xfe, 6, 0xef,
    AceKey_h, 6, 0xef, -1, 0,
    AceKey_I, 0, 0xfe, 5, 0xfb,
    AceKey_i, 5, 0xfb, -1, 0,
    AceKey_J, 0, 0xfe, 6, 0xf7,
    AceKey_j, 6, 0xf7, -1, 0,
    AceKey_K, 0, 0xfe, 6, 0xfb,
    AceKey_k, 6, 0xfb, -1, 0,
    AceKey_L, 0, 0xfe, 6, 0xfd,
    AceKey_l, 6, 0xfd, -1, 0,
    AceKey_M, 0, 0xfe, 7, 0xfd,
    AceKey_m, 7, 0xfd, -1, 0,
    AceKey_N, 0, 0xfe, 7, 0xfb,
    AceKey_n, 7, 0xfb, -1, 0,
    AceKey_O, 0, 0xfe, 5, 0xfd,
    AceKey_o, 5, 0xfd, -1, 0,
    AceKey_P, 0, 0xfe, 5, 0xfe,
    AceKey_p, 5, 0xfe, -1, 0,
    AceKey_Q, 0, 0xfe, 2, 0xfe,
    AceKey_q, 2, 0xfe, -1, 0,
    AceKey_R, 0, 0xfe, 2, 0xf7,
    AceKey_r, 2, 0xf7, -1, 0,
    AceKey_S, 0, 0xfe, 1, 0xfd,
    AceKey_s, 1, 0xfd, -1, 0,
    AceKey_T, 0, 0xfe, 2, 0xef,
    AceKey_t, 2, 0xef, -1, 0,
    AceKey_U, 0, 0xfe, 5, 0xf7,
    AceKey_u, 5, 0xf7, -1, 0,
    AceKey_V, 0, 0xfe, 7, 0xef,
    AceKey_v, 7, 0xef, -1, 0,
    AceKey_W, 0, 0xfe, 2, 0xfd,
    AceKey_w, 2, 0xfd, -1, 0,
    AceKey_X, 0, 0xf6, -1, 0,
    AceKey_x, 0, 0xf7, -1, 0,
    AceKey_Y, 0, 0xfe, 5, 0xef,
    AceKey_y, 5, 0xef, -1, 0,
    AceKey_Z, 0, 0xfa, -1, 0,
    AceKey_z, 0, 0xfb, -1, 0,
    AceKey_less, 2, 0xf7, 0, 0xfd,
    AceKey_greater, 2, 0xef, 0, 0xfd,
    AceKey_bracketleft, 5, 0xef, 0, 0xfd,
    AceKey_bracketright, 5, 0xf7, 0, 0xfd,
    AceKey_copyright, 5, 0xfb, 0, 0xfd,
    AceKey_semicolon, 5, 0xfd, 0, 0xfd,
    AceKey_quotedbl, 5, 0xfe, 0, 0xfd,
    AceKey_asciitilde, 1, 0xfe, 0, 0xfd,
    AceKey_bar, 1, 0xfd, 0, 0xfd,
    AceKey_backslash, 1, 0xfb, 0, 0xfd,
    AceKey_braceleft, 1, 0xf7, 0, 0xfd,
    AceKey_braceright, 1, 0xef, 0, 0xfd,
    AceKey_asciicircum, 6, 0xef, 0, 0xfd,
    AceKey_minus, 6, 0xf7, 0, 0xfd,
    AceKey_plus, 6, 0xfb, 0, 0xfd,
    AceKey_equal, 6, 0xfd, 0, 0xfd,
    AceKey_Return, 6, 0xfe, -1, 0,
    AceKey_colon, 0, 0xf9, -1, 0,
    AceKey_sterling, 0, 0xf5, -1, 0,
    AceKey_question, 0, 0xed, -1, 0,
    AceKey_slash, 7, 0xef, 0, 0xfd,
    AceKey_asterisk, 7, 0xf7, 0, 0xfd,
    AceKey_comma, 7, 0xfb, 0, 0xfd,
    AceKey_period, 7, 0xfd, 0, 0xfd,
    AceKey_space, 7, 0xfe, -1, 0,
    AceKey_Tab, 7, 0xfe, -1, 0,
};

static int keyboard_get_key_response(AceKey aceKey, int *keyport1, int *keyport2, int *keyport1_response, int *keyport2_response)
{
    int i;
    int num_keys = sizeof(keypress_response)/sizeof(keypress_response[0]);
    
    for (i = 0; i < num_keys; i+= 5) {
        if (keypress_response[i] == aceKey) {
            *keyport1 = keypress_response[i+1];
            *keyport2 = keypress_response[i+3];
            *keyport1_response = keypress_response[i+2];
            *keyport2_response = keypress_response[i+4];
            return 1;
        }
    }
    return 0;
}

static void keyboard_process_keypress_keyports(AceKey aceKey)
{
    int key_found;
    int keyport1, keyport2;
    int keyport1_and_value, keyport2_and_value;
    
    key_found = keyboard_get_key_response(aceKey, &keyport1, &keyport2,
                                          &keyport1_and_value, &keyport2_and_value);
    if (key_found) {
        keyboard_ports[keyport1] &= keyport1_and_value;
        if (keyport2 != -1)
            keyboard_ports[keyport2] &= keyport2_and_value;
    }
}

static void keyboard_process_keyrelease_keyports(AceKey aceKey)
{
    int key_found;
    int keyport1, keyport2;
    int keyport1_or_value, keyport2_or_value;
    
    key_found = keyboard_get_key_response(aceKey, &keyport1, &keyport2, &keyport1_or_value, &keyport2_or_value);
    if (key_found) {
        keyboard_ports[keyport1] |= ~keyport1_or_value;
        if (keyport2 != -1)
            keyboard_ports[keyport2] |= ~keyport2_or_value;
    }
}

void keyboard_keypress(int aceKey)
{
    keyboard_process_keypress_keyports(aceKey);
}

void keyboard_keyrelease(int aceKey)
{
    keyboard_process_keyrelease_keyports(aceKey);
}

unsigned char keyboard_get_keyport(int port)
{
    return keyboard_ports[port];
}

void keyboard_clear(void)
{
    for (int i=0; i < 8; i++)
        keyboard_ports[i] = 0xff;
}

static char *spooling_string = NULL;
static char *spooling_string_pos = NULL;

int spooler_is_active()
{
    return spooling_string ? 1 : 0;
}

int spooler_read_char()
{
    int rc = 0;
    if (spooling_string_pos) {
        rc = *spooling_string_pos++;
        if (!*spooling_string_pos) {
            free(spooling_string);
            spooling_string = NULL;
            spooling_string_pos = NULL;
        }
    }
    return rc;
}

@interface ViewController ()

@end

@implementation ViewController

- (void)refresh_screen:(NSTimer*)timer
{
    UIImage *image = get_screen_image();
    if (image)
        self.screenImageView.image = image;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    CGSize viewSize = self.view.bounds.size;
    CGSize windowSize = UIApplication.sharedApplication.windows.firstObject.bounds.size;

    CGFloat scaleX = windowSize.width / viewSize.width;
    CGFloat scaleY = windowSize.height / viewSize.height;

    self.view.transform = CGAffineTransformMakeScale(scaleX, scaleY);

    _resetButton.layer.borderColor = UIColor.whiteColor.CGColor;
    _resetButton.layer.borderWidth = 1;
    _resetButton.layer.cornerRadius = 10;
    _openInfoButton.layer.borderColor = UIColor.whiteColor.CGColor;
    _openInfoButton.layer.borderWidth = 1;
    _openInfoButton.layer.cornerRadius = 10;
    _openJupterACEButton.layer.borderColor = UIColor.whiteColor.CGColor;
    _openJupterACEButton.layer.borderWidth = 1;
    _openJupterACEButton.layer.cornerRadius = 10;

#if ACTIVATE_EDIT_MODE
    self.editSwitch.hidden = NO;
#endif
    
    [MyPDFView loadAnnotations];
    
    [self.pageSlider setMinimumTrackImage:[[UIImage imageNamed:@"slider"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 5.0)]
                                 forState:UIControlStateNormal];
    [self.pageSlider setMaximumTrackImage:[[UIImage imageNamed:@"slider"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 5.0)]
                                 forState:UIControlStateNormal];
    [self.pageSlider setThumbImage:[UIImage imageNamed:@"sliderthumb"]
                          forState:UIControlStateNormal];
    
    [(UIScrollView*)[self.bookScrollView superview] setContentSize:CGSizeMake(768, 1024)];
    
    self.bookScrollView.contentSize = CGSizeMake(768*3, 1024);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger lastpage = [defaults integerForKey:@"lastpage"];
    BOOL shownResetMessage = [defaults boolForKey:@"reset_msg2"];
    self.toggleShiftKeySwitch.on = [defaults boolForKey:@"toggle_shift_keys"];
    
    if (lastpage)
        [self gotoPage:lastpage];
    else
        [self gotoPage:2]; // Manual pdf seem to have an empty "initial" page
    
    if (!shownResetMessage) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"reveal"]];
        imageView.tag = 99;
        [self.keyboardDrawer addSubview:imageView];
        imageView.center = CGPointMake(450, 200);
    }
    
    self.screenDrawer.layer.shadowOffset = CGSizeMake(0, 8);
    self.screenDrawer.layer.shadowRadius = 8;
    self.screenDrawer.layer.shadowOpacity = 0.7;
    self.screenDrawer.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.screenDrawer.bounds].CGPath;
    
    self.keyboardDrawer.layer.shadowOffset = CGSizeMake(0, 8);
    self.keyboardDrawer.layer.shadowRadius = 8;
    self.keyboardDrawer.layer.shadowOpacity = 0.7;
    self.keyboardDrawer.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.keyboardDrawer.bounds].CGPath;

    CGRect frame;
    
    frame = self.screenDrawer.frame;
    frame.origin.y = -500;
    self.screenDrawer.frame = frame;
    frame = self.keyboardDrawer.frame;
    frame.origin.y = -500;
    self.keyboardDrawer.frame = frame;
    
    [self calculateBookViewSizeAndPosition];
    
    // 20 Hz screen refresh
    [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(refresh_screen:) userInfo:nil repeats:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)keyDown:(id)sender
{
    if (spooler_is_active())
        return;
    NSInteger x = [sender tag];
    if ((x==256 || x==512) && self.toggleShiftKeySwitch.on)
        return;
    keyboard_ports[0xff & x] &= ~(x>>8);
}

- (IBAction)keyUp:(id)sender
{
    NSInteger x = [sender tag];
    if (spooler_is_active()) {
        if (x==263) { // break! stop spooling if break-space pressed (on keyup for safety)
            free(spooling_string);
            spooling_string = NULL;
            spooling_string_pos = NULL;
        }
        return;
    }
    if ((x==256 || x==512) && self.toggleShiftKeySwitch.on)
        return;
    keyboard_ports[0xff & x] |= (x>>8);
}

- (void)highlightButton:(UIButton *)b
{
    [b setHighlighted:YES];
}

- (IBAction)shiftKeyDown:(UIButton*)sender
{
    if (spooler_is_active())
        return;
    
    NSInteger x = sender.tag;
    if (!self.toggleShiftKeySwitch.on) {
        [self keyUp:sender];
        return;
    }
    
    BOOL pressed = !(keyboard_ports[0xff & x] & (x>>8));
    
    if (pressed)
        keyboard_ports[0xff & x] |= (x>>8);
    else
        keyboard_ports[0xff & x] &= 0xff & ~(x>>8);

    if (!pressed)
        [self performSelector:@selector(highlightButton:) withObject:sender afterDelay:0.0];
}

- (void)calculateBookViewSizeAndPosition
{
    CGRect f = self.keyboardDrawer.frame;
    CGFloat bookTop = f.origin.y + f.size.height;
    if (bookTop > 800)
        bookTop = 800;
    CGFloat bookHeight = 1024-bookTop;
    f = self.bookScrollView.superview.frame;
    f.origin.y = bookTop;
    f.size.height = bookHeight;
    self.bookScrollView.superview.frame = f;
}

- (IBAction)gestureMoved:(UIPanGestureRecognizer*)gr
{
    if (gr.view == self.screenDrawer) {
        CGRect f = self.screenDrawer.frame;
        if (gr.state == UIGestureRecognizerStateBegan)
            self.panStartPosition = f.origin.y;
        CGPoint p = [gr translationInView:self.screenDrawer];
        f.origin.y = self.panStartPosition + p.y;
        f.origin.y = MAX(f.origin.y, -500);
        f.origin.y = MIN(f.origin.y, 0);
        self.screenDrawer.frame = f;
        f = self.keyboardDrawer.frame;
        f.origin.y = MIN(self.keyboardDrawer.frame.origin.y, self.screenDrawer.frame.origin.y+582);
        f.origin.y = MAX(f.origin.y, self.screenDrawer.frame.origin.y);
        self.keyboardDrawer.frame = f;
    } else if (gr.view == self.keyboardDrawer) {
        CGRect f = self.keyboardDrawer.frame;
        if (gr.state == UIGestureRecognizerStateBegan)
            self.panStartPosition = f.origin.y;
        CGPoint p = [gr translationInView:self.keyboardDrawer];
        f.origin.y = self.panStartPosition + p.y;
        f.origin.y = MAX(f.origin.y, -500);
        f.origin.y = MIN(f.origin.y, 317);
        self.keyboardDrawer.frame = f;
        f = self.screenDrawer.frame;
        f.origin.y = MIN(self.keyboardDrawer.frame.origin.y, self.screenDrawer.frame.origin.y);
        f.origin.y = MAX(self.keyboardDrawer.frame.origin.y-582, f.origin.y);
        self.screenDrawer.frame = f;
    } else {
        int pageNumber = self.pageSlider.value;
        MyAnnotation *annotation;
        CGPoint p;
        MyPDFView *pdfView;
        if (self.currentBookView.pageNumber == pageNumber)
            pdfView = self.currentBookView;
        else
            pdfView = self.otherBookView;
        if (gr.state == UIGestureRecognizerStateBegan) {
            p = [gr locationInView:pdfView];
            annotation = [pdfView annotationAtPoint:p];
            if (!annotation) {
                annotation = [[MyAnnotation alloc] init];
                self.createdAnnotation = annotation;
                self.createdAnnotation.rect = CGRectMake(p.x, p.y, 0, 0);
                [pdfView addAnnotation:annotation];
            } else {
                self.movingAnnotation = annotation;
            }
        } else if (gr.state == UIGestureRecognizerStateChanged) {
            if (self.movingAnnotation) {
                p = [gr translationInView:pdfView];
                CGRect rect = self.movingAnnotation.rect;
                rect.origin.x += p.x;
                rect.origin.y += p.y;
                self.movingAnnotation.rect = rect;
                [gr setTranslation:CGPointZero inView:pdfView];
            } else {
                CGPoint p = [gr locationInView:pdfView];
                CGPoint p2 = [gr translationInView:pdfView];
                p2.x = p.x - p2.x;
                p2.y = p.y - p2.y;
                CGRect rect;
                rect.origin.x = MIN(p.x, p2.x);
                rect.origin.y = MIN(p.y, p2.y);
                rect.size.width = fabs(p.x-p2.x);
                rect.size.height = fabs(p.y-p2.y);
                self.createdAnnotation.rect = rect;
            }
            [pdfView setNeedsDisplay];
        } else {
            CGRect rect = self.createdAnnotation.rect;
            rect.size.width = MAX(50, rect.size.width);
            rect.size.height = MAX(44, rect.size.height);
            self.createdAnnotation.rect = rect;
            self.createdAnnotation = nil;
            self.movingAnnotation = nil;
            [pdfView setNeedsDisplay];
        }
    }

    [self calculateBookViewSizeAndPosition];
}

- (IBAction)gestureTapped:(UITapGestureRecognizer*)sender
{
    if (sender.view == self.bookScrollView) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             CGRect frame;
                             frame = self.screenDrawer.frame;
                             frame.origin.y = 0;
                             self.screenDrawer.frame = frame;
                             frame = self.keyboardDrawer.frame;
                             frame.origin.y = 317;
                             self.keyboardDrawer.frame = frame;
                             [self calculateBookViewSizeAndPosition];
                         }];
    } else if (sender.view == self.screenDrawer) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             CGRect frame;
                             frame = self.screenDrawer.frame;
                             frame.origin.y = -500;
                             self.screenDrawer.frame = frame;
                             frame = self.keyboardDrawer.frame;
                             frame.origin.y = -500;
                             self.keyboardDrawer.frame = frame;
                             [self calculateBookViewSizeAndPosition];
                         }];
    } else {
        int pageNumber = self.pageSlider.value;
        MyAnnotation *annotation;
        MyPDFView *pdfView;
        CGPoint p;
        if (self.currentBookView.pageNumber == pageNumber)
            pdfView = self.currentBookView;
        else
            pdfView = self.otherBookView;
        p = [sender locationInView:pdfView];
        annotation = [pdfView annotationAtPoint:p];
        if (annotation) {
            if (self.editSwitch.on) {
                AnnotationViewController *contentViewController = [[AnnotationViewController alloc] initWithNibName:@"AnnotationViewController" bundle:[NSBundle mainBundle]];
                contentViewController.annotation = annotation;
                contentViewController.pdfView = pdfView;
                self.popover = [[UIPopoverController alloc] initWithContentViewController:contentViewController];
                self.popover.popoverContentSize = contentViewController.view.bounds.size;
                [self.popover presentPopoverFromRect:annotation.rect
                                              inView:pdfView
                            permittedArrowDirections:UIPopoverArrowDirectionAny
                                            animated:YES];
                contentViewController.containerPopover = self.popover;
            } else {
                if ([annotation.value hasPrefix:@"goto"]) {
                    [self gotoPage:[[annotation.value substringFromIndex:5] integerValue]+2];
                } else if ([annotation.value hasPrefix:@"open"]) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[annotation.value substringFromIndex:5]]];
                } else if ([annotation.value hasPrefix:@"type"]) {
                    NSString *filtered = [annotation.value stringByReplacingOccurrencesOfString:@"\\" withString:@"\n"];
                    filtered = [filtered stringByAppendingString:@"\n"];
                    const char *str = [[filtered substringFromIndex:5] cStringUsingEncoding:NSUTF8StringEncoding];
                    if (spooling_string)
                        free(spooling_string);
                    spooling_string = strdup(str);
                    spooling_string_pos = spooling_string;
                    keyboard_clear();
                }
            }
        }
    }
}

- (void)saveLastpage:(NSInteger)lastpage
{
    // Lets have a slight delay so we don't save to preferences like crazy
    static int counter = 0;
    counter++;
    int64_t delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        counter--;
        if (!counter) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setInteger:lastpage forKey:@"lastpage"];
            [defaults synchronize];
        }
    });
}

- (void)gotoPage:(NSInteger)page
{
    self.pageSlider.value = page;
    if (page == 2) {
        // Special case for first page, shown in scrollview first part of 3
        [self.bookView1 gotoPage:page];
        [self.bookView2 gotoPage:page+1];
        self.currentBookView = self.bookView2;
        self.otherBookView = self.bookView1;
        CGRect frame;
        frame = self.bookView1.frame;
        frame.origin.x = 0+4;
        self.bookView1.frame = frame;
        frame = self.bookView2.frame;
        frame.origin.x = 768+4;
        self.bookView2.frame = frame;
        self.bookScrollView.contentOffset = CGPointMake(0, 0);
    } else if (page > self.currentBookView.numberOfPages) {
        // Special case for last page, shown in scrollview last part of 3
        [self.bookView1 gotoPage:page];
        [self.bookView2 gotoPage:page-1];
        self.currentBookView = self.bookView2;
        self.otherBookView = self.bookView1;
        CGRect frame;
        frame = self.otherBookView.frame;
        frame.origin.x = 768*2+4;
        self.otherBookView.frame = frame;
        frame = self.currentBookView.frame;
        frame.origin.x = 768+4;
        self.currentBookView.frame = frame;
        self.bookScrollView.contentOffset = CGPointMake(768*2, 0);
    } else {
        // All other pages shown in middle part of 3
        [self.bookView1 gotoPage:page];
        [self.bookView2 gotoPage:page-1];
        self.currentBookView = self.bookView1;
        self.otherBookView = self.bookView2;
        CGRect frame;
        frame = self.currentBookView.frame;
        frame.origin.x = 768+4;
        self.currentBookView.frame = frame;
        frame = self.otherBookView.frame;
        frame.origin.x = 0+4;
        self.otherBookView.frame = frame;
        self.bookScrollView.contentOffset = CGPointMake(768, 0);
    }
    [self saveLastpage:page];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != 0) {
        extern int reset_ace;
        reset_ace = 1;
    }
}

- (IBAction)pageSliderChanged:(id)sender
{
    NSInteger currentPage = self.pageSlider.value;

    if (currentPage > self.currentBookView.numberOfPages)
        currentPage = self.currentBookView.numberOfPages+1;
    
    [self gotoPage:currentPage];
}

- (IBAction)editModeChanged:(UISwitch*)sender
{
    [self.bookView1.gestureRecognizers enumerateObjectsUsingBlock:^(UIGestureRecognizer *gr, NSUInteger idx, BOOL *stop) {
        if ([gr isMemberOfClass:[MyPanGestureRecognizer class]])
            gr.enabled = sender.on;
    }];

    if (!sender.on)
        [MyPDFView saveAnnotations];
}

- (IBAction)lidGestureMoved:(UIPanGestureRecognizer*)panGesture
{
    CGPoint center = self.settingsLidImageView.center;
    CGPoint translation = [panGesture translationInView:self.settingsLidImageView];

    center.x += translation.x;
    center.y += translation.y;
    center.x = MAX(center.x, 0);
    center.y = MAX(center.y, 0);
    center.x = MIN(center.x, 768);
    center.y = MIN(center.y, 300);
    
    self.settingsLidImageView.center = center;

    [panGesture setTranslation:CGPointZero inView:self.settingsLidImageView];

    if (panGesture.state == UIGestureRecognizerStateEnded) {
        CGPoint p = [panGesture locationInView:self.settingsLidImageView.superview];
        if (CGRectContainsPoint(CGRectMake(24, 6, 378, 178), p)) {
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.settingsLidImageView.frame = CGRectMake(24, 6, 378, 178);
                             }
                             completion:^(BOOL finished) {
                                 self.settingsLidImageView.layer.shadowOpacity = 0.0;
                             }];
        }
    } else {
        UIView *v = [self.keyboardDrawer viewWithTag:99];
        if (v) {
            [v removeFromSuperview];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:YES forKey:@"reset_msg2"];
            [defaults synchronize];
        }
        if (self.settingsLidImageView.layer.shadowOpacity < 0.1) {
            self.settingsLidImageView.layer.shadowColor = [UIColor blackColor].CGColor;
            self.settingsLidImageView.layer.shadowOffset = CGSizeMake(0, 8);
            self.settingsLidImageView.layer.shadowRadius = 7;
            self.settingsLidImageView.layer.shadowOpacity = 0.7;
        }
    }
}

- (IBAction)resetPressed:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Reset"
                                                    message:@"Do you want to reset the Jupiter ACE?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
    [alert show];
}

- (IBAction)toggleShiftKeysSwitch:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.toggleShiftKeySwitch.on forKey:@"toggle_shift_keys"];
    [defaults synchronize];
}

- (IBAction)openInfoPage:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://memention.com/iace"]];
}

- (IBAction)openJupiterACEPage:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://jupiter-ace.com"]];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.x < 768/2) {
        if (self.currentBookView.pageNumber > 3) {
            MyPDFView *current = self.currentBookView;
            
            self.currentBookView = self.otherBookView;
            self.otherBookView = current;
            
            CGRect frame = self.currentBookView.frame;
            frame.origin.x = 768+4;
            self.currentBookView.frame = frame;
            frame.origin.x = 768*2+4;
            self.otherBookView.frame = frame;
            
            CGPoint offset = scrollView.contentOffset;
            offset.x += 768;
            scrollView.contentOffset = offset;
            
            self.pageSlider.value = self.currentBookView.pageNumber;
            [self saveLastpage:self.currentBookView.pageNumber];
        } else {
            if ((int)self.pageSlider.value != self.otherBookView.pageNumber) {
                self.pageSlider.value = self.otherBookView.pageNumber;
                [self saveLastpage:self.otherBookView.pageNumber];
            }
        }
        
    } else if (scrollView.contentOffset.x > 768+768/2) {
        if (self.currentBookView.pageNumber < self.currentBookView.numberOfPages) {
            MyPDFView *current = self.currentBookView;
            
            self.currentBookView = self.otherBookView;
            self.otherBookView = current;
            
            CGRect frame = self.currentBookView.frame;
            frame.origin.x = 768+4;
            self.currentBookView.frame = frame;
            frame.origin.x = 0+4;
            self.otherBookView.frame = frame;
            
            CGPoint offset = scrollView.contentOffset;
            offset.x -= 768;
            scrollView.contentOffset = offset;
            
            self.pageSlider.value = self.currentBookView.pageNumber;
            [self saveLastpage:self.currentBookView.pageNumber];
        } else {
            if ((int)self.pageSlider.value != self.otherBookView.pageNumber) {
                self.pageSlider.value = self.otherBookView.pageNumber;
                [self saveLastpage:self.otherBookView.pageNumber];
            }
        }

    } else if (scrollView.contentOffset.x < 768) {
        if (self.otherBookView.pageNumber > self.currentBookView.pageNumber) {

            [self.otherBookView gotoPage:self.currentBookView.pageNumber-1];
            CGRect frame = self.currentBookView.frame;
            frame.origin.x = 0+4;
            self.otherBookView.frame = frame;
            
        }
    } else if (scrollView.contentOffset.x > 768) {
        if (self.otherBookView.pageNumber < self.currentBookView.pageNumber) {
            
            [self.otherBookView gotoPage:self.currentBookView.pageNumber+1];
            CGRect frame = self.currentBookView.frame;
            frame.origin.x = 768*2+4;
            self.otherBookView.frame = frame;

        }
    } else {
        if ((int)self.pageSlider.value != self.currentBookView.pageNumber) {
            self.pageSlider.value = self.currentBookView.pageNumber;
            [self saveLastpage:self.currentBookView.pageNumber];
        }
    }

}

- (void)viewDidUnload
{
    [self setBookView1:nil];
    [self setBookView2:nil];
    [self setBookScrollView:nil];
    [self setPageSlider:nil];
    [self setEditSwitch:nil];
    [self setSettingsLidImageView:nil];
    [self setToggleShiftKeySwitch:nil];
    [super viewDidUnload];
}

@end
