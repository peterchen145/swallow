//
//  PCAssetCell.m
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/4.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import "PCAssetCell.h"
#import "PCAssetModel.h"

static const CGFloat kStateButtonWidthAndHeight = 30;
@interface PCAssetCell()<NSCopying>

@end

@implementation PCAssetCell

- (void)initGUI{
    [self initPhotoView];
    [self initStateButton];
}


- (void)initPhotoView{
    if (!_photoView) {
        _photoView = [[UIImageView alloc]initWithFrame:self.bounds];
    }
    _photoView.contentMode = UIViewContentModeScaleAspectFill;
    _photoView.clipsToBounds = YES;
    _photoView.backgroundColor = [UIColor redColor];
    [self.contentView addSubview:_photoView];
}

- (void)initStateButton{
    if (!_photoStateButton) {
        //如果buttontype为uibuttontypesystem的话，selected状态下，会有个蓝色的色块，改为UIButtonTypeCustom就没有了,fuck!!
        _photoStateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    _photoStateButton.frame = CGRectMake(0, 0, kStateButtonWidthAndHeight, kStateButtonWidthAndHeight);
    _photoStateButton.center = CGPointMake(self.bounds.size.width - kStateButtonWidthAndHeight / 2 , kStateButtonWidthAndHeight / 2);
    [_photoStateButton setBackgroundImage:[UIImage imageNamed:@"photopicker_state_normal"] forState:UIControlStateNormal];
//    [_photoStateButton setBackgroundImage:[UIImage imageNamed:@"photopicker_state_selected"] forState:UIControlStateSelected ];
    [_photoStateButton addTarget:self action:@selector(stateBtnTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_photoStateButton];
}
- (void)setAsset:(PCAssetModel * _Nonnull)asset{
    _asset = asset;
//    _photoStateButton.selected = asset.selected;
//    _stateBtnSelected = _photoStateButton.selected;
    _photoView.image = asset.thumbnail;
    if (asset.selected) {
        [_photoStateButton setBackgroundImage:[UIImage imageNamed:@"photopicker_state_selected"] forState:UIControlStateNormal ];
        _stateBtnSelected = YES;
        
    }else{
        _stateBtnSelected = NO;
        [_photoStateButton setBackgroundImage:[UIImage imageNamed:@"photopicker_state_normal"] forState:UIControlStateNormal];
        
    }
}

- (void)stateBtnTapped{
    _stateBtnSelected = !_stateBtnSelected;
    
    if (_stateBtnSelected) {
        [_photoStateButton setBackgroundImage:[UIImage imageNamed:@"photopicker_state_selected"] forState:UIControlStateNormal ];
        if ([_delegate respondsToSelector:@selector(pccassetCellDidSelected:)]) {
            [_delegate pccassetCellDidSelected:self];
        }
        
    }else{
        [_photoStateButton setBackgroundImage:[UIImage imageNamed:@"photopicker_state_normal"] forState:UIControlStateNormal];
        if ([_delegate respondsToSelector:@selector(pccassetCellDidDeselected:)]) {
            [_delegate pccassetCellDidDeselected:self];
        }
    }
}

- (void)setStateBtnSelected:(BOOL)stateBtnSelected{
    _stateBtnSelected = stateBtnSelected;
    if (_stateBtnSelected) {
        [_photoStateButton setBackgroundImage:[UIImage imageNamed:@"photopicker_state_selected"] forState:UIControlStateNormal ];
        
        
    }else{
        [_photoStateButton setBackgroundImage:[UIImage imageNamed:@"photopicker_state_normal"] forState:UIControlStateNormal];
       
    }
}

- (id)copyWithZone:(NSZone *)zone{
    PCAssetCell *copy = [[self class] allocWithZone:zone];
    return copy;
}

@end
