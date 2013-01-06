//
//  AnnotationViewController.h
//  iACE
//
//  Created by Edward Patel on 2013-01-06.
//  Copyright (c) 2013 Edward Patel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyPDFView.h"

@interface AnnotationViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *annotationValue;
@property (weak, nonatomic) MyAnnotation *annotation;
@property (weak, nonatomic) MyPDFView *pdfView;
@property (weak, nonatomic) UIPopoverController *containerPopover;

- (IBAction)annotationDidChange:(id)sender;
- (IBAction)deleteAnnotation:(id)sender;

@end
