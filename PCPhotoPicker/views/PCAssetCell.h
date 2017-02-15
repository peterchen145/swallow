//
//  PCAssetCell.h
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/4.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PCAssetModel,PCAssetCell;

@protocol PCAssetCellDelegate <NSObject>

- (void)pccassetCellDidSelected:(PCAssetCell * _Nonnull)assetCell;
- (void)pccassetCellDidDeselected:(PCAssetCell *_Nonnull)assetCell;
@end

@interface PCAssetCell : UICollectionViewCell

@property (strong, nonatomic) PCAssetModel *asset;
@property (strong, nonatomic) NSIndexPath *indexPath;
@property (strong, nonatomic) UIImageView *photoView;
@property (assign, nonatomic) BOOL stateBtnSelected;

@property (strong, nonatomic) UIButton *photoStateButton;
@property (weak, nonatomic) id<PCAssetCellDelegate> delegate;
- (void)initGUI;
@end
