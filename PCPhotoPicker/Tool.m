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
//    for (NSMutableArray *arr in array) {
        for (NSIndexPath *ind in array) {
            if (ind.section == cell.indexPath.section && ind.row == cell.indexPath.row) {
                return YES;
            }
        }
//    }
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
//        NSMutableArray *arr = [array lastObject];
//        if (!arr) {
//            arr = [[NSMutableArray alloc]init];
//            [array addObject:ind];
//        }
        
        cell.stateBtnSelected = YES;
        [array addObject:ind];
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
//        NSMutableArray *arr = array[i];
        
//        for (int j = 0; j<arr.count; j++) {
            NSIndexPath *ind = array[i];
            if (ind.section == cell.indexPath.section && ind.row == cell.indexPath.row) {
                [array removeObject:ind];
                cell.stateBtnSelected = NO;
            }
//        }
//        if (arr.count <= 0) {
//            [array removeObject:arr];
//        }
    }
    
}


//自动加入可见的cell的indexpath
+(void)autoAddVisibleItemsForMoveUpWithArray:(NSMutableArray *)array collectionView:(UICollectionView *)collectionView originIndexPath:(NSIndexPath *)originIndexPath{
    //有可能是下滑完再上 滑
    NSIndexPath *preIndexPath = (NSIndexPath *)array.lastObject;
    
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
//    NSMutableArray *arr = [array lastObject];
    
    //有可能是上滑完再下滑
    NSIndexPath *preIndexPath = (NSIndexPath *)array.lastObject;
    
    NSMutableArray *items = collectionView.indexPathsForVisibleItems.mutableCopy;
    //把可见的cell的indexpath进行排序
    [items sortUsingComparator:^NSComparisonResult(NSIndexPath * obj1, NSIndexPath * obj2) {
        return [obj1 compare:obj2];
    }];
    for (NSInteger i = 0; i < items.count; i++) {
        NSIndexPath *index = items[i];
        if (index.section > originIndexPath.section ) {
            if (index.section == preIndexPath.section && index.row > preIndexPath.row) {
                [self addCellInLoopToCollectionView:collectionView WithIndex:index.row section:index.section array:array];
            }else if (index.section > preIndexPath.section){
                [self addCellInLoopToCollectionView:collectionView WithIndex:index.row section:index.section array:array];
            }
        }else if (index.section == originIndexPath.section){
            
            if (index.row < originIndexPath.row) {
                [Tool removeCellsInLoopWithIndex:index.row section:index.section collectionView:collectionView fromArray:array];
            }else if (index.row > originIndexPath.row){
                [self addCellInLoopToCollectionView:collectionView WithIndex:index.row section:index.section array:array];
            }
            
            
            
        }else{
            [Tool removeCellsInLoopWithIndex:index.row section:index.section collectionView:collectionView fromArray:array];
        }
    }
}



+ (NSMutableArray *)groupFromAttributeArr:(NSMutableArray *)arr{
    NSMutableArray *group = [[NSMutableArray alloc]init];
    UICollectionViewLayoutAttributes *index = arr[0];
    NSMutableArray *firt = [[NSMutableArray alloc]init];
    [firt addObject:index];
    [group addObject:firt];
    NSInteger section = index.indexPath.section;
    for (NSInteger i = 1; i < arr.count; i++) {
        UICollectionViewLayoutAttributes *temp = arr[i];
        if (temp.indexPath.section == section) {
            NSMutableArray *element = group.lastObject;
            [element addObject:temp];
        }else if (temp.indexPath.section > section){
            section = temp.indexPath.section;
            NSMutableArray *nextElement = [[NSMutableArray alloc]init];
            [nextElement addObject:temp];
            [group addObject:nextElement];
        }
    }
    return group;
}

