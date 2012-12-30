//
//  MyPDFView.m
//  GoForth
//
//  Created by Edward Patel on 2010-12-25.
//  Copyright 2010 Memention AB. All rights reserved.
//

#import "MyPDFView.h"

static CGPDFDocumentRef book = NULL;
static int numBookPages = 0;

@implementation MyPDFView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        if (!book) {
            NSURL *bookURL = [[NSBundle mainBundle] URLForResource:@"JA-Manual-Second-Edition" withExtension:@"pdf"];
            book = CGPDFDocumentCreateWithURL((CFURLRef)bookURL);
            numBookPages = CGPDFDocumentGetNumberOfPages(book);
        }
		pageNumber = 2;
    }
    return self;
}

- (int)numberOfPages
{
    return numBookPages;
}

- (int)pageNumber
{
    return pageNumber;
}

- (void)gotoPage:(int)nextPage
{
	pageNumber = nextPage;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	CGPDFPageRef page;
    page = CGPDFDocumentGetPage(book, pageNumber-1);
    
    CGRect pageRect;
    pageRect = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
    
    CGRect frameRect = self.bounds;
    
    CGFloat scaleFactorWidth = frameRect.size.width/pageRect.size.width;
    CGFloat extraScale = 0.0;

    // Special tweak scaling for cover pages
    if (self.pageNumber == 2 || self.pageNumber == 4)
        extraScale = 0.4;

    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(context, frameRect);
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, frameRect.size.width/2.0, pageRect.size.height*scaleFactorWidth*(1+extraScale/2));
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextScaleCTM(context, scaleFactorWidth*(1+extraScale), scaleFactorWidth*(1+extraScale));
    CGContextTranslateCTM(context, -0.5*frameRect.size.width/scaleFactorWidth, 0);
    CGContextDrawPDFPage(context, page);
}

@end
