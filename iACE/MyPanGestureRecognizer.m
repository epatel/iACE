//
//  MyPanGestureRecognizer.m
//  iACE
//
//  Created by Edward Patel on 2013-01-06.
//  Copyright (c) 2013 Edward Patel. All rights reserved.
//

#import "MyPanGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation MyPanGestureRecognizer

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStateChanged;
    [super touchesMoved:touches withEvent:event];
}

@end
