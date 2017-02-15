//
//  ScrollBar.h
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/4.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ScrollBarDelegate <NSObject>

- (void)scrollBarBegin;

- (void)scrollBarScroll:(CGPoint)point;

@end



@interface ScrollBar : UIView

@property (strong, nonatomic) UIColor *tintColor;
@property (strong, nonatomic) UIView *bar;
@property (strong, nonatomic) UIScrollView *targetView;
@property (weak, nonatomic) id<ScrollBarDelegate> delegate;
@property (assign, nonatomic) BOOL scrolling;
@end
