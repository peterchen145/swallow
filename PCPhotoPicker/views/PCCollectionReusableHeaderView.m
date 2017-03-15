//
//  PCCollectionReusableHeaderView.m
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/27.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import "PCCollectionReusableHeaderView.h"

@implementation PCCollectionReusableHeaderView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        _contentLabel = [[UILabel alloc]initWithFrame:self.bounds];
        _contentLabel.backgroundColor = [UIColor whiteColor];
        _contentLabel.textColor = [UIColor blackColor];
        [self addSubview:_contentLabel];
        [self initStateBtn];
        [self initSelectAllBtn];
    }
    return self;
}


- (void)initStateBtn{
    if (!_stateBtn) {
        _stateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _stateBtn.frame = CGRectMake(self.frame.size.width - 50, 0, 50, self.frame.size.height);
        [_stateBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_stateBtn addTarget:self action:@selector(closeOrOpen:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_stateBtn];
    }
}

- (void)initSelectAllBtn{
    if (!_selectAllBtn) {
        _selectAllBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [_selectAllBtn setTitle:@"全选" forState:UIControlStateNormal];
        _selectAllBtn.frame = CGRectMake(self.frame.size.width - 110, 0, 50, self.frame.size.height);
        [_selectAllBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_selectAllBtn addTarget:self action:@selector(selectAll:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_selectAllBtn];
    }
    
    
}


- (void)setState:(NSString *)state{
    _state = state;
    if ([state isEqualToString:@"1"]) {
        //展开
        [_stateBtn setTitle:@"↑" forState:UIControlStateNormal];
        _selectAllBtn.hidden = NO;
    }else if ([state isEqualToString:@"0"]){
        //收起
        [_stateBtn setTitle:@"↓" forState:UIControlStateNormal];
        _selectAllBtn.hidden = YES;
    }
}

- (void)setSelectedAll:(NSString *)selectedAll{
    _selectedAll = selectedAll;
    if ([selectedAll isEqualToString:@"1"]) {
        //展开
        [_selectAllBtn setTitle:@"取消" forState:UIControlStateNormal];
    }else if ([selectedAll isEqualToString:@"0"]){
        //收起
        [_selectAllBtn setTitle:@"全选" forState:UIControlStateNormal];
    }
}



- (void)closeOrOpen:(UIButton *)sender{
    if ([_state isEqualToString:@"1"]) {
        //展开
        _state = @"0";
        [_stateBtn setTitle:@"↓" forState:UIControlStateNormal];
    }else if ([_state isEqualToString:@"0"]){
        //收起
        _state = @"1";
        [_stateBtn setTitle:@"↑" forState:UIControlStateNormal];
    }
    if ([_delegate respondsToSelector:@selector(pcCollectionReusableHeaderViewBtnClick:) ]) {
        [_delegate pcCollectionReusableHeaderViewBtnClick:self];
    }
}

- (void)selectAll:(UIButton*)sender{
    
    if ([_state isEqualToString:@"1"]) {
        if ([_selectedAll isEqualToString:@"1"]) {
            _selectedAll = @"0";
            [sender setTitle:@"全选" forState:UIControlStateNormal];
        }else if([_selectedAll isEqualToString:@"0"]){
            _selectedAll = @"1";
            [sender setTitle:@"取消" forState:UIControlStateNormal];
        }
        
        if ([_delegate respondsToSelector:@selector(pcCollectionReusableHeaderViewSelectAll:)]) {
            [_delegate pcCollectionReusableHeaderViewSelectAll:self];
        }
    }
    
}

@end
