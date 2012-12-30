//
//  MyPDFView.h
//  GoForth
//
//  Created by Edward Patel on 2010-12-25.
//  Copyright 2010 Memention AB. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MyPDFView : UIView {
    int pageNumber;
}

- (void)gotoPage:(int)nextPage;
- (int)pageNumber;
- (int)numberOfPages;

@end
