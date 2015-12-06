//
//  MyPDFView.h
//  GoForth
//
//  Created by Edward Patel on 2010-12-25.
//  Copyright 2010 Memention AB. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyAnnotation : NSObject <NSCoding>

@property (nonatomic, assign) CGRect rect;
@property (nonatomic, copy) NSString *value;


- (void)draw;

@end

@interface MyPDFView : UIView {
    NSInteger pageNumber;
}

+ (void)loadAnnotations;
+ (void)saveAnnotations;

- (void)gotoPage:(NSInteger)nextPage;
- (NSInteger)pageNumber;
- (NSInteger)numberOfPages;

- (MyAnnotation*)annotationAtPoint:(CGPoint)point;
- (void)addAnnotation:(MyAnnotation*)annotation;
- (void)removeAnnotation:(MyAnnotation*)annotation;

@end
