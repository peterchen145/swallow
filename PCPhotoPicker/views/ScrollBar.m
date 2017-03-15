//
//  ScrollBar.m
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/4.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import "ScrollBar.h"


CGFloat startPoint = 25;

@implementation ScrollBar

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self initContentView];
        [self initBar];
        [self initGestureRecognizer];
        [self initScrollTopBtn];
        [self initScrollToBottomBtn];
    }
    return self;
}

- (void)initContentView{
    if (!_contentView) {
        _contentView = [[UIView alloc]initWithFrame:CGRectMake(0, startPoint, self.frame.size.width, self.frame.size.height - startPoint * 2)];
        _contentView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_contentView];
    }
}

- (void)initBar{
    if (!_bar) {
        _bar = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width , 40)];
        _bar.backgroundColor = [UIColor grayColor];
        _bar.layer.cornerRadius = 3;
    }
    [_contentView addSubview:_bar];
}

- (void)initScrollTopBtn{
    if (!_scrollToTopBtn) {
        _scrollToTopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _scrollToTopBtn.frame = CGRectMake(0, 0, self.frame.size.width, startPoint);
//        _scrollToTopBtn.backgroundColor = [UIColor redColor];
        [_scrollToTopBtn setBackgroundImage:[UIImage imageNamed:@"triangle_up"] forState:UIControlStateNormal];
        [_scrollToTopBtn addTarget:self action:@selector(scrollToTop ) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_scrollToTopBtn];
    }
}

- (void)initScrollToBottomBtn{
    if (!_scrollToBottomBtn) {
        _scrollToBottomBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _scrollToBottomBtn.frame = CGRectMake(0, _contentView.frame.origin.y + _contentView.frame.size.height , self.frame.size.width, startPoint);
//        _scrollToBottomBtn.backgroundColor = [UIColor redColor];
        [_scrollToBottomBtn setBackgroundImage:[UIImage imageNamed:@"triangle_down"] forState:UIControlStateNormal];
        [_scrollToBottomBtn addTarget:self action:@selector(scrollToBottom ) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_scrollToBottomBtn];
    }
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
        _scrollToBottomBtn.enabled = YES;
        _scrollToTopBtn.enabled = YES;
        _bar.userInteractionEnabled = YES;
        CGFloat height = _contentView.frame.size.height * (targetView.frame.size.height /targetView.contentSize.height);
        if (height < 40) {
            height = 40;
        }
        
        if (_bar.frame.origin.y < 0) {
            _bar.frame = CGRectMake(_bar.frame.origin.x, 0, self.frame.size.width, height) ;
        }else{
            
            CGFloat percent = targetView.contentOffset.y / targetView.contentSize.height;
            CGFloat yDistanceForBar = (_contentView.frame.size.height - _bar.frame.size.height) * percent ;
//            _scrollBar.bar.center = CGPointMake(_scrollBar.bar.center.x,  yDistanceForBar);
            
            _bar.frame = CGRectMake(_bar.frame.origin.x, _bar.frame.origin.y, self.frame.size.width, height) ;
        }
        
        
    }else{
        _scrollToBottomBtn.enabled = NO;
        _scrollToTopBtn.enabled = NO;
        
        if (targetView.frame.size.height > _contentView.frame.size.height) {
            _bar.frame = CGRectMake(_bar.frame.origin.x, _bar.frame.origin.y, self.frame.size.width, _contentView.frame.size.height) ;
        }else{
            _bar.frame = CGRectMake(_bar.frame.origin.x, _bar.frame.origin.y, self.frame.size.width, targetView.frame.size.height) ;
        }
        
        _bar.userInteractionEnabled = NO;
    }
    
}

- (void)pan:(UIPanGestureRecognizer *)pan{
    if (_targetView.contentSize.height > _targetView.frame.size.height) {
        CGFloat oldYOffset ;
        if ([pan state] == UIGestureRecognizerStateBegan) {
            _scrolling = YES;
            if ([_delegate respondsToSelector:@selector(scrollBarBegin)]) {
                [_delegate scrollBarBegin];
            }
        }
        CGPoint translation = [pan translationInView:_contentView];
        
        CGFloat x = pan.view.center.x ;
        CGFloat y = pan.view.center.y + translation.y;
        
        oldYOffset = _targetView.contentOffset.y;
        
        if (y < (_bar.frame.size.height / 2  ) ) {
            y = _bar.frame.size.height / 2 ;
        }
        
        if (y > (_contentView.frame.size.height - (_bar.frame.size.height / 2) )) {
            y = _contentView.frame.size.height - (_bar.frame.size.height / 2);
        }
        
        pan.view.center = CGPointMake(x, y);
        
        
        CGFloat percent = translation.y / (_contentView.frame.size.height - _bar.frame.size.height /2 );
        
        CGFloat yOffset = _targetView.contentSize.height * percent;
        CGFloat nYOffset = oldYOffset + yOffset;
        
        if (nYOffset < _targetView.contentSize.height && nYOffset > 0) {
            
            
            if (y == _contentView.frame.size.height - (_bar.frame.size.height / 2)) {
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

   
}

- (void)scrollToTop{
    if (_targetView.contentSize.height > _targetView.frame.size.height) {
        [UIView animateWithDuration:0.1
                         animations:^{
                             _bar.frame = CGRectMake(0, 0, self.frame.size.width , 40);
                         }];
        [_targetView setContentOffset:CGPointMake(0, 0) animated:YES];
    }
    
}

- (void)scrollToBottom{
   
    if (_targetView.contentSize.height > _targetView.frame.size.height) {
         [_targetView setContentOffset:CGPointMake(0, _targetView.contentSize.height - _targetView.frame.size.height) animated:YES];
        [UIView animateWithDuration:0.1
                         animations:^{
                             _bar.frame = CGRectMake(0, _contentView.frame.size.height - 40, self.frame.size.width , 40);
                         }];
       
    }
    
}

@end
