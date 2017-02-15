//
//  ScrollBar.m
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/4.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import "ScrollBar.h"

@implementation ScrollBar

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self initBar];
        [self initGestureRecognizer];
    }
    return self;
}

- (void)initBar{
    if (!_bar) {
        _bar = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width , 40)];
        _bar.backgroundColor = [UIColor grayColor];
        _bar.layer.cornerRadius = 3;
    }
    [self addSubview:_bar];
}

- (void)setTintColor:(UIColor *)tintColor{
    _tintColor = tintColor;
    _bar.backgroundColor = tintColor;
}

- (void)initGestureRecognizer{
    UIPanGestureRecognizer *gestureR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan: )];
    [_bar addGestureRecognizer:gestureR];
}


- (void)setTargetView:(UIScrollView *)targetView{
    _targetView = targetView;
    
    if (targetView.contentSize.height > targetView.frame.size.height) {
        
        CGFloat height = self.frame.size.height * (targetView.frame.size.height /targetView.contentSize.height);
        if (height < 40) {
            height = 40;
        }
        
        if (_bar.frame.origin.y < 0) {
            _bar.frame = CGRectMake(_bar.frame.origin.x, 0, self.frame.size.width, height) ;
        }else{
            _bar.frame = CGRectMake(_bar.frame.origin.x, _bar.frame.origin.y, self.frame.size.width, height) ;
        }
        
        
    }else{
        
        _bar.frame = CGRectMake(_bar.frame.origin.x, _bar.frame.origin.y, self.frame.size.width, targetView.frame.size.height) ;
    }
    
}

- (void)pan:(UIPanGestureRecognizer *)pan{
    
//    CGFloat oldY ;
    CGFloat oldYOffset ;
    if ([pan state] == UIGestureRecognizerStateBegan) {
        _scrolling = YES;
        if ([_delegate respondsToSelector:@selector(scrollBarBegin)]) {
            [_delegate scrollBarBegin];
        }
    }
    CGPoint translation = [pan translationInView:self];
    
    CGFloat x = pan.view.center.x ;
    CGFloat y = pan.view.center.y + translation.y;

    oldYOffset = _targetView.contentOffset.y;
    
    if (y < (_bar.frame.size.height / 2) ) {
        y = _bar.frame.size.height / 2;
    }
    
    if (y > (self.frame.size.height - (_bar.frame.size.height / 2))) {
        y = self.frame.size.height - (_bar.frame.size.height / 2);
    }
    
    pan.view.center = CGPointMake(x, y);

    
    CGFloat percent = translation.y / (self.frame.size.height - _bar.frame.size.height /2 );
    
    CGFloat yOffset = _targetView.contentSize.height * percent;
    CGFloat nYOffset = oldYOffset + yOffset;
    
    if (nYOffset < _targetView.contentSize.height && nYOffset > 0) {
        
        
        if (y == self.frame.size.height - (_bar.frame.size.height / 2)) {
            [_targetView setContentOffset:CGPointMake(0, _targetView.contentSize.height - _targetView.frame.size.height) animated:NO];
        }else if (y == _bar.frame.size.height / 2){
             [_targetView setContentOffset:CGPointMake(0, 0) animated:NO];
        }
        
        else{
            //这里的animated 要舍为no，如果用yes，则需要动画，耗费时间，导致无效
            [_targetView setContentOffset:CGPointMake(0, nYOffset) animated:NO];
            //        NSLog(@"ydistance:%f  percent:%f   oldoffset:%f  newoffset:%f  yoffset:%f  yyofset:%f",translation.y,percent,oldYOffset,nYOffset,yOffset,_targetView.contentOffset.y);
        }
    }
    

        if ([_delegate respondsToSelector:@selector(scrollBarScroll:)]) {
        [_delegate scrollBarScroll:translation];
    }
    [pan setTranslation:CGPointMake(0, 0) inView:self];
}
@end
