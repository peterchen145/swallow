//
//  PCAlbumModel.m
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/3.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import "PCAlbumModel.h"


@implementation PCAlbumModel

+ (instancetype)albumWithFetchResult:(PHFetchResult *)result name:(NSString *)name collection:(PHAssetCollection *)collection{
    PCAlbumModel *model = [[PCAlbumModel alloc]init];
    model.fetchResult = result;
    model.count = result.count;
    model.name = [self albumNameWithOriginName:name];
    model.collection = collection;
    
    return model;
}

+ (NSString *)albumNameWithOriginName:(NSString *)name{
    NSString *newName = @"";
    if ([name containsString:@"Roll"]) {
        newName = @"相机胶卷";
    }else if([name containsString:@"Steam"]){
        newName = @"我的照片流";
    }else if ([name containsString:@"Added"]){
        newName = @"最近添加";
    }else if ([name containsString:@"Selfies"]){
        newName = @"自拍";
    }else if ([name containsString:@"shots"]){
        newName = @"截屏";
    }else{
        newName = name;
    }
    return newName;
}
@end
