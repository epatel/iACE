//
//  MyPDFView.m
//  GoForth
//
//  Created by Edward Patel on 2010-12-25.
//  Copyright 2010 Memention AB. All rights reserved.
//

#import "MyPDFView.h"

@implementation MyAnnotation

- (void)draw
{
    if ([self.value hasPrefix:@"type"]) {
        CGRect rect = self.rect;
        rect.size.width = 70;
        rect.size.height = 44;
        self.rect = rect;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.rect cornerRadius:7.0];
#if ACTIVATE_EDIT_MODE
        [[UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:0.3] setFill];
        [path fill];
#endif
        [[UIColor blackColor] set];
        [[UIColor blackColor] setFill];
        [path stroke];
        NSString *str = @"Enter";
        CGSize size = [str sizeWithFont:[UIFont systemFontOfSize:17]];
        [str drawInRect:CGRectInset(self.rect, (self.rect.size.width-size.width)/2.0, (self.rect.size.height-size.height)/2.0) withFont:[UIFont systemFontOfSize:17]];
    } else {
#if ACTIVATE_EDIT_MODE
        [[UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:0.3] setFill];
        [[UIBezierPath bezierPathWithRect:self.rect] fill];
#endif
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.rect = [aDecoder decodeCGRectForKey:@"rect"];
        self.value = [aDecoder decodeObjectForKey:@"value"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeCGRect:self.rect forKey:@"rect"];
    [aCoder encodeObject:self.value forKey:@"value"];
}

@end

static CGPDFDocumentRef book = NULL;
static int numBookPages = 0;
static NSMutableDictionary *annotations;

@implementation MyPDFView

+ (void)loadAnnotations
{
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"annotations" withExtension:@"dic"]]];

    annotations = [unarchiver decodeObjectForKey:@"annotations"];

    if (!annotations)
        annotations = [[NSMutableDictionary alloc] init];
}

+ (void)saveAnnotations
{
#if ACTIVATE_EDIT_MODE
    if (annotations) {
        NSMutableData *data = [[NSMutableData alloc] init];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];

        [archiver encodeObject:annotations forKey:@"annotations"];
        [archiver finishEncoding];

        [data writeToFile:@"/tmp/annotations.dic" atomically:YES];
    }
#endif
}

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

- (MyAnnotation*)annotationAtPoint:(CGPoint)point
{
    NSArray *page_annotations = annotations[@(pageNumber)];
    __block MyAnnotation *found = nil;
    [page_annotations enumerateObjectsUsingBlock:^(MyAnnotation *annotation, NSUInteger idx, BOOL *stop) {
        if (CGRectContainsPoint(annotation.rect, point)) {
            found = annotation;
            *stop = YES;
        }
    }];
    return found;
}

- (void)addAnnotation:(MyAnnotation*)annotation
{
    NSArray *page_annotations = annotations[@(self.pageNumber)];
    if (page_annotations)
        annotations[@(self.pageNumber)] = [page_annotations arrayByAddingObject:annotation];
    else
        annotations[@(self.pageNumber)] = @[ annotation ];
}

- (void)removeAnnotation:(MyAnnotation*)annotation
{
    NSArray *page_annotations = annotations[@(self.pageNumber)];
    if (page_annotations) {
        __block NSMutableArray *array = [NSMutableArray array];
        [page_annotations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (obj != annotation)
                [array addObject:obj];
        }];
        annotations[@(self.pageNumber)] = [NSArray arrayWithArray:array];
    }
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
    
    CGContextSaveGState(context);
    
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(context, frameRect);
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, frameRect.size.width/2.0, pageRect.size.height*scaleFactorWidth*(1+extraScale/2));
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextScaleCTM(context, scaleFactorWidth*(1+extraScale), scaleFactorWidth*(1+extraScale));
    CGContextTranslateCTM(context, -0.5*frameRect.size.width/scaleFactorWidth, 0);
    CGContextDrawPDFPage(context, page);
    
    CGContextRestoreGState(context);

    if (annotations) {
        NSArray *page_annotations = [annotations objectForKey:@(pageNumber)];
        [page_annotations enumerateObjectsUsingBlock:^(MyAnnotation *annotation, NSUInteger idx, BOOL *stop) {
            [annotation draw];
        }];
    }    
}

@end
