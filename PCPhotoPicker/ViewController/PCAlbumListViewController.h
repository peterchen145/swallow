//
//  PCAlbumListViewController.h
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/4.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PCAlbumListViewController : UIViewController
@property (strong, nonatomic) NSArray *albums;

@property (strong, nonatomic) NSMutableArray *selectedAssets;
@property (strong, nonatomic) NSMutableArray *selectedIndexPathesForAssets;
@end