+ (NSMutableArray *)layoutAttributesArrWithOriginLocation:(CGPoint )originLocation currentLocation:(CGPoint)currentLocation collectionView:(UICollectionView *)collectionView{
    CGRect rect = CGRectMake(originLocation.x, originLocation.y,  currentLocation.x - originLocation.x,  currentLocation.y - originLocation.y);
    NSMutableArray *arr = [collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect].mutableCopy;
    NSSortDescriptor *s1 = [NSSortDescriptor sortDescriptorWithKey:@"indexPath" ascending:YES];
    NSSortDescriptor *s2 = [NSSortDescriptor sortDescriptorWithKey:@"representedElementCategory" ascending:NO];
    NSArray *sorts = @[s1,s2];
    [arr sortUsingDescriptors:sorts];
    return arr;
}




+ (NSIndexPath *)currentIndexPathForForthQuadrantWithGroup:(NSMutableArray*)group numberPerLine:(NSInteger)numberPerLine{
    NSIndexPath *currentIndexPath = nil;
    NSMutableArray *lastPart = group.lastObject;
    UICollectionViewLayoutAttributes *att = lastPart.lastObject;
    if (att.representedElementCategory == 1) {
        currentIndexPath = att.indexPath;
    }else if(att.representedElementCategory == 0){
        //归类
        NSMutableArray *lastSectionGroup = group.lastObject;
        UICollectionViewLayoutAttributes *index = lastSectionGroup.firstObject;
        NSMutableArray *first = [[NSMutableArray alloc]init];
        if (index.representedElementCategory == 1) {
            index = lastSectionGroup[1];
        }
        [first addObject:index];
        NSInteger remainder = index.indexPath.row/numberPerLine;
        NSMutableArray *divGroup = [Tool divGroupWithFirstElement:first sectionGroup:lastSectionGroup remainder:remainder numberPerLine:numberPerLine];
        NSMutableArray *lastPart = divGroup.lastObject;
        UICollectionViewLayoutAttributes *firstAtt = lastPart.lastObject;
        currentIndexPath = firstAtt.indexPath;
    }
    return currentIndexPath;
}


+ (NSIndexPath *)currentIndexPathForFirstQuadrantWithGroup:(NSMutableArray*)group numberPerLine:(NSInteger)numberPerLine{
    NSIndexPath *currentIndexPath = nil;
    NSMutableArray *firstPart = group[0];
    UICollectionViewLayoutAttributes *att = firstPart.firstObject;
    if (att.representedElementCategory == 1) {
        currentIndexPath = att.indexPath;
    }else if(att.representedElementCategory == 0){
        //归类
        NSMutableArray *firstSectionGroup = group[0];
       
        UICollectionViewLayoutAttributes *index = firstSectionGroup[0];
        NSMutableArray *first = [[NSMutableArray alloc]init];
        [first addObject:index];
         NSInteger remainder = index.indexPath.row/numberPerLine;
        NSMutableArray *divGroup = [Tool divGroupWithFirstElement:first sectionGroup:firstSectionGroup remainder:remainder numberPerLine:numberPerLine];
        NSMutableArray *firstPart = divGroup[0];
        UICollectionViewLayoutAttributes *firstAtt = firstPart.lastObject;
        currentIndexPath = firstAtt.indexPath;
    }
     return currentIndexPath;
}


+ (NSIndexPath *)currentIndexPathForThirdQuadrantWithGroup:(NSMutableArray *)group numberPerLine:(NSInteger)numberPerLine{
    NSIndexPath *currentIndexPath = nil;
    NSMutableArray *lastPart = group.lastObject;
    UICollectionViewLayoutAttributes *att = lastPart.lastObject;
    if (att.representedElementCategory == 1) {
        currentIndexPath = att.indexPath;
    }else if(att.representedElementCategory == 0){
        //归类
        NSMutableArray *lastSectionGroup = group.lastObject;
        UICollectionViewLayoutAttributes *index = lastSectionGroup.firstObject;
        NSMutableArray *first = [[NSMutableArray alloc]init];
        if (index.representedElementCategory == 1) {
            index = lastSectionGroup[1];
        }
        [first addObject:index];
        NSInteger remainder = index.indexPath.row/numberPerLine;
        NSMutableArray *divGroup = [Tool divGroupWithFirstElement:first sectionGroup:lastSectionGroup remainder:remainder numberPerLine:numberPerLine];
        NSMutableArray *lastPart = divGroup.lastObject;
        UICollectionViewLayoutAttributes *firstAtt = lastPart.firstObject;
        currentIndexPath = firstAtt.indexPath;
    }
    return currentIndexPath;
}


