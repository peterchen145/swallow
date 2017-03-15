//
//  PCCollectionReusableHeaderView.h
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/27.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PCCollectionReusableHeaderView;
@protocol PCCollectionReusableHeaderViewDelegate <NSObject>

- (void)pcCollectionReusableHeaderViewBtnClick:(PCCollectionReusableHeaderView *)header;
- (void)pcCollectionReusableHeaderViewSelectAll:(PCCollectionReusableHeaderView *)header;
@end


@interface PCCollectionReusableHeaderView : UICollectionReusableView
@property (strong, nonatomic) UILabel *contentLabel;
@property (strong, nonatomic) UIButton *stateBtn;
@property (strong, nonatomic) UIButton *selectAllBtn;
@property (strong, nonatomic) NSString *state;
@property (strong, nonatomic) NSString *selectedAll;
@property (weak, nonatomic) id<PCCollectionReusableHeaderViewDelegate> delegate;
@end
