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



+(void)autoAddVisibleItemsForMoveUpWithArray:(NSMutableArray *)array collectionView:(UICollectionView *)collectionView originIndexPath:(NSIndexPath *)originIndexPath;

+ (void)autoAddVisibleItemsForMoveDownWithArray:(NSMutableArray *)array collectionView:(UICollectionView *)collectionView originIndexPath:(NSIndexPath *)originIndexPath;



/**
 把手势rect覆盖的attribute数组按section分类

 @param arr <#arr description#>
 @return <#return value description#>
 */
+ (NSMutableArray *)groupFromAttributeArr:(NSMutableArray *)arr;




/**
 获取手势rect覆盖的layoutattributes数组，并按indexpath 升序 representedElementCategory降序排序

 @param originLocation <#originLocation description#>
 @param currentLocation <#currentLocation description#>
 @param collectionView <#collectionView description#>
 @return <#return value description#>
 */
+ (NSMutableArray *)layoutAttributesArrWithOriginLocation:(CGPoint )originLocation currentLocation:(CGPoint)currentLocation collectionView:(UICollectionView *)collectionView;


/**
 第四象限的currentindexpath

 @param arr <#arr description#>
 @param numberPerLine <#numberPerLine description#>
 @return <#return value description#>
 */
+ (NSIndexPath *)currentIndexPathForForthQuadrantWithGroup:(NSMutableArray*)group numberPerLine:(NSInteger)numberPerLine;


/**
 第一象限的currentindexpath

 @param arr <#arr description#>
 @param numberPerLine <#numberPerLine description#>
 @return <#return value description#>
 */
+ (NSIndexPath *)currentIndexPathForFirstQuadrantWithGroup:(NSMutableArray*)group numberPerLine:(NSInteger)numberPerLine;



/**
 第三象限的currentindexpath

 @param group <#group description#>
 @param numberPerLine <#numberPerLine description#>
 @return <#return value description#>
 */
+ (NSIndexPath *)currentIndexPathForThirdQuadrantWithGroup:(NSMutableArray *)group numberPerLine:(NSInteger)numberPerLine;



/**
 第二象限的currentIndexpath;

 @param group <#group description#>
 @param numberPerLine <#numberPerLine description#>
 @return <#return value description#>
 */
+ (NSIndexPath *)currentIndexPathForSecQuadrantWithGroup:(NSMutableArray *)group numberPerLine:(NSInteger)numberPerLine;



/**
 进入第四象限时的前期处理

 @param originindexPath <#originindexPath description#>
 @param currentIndexPath <#currentIndexPath description#>
 @param preIndexPath <#preIndexPath description#>
 @param collectionView <#collectionView description#>
 @param selectedIndexArr <#selectedIndexArr description#>
 @param assets <#assets description#>
 */
+ (void)preHandlerForForthQuadrantWithOriginIndexPath:(NSIndexPath *)originindexPath currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr assets:(NSArray *)assets;



/**
 第四象限在减少的情况下的处理函数

 @param collectionView <#collectionView description#>
 @param currentIndexPath <#currentIndexPath description#>
 @param selectedIndexArr <#selectedIndexArr description#>
 @param lastLayoutAttribute <#lastLayoutAttribute description#>
 */
+ (void)handlerForForthQuadrantInSubtractionWithIndexArr:(NSMutableArray *)group currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath originIndexPath:(NSIndexPath *)originIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr assets:(NSArray *)assets
                                     lastLayoutAttribute:(UICollectionViewLayoutAttributes *)lastLayoutAttribute;



/**
 第四象限在增加的情况下的处理函数 

 @param group <#group description#>
 @param currentIndexPath <#currentIndexPath description#>
 @param preIndexPath <#preIndexPath description#>
 @param originIndexPath <#originIndexPath description#>
 @param collectionView <#collectionView description#>
 @param selectedIndexArr <#selectedIndexArr description#>
 @param assets <#assets description#>
 @param lastLayoutAttribute <#lastLayoutAttribute description#>
 */
+ (void)handlerForForthQuadrantInAddingWithIndexArr:(NSMutableArray *)group currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath originIndexPath:(NSIndexPath *)originIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr assets:(NSArray *)assets
                                lastLayoutAttribute:(UICollectionViewLayoutAttributes *)lastLayoutAttribute;





/**
 第一象限的预处理函数

 @param originIndexPath <#originIndexPath description#>
 @param currentIndexPath <#currentIndexPath description#>
 @param preIndexPath <#preIndexPath description#>
 @param collectionView <#collectionView description#>
 @param selectedIndexArr <#selectedIndexArr description#>
 */
