//
//  Tool.h
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/3/14.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class PCAssetCell;
@interface Tool : NSObject


+ (BOOL)cellIsSelected:(PCAssetCell *)cell inArrary:(NSArray *)array;

/**
 添加cell到array

 @param collectionView collectionView
 @param i i
 @param section section
 @param array 目标array
 */
+ (void)addCellInLoopToCollectionView:(UICollectionView *)collectionView WithIndex:(NSInteger)i section:(NSInteger)section array:(NSMutableArray *)array;


/**
 从array中删除cell

 @param i <#i description#>
 @param section <#section description#>
 @param collectionView <#collectionView description#>
 */
+ (void)removeCellsInLoopWithIndex:(NSInteger)i section:(NSInteger)section collectionView:(UICollectionView *)collectionView fromArray:array;



+(void)autoAddVisibleItemsWithArray:(NSMutableArray *)array collectionView:(UICollectionView *)collectionView;
@end
