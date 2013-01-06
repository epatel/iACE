//
//  ViewController.m
//  iACE
//
//  Created by Edward Patel on 2012-12-17.
//  Copyright (c) 2012 Edward Patel. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>

UIImage *get_screen_image();
extern volatile int interrupted;

static unsigned char keyboard_ports[8];

unsigned char keyboard_get_keyport(int port)
{
    return keyboard_ports[port];
}

void keyboard_clear(void)
{
    for (int i=0; i < 8; i++)
        keyboard_ports[i] = 0xff;
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
    BOOL shownResetMessage = [defaults boolForKey:@"reset_msg"];
    
    if (lastpage)
        [self gotoPage:lastpage];
    else
        [self gotoPage:2]; // Manual pdf seem to have an empty "initial" page
    
    if (!shownResetMessage) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"reset_msg"]];
        imageView.tag = 99;
        [self.keyboardDrawer addSubview:imageView];
        imageView.center = CGPointMake(768/2, 150);
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
    int x = [sender tag];
    keyboard_ports[0xff & x] &= 0xff & ~(x>>8);
}

- (IBAction)keyUp:(id)sender
{
    int x = [sender tag];
    keyboard_ports[0xff & x] |= ~(0xff & ~(x>>8));
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
    }
    
    if (gr.view == self.keyboardDrawer) {
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
    }
    if (sender.view == self.screenDrawer) {
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
    }
}

- (void)saveLastpage:(int)lastpage
{
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

- (void)gotoPage:(int)page
{
    if (page == 2) {
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

- (IBAction)gestureLongPressed:(UILongPressGestureRecognizer*)sender
{
    CGPoint p = [sender locationInView:sender.view];
    if (p.y > 340) {
        sender.enabled = NO;
        sender.enabled = YES;
    } else if (sender.state == UIGestureRecognizerStateBegan) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Reset"
                                                        message:@"Do you want to reset the Jupiter ACE?"
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Yes", nil];
        [alert show];
        
        UIView *v = [self.keyboardDrawer viewWithTag:99];
        if (v) {
            [v removeFromSuperview];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:YES forKey:@"reset_msg"];
            [defaults synchronize];
        }
    }
}

- (IBAction)pageSliderChanged:(id)sender
{
    int currentPage = self.pageSlider.value;

    if (currentPage > self.currentBookView.numberOfPages)
        currentPage = self.currentBookView.numberOfPages+1;
    
    [self gotoPage:currentPage];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.x < 768/2 && self.currentBookView.pageNumber > 3) {
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
        
    } else if (scrollView.contentOffset.x > 768+768/2 && self.currentBookView.pageNumber < self.currentBookView.numberOfPages) {
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
    }

}

- (void)viewDidUnload
{
    [self setBookView1:nil];
    [self setBookView2:nil];
    [self setBookScrollView:nil];
    [self setPageSlider:nil];
    [super viewDidUnload];
}

@end
