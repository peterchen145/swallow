//
//  PCPhotosViewController.m
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/4.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import "PCPhotosViewController.h"
#import "PCAlbumModel.h"
#import "PCAssetModel.h"
#import "PCPhotoPickerHelper.h"
#import "PCAssetCell.h"
#import "ScrollBar.h"

@interface PCPhotosViewController ()<ScrollBarDelegate,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UICollectionViewDataSource>
@property (strong, nonatomic) NSArray<PCAssetModel *> * assets;
@property (strong, nonatomic) ScrollBar *scrollBar;
@property (assign, nonatomic) CGFloat oldY;
@property (assign, nonatomic) CGFloat nY;
@property (assign, nonatomic) CGFloat oldYOffset;
@property (strong, nonatomic) UICollectionView *collectionView;
@end

static NSString * const reuseIdentifier = @"Cell";

@implementation PCPhotosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = _album.name;
    [self setUpCollectionView];
    
    [self.collectionView registerClass:[PCAssetCell class] forCellWithReuseIdentifier:reuseIdentifier];
    _assets = [[PCPhotoPickerHelper sharedPhotoPickerHelper] assetsFromAlbum:_album.fetchResult];
    [self.collectionView reloadData];
    
    [self initScrollBar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUpCollectionView{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
    CGFloat kXMNMargin = 1;
    //宽度为其他值行不行？
    CGFloat width = ([UIScreen mainScreen].bounds.size.width ) / 4 - kXMNMargin;
    layout.itemSize = CGSizeMake(width,width);
    layout.minimumInteritemSpacing = 1;
    layout.minimumLineSpacing = 1;
    self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 0,[UIScreen mainScreen].bounds.size.width - 50 , [UIScreen mainScreen].bounds.size.height ) collectionViewLayout:layout];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.alwaysBounceHorizontal = NO;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    //    self.collectionView.contentSize = CGSizeMake(self.view.frame.size.width, )
    [self.view addSubview:self.collectionView];
}

- (void)initScrollBar{
    if(!_scrollBar){
        _scrollBar  = [[ScrollBar alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 50, 64 + 10, 50, self.collectionView.frame.size.height - 64 -50)];
        _scrollBar.backgroundColor = [UIColor redColor];
        _scrollBar.delegate = self;
    }
    [self.view addSubview:_scrollBar];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    return _assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PCAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    [cell initGUI];
    cell.asset = _assets[indexPath.row];
    // Configure the cell
    
    return cell;
}

- (void)scrollBarBegin{
    _oldY = _scrollBar.bar.center.y;
    _oldYOffset = self.collectionView.contentOffset.y;
}

- (void)scrollBarScroll:(CGPoint)point{
    NSLog(@"y:%f",point.y);
    
    _nY = _scrollBar.bar.center.y;
    CGFloat yDistance = _nY - _oldY;
    CGFloat percent = yDistance / (_scrollBar.frame.size.height - _scrollBar.bar.frame.size.height / 2);
    CGFloat yOffset = self.collectionView.contentSize.height * percent;
    CGFloat nYOffset = _oldYOffset + yOffset;
    
    [self.collectionView setContentOffset:CGPointMake(0, nYOffset) animated:YES];
}

@end
