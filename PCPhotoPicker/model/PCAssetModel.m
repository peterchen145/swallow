//
//  PCAssetModel.m
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/3.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import "PCAssetModel.h"
#import "PCPhotoPickerHelper.h"

@implementation PCAssetModel
+ (instancetype)modelWithAsset:(PHAsset *)asset type:(PCAssetType )type{
    PCAssetModel *model = [[PCAssetModel alloc]init];
    model.asset = asset;
    model.type = type;
    model.modificationDate = asset.modificationDate;
    return model;
}

- (UIImage *)thumbnail{
    if (_thumbnail) {
        return _thumbnail;
    }
    
    __block UIImage *resultImage;
    resultImage = [[PCPhotoPickerHelper sharedPhotoPickerHelper] thumbnailWithAsset:_asset size:CGSizeMake(([UIScreen mainScreen].bounds.size.width) / 4 - 5, ([UIScreen mainScreen].bounds.size.width) / 4 - 5)];
    _thumbnail = resultImage;
    return resultImage;
}
@end
