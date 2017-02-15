//
//  PCPhotoPickerHelper.h
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/3.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@interface PCPhotoPickerHelper : NSObject

+ (id)sharedPhotoPickerHelper;

- (NSArray *)getAlbums;

- (BOOL)createNewAlbumWithTitle:(NSString *)title;

- (void)modifyCollection:(PHAssetCollection *)collection WithTitle:(NSString *)title;

- (NSArray *)assetsFromAlbum:(PHFetchResult *)album;

- (UIImage *)originImgWithAsset:(PHAsset *)asset;

- (UIImage *)thumbnailWithAsset:(PHAsset *)asset size:(CGSize)size;
@end
