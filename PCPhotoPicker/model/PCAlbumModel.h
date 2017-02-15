//
//  PCAlbumModel.h
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/3.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface PCAlbumModel : NSObject

@property (strong, nonatomic) NSString *name;

@property (assign, nonatomic) NSUInteger count;

@property (strong, nonatomic) PHFetchResult *fetchResult;

@property (strong, nonatomic) PHAssetCollection *collection;

+ (instancetype)albumWithFetchResult:(PHFetchResult *)result name:(NSString *)name collection:(PHAssetCollection *)collection;
@end