+ (NSIndexPath *)currentIndexPathForSecQuadrantWithGroup:(NSMutableArray *)group numberPerLine:(NSInteger)numberPerLine{
    NSIndexPath *currentIndexPath = nil;
    NSMutableArray *firstPart = group[0];
    UICollectionViewLayoutAttributes *att = firstPart.firstObject;
    if (att.representedElementCategory == 1) {
        currentIndexPath = att.indexPath;
    }else if(att.representedElementCategory == 0){
        //归类
        NSMutableArray *firstSectionGroup = group[0];
        UICollectionViewLayoutAttributes *index = firstSectionGroup[0];
        NSMutableArray *first = [[NSMutableArray alloc]init];
        [first addObject:index];
        NSInteger remainder = index.indexPath.row/numberPerLine;
        NSMutableArray *divGroup = [Tool divGroupWithFirstElement:first sectionGroup:firstSectionGroup remainder:remainder numberPerLine:numberPerLine];
        NSMutableArray *firstPart = divGroup[0];
        UICollectionViewLayoutAttributes *firstAtt = firstPart.firstObject;
        currentIndexPath = firstAtt.indexPath;
    }
    return currentIndexPath;
}


/**
 把group的最后一部分进行划分，同一行的layoutattribute为一组

 @param group
 @param numberPerLine
 @return
 */
+ (NSMutableArray *)divGroupWithFirstElement:(NSMutableArray *)first sectionGroup:(NSMutableArray *)sectionGroup remainder:(NSInteger )remainder numberPerLine:(NSInteger)numberPerLine{
    NSMutableArray *divGroup = [[NSMutableArray alloc]init];
    
    [divGroup addObject:first];
    for (NSInteger i = 1; i< sectionGroup.count; i++) {
        UICollectionViewLayoutAttributes *temp = sectionGroup[i];
        if (temp.indexPath.row / numberPerLine == remainder) {
            NSMutableArray *element = [divGroup lastObject];
            [element addObject:temp];
        }else if(temp.indexPath.row / numberPerLine > remainder){
            if (temp.representedElementCategory == 0) {
                remainder = temp.indexPath.row / numberPerLine;
                NSMutableArray *nextElement = [[NSMutableArray alloc]init];
                [nextElement addObject:temp];
                [divGroup addObject:nextElement];
            }
        }
    }
    return divGroup;
}



#pragma 

