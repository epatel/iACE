//
//  ViewController.h
//  iACE
//
//  Created by Edward Patel on 2012-12-17.
//  Copyright (c) 2012 Edward Patel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyPDFView.h"

@interface ViewController : UIViewController <UIScrollViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *screenImageView;
@property (weak, nonatomic) IBOutlet UIView *keyboardDrawer;
@property (weak, nonatomic) IBOutlet UIView *screenDrawer;
@property (weak, nonatomic) IBOutlet MyPDFView *bookView1;
@property (weak, nonatomic) IBOutlet MyPDFView *bookView2;
@property (assign, nonatomic) MyPDFView *currentBookView;
@property (assign, nonatomic) MyPDFView *otherBookView;
@property (assign, nonatomic) CGFloat panStartPosition;
@property (weak, nonatomic) IBOutlet UIScrollView *bookScrollView;
@property (weak, nonatomic) IBOutlet UISlider *pageSlider;
@property (weak, nonatomic) IBOutlet UISwitch *editSwitch;
@property (weak, nonatomic) MyAnnotation *createdAnnotation;
@property (weak, nonatomic) MyAnnotation *movingAnnotation;
@property (strong, nonatomic) UIPopoverController *popover;

- (IBAction)keyDown:(id)sender;
- (IBAction)keyUp:(id)sender;

- (IBAction)gestureMoved:(UIPanGestureRecognizer*)sender;
- (IBAction)gestureTapped:(UITapGestureRecognizer*)sender;
- (IBAction)gestureLongPressed:(UILongPressGestureRecognizer*)sender;
- (IBAction)pageSliderChanged:(id)sender;
- (IBAction)editModeChanged:(id)sender;

@end
