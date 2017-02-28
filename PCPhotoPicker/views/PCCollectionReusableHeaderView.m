//
//  PCCollectionReusableHeaderView.m
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/27.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import "PCCollectionReusableHeaderView.h"

@implementation PCCollectionReusableHeaderView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        _contentLabel = [[UILabel alloc]initWithFrame:self.bounds];
        _contentLabel.backgroundColor = [UIColor whiteColor];
        _contentLabel.textColor = [UIColor blackColor];
        [self addSubview:_contentLabel];
    }
    return self;
}


@end