#pragma 第四象限的处理函数
+ (void)preHandlerForForthQuadrantWithOriginIndexPath:(NSIndexPath *)originindexPath currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr assets:(NSArray *)assets{
    if (currentIndexPath.section == originindexPath.section && currentIndexPath.row > originindexPath.row ) {
        //从第一象限进入时，有时没选上
        for (NSInteger i = originindexPath.row; i <= currentIndexPath.row; i++) {
            [Tool addCellInLoopToCollectionView:collectionView WithIndex:i section:originindexPath.section array:selectedIndexArr];
        }
        
        if (preIndexPath.row < originindexPath.row && preIndexPath.section == originindexPath.section) {
            for (NSInteger i = originindexPath.row - 1;i >= preIndexPath.row ; i--) {
                [Tool removeCellsInLoopWithIndex:i section:originindexPath.section collectionView:collectionView fromArray:selectedIndexArr];
            }
        }else if (preIndexPath.section < originindexPath.section){
            //有可能是从上个section进入，要把上个section的删除
            
            NSDictionary *dict = assets[preIndexPath.section];
            NSArray *preSectionArr = dict[@"assets"];
            for (NSInteger i = preIndexPath.row ; i < preSectionArr.count; i++) {
                [Tool removeCellsInLoopWithIndex:i section:preIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
            }
            
            for (NSInteger i = 0 ; i < originindexPath.row; i++) {
                [Tool removeCellsInLoopWithIndex:i section:originindexPath.section collectionView:collectionView fromArray:selectedIndexArr];
            }
        }
    }else if (currentIndexPath.section > originindexPath.section){
        if (preIndexPath.row < originindexPath.row && preIndexPath.section == originindexPath.section) {
            for (NSInteger i = originindexPath.row - 1;i >= preIndexPath.row ; i--) {
                [Tool removeCellsInLoopWithIndex:i section:originindexPath.section collectionView:collectionView fromArray:selectedIndexArr];
            }
        }else if (preIndexPath.section < originindexPath.section){
            //有可能是从上个section进入，要把上个section的删除
            NSDictionary *dict = assets[preIndexPath.section];
            NSArray *preSectionArr = dict[@"assets"];
            for (NSInteger i = preIndexPath.row ; i < preSectionArr.count; i++) {
                [Tool removeCellsInLoopWithIndex:i section:preIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
            }
            
            for (NSInteger i = 0 ; i < originindexPath.row; i++) {
                [Tool removeCellsInLoopWithIndex:i section:originindexPath.section collectionView:collectionView fromArray:selectedIndexArr];
            }
        }
    }
}


+ (void)handlerForForthQuadrantInSubtractionWithIndexArr:(NSMutableArray *)group currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath originIndexPath:(NSIndexPath *)originIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr assets:(NSArray *)assets
                                     lastLayoutAttribute:(UICollectionViewLayoutAttributes *)lastLayoutAttribute{

    
        if ( currentIndexPath.section == preIndexPath.section ) {
            if (lastLayoutAttribute.representedElementCategory == 0) {
            
                for (NSInteger i = preIndexPath.row;  i > currentIndexPath.row ; i--) {
                    [Tool removeCellsInLoopWithIndex:i section:currentIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
                }
            }
            else if (lastLayoutAttribute.representedElementCategory == 1){
                //移到headerview
                for (NSInteger i = preIndexPath.row;  i >= currentIndexPath.row ; i--) {
                    [Tool removeCellsInLoopWithIndex:i section:currentIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
                }
            }
        }else if (preIndexPath.section > currentIndexPath.section){
//            处理preindexpath所在的section
            for (NSInteger i = preIndexPath.row ; i >= 0; i--) {
                [Tool removeCellsInLoopWithIndex:i section:preIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
            }
            
            //处理中间的section
            for (NSInteger i = preIndexPath.section - 1; i > currentIndexPath.section ; i--) {
                NSDictionary *dict = assets[i];
                NSArray *midSectionArr = dict[@"assets"];
                for (NSInteger j = midSectionArr.count - 1; j >= 0 ; j--) {
                    [Tool removeCellsInLoopWithIndex:j section:i collectionView:collectionView fromArray:selectedIndexArr];
                }
            }
            
            //处理currentindexpath所在的section
            NSDictionary *dict = assets[currentIndexPath.section];
            NSArray *currentSectionArr = dict[@"assets"];
            if (lastLayoutAttribute.representedElementCategory == 0) {
                for (NSInteger i = currentSectionArr.count - 1; i >currentIndexPath.row; i--) {
                    [Tool removeCellsInLoopWithIndex:i section:currentIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
                }
            }
            else if (lastLayoutAttribute.representedElementCategory == 1){
                //移到headerview
                for (NSInteger i = currentSectionArr.count - 1; i >=currentIndexPath.row; i--) {
                    [Tool removeCellsInLoopWithIndex:i section:currentIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
                }
            }
        }
}




+ (void)handlerForForthQuadrantInAddingWithIndexArr:(NSMutableArray *)group currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath originIndexPath:(NSIndexPath *)originIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr assets:(NSArray *)assets
lastLayoutAttribute:(UICollectionViewLayoutAttributes *)lastLayoutAttribute{
    if (group.count == 1) {
        //只有一个section
        
        if (currentIndexPath.row > originIndexPath.row) {
            for (NSInteger i = originIndexPath.row; i <= currentIndexPath.row; i++) {
                [Tool addCellInLoopToCollectionView:collectionView WithIndex:i section:originIndexPath.section array:selectedIndexArr];
            }
            
            if (preIndexPath.row < originIndexPath.row && preIndexPath.section == originIndexPath.section) {
                for (NSInteger i = originIndexPath.row - 1;i >= preIndexPath.row ; i--) {
                    [Tool removeCellsInLoopWithIndex:i section:originIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
                }
            }
        }
    }else if (group.count > 1){
        // 多个section
        //处理原始section
        NSDictionary *dict = assets[originIndexPath.section];
        NSArray *currentSectionArr = dict[@"assets"];
        for (NSInteger i = originIndexPath.row; i <currentSectionArr.count; i++) {
            [Tool addCellInLoopToCollectionView:collectionView WithIndex:i section:originIndexPath.section array:selectedIndexArr];
        }
        
        if (preIndexPath.row < originIndexPath.row && preIndexPath.section == originIndexPath.section) {
            for (NSInteger i = originIndexPath.row - 1;i >= preIndexPath.row ; i--) {
                [Tool removeCellsInLoopWithIndex:i section:originIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
            }
        }
        
        //处理中间的section
        for (NSInteger i = 1; i < group.count - 1; i++) {
            NSMutableArray *midPart = group[i];
            UICollectionViewLayoutAttributes *firstAtt = midPart.firstObject;
            NSDictionary *dict = assets[firstAtt.indexPath.section];
            NSArray *midSectionArr = dict[@"assets"];
            for ( NSInteger i = midSectionArr.count - 1; i>= 0; i--) {
                [Tool addCellInLoopToCollectionView:collectionView WithIndex:i section:firstAtt.indexPath.section array:selectedIndexArr];
            }
        }
        
        //处理最后一个section
        if (lastLayoutAttribute.representedElementCategory == 0) {
            //进到cell，
            for (NSInteger i = 0; i <= currentIndexPath.row; i++) {
                [Tool addCellInLoopToCollectionView:collectionView WithIndex:i section:currentIndexPath.section array:selectedIndexArr];
            }
        }
        
    }
}

#pragma 第一象限

+ (void)preHandlerForFirstQuadrantWithOriginIndexPath:(NSIndexPath *)originIndexPath currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr{
    if (preIndexPath.section == originIndexPath.section && preIndexPath.row > originIndexPath.row) {
        for (NSInteger i = preIndexPath.row; i > originIndexPath.row; i--) {
            [Tool removeCellsInLoopWithIndex:i section:originIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
        }
    }
}



+ (void)handlerForFirstQuadrantInSubtractionWithIndexArr:(NSMutableArray *)group currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath originIndexPath:(NSIndexPath *)originIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr assets:(NSArray *)assets
                                         lastLayoutAttribute:(UICollectionViewLayoutAttributes *)lastLayoutAttribute{
    //糟了，忘了这段代码的作用了。。。。
    if (currentIndexPath.section == originIndexPath.section && currentIndexPath.row > originIndexPath.row) {
        return;
    }

    if ( currentIndexPath.section == preIndexPath.section ) {
        //在同一section
        for (NSInteger i = preIndexPath.row; i < currentIndexPath.row; i++) {
            [Tool removeCellsInLoopWithIndex:i section:currentIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
        }
    }else if (currentIndexPath.section > preIndexPath.section){
        //处理preindexpath所在的section
        NSDictionary *dict = assets[preIndexPath.section];
        NSArray *preSectionArr = dict[@"assets"];
        for (NSInteger i = preIndexPath.row; i < preSectionArr.count; i++) {
            [Tool removeCellsInLoopWithIndex:i section:preIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
        }
        
        //处理中间的section
        for (NSInteger i = preIndexPath.section + 1; i < currentIndexPath.section; i++) {
            NSDictionary *dict = assets[i];
            NSArray *midSectionArr = dict[@"assets"];
            for (NSInteger j = midSectionArr.count - 1; j >= 0 ; j--) {
                [Tool removeCellsInLoopWithIndex:j section:i collectionView:collectionView fromArray:selectedIndexArr];
            }
        }
        
        //处理currentindexpath所在的section
        for (NSInteger i = 0; i < currentIndexPath.row; i++) {
            [Tool removeCellsInLoopWithIndex:i section:currentIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
        }
    }
}

+ (void)handlerForFirstQuadrantInAddingWithIndexArr:(NSMutableArray *)group currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath originIndexPath:(NSIndexPath *)originIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr assets:(NSArray *)assets{
    if (group.count == 1) {
        if (currentIndexPath.row < originIndexPath.row) {
            for (NSInteger i = originIndexPath.row; i >= currentIndexPath.row; i--) {
                [Tool addCellInLoopToCollectionView:collectionView WithIndex:i section:originIndexPath.section array:selectedIndexArr];
            }
            
            
            if (preIndexPath.section == originIndexPath.section && preIndexPath.row > originIndexPath.row) {
                for (NSInteger i = preIndexPath.row; i > originIndexPath.row; i--) {
                    [Tool removeCellsInLoopWithIndex:i section:originIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
                }
            }
            
        }
    }else if (group.count >1){
        //
        //处理原始section
        for (NSInteger i = originIndexPath.row; i >= 0; i--) {
            [Tool addCellInLoopToCollectionView:collectionView WithIndex:i section:originIndexPath.section array:selectedIndexArr];
        }
        
        //处理中间的section
        for (NSInteger i = 1; i < group.count - 1; i++) {
            NSMutableArray *midPart = group[i];
            UICollectionViewLayoutAttributes *firstAtt = midPart.firstObject;
            NSDictionary *dict = assets[firstAtt.indexPath.section];
            NSArray *midSectionArr = dict[@"assets"];
            for ( NSInteger i = 0; i< midSectionArr.count; i++) {
                [Tool addCellInLoopToCollectionView:collectionView WithIndex:i section:firstAtt.indexPath.section array:selectedIndexArr];
            }
            
        }
        
        //处理第一个section
        NSMutableArray *firstPart = group[0];
        UICollectionViewLayoutAttributes *firstAtt = firstPart.firstObject;
        NSDictionary *firstDict = assets[firstAtt.indexPath.section];
        NSArray *firstSectionArr = firstDict[@"assets"];
        for ( NSInteger i = firstSectionArr.count - 1; i>= currentIndexPath.row; i--) {
            [Tool addCellInLoopToCollectionView:collectionView WithIndex:i section:firstAtt.indexPath.section array:selectedIndexArr];
        }
        
    }
}


#pragma 第二象限

+ (void)preHandlerForSecondQuadrantOriginIndexPath:(NSIndexPath *)originIndexPath currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr assets:(NSArray *)assets{
    if (currentIndexPath.section == originIndexPath.section && currentIndexPath.row < originIndexPath.row) {
        //从第三象限进入时，有时没选上
        for (NSInteger i = originIndexPath.row; i >= currentIndexPath.row; i--) {
            [Tool addCellInLoopToCollectionView:collectionView WithIndex:i section:originIndexPath.section array:selectedIndexArr];
        }
        
        if (preIndexPath.section == originIndexPath.section && preIndexPath.row > originIndexPath.row){
            for (NSInteger i = preIndexPath.row; i > originIndexPath.row; i--) {
                [Tool removeCellsInLoopWithIndex:i section:originIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
            }
        }
    }
    
    //有可能从下一个section往上滑进入第二象限
    if (preIndexPath.section > originIndexPath.section) {
        for (NSInteger i = preIndexPath.row; i>= 0; i--) {
            [Tool removeCellsInLoopWithIndex:i section:preIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
        }
    }
}

+ (void)handlerForSecondQuadrantInSubtractionWithIndexArr:(NSMutableArray *)group currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath originIndexPath:(NSIndexPath *)originIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr assets:(NSArray *)assets
                                      lastLayoutAttribute:(UICollectionViewLayoutAttributes *)lastLayoutAttribute{
    
    if ( currentIndexPath.section == preIndexPath.section ) {
        //在同一个section
        for (NSInteger i = preIndexPath.row; i < currentIndexPath.row; i++) {
            [Tool removeCellsInLoopWithIndex:i section:currentIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
        }
        
    }else if (currentIndexPath.section > preIndexPath.section){
        //处理preindexpath所在的section
        NSDictionary *dict = assets[preIndexPath.section];
        NSArray *preSectionArr = dict[@"assets"];
        for (NSInteger i = preIndexPath.row; i < preSectionArr.count; i++) {
            [Tool removeCellsInLoopWithIndex:i section:preIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
        }
        
        //处理中间的section
        for (NSInteger i = preIndexPath.section + 1; i < currentIndexPath.section; i++) {
            NSDictionary *dict = assets[i];
            NSArray *midSectionArr = dict[@"assets"];
            for (NSInteger j = midSectionArr.count - 1; j >= 0 ; j--) {
                [Tool removeCellsInLoopWithIndex:j section:i collectionView:collectionView fromArray:selectedIndexArr];
            }
        }
        
        //处理currentindexpath所在的section
        for (NSInteger i = 0; i < currentIndexPath.row; i++) {
            [Tool removeCellsInLoopWithIndex:i section:currentIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
        }
    }
}



+ (void)handlerForSecondQuadrantInAddingWithIndexArr:(NSMutableArray *)group currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath originIndexPath:(NSIndexPath *)originIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr assets:(NSArray *)assets {
    if (group.count == 1) {
        //只有一个section 理论上是原始section
        for (NSInteger i = originIndexPath.row; i >= currentIndexPath.row; i--) {
            [Tool addCellInLoopToCollectionView:collectionView WithIndex:i section:originIndexPath.section array:selectedIndexArr];
        }
    
        //似乎有些多余，相同的操作在预处理函数中已经做了。。。
        if (preIndexPath.section == originIndexPath.section && preIndexPath.row > originIndexPath.row) {
            for (NSInteger i = preIndexPath.row; i > originIndexPath.row; i--) {
                [Tool removeCellsInLoopWithIndex:i section:originIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
            }
        }
    }else if (group.count >1){
        //多个section
        //处理原始section
        for (NSInteger i = originIndexPath.row; i >= 0; i--) {
            [Tool addCellInLoopToCollectionView:collectionView WithIndex:i section:originIndexPath.section array:selectedIndexArr];
        }
        
        //处理中间的section
        for (NSInteger i = 1; i < group.count - 1; i++) {
            NSMutableArray *midPart = group[i];
            UICollectionViewLayoutAttributes *firstAtt = midPart.firstObject;
            NSDictionary *dict = assets[firstAtt.indexPath.section];
            NSArray *midSectionArr = dict[@"assets"];
            for ( NSInteger i = midSectionArr.count - 1; i>= 0; i--) {
                [Tool addCellInLoopToCollectionView:collectionView WithIndex:i section:firstAtt.indexPath.section array:selectedIndexArr];
            }
        }
        //处理第一个section
        NSMutableArray *firstPart = group[0];
        UICollectionViewLayoutAttributes *firstAtt = firstPart.firstObject;
        NSDictionary *dict = assets[firstAtt.indexPath.section];
        NSArray *firstSectionArr = dict[@"assets"];
        for ( NSInteger i = firstSectionArr.count - 1; i>= currentIndexPath.row; i--) {
            [Tool addCellInLoopToCollectionView:collectionView WithIndex:i section:firstAtt.indexPath.section array:selectedIndexArr];
        }
    }
}


#pragma 第三象限 
+ (void)handlerForThirdQuadrantInSubtractionWithCollectionView:(UICollectionView *)collectionView currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath selectedIndexArr:(NSMutableArray *)selectedIndexArr originIndexPath:(NSIndexPath *)originIndexPath assets:(NSArray *)assets lastLayoutAttribute:(UICollectionViewLayoutAttributes *)lastLayoutAttribute{
    //有一种情况：在原始section， 滑动到该section 的末尾的右边，此时的currentlocation的坐标比原始cell的低，所以在第三象限，但是获得的currentIndexPath却在原始indexpath的左边，这种情况直接返回
    if (currentIndexPath.section == originIndexPath.section && currentIndexPath.row < originIndexPath.row) {
        return;
    }
    if ( currentIndexPath.section == preIndexPath.section   ) {
        
        if (currentIndexPath.row < preIndexPath.row) {
            //在同一个section
            
            for (NSInteger i = preIndexPath.row; i > currentIndexPath.row; i--) {
                [Tool removeCellsInLoopWithIndex:i section:currentIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
            }
        }else if (currentIndexPath.row == preIndexPath.row){
            
            NSDictionary *dict = assets[currentIndexPath.section];
            NSArray *currentSectionArr = dict[@"assets"];
            if (lastLayoutAttribute.representedElementCategory == 1){
                //向上滑到headerview，此时currentindexpath 的row是0，preindexpath的row 也是0
                for (NSInteger i = currentSectionArr.count - 1; i >=0; i--) {
                    [Tool removeCellsInLoopWithIndex:i section:currentIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
                }
            }
        }
    }else if (currentIndexPath.section < preIndexPath.section){
        //处理preindexpath所在的section
        for (NSInteger i = preIndexPath.row; i >= 0; i--) {
            [Tool removeCellsInLoopWithIndex:i section:preIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
        }
        
        //处理中间的section
        for (NSInteger i = preIndexPath.section + 1; i < currentIndexPath.section; i++) {
            NSDictionary *dict = assets[i];
            NSArray *midSectionArr = dict[@"assets"];
            for (NSInteger j = midSectionArr.count - 1; j >= 0 ; j--) {
                [Tool removeCellsInLoopWithIndex:j section:i collectionView:collectionView fromArray:selectedIndexArr];
            }
        }
        
        //处理currentindexpath所在的section
        NSDictionary *dict = assets[currentIndexPath.section];
        NSArray *currentSectionArr = dict[@"assets"];
        for (NSInteger i = currentSectionArr.count - 1; i > currentIndexPath.row; i--) {
            [Tool removeCellsInLoopWithIndex:i section:currentIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
        }
    }
}



+ (void)handlerForThirdQuadrantInAddingWithIndexArr:(NSMutableArray *)group currentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath originIndexPath:(NSIndexPath *)originIndexPath collectionView:(UICollectionView *)collectionView selectedIndexArr:(NSMutableArray *)selectedIndexArr assets:(NSArray *)assets lastLayoutAttribute:(UICollectionViewLayoutAttributes *)lastLayoutAttribute{
    if (group.count ==1 ) {
        //只有一个section
        if (currentIndexPath.row > originIndexPath.row) {
            for (NSInteger i = originIndexPath.row; i <= currentIndexPath.row; i++) {
                [Tool addCellInLoopToCollectionView:collectionView WithIndex:i section:originIndexPath.section array:selectedIndexArr];
            }
        }
        
        if (preIndexPath.section == originIndexPath.section && preIndexPath.row < originIndexPath.row) {
            for (NSInteger i = preIndexPath.row; i < originIndexPath.row; i++) {
                [Tool removeCellsInLoopWithIndex:i section:originIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
            }
        }
    }else if (group.count > 1){
        //包含多个section
        //处理原始section
        NSDictionary *dict = assets[originIndexPath.section];
        NSArray *currentSectionArr = dict[@"assets"];
        for (NSInteger i = originIndexPath.row; i < currentSectionArr.count; i++) {
            [Tool addCellInLoopToCollectionView:collectionView WithIndex:i section:originIndexPath.section array:selectedIndexArr];
        }
        for (NSInteger i = 0; i <originIndexPath.row; i++) {
            [Tool removeCellsInLoopWithIndex:i section:originIndexPath.section collectionView:collectionView fromArray:selectedIndexArr];
        }
        
        //处理中间的section
        for (NSInteger i = 1; i < group.count - 1; i++) {
            NSMutableArray *midPart = group[i];
            UICollectionViewLayoutAttributes *firstAtt = midPart.firstObject;
            NSDictionary *dict = assets[firstAtt.indexPath.section];
            NSArray *midSectionArr = dict[@"assets"];
            for ( NSInteger i = 0; i< midSectionArr.count; i++) {
                [Tool addCellInLoopToCollectionView:collectionView WithIndex:i section:firstAtt.indexPath.section array:selectedIndexArr];
            }
            
        }
        
        
        //处理最后的section
        if (lastLayoutAttribute.representedElementCategory == 0) {
            for (NSInteger i = 0; i <= currentIndexPath.row; i++) {
                [Tool addCellInLoopToCollectionView:collectionView WithIndex:i section:currentIndexPath.section array:selectedIndexArr];
            }
        }
    }
}




@end
