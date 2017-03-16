//
//  Tool.m
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/3/14.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import "Tool.h"
#import "PCAssetCell.h"
#import "PCAssetCell.h"


@implementation Tool

//判断当前cell是否已经被选中
+ (BOOL)cellIsSelected:(PCAssetCell *)cell inArrary:(NSArray *)array{
    for (NSMutableArray *arr in array) {
        for (NSIndexPath *ind in arr) {
            if (ind.section == cell.indexPath.section && ind.row == cell.indexPath.row) {
                return YES;
            }
        }
    }
    return NO;
}

//添加多个cell到_selectedAssets
+ (void)addCellInLoopToCollectionView:(UICollectionView *)collectionView WithIndex:(NSInteger)i array:(NSArray *)array{
    NSIndexPath *ind = [NSIndexPath indexPathForRow:i inSection:0];
    PCAssetCell *cell = (PCAssetCell *)[collectionView cellForItemAtIndexPath:ind];
    
    if (cell && ![self cellIsSelected:cell inArrary:array]) {
        NSMutableArray *arr = [array lastObject];
        cell.stateBtnSelected = YES;
        [arr addObject:ind];
    }
}

+ (void)addCellInLoopToCollectionView:(UICollectionView *)collectionView WithIndex:(NSInteger)i section:(NSInteger)section array:(NSMutableArray *)array {
    NSIndexPath *ind = [NSIndexPath indexPathForRow:i inSection:section];
    PCAssetCell *cell = (PCAssetCell *)[collectionView cellForItemAtIndexPath:ind];
    
    
    if (cell && ![self cellIsSelected:cell inArrary:array]) {
        NSMutableArray *arr = [array lastObject];
        if (!arr) {
            arr = [[NSMutableArray alloc]init];
            [array addObject:arr];
        }
        
        cell.stateBtnSelected = YES;
        [arr addObject:ind];
    }
}


//添加单个cell到_selectedAssets
+ (void)addSingleCellWithCell:(PCAssetCell *)cell toArray:(NSArray *)array withCollectionView:(UICollectionView *)collectionView{
    if (cell && ![self cellIsSelected:cell inArrary:array]) {
        cell.stateBtnSelected = YES;
        NSMutableArray *arr = [array lastObject];
        NSIndexPath *index = [collectionView indexPathForCell:cell];
        [arr addObject:index];
    }
}

//从_selectedAssets删除多个cell
+ (void)removeCellsInLoopWithIndex:(NSInteger)i collectionView:(UICollectionView *)collectionView fromArray:array{
    NSIndexPath *ind = [NSIndexPath indexPathForRow:i inSection:0];
    PCAssetCell *cell = (PCAssetCell *)[collectionView cellForItemAtIndexPath:ind];
    
    
    [self removeSingleCell:cell fromArray:array];
    
}

+ (void)removeCellsInLoopWithIndex:(NSInteger)i section:(NSInteger)section collectionView:(UICollectionView *)collectionView fromArray:array{
    NSIndexPath *ind = [NSIndexPath indexPathForRow:i inSection:section];
    PCAssetCell *cell = (PCAssetCell *)[collectionView cellForItemAtIndexPath:ind];
    
    
    [self removeSingleCell:cell fromArray:array];
    
}

//从_selectedAssets删除单个cell
+ (void)removeSingleCell:(PCAssetCell *)cell fromArray:(NSMutableArray *)array{
    
    for (int i = 0 ; i<array.count; i++) {
        NSMutableArray *arr = array[i];
        
        for (int j = 0; j<arr.count; j++) {
            NSIndexPath *ind = arr[j];
            if (ind.section == cell.indexPath.section && ind.row == cell.indexPath.row) {
                [arr removeObject:ind];
                cell.stateBtnSelected = NO;
            }
        }
        if (arr.count <= 0) {
            [array removeObject:arr];
        }
    }
    
}


//自动加入可见的cell的indexpath
+(void)autoAddVisibleItemsForMoveUpWithArray:(NSMutableArray *)array collectionView:(UICollectionView *)collectionView originIndexPath:(NSIndexPath *)originIndexPath{
    NSMutableArray *arr = [array lastObject];
    NSIndexPath *preIndexPath = (NSIndexPath *)arr.lastObject;
    
    NSMutableArray *items = collectionView.indexPathsForVisibleItems.mutableCopy;
    //把可见的cell的indexpath进行排序
    [items sortUsingComparator:^NSComparisonResult(NSIndexPath * obj1, NSIndexPath * obj2) {
        return [obj1 compare:obj2];
    }];
    
    for (NSInteger i = items.count - 1; i >= 0; i--) {
        NSIndexPath *index = items[i];
        if (index.section < originIndexPath.section ) {
            if (index.section == preIndexPath.section && index.row < preIndexPath.row) {
                [Tool addCellInLoopToCollectionView:collectionView WithIndex:index.row section:index.section array:array];
            }else if (index.section < preIndexPath.section){
                [Tool addCellInLoopToCollectionView:collectionView WithIndex:index.row section:index.section array:array];
            }
        }else if (index.section == originIndexPath.section){
            if (index.row < originIndexPath.row) {
                if (index.row < preIndexPath.row) {
                    [Tool addCellInLoopToCollectionView:collectionView WithIndex:index.row section:index.section array:array];
                }
            }else if (index.row > originIndexPath.row){
                
                [Tool removeCellsInLoopWithIndex:index.row section:index.section collectionView:collectionView fromArray:array];
//                NSLog(@"row:%ld  orirow:%ld   arr:%@",index.row,originIndexPath.row,array);
            }
            
        }
        else{
            [Tool removeCellsInLoopWithIndex:index.row section:index.section collectionView:collectionView fromArray:array];
        }
        
    }
}

+ (void)autoAddVisibleItemsForMoveDownWithArray:(NSMutableArray *)array collectionView:(UICollectionView *)collectionView originIndexPath:(NSIndexPath *)originIndexPath{
    NSMutableArray *arr = [array lastObject];
    NSIndexPath *preIndexPath = (NSIndexPath *)arr.lastObject;
    
    NSMutableArray *items = collectionView.indexPathsForVisibleItems.mutableCopy;
    //把可见的cell的indexpath进行排序
    [items sortUsingComparator:^NSComparisonResult(NSIndexPath * obj1, NSIndexPath * obj2) {
        return [obj1 compare:obj2];
    }];
    for (NSInteger i = 0; i < items.count; i++) {
        NSIndexPath *index = items[i];
        if (index.section >= originIndexPath.section ) {
            if (index.section == preIndexPath.section && index.row > preIndexPath.row) {
                [self addCellInLoopToCollectionView:collectionView WithIndex:index.row section:index.section array:array];
            }else if (index.section > preIndexPath.section){
                [self addCellInLoopToCollectionView:collectionView WithIndex:index.row section:index.section array:array];
            }
        }
    }
}

@end