+ (void)preHandlerForFirstQuadrantWithOriginIndexPath:(NSIndexPath *)originIndexPath currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr;

/**
 第一象限在减少情况下的处理函数

 @param collectionView <#collectionView description#>
 @param currentIndexPath <#currentIndexPath description#>
 @param selectedIndexArr <#selectedIndexArr description#>
 @param originIndexPath <#originIndexPath description#>
 */
+ (void)handlerForFirstQuadrantInSubtractionWithIndexArr:(NSMutableArray *)group currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath originIndexPath:(NSIndexPath *)originIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr assets:(NSArray *)assets
                                     lastLayoutAttribute:(UICollectionViewLayoutAttributes *)lastLayoutAttribute;



/**
 第一象限在增加的情况下的处理函数

 @param group <#group description#>
 @param currentIndexPath <#currentIndexPath description#>
 @param preIndexPath <#preIndexPath description#>
 @param originIndexPath <#originIndexPath description#>
 @param collectionView <#collectionView description#>
 @param selectedIndexArr <#selectedIndexArr description#>
 @param assets <#assets description#>
 */
+ (void)handlerForFirstQuadrantInAddingWithIndexArr:(NSMutableArray *)group currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath originIndexPath:(NSIndexPath *)originIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr assets:(NSArray *)assets;



/**
 第二象限的预处理函数
 
 @param originIndexPath <#originIndexPath description#>
 @param currentIndexPath <#currentIndexPath description#>
 @param preIndexPath <#preIndexPath description#>
 @param collectionView <#collectionView description#>
 @param selectedIndexArr <#selectedIndexArr description#>
 @param assets <#assets description#>
 */
+ (void)preHandlerForSecondQuadrantOriginIndexPath:(NSIndexPath *)originIndexPath currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr assets:(NSArray *)assets;


/**
 第二象限在减少的情况下的处理函数
 
 @param collectionView <#collectionView description#>
 @param currentIndexPath <#currentIndexPath description#>
 @param preIndexPath <#preIndexPath description#>
 @param selectedIndexArr <#selectedIndexArr description#>
 */
+ (void)handlerForSecondQuadrantInSubtractionWithIndexArr:(NSMutableArray *)group currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath originIndexPath:(NSIndexPath *)originIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr assets:(NSArray *)assets
                                      lastLayoutAttribute:(UICollectionViewLayoutAttributes *)lastLayoutAttribute;



/**
 第二象限在增加的情况下的处理函数
 
 @param group <#group description#>
 @param currentIndexPath <#currentIndexPath description#>
 @param preIndexPath <#preIndexPath description#>
 @param originIndexPath <#originIndexPath description#>
 @param collectionView <#collectionView description#>
 @param selectedIndexArr <#selectedIndexArr description#>
 @param assets <#assets description#>
 */
+ (void)handlerForSecondQuadrantInAddingWithIndexArr:(NSMutableArray *)group currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath originIndexPath:(NSIndexPath *)originIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr assets:(NSArray *)assets;




/**
 第三象限在减少的情况下的处理函数 

 @param collectionView <#collectionView description#>
 @param currentIndexPath <#currentIndexPath description#>
 @param preIndexPath <#preIndexPath description#>
 @param selectedIndexArr <#selectedIndexArr description#>
 @param originIndexPath <#originIndexPath description#>
 @param assets <#assets description#>
 @param lastLayoutAttribute <#lastLayoutAttribute description#>
 */
+ (void)handlerForThirdQuadrantInSubtractionWithCollectionView:(UICollectionView *)collectionView currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath selectedIndexArr:(NSMutableArray *)selectedIndexArr originIndexPath:(NSIndexPath *)originIndexPath assets:(NSArray *)assets lastLayoutAttribute:(UICollectionViewLayoutAttributes *)lastLayoutAttribute;



/**
 第三象限在增加的情况下的处理函数

 @param group <#group description#>
 @param currentIndexPath <#currentIndexPath description#>
 @param preIndexPath <#preIndexPath description#>
 @param originIndexPath <#originIndexPath description#>
 @param collectionView <#collectionView description#>
 @param selectedIndexArr <#selectedIndexArr description#>
 @param assets <#assets description#>
 @param lastLayoutAttribute <#lastLayoutAttribute description#>
 */
+ (void)handlerForThirdQuadrantInAddingWithIndexArr:(NSMutableArray *)group currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath originIndexPath:(NSIndexPath *)originIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr assets:(NSArray *)assets lastLayoutAttribute:(UICollectionViewLayoutAttributes *)lastLayoutAttribute;





@end
