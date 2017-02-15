//
//  PCPhotosViewController.h
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/4.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PCAlbumModel;

@interface PCPhotosViewController : UIViewController
@property (strong, nonatomic) PCAlbumModel *album;
@end
