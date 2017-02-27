//
//  PCAlbumCell.m
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/3.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import "PCAlbumCell.h"
#import "PCAlbumModel.h"
#import "PCPhotoPickerHelper.h"

@interface PCAlbumCell()
@property (strong, nonatomic) UIImageView *coverImgView;

@end

@implementation PCAlbumCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initGUI{
//    [self initCoverImgView];
    [self initTitleLabel];
}

- (void)initCoverImgView{
    if (!_coverImgView) {
        _coverImgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 70, 70)];
    }
    _coverImgView.contentMode = UIViewContentModeScaleAspectFill;
    _coverImgView.clipsToBounds = YES;
    [self.contentView addSubview:_coverImgView];
}


- (void)initTitleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 0, self.frame.size.width - 15, self.frame.size.height)];
    }
    [self.contentView addSubview:_titleLabel];
}

- (void)configWithItem:(PCAlbumModel *)item{
    NSString *name = @"";
    if (item.name) {
        name = item.name;
    }
    [self initGUI];
    NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc]initWithString:name
                                                                                  attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:16],NSForegroundColorAttributeName:[UIColor blackColor]}];
    NSMutableAttributedString *countString = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"   (%ld)",(unsigned long)item.count]
                                                                                   attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:16],NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
    [nameString appendAttributedString:countString];
    self.titleLabel.attributedText = nameString;
    _coverImgView.image = [[PCPhotoPickerHelper sharedPhotoPickerHelper] thumbnailWithAsset:[item.fetchResult lastObject] size:CGSizeMake(self.frame.size.height, self.frame.size.height)];
    
}
@end
