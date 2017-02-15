//
//  PCAlbumCell.h
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/3.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PCAlbumModel;

@interface PCAlbumCell : UITableViewCell
@property (strong, nonatomic) UILabel *titleLabel;

- (void)configWithItem:(PCAlbumModel *)item;
@end
