//
//  MyInnerShadowView.m
//  iACE
//
//  Created by Edward Patel on 2013-01-08.
//  Copyright (c) 2013 Edward Patel. All rights reserved.
//

#import "MyInnerShadowView.h"

@implementation MyInnerShadowView

- (void)drawRect:(CGRect)rect
{
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.bounds];
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:CGRectInset(self.bounds, -2, -2)];
    [shadowPath appendPath:path];
    shadowPath.usesEvenOddFillRule = YES;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetShadowWithColor(context, CGSizeMake(0, 2), 7.0, [UIColor colorWithWhite:0.0 alpha:1.0].CGColor);
    CGContextDrawPath(context, kCGPathFill);
    [[UIColor blackColor] setFill];
    [shadowPath fill];
}

@end
