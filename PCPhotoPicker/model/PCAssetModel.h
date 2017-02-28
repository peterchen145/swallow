//
//  PCAssetModel.h
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/3.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class PHAsset ;

typedef NS_ENUM(NSUInteger, PCAssetType){
        PCAssetTypePhoto = 0,
    PCAssetTypeLivePhoto,
    PCAssetTypeVideo,
    PCAssetTypeAudio
};

@interface PCAssetModel : NSObject

@property (strong, nonatomic) PHAsset *asset;
@property (assign, nonatomic) PCAssetType type;

@property (strong, nonatomic) UIImage *originImg;
@property (strong, nonatomic) UIImage *thumbnail;
@property (strong, nonatomic) UIImage *previewImg;
@property (strong, nonatomic) NSDate *modificationDate;

@property (assign, nonatomic) UIImageOrientation imageOrientation;

@property (assign, nonatomic) BOOL selected;


+ (instancetype)modelWithAsset:(PHAsset *)asset type:(PCAssetType )type;


@end
