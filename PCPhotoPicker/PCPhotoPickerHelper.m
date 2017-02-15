//
//  PCPhotoPickerHelper.m
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/3.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import "PCPhotoPickerHelper.h"
//#import <Photos/Photos.h>
#import "PCAlbumModel.h"
#import "PCAssetModel.h"

@implementation PCPhotoPickerHelper

+ (id)sharedPhotoPickerHelper{
    static PCPhotoPickerHelper *helper;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        helper = [[self alloc]init];
    });
    return helper;
}

- (NSArray *)getAlbums{
    NSMutableArray *albumArr = [[NSMutableArray alloc]init];
    PHAssetCollectionSubtype smartAlbumSubtype = PHAssetCollectionSubtypeSmartAlbumUserLibrary;
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                                          subtype:smartAlbumSubtype
                                                                          options:nil];
    PHFetchOptions *option = [[PHFetchOptions alloc]init];
    option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    for (PHAssetCollection *collection in smartAlbums) {
        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
        if (fetchResult.count < 1) {
            continue;
        }
        if ([collection.localizedTitle containsString:@"Deleted"]) {
            continue;
        }
        if ([collection.localizedTitle isEqualToString:@"Camera Roll"]) {
            [albumArr insertObject:[PCAlbumModel albumWithFetchResult:fetchResult name:collection.localizedTitle collection:collection] atIndex:0];
        }else{
            [albumArr addObject:[PCAlbumModel albumWithFetchResult:fetchResult name:collection.localizedTitle collection:collection]];
        }
    }
    
    PHFetchResult *albums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                                     subtype:PHAssetCollectionSubtypeAlbumRegular| PHAssetCollectionSubtypeAlbumSyncedAlbum
                                                                     options:nil];
//    for (PHAssetCollection *collection in albums) {
//        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
//        if (fetchResult.count < 1) {
//            continue;
//        }
//        if ([collection.localizedTitle isEqualToString:@"My Photo Stream"]) {
//            [albumArr insertObject:[PCAlbumModel albumWithFetchResult:fetchResult name:collection.localizedTitle collection:collection] atIndex:1];
//        }else{
//            [albumArr addObject:[PCAlbumModel albumWithFetchResult:fetchResult name:collection.localizedTitle collection:collection]];
//        }
//    }
    
    // 列出所有用户创建的相册
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    for (PHAssetCollection *collection in topLevelUserCollections) {
        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
        [albumArr addObject:[PCAlbumModel albumWithFetchResult:fetchResult name:collection.localizedTitle collection:collection]];
    }
    
    return albumArr;
}


- (BOOL)createNewAlbumWithTitle:(NSString *)title{
    __block NSString *createdCollectionId = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        createdCollectionId = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title].placeholderForCreatedAssetCollection.localIdentifier;
    } error:nil];
    
    if (createdCollectionId.length > 0) {
        return true;
    }else{
        return false;
    }
}

- (void)modifyCollection:(PHAssetCollection *)collection WithTitle:(NSString *)title{
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        PHAssetCollectionChangeRequest *request =  [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
        request.title = title;
    } error:nil];
}


- (NSArray *)assetsFromAlbum:(PHFetchResult *)album{
    NSMutableArray *photoArr = [[NSMutableArray alloc]init];
    for (PHAsset *asset in album) {
        PCAssetType type = [self assetTypeWithOriginType:asset.mediaType];
        [photoArr addObject:[PCAssetModel modelWithAsset:asset type:type]];
    }
    return photoArr;
}

- (PCAssetType)assetTypeWithOriginType:(NSInteger)originType{
    if (originType == PHAssetMediaTypeAudio) {
        return PCAssetTypeAudio;
    }else if (originType == PHAssetMediaTypeVideo){
        return PCAssetTypeVideo;
    }else if (originType == PHAssetMediaSubtypePhotoLive){
        return PCAssetTypeLivePhoto;
    }else{
        return PCAssetTypePhoto;
    }
}

- (UIImage *)originImgWithAsset:(PHAsset *)asset{
    __block UIImage *originImg;
    PHImageRequestOptions *requestOption = [[PHImageRequestOptions alloc]init];
    requestOption.synchronous = YES;
    PHCachingImageManager *cachingImgManager = [[PHCachingImageManager alloc]init];
    [cachingImgManager requestImageForAsset:asset
                                 targetSize:PHImageManagerMaximumSize
                                contentMode:PHImageContentModeDefault
                                    options:requestOption
                              resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                  originImg = result;
                              }];
    return originImg;
}

- (UIImage *)thumbnailWithAsset:(PHAsset *)asset size:(CGSize)size{
    __block UIImage *thumbnail;
    PHImageRequestOptions *requestOption = [[PHImageRequestOptions alloc]init];
    requestOption.synchronous = YES;
    requestOption.resizeMode = PHImageRequestOptionsResizeModeExact;
    CGFloat screenScale = [UIScreen mainScreen].scale;
    PHCachingImageManager *cachingImgManager = [[PHCachingImageManager alloc]init];
    [cachingImgManager requestImageForAsset:asset
                                 targetSize:CGSizeMake(size.width *screenScale, size.height * screenScale)
                                contentMode:PHImageContentModeAspectFit
                                    options:requestOption
                              resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                  thumbnail = result;
                              }];
    return thumbnail;
}

@end
