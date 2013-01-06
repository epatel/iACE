//
//  AnnotationViewController.m
//  iACE
//
//  Created by Edward Patel on 2013-01-06.
//  Copyright (c) 2013 Edward Patel. All rights reserved.
//

#import "AnnotationViewController.h"

@interface AnnotationViewController ()

@end

@implementation AnnotationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.annotationValue.text = self.annotation.value;
    [self.annotationValue becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [self setAnnotationValue:nil];
    [super viewDidUnload];
}

- (IBAction)annotationDidChange:(id)sender
{
    self.annotation.value = self.annotationValue.text;
    [self.pdfView setNeedsDisplay];
}

- (IBAction)deleteAnnotation:(id)sender
{
    [self.pdfView removeAnnotation:self.annotation];
    [self.pdfView setNeedsDisplay];
    [self.containerPopover dismissPopoverAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.containerPopover dismissPopoverAnimated:YES];
    return NO;
}

@end
