//
//  PCAlbumListViewController.m
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/4.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import "PCAlbumListViewController.h"
#import "PCPhotoPickerHelper.h"
#import "PCAlbumCell.h"
#import "PCAlbumModel.h"
#import "PCAssetModel.h"
#import "PCAssetCell.h"
#import "ScrollBar.h"

const CGFloat scrollBarWidth = 30;

@interface PCAlbumListViewController ()<UITableViewDelegate,UITableViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UICollectionViewDataSource,UIGestureRecognizerDelegate,PCAssetCellDelegate,UIActionSheetDelegate,PHPhotoLibraryChangeObserver,ScrollBarDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray<PCAssetModel *> * assets;

@property (assign, nonatomic) CGPoint originPoint;
@property (assign, nonatomic) CGPoint originLocation;

@property (strong, nonatomic) NSMutableArray *selectedImgViewArr;
@property (strong, nonatomic) UIPanGestureRecognizer *panForCollection;
@property (strong, nonatomic) NSIndexPath *originIndexPath;
@property (strong, nonatomic) UIButton *deleteBtn;
@property (strong, nonatomic) UIButton *selectAllBtn;
@property (strong, nonatomic) UIButton *cancelBtn;
@property (strong, nonatomic) UIView *bottomView;

@property (strong, nonatomic) UIView *bottomViewForTV;//相册的bottomview
@property (strong, nonatomic) UIButton *createNewAlbumBtn;
@property (strong, nonatomic) UIButton *editBtn;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) PCAssetCell *originCell;
@property (assign, nonatomic) CGFloat originCellY;//originCell 的y坐标
@property (assign, nonatomic) BOOL doneSelection;//选择过程结束

@property (strong, nonatomic) NSString *nAlbumTitle;

@property (assign, nonatomic) BOOL tableViewMoveUp;
@property (assign, nonatomic) BOOL collectionViewMoveUp;

@property (strong, nonatomic) ScrollBar *scrollBar;
//@property (assign, nonatomic) CGFloat oldOffsetY;
//@property (assign, nonatomic) CGFloat nOffsetY;
//@property (assign, nonatomic) CGFloat oldBarY;
@end

static const NSString *PCAlbumListCellIdentifier = @"PCAlbumListCellIdentifier";
static NSString * const reuseIdentifier = @"Cell";
const NSInteger numberPerLine = 4; //每行的图片cell的个数
@implementation PCAlbumListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"相册";
    [self setUpTableView];
    [self setUpCollectionView];
    [self setUpBottomView];
    [self setUpBottomVieForTV];
    [self initScrollBar];
    [self setLeftBarButton];
    _selectedAssets = [[NSMutableArray alloc]init];
//    _selectedIndexPathesForAssets = [[NSMutableArray alloc]init];
    _selectedImgViewArr = [[NSMutableArray alloc]init];
    _originLocation = CGPointZero;
}



- (void)setUpTableView{
    if(!_tableView){
        _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width/3, self.view.frame.size.height - 40) ];
        [self.tableView registerClass:[PCAlbumCell class] forCellReuseIdentifier:PCAlbumListCellIdentifier];
        self.tableView.rowHeight = 75.0f;
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        _albums = [[PCPhotoPickerHelper sharedPhotoPickerHelper] getAlbums];
       
        
        [self.tableView reloadData];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//        UITableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
//        [cell setSelected:YES];
        [_tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    [self.view addSubview:_tableView];
}

- (void)setUpCollectionView{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
    CGFloat kXMNMargin = 1;
    //宽度为其他值行不行？
    CGFloat width = ([UIScreen mainScreen].bounds.size.width * 2/ 3 - scrollBarWidth) / 4 - kXMNMargin;
    CGFloat height = 100;
    layout.itemSize = CGSizeMake(width,width);
    layout.minimumInteritemSpacing = 1;
    layout.minimumLineSpacing = 1;
    self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/3, 64,[UIScreen mainScreen].bounds.size.width * 2 / 3 - scrollBarWidth, self.view.frame.size.height - 64 - 40) collectionViewLayout:layout];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.alwaysBounceHorizontal = NO;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    //    self.collectionView.contentSize = CGSizeMake(self.view.frame.size.width, )
    PCAlbumModel *model = _albums[0];
    _assets = [[PCPhotoPickerHelper sharedPhotoPickerHelper] assetsFromAlbum:model.fetchResult].mutableCopy;
     [self.collectionView registerClass:[PCAssetCell class] forCellWithReuseIdentifier:reuseIdentifier];
    [self.view addSubview:self.collectionView];
    [_collectionView reloadData];
    
    _panForCollection = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panForCollection:)];
    _panForCollection.delegate = self;
    [_collectionView addGestureRecognizer:_panForCollection];
    [_collectionView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)setUpBottomView{
    if (!_bottomView) {
        CGFloat height = 40;
        _bottomView = [[UIView alloc]initWithFrame:CGRectMake(self.collectionView.frame.origin.x, [UIScreen mainScreen].bounds.size.height -height , self.collectionView.frame.size.width, height)];
        _bottomView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:_bottomView];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self
                                                                             action:@selector(tapForCollectionView:)];
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        [_bottomView addGestureRecognizer:tap];
        
    }
    
    if (!_deleteBtn) {
        _deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _deleteBtn.frame = CGRectMake(_bottomView.frame.size.width - 50, 5, 40, 30);
        [_deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
        [_deleteBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_deleteBtn addTarget:self action:@selector(delete ) forControlEvents:UIControlEventTouchUpInside];
        [_bottomView addSubview:_deleteBtn];
    }
    
    if (!_selectAllBtn) {
        _selectAllBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _selectAllBtn.frame = CGRectMake(10, 5, 40, 30);
        [_selectAllBtn setTitle:@"全选" forState:UIControlStateNormal];
        [_selectAllBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_selectAllBtn addTarget:self action:@selector(selectAll) forControlEvents:UIControlEventTouchUpInside];
        [_bottomView addSubview:_selectAllBtn];
    }
    
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelBtn.frame = CGRectMake(60, 5, 40, 30);
        [_cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        [_cancelBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_cancelBtn addTarget:self action:@selector(cancelSelection) forControlEvents:UIControlEventTouchUpInside];
        [_bottomView addSubview:_cancelBtn];
    }
}

- (void)setUpBottomVieForTV{
    if (!_bottomViewForTV) {
        
        _bottomViewForTV = [[UIView alloc]initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - _bottomView.frame.size.height , _tableView.frame.size.width, _bottomView.frame.size.height)];
        _bottomViewForTV.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:_bottomViewForTV];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self
                                                                             action:@selector(tapForTableView:)];
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        [_bottomViewForTV addGestureRecognizer:tap];
    }
    
    if (!_createNewAlbumBtn) {
        _createNewAlbumBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _createNewAlbumBtn.frame = CGRectMake(10, 5, 40, 30);
        [_createNewAlbumBtn setTitle:@"+" forState:UIControlStateNormal];
        [_createNewAlbumBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_createNewAlbumBtn addTarget:self action:@selector(createNewAlbum) forControlEvents:UIControlEventTouchUpInside];
        [_bottomViewForTV addSubview:_createNewAlbumBtn];
    }
}


- (void)initScrollBar{
    if(!_scrollBar){
        _scrollBar  = [[ScrollBar alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - scrollBarWidth, 64 , scrollBarWidth, self.collectionView.frame.size.height )];
        _scrollBar.backgroundColor = [UIColor whiteColor];
        _scrollBar.delegate = self;
    }
    [self.view addSubview:_scrollBar];
}

- (void)setLeftBarButton {
   
    UIBarButtonItem *sort = [[UIBarButtonItem alloc]initWithTitle:@"排序" style:UIBarButtonItemStylePlain target:self action:@selector(sortAlbum)];
    self.navigationItem.leftBarButtonItem = sort;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _albums.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PCAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:PCAlbumListCellIdentifier forIndexPath:indexPath];
    
    [cell configWithItem:_albums[indexPath.row]];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPress:)];
    longPress.minimumPressDuration = 1.0;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (_selectedAssets.count > 0) {
        [_selectedAssets removeAllObjects];
//        [_selectedIndexPathesForAssets removeAllObjects];
    }
    PCAlbumModel *model = _albums[indexPath.row];
    _assets = [[PCPhotoPickerHelper sharedPhotoPickerHelper] assetsFromAlbum:model.fetchResult].mutableCopy;
    [_collectionView reloadData];
    
    if (!_editBtn) {
        _editBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _editBtn.frame =  CGRectMake(_bottomViewForTV.frame.size.width - 50, 5, 40, 30);
        _editBtn.tag = indexPath.row;
        [_editBtn setTitle:@"编辑" forState:UIControlStateNormal];
        [_editBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_editBtn addTarget:self action:@selector(editAlbum:) forControlEvents:UIControlEventTouchUpInside];
        [_bottomViewForTV addSubview:_editBtn];
    }
}


- (NSArray <UITableViewRowAction*>*)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewRowAction *delete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault
                                                                    title:@"删除"
                                                                  handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                                                                      NSError *err = nil;
//                                                                      [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
                                                                      [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                                                                          PCAlbumModel *model = _albums[indexPath.row];
                                                                          [PHAssetCollectionChangeRequest deleteAssetCollections:@[model.collection]];
                                                                      } error:&err];
                                                                      if (err) {
                                                                          NSLog(@"err:%@",[err localizedDescription]);
                                                                      }else{
                                                                          _albums = [[PCPhotoPickerHelper sharedPhotoPickerHelper] getAlbums];
                                                                          [_tableView reloadData];
                                                                          
                                                                          NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_albums.count - 1
                                                                                                                      inSection:0];
                                                                          [_tableView selectRowAtIndexPath:indexPath
                                                                                                  animated:NO
                                                                                            scrollPosition:UITableViewScrollPositionNone];
                                                                          PCAlbumModel *model = _albums[_albums.count - 1];
                                                                          _assets = [[PCPhotoPickerHelper sharedPhotoPickerHelper] assetsFromAlbum:model.fetchResult].mutableCopy;
                                                                          [_collectionView reloadData];
                                                                      }
                                                                  }];
    return @[delete];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return _assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *arr = [_selectedAssets lastObject];
    NSLog(@"lastcount:%ld  arrcou:%ld",arr.count,_selectedAssets.count);

    PCAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    [cell initGUI];
    cell.indexPath = indexPath;
    cell.delegate = self;
    cell.asset = _assets[indexPath.row];
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 50, 20, 20)];
    label.text = [NSString stringWithFormat:@"%ld",indexPath.row];
 
//    for (int i = 0; i < _selectedAssets.count; i++) {
//        NSArray *arr = _selectedAssets[i];
//        for (PCAssetCell *tempCell in arr) {
//            NSLog(@"ind:%ld",tempCell.indexPath.row);
//        }
//    }
    return cell;
}




//判断当前cell是否已经被选中
- (BOOL)cellIsSelected:(PCAssetCell *)cell {
    for (NSArray *arr in _selectedAssets) {
        if ([arr containsObject:cell]) {
            return YES;
        }else{
            for (PCAssetCell *temp in arr) {
                
                if (temp.indexPath.row == cell.indexPath.row && temp.indexPath.section == cell.indexPath.section) {
                    return YES;
                }else{
                    return NO;
                }
            }
        }
        
        
        
    }
    return NO;
}

//添加多个cell到_selectedAssets
- (void)addCellInLoopWithIndex:(NSInteger)i{
    NSIndexPath *ind = [NSIndexPath indexPathForRow:i inSection:0];
    PCAssetCell *cell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:ind];
    
    
    if (cell && ![self cellIsSelected:cell]) {
        
        NSMutableArray *arr = [_selectedAssets lastObject];
        
        [arr addObject:cell];
        cell.stateBtnSelected = YES;
        cell.asset.selected = YES;
//        [_selectedIndexPathesForAssets addObject:ind];
    }
}
//添加单个cell到_selectedAssets
- (void)addSingleCellWithCell:(PCAssetCell *)cell{
    if (cell && ![self cellIsSelected:cell]) {
        NSMutableArray *arr = [_selectedAssets lastObject];
        
        [arr addObject:cell];
        cell.stateBtnSelected = YES;
        cell.asset.selected = YES;
        
//        NSIndexPath *index = [_collectionView indexPathForCell:cell];
        
//        [_selectedIndexPathesForAssets addObject:index];
    }
}

//从_selectedAssets删除多个cell
- (void)removeCellsInLoopWithIndex:(NSInteger)i{
    NSIndexPath *ind = [NSIndexPath indexPathForRow:i inSection:0];
    PCAssetCell *cell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:ind];
    if ([self cellIsSelected:cell]) {
        NSMutableArray *arr = [_selectedAssets lastObject];
        [arr removeObject:cell];
        cell.stateBtnSelected = NO;
        cell.asset.selected = NO;
        
       
        if (arr.count <= 0) {
            [_selectedAssets removeObject:arr];
        }
        
    }
}
//从_selectedAssets删除单个cell
- (void)removeSingleCell:(PCAssetCell *)cell{
    if ([self cellIsSelected:cell]) {
        NSMutableArray *arr = [_selectedAssets lastObject];
        [arr removeObject:cell];
        cell.stateBtnSelected = NO;
        cell.asset.selected = NO;
        
        if (arr.count <= 0) {
            [_selectedAssets removeObject:arr];
        }
    }
}

//处理第四象限的情况
- (void)handlerForForthQuadrantWithCurrentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath currentCell:(PCAssetCell *)currentCell preCell:(PCAssetCell *)preCell{
//    NSLog(@"第四象限");
    if (currentIndexPath.row > preIndexPath.row) {
        
        if (currentIndexPath.row - preIndexPath.row == 1) {
            //向右滑动，一次增加一个cell
            [self addSingleCellWithCell:currentCell];
            
        }else if(currentIndexPath.row - preIndexPath.row >= numberPerLine){
            //向下滑
            PCAssetCell *firstCell = [[_selectedAssets lastObject] firstObject];
            NSIndexPath *firstIndexPath = [_collectionView indexPathForCell:firstCell];
            if (currentIndexPath.row - _originIndexPath.row >= numberPerLine) {
                //一直在第四象限
                //向下滑动，一次增加多个cell
                NSLog(@"currentrow:%ld",currentIndexPath.row);
                for (NSInteger i = preIndexPath.row + 1; i <= currentIndexPath.row; i++) {
                    [self addCellInLoopWithIndex:i];
                    
                }
            }else{
                //从第一象限进入第四象限 先把原来的删除（除了第一个cell ）,再加入新的cell
                
                for (NSInteger i = preIndexPath.row; i < _originIndexPath.row; i++) {
                    [self removeCellsInLoopWithIndex:i];
                }
                
                for (NSInteger i = _originIndexPath.row + 1; i <= currentIndexPath.row; i++) {
                    [self addCellInLoopWithIndex:i];
                }
            }
        }
    }else if (currentIndexPath.row < preIndexPath.row){
        //向左滑
        if (preIndexPath.row - currentIndexPath.row == 1) {
            [self removeSingleCell:preCell];
        }else if(preIndexPath.row - currentIndexPath.row >= numberPerLine){
            //向上滑
            for (NSInteger i = currentIndexPath.row+1 ; i <= preIndexPath.row; i++) {
               [self removeCellsInLoopWithIndex:i];
            }
        }
    }
    
}

//第一象限的情况
- (void)handlerForFirstQuadrantWithCurrentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath currentCell:(PCAssetCell *)currentCell preCell:(PCAssetCell *)preCell{
//    NSLog(@"第一象限");
    if (currentIndexPath.row < preIndexPath.row) {
        
        if (preIndexPath.row - currentIndexPath.row == 1) {
            //向左滑动，一次增加一个cell
            [self addSingleCellWithCell:currentCell];
        }else if (preIndexPath.row - currentIndexPath.row >= numberPerLine){
            //向上滑
            PCAssetCell *firstCell = [[_selectedAssets lastObject] firstObject];
            NSIndexPath *firstIndexPath = [_collectionView indexPathForCell:firstCell];
            if (_originIndexPath.row - currentIndexPath.row >= numberPerLine) {
                //一直在第一象限
                //向上滑动，一次增加多个cell 注意添加cell的顺序  从高到低添加
                for ( NSInteger i = preIndexPath.row - 1 ; i >= currentIndexPath.row; i--) {

                    [self addCellInLoopWithIndex:i];
                }
            }else{
                //从第四象限进入第一象限
                for (NSInteger i = _originIndexPath.row + 1; i <= preIndexPath.row; i++) {
                   [self removeCellsInLoopWithIndex:i];
                }
                
                //注意添加cell的顺序  从高到低添加
                for (NSInteger i = _originIndexPath.row - 1; i > currentIndexPath.row; i--) {
                    [self addCellInLoopWithIndex:i];
                }
            }
        }
    }else if (currentIndexPath.row > preIndexPath.row){
        
        if (currentIndexPath.row -preIndexPath.row == 1) {
            //向右滑
           [self removeSingleCell:preCell];
        }else if(currentIndexPath.row -preIndexPath.row >= numberPerLine){
            //向下滑
            for (NSInteger i = preIndexPath.row ; i < currentIndexPath.row; i++) {
                [self removeCellsInLoopWithIndex:i];
            }
        }
    }
}
//第三象限
- (void)handlerForThirdQuadrantWithCurrentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath currentCell:(PCAssetCell *)currentCell preCell:(PCAssetCell *)preCell{
//    NSLog(@"第三象限");
    if (currentIndexPath.row < preIndexPath.row) {
        if (preIndexPath.row -currentIndexPath.row == 1) {
            //向左滑
            [self removeSingleCell:preCell];
        }else if(preIndexPath.row -currentIndexPath.row >= numberPerLine){
            //向上滑
            for (NSInteger i = preIndexPath.row ; i > currentIndexPath.row; i--) {
                [self removeCellsInLoopWithIndex:i];
            }
        }
        
    }else if (currentIndexPath.row > preIndexPath.row){
        
        if (currentIndexPath.row - preIndexPath.row == 1) {
            //向右滑动，一次增加一个cell
            [self addSingleCellWithCell:currentCell];
        }else if (currentIndexPath.row - preIndexPath.row >= numberPerLine){
            //向下滑
            PCAssetCell *firstCell = [[_selectedAssets lastObject] firstObject];
            NSIndexPath *firstIndexPath = [_collectionView indexPathForCell:firstCell];
            if (currentIndexPath.row - _originIndexPath.row >= numberPerLine) {
                //一直在第三象限
                //向下滑动，一次增加多个cell
                for (NSInteger i = preIndexPath.row + 1 ; i < currentIndexPath.row; i++) {
                    [self addCellInLoopWithIndex:i];
                }
            }else{
                //从第二象限进入第三象限
                for (NSInteger i = preIndexPath.row ; i < _originIndexPath.row; i++) {
                    [self removeCellsInLoopWithIndex:i];
                }
                
                for (NSInteger i = _originIndexPath.row + 1; i < currentIndexPath.row; i++) {
                    [self addCellInLoopWithIndex:i];
                }
            }
        }
    }
}

//第二象限
- (void)handlerForSecondQuadrantWithCurrentIndexPath:(NSIndexPath *)currentIndexPath preIndexPath:(NSIndexPath *)preIndexPath currentCell:(PCAssetCell *)currentCell preCell:(PCAssetCell *)preCell{
//    NSLog(@"第二象限");
    if (currentIndexPath.row > preIndexPath.row) {
        
        if (currentIndexPath.row - preIndexPath.row == 1) {
            //向右滑动，一次删除一个cell
           [self removeSingleCell:preCell];
            
        }else if(currentIndexPath.row - preIndexPath.row >= numberPerLine){
            
            //向下滑动，一次增加多个cell
            for (NSInteger i = preIndexPath.row  ; i < currentIndexPath.row; i++) {
               [self removeCellsInLoopWithIndex:i];
            }
        }
        
        
    }else if (currentIndexPath.row < preIndexPath.row){
        
        if (preIndexPath.row - currentIndexPath.row == 1) {
            //向左滑
            [self addSingleCellWithCell:currentCell];
        }else if(preIndexPath.row - currentIndexPath.row >= numberPerLine){
            //向上滑
            
            PCAssetCell *firstCell = [[_selectedAssets lastObject] firstObject];
            NSIndexPath *firstIndexPath = [_collectionView indexPathForCell:firstCell];
            if (_originIndexPath.row - currentIndexPath.row >= numberPerLine) {
                //一直在第二象限
                NSLog(@"here");
                for (NSInteger i = preIndexPath.row - 1 ; i >= currentIndexPath.row; i--) {
                    [self addCellInLoopWithIndex:i];
                }
            }else{
                //从第三象限进入第二象限
                NSLog(@"fuck");
                for (NSInteger i = firstIndexPath.row + 1; i <= preIndexPath.row; i++) {
                    [self removeCellsInLoopWithIndex:i];
                }
                
                for (NSInteger i = firstIndexPath.row - 1; i > currentIndexPath.row; i--) {
                    [self addCellInLoopWithIndex:i];
                }
            }
        }
    }
}

//选择结束后，开始拖动
- (void)handlerWhenSelectionDoneWithPanInTheBeginState:(UIGestureRecognizer *)pan{
    _originPoint = [pan locationInView:self.view];
    
    if (_selectedImgViewArr.count > 0) {
        [_selectedImgViewArr removeAllObjects];
    }
    
    if (_selectedAssets.count > 0) {
        for (NSArray *cellsArr in _selectedAssets) {
            for (PCAssetCell *cell in cellsArr) {
                cell.alpha = 0.2;
                CGPoint cellCenter = CGPointMake(cell.frame.origin.x, cell.frame.origin.y);
                UIImageView *imgV = [[UIImageView alloc]initWithFrame:CGRectMake(cellCenter.x + _collectionView.frame.origin.x + 5, cellCenter.y + _collectionView.frame.origin.y - 5 , cell.frame.size.width, cell.frame.size.height)];
                imgV.image = cell.photoView.image;
                imgV.hidden = NO;
                [_selectedImgViewArr addObject:imgV];
                [self.view addSubview:imgV];
            }
        }
    }
}
//选择结束后，开始拖动，pan手势的change阶段
- (void)handlerWhenSelctionDoneWithPanInTheChangeState:(UIGestureRecognizer *)pan{
    CGPoint point = [pan locationInView:self.view];
    
    for (int i = 0; i< _selectedImgViewArr.count; i++) {
        UIImageView *imgV = _selectedImgViewArr[i];
        imgV.center = CGPointMake(point.x + i*2, point.y + i*2);
    }
    
    
    if (point.x < _collectionView.frame.origin.x) {
        //进入到左边相册区域
        point = [pan locationInView:_tableView];
        NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:point];
        PCAlbumCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
        NSArray *cells = [_tableView visibleCells];
        for (UITableViewCell *item in cells) {
            if (item != cell) {
                [item setSelected:NO];
            }
        }
        [cell setSelected:YES];
        
        CGPoint point = [pan locationInView:self.view];
        
        if (point.y > _collectionView.frame.origin.y + _collectionView.frame.size.height  ){
            _tableViewMoveUp = NO;
            [self tableViewStartScroll];
        }else if (point.y < 64){
            
            _tableViewMoveUp = YES;
            [self tableViewStartScroll];
        } else{
            if (_timer) {
                [_timer invalidate];
            }
        }

    }else{
        if (_timer) {
            [_timer invalidate];
        }
    }
    
}

//选择结束，开始拖动，pan手势结束的情况
- (void)handlerWhenSelectionDoneWithPanInTheEndState:(UIPanGestureRecognizer *)pan{
    CGPoint point = [pan locationInView:self.view];
    if (point.x < _collectionView.frame.origin.x) {
        
        point = [pan locationInView:_tableView];
        NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:point];
        PCAlbumModel *model = _albums[indexPath.row];
        
        
        //                for (NSArray *cellsArr in _selectedAssets) {
        for (int i = 0; i < _selectedAssets.count; i++) {
            NSArray *cellsArr = _selectedAssets[i];
            for (int j = 0; j < cellsArr.count; j++) {
                PCAssetCell *cell = cellsArr[j];
                PHAsset * asset = cell.asset.asset;
                
                
                NSError *err = nil;
                [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                    PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:model.collection];
                    [request insertAssets:@[asset] atIndexes:[NSIndexSet indexSetWithIndex:0]];
                } error:&err];
                
                if (!err) {
                    NSLog(@"success savedd");
                    //                    _selectedImgV.hidden = YES;
                    
                }else{
                    NSLog(@"save fail");
                }
            }
        }
        
        for (UIImageView *imgV in _selectedImgViewArr) {
            imgV.hidden = YES;
        }
        
        
        [_selectedImgViewArr removeAllObjects];
        _albums = [[PCPhotoPickerHelper sharedPhotoPickerHelper] getAlbums];
        
        [self.tableView reloadData];
        [_tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        model = _albums[indexPath.row];
        _assets = [[PCPhotoPickerHelper sharedPhotoPickerHelper] assetsFromAlbum:model.fetchResult];
        [_collectionView reloadData];
        
        [_selectedAssets removeAllObjects];
    }else{
        for (int i = 0; i < _selectedAssets.count; i++) {
            NSArray *cellsArr = _selectedAssets[i];
            for (int j = 0; j < cellsArr.count; j++) {
                PCAssetCell *cell = cellsArr[j];
                cell.alpha = 1.0;
            }
        }
        for (UIImageView *imgV in _selectedImgViewArr) {
            imgV.hidden = YES;
        }
        
        [_selectedImgViewArr removeAllObjects];
        
        
    }
}


- (void)panForCollection:(UIPanGestureRecognizer *)pan{
    
    
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        CGFloat kXMNMargin = 1;
        CGFloat itemCellWidth = ([UIScreen mainScreen].bounds.size.width/2 ) / numberPerLine - kXMNMargin;
        CGFloat itemCellHeight = 100;
        CGPoint currentLocation = [pan locationInView:self.collectionView];
//        NSLog(@"begin x:%f, y:%f",currentLocation.x,currentLocation.y);
        NSIndexPath *currentIndexPath = [_collectionView indexPathForItemAtPoint:currentLocation];
//        NSLog(@"row:%ld",currentIndexPath.row);
        if ((currentLocation.x > itemCellWidth || currentLocation.y > itemCellHeight ) &&  currentIndexPath.row == 0) {
            //如果滑动的位置位于item cell的中间地带，则indexpath.row会返回0，但是此时未必选中row为0的item，所以要做个判断，
//            NSLog(@"here shit");
            return;
        }
        
        _originLocation = [pan locationInView:self.collectionView];
        _originIndexPath = [_collectionView indexPathForItemAtPoint:_originLocation];
        _originCell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:_originIndexPath];
        _originCellY = _originCell.frame.origin.y;
        if (_originCell ) {
            if (![self cellIsSelected:_originCell]) {
                _doneSelection = NO;
                NSMutableArray *currentSelectedArr = [[NSMutableArray alloc]init];
                [currentSelectedArr addObject:_originCell];
                [_selectedAssets addObject:currentSelectedArr];
                _originCell.stateBtnSelected = YES;
                _originCell.asset.selected = YES;
                
//                [_selectedIndexPathesForAssets addObject:_originIndexPath];
            }else{
                //选择过程结束，开始拖动复制
                _doneSelection = YES;
                [self handlerWhenSelectionDoneWithPanInTheBeginState:pan];
            }
            
        }
    }else if (pan.state == UIGestureRecognizerStateChanged) {
        if (!_doneSelection) {
            if (_originCell) {
                
                
                CGFloat kXMNMargin = 1;
                CGFloat itemCellWidth = ([UIScreen mainScreen].bounds.size.width/2 ) / numberPerLine - kXMNMargin;
                CGFloat itemCellHeight = 100;
                CGPoint currentLocation = [pan locationInView:self.collectionView];
                NSIndexPath *currentIndexPath = [_collectionView indexPathForItemAtPoint:currentLocation];
                
//                NSLog(@"change x:%f, y:%f  orignx:%f  origny:%f",currentLocation.x,currentLocation.y,_originCell.frame.origin.x,_originCell.frame.origin.y);
                if ((currentLocation.x > itemCellWidth || currentLocation.y > itemCellHeight ) &&  currentIndexPath.row == 0) {
                    //如果滑动的位置位于item cell的中间地带，则indexpath.row会返回0，但是此时未必选中row为0的item，所以要做个判断，
                    //            NSLog(@"row:%ld",currentIndexPath.row);
                    return;
                }
                
                
                PCAssetCell *currentCell = [_collectionView cellForItemAtIndexPath:currentIndexPath];
                
                PCAssetCell *preCell  = [[_selectedAssets lastObject] lastObject];
                NSIndexPath *preIndexPath = [_collectionView indexPathForCell:preCell];
                
                //先按起始点的x坐标分为左右两边 右边的处于第一象限 和第四象限 左边的处于第二象限和第三象限
                if (currentLocation.x >= _originLocation.x ) {
                    //                NSLog(@"right");
                    //如果y坐标大于起始cell的y坐标，处于第四象限,否则，处于第一象限（注意不是起始y坐标，因为起始的y坐标是大于起始cell的y坐标的，即使比起始y坐标小也有可能处于第四象限， ）
                    if (currentLocation.y >= _originCellY) {
                        //                    NSLog(@"forth");
                        [self handlerForForthQuadrantWithCurrentIndexPath:currentIndexPath
                                                             preIndexPath:preIndexPath
                                                              currentCell:currentCell
                                                                  preCell:preCell];
                        
                    }else{
                        [self handlerForFirstQuadrantWithCurrentIndexPath:currentIndexPath
                                                             preIndexPath:preIndexPath
                                                              currentCell:currentCell
                                                                  preCell:preCell];
                    }
                }else if (currentLocation.x < _originLocation.x  ){
                    //如果y坐标大于起始cell的y+cell的高度，则位于第三象限，否则，位于第二象限
                    if (currentLocation.y >= _originCellY + _originCell.frame.size.height) {
                        [self handlerForThirdQuadrantWithCurrentIndexPath:currentIndexPath
                                                             preIndexPath:preIndexPath
                                                              currentCell:currentCell
                                                                  preCell:preCell];
                    }else{
                        [self handlerForSecondQuadrantWithCurrentIndexPath:currentIndexPath
                                                              preIndexPath:preIndexPath
                                                               currentCell:currentCell
                                                                   preCell:preCell];
                        
                    }
                }
                //pan手势滑到底部时，collectionview开始自动滚动
                [self handlerForAutoScroll:pan];
            }
        }else{
            //选择过程结束  开始拖动复制
            [self handlerWhenSelctionDoneWithPanInTheChangeState:pan];
        }
        
        
    }else if (pan.state == UIGestureRecognizerStateEnded){
        if (!_doneSelection) {
//            NSLog(@"selected assets:%@",_selectedAssets);
            if (_timer) {
                [_timer invalidate];
            }
        }else{
            
            [self handlerWhenSelectionDoneWithPanInTheEndState:pan];
        }
        
    }
}

//pan手势滑到底部时，collectionview开始自动滚动
- (void)handlerForAutoScroll:(UIPanGestureRecognizer *)pan{

    CGPoint  currentLocation = [pan locationInView:self.view];
    if (currentLocation.y > _bottomView.frame.origin.y  ) {
        if (currentLocation.x > _collectionView.frame.origin.x) {
            _collectionViewMoveUp = NO;
            [self collectionViewStartScroll];
        }
        
    }else if(currentLocation.y < 64){
        _collectionViewMoveUp = YES;
//        NSLog(@"move up");
        [self collectionViewStartScroll];
    }
    
    else{
        if (_timer) {
            [_timer invalidate];
        }
    }
}

- (void)collectionViewStartScroll{
    if (!_timer || !_timer.isValid) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                repeats:YES
                                                  block:^(NSTimer * _Nonnull timer) {
                                                      CGFloat yOffset = _collectionView.contentOffset.y;
                                                      
                                                      if (_collectionViewMoveUp ) {
                                                          yOffset -= 4;
                                                          if (_collectionView.contentOffset.y > 0) {
                                                              [_collectionView setContentOffset:CGPointMake(_collectionView.contentOffset.x, yOffset)];
                                                          }else{
                                                              //滚动到最顶部的时候，顶部的几个cell没有被自动选中，在此选中
                                                              for (int i = 3; i > -1 ; i--) {
                                                                  [self addCellInLoopWithIndex:i];
                                                              }
                                                          }
                                                      }else{
                                                          yOffset += 4;
                                                          if (_collectionView.contentOffset.y + _collectionView.frame.size.height < _collectionView.contentSize.height) {
                                                              [_collectionView setContentOffset:CGPointMake(_collectionView.contentOffset.x, yOffset)];
                                                          }
                                                          
                                                      }
                                                      
                                                  }];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
}

- (void)tableViewStartScroll{
    if (!_timer || !_timer.isValid) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                 repeats:YES
                                                   block:^(NSTimer * _Nonnull timer) {
                                                       CGFloat yOffset = _tableView.contentOffset.y;
                                                       if (_tableViewMoveUp) {
                                                           yOffset -= 5;
                                                           if (_tableView.contentOffset.y > -64) {
                                                               [_tableView setContentOffset:CGPointMake(_tableView.contentOffset.x, yOffset)];
                                                           }
                                                       }else{
                                                           yOffset += 5;
                                                           if (_tableView.contentOffset.y + _tableView.frame.size.height < _tableView.contentSize.height) {
                                                               [_tableView setContentOffset:CGPointMake(_tableView.contentOffset.x, yOffset)];
                                                           }
                                                       }
                                                       
                                                       
                                                   }];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    if (gestureRecognizer == _panForCollection) {
        CGPoint point = [_panForCollection translationInView:self.collectionView];
        if (point.y == 0 || fabs(point.x / point.y) > 5.0) {
            //左右方向
//            NSLog(@"左右");
            return YES;
        }
        
        if (point.x == 0 || fabs(point.y / point.x) > 5.0) {
            //上下方向
//            NSLog(@"上下");
            CGPoint currentLocation = [_panForCollection locationInView:self.collectionView];
            
            NSIndexPath *currentIndexPath = [_collectionView indexPathForItemAtPoint:currentLocation];
            PCAssetCell * cell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:currentIndexPath];
            if (cell && [self cellIsSelected:cell]) {
                _doneSelection = YES;
                return YES;
            }else{
                return NO;
            }
        }
    }
    return YES;
}


- (void)delete{
    if (_selectedAssets.count > 0) {
        UIActionSheet *sheet = [[UIActionSheet alloc]initWithTitle:nil
                                                          delegate:self
                                                 cancelButtonTitle:@"取消"
                                            destructiveButtonTitle:@"从相簿删除"
                                                 otherButtonTitles:@"删除", nil];
        [sheet showInView:self.view];
        
    }else{
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil
                                                message:@"请选择图片"
                                                delegate:self
                                                cancelButtonTitle:@"取消"
                                             otherButtonTitles:@"确定", nil];
        [alert show];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == 0) {
        //从相簿删除
        NSMutableArray *assets = [[NSMutableArray alloc]init];
        NSMutableArray *indexPaths = [[NSMutableArray alloc]init];
        for (int i = 0; i < _selectedAssets.count; i++) {
            NSArray *arr = _selectedAssets[i];
            for (int j = 0; j < arr.count; j++) {
                PCAssetCell *cell = arr[j];
                PHAsset *asset = cell.asset.asset;
                [assets addObject:asset];
                NSIndexPath *indexPath = [_collectionView indexPathForCell:cell];
                [indexPaths addObject:indexPath];
            }
        }
        
        NSError *err = nil;
        NSInteger index = [_tableView indexPathForSelectedRow].row;
        
        PCAlbumModel *model = _albums[index];
        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
            
            PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:model.collection];
            [request removeAssets:assets];
//            [PHAssetChangeRequest deleteAssets:assets];
        
        } error:&err];
        
        
        if (err) {
            NSLog(@"err:%@",[err localizedDescription]);
        }else{
            NSLog(@"delete success");
            
            NSInteger index = [_tableView indexPathForSelectedRow].row;
            _albums = [[PCPhotoPickerHelper sharedPhotoPickerHelper] getAlbums];
            PCAlbumModel *model = _albums[index];
            
            _assets = [[PCPhotoPickerHelper sharedPhotoPickerHelper] assetsFromAlbum:model.fetchResult].mutableCopy;
            
            [_collectionView deleteItemsAtIndexPaths:indexPaths];
            [_collectionView reloadData];
            [_tableView reloadData];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [_tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            [_selectedAssets removeAllObjects];
        }
        
    }else if (buttonIndex == 1){
        //整体删除
        
        
    }
}

- (void)selectAll{
    
        
        if (_selectedAssets.count > 0) {
            [_selectedAssets removeAllObjects];
        }
        NSMutableArray *arr = [[NSMutableArray alloc]init];
        if (_assets.count < 500) {
            for (int i = 0 ; i < _assets.count; i++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
                PCAssetCell *cell = [_collectionView cellForItemAtIndexPath:indexPath];
                cell.stateBtnSelected = YES;
                cell.asset.selected = YES;
                [arr addObject:cell];
            }
            [_selectedAssets addObject:arr];
            _doneSelection = YES;
        }else{
            NSLog(@"超过500张");
        }

}

- (void)cancelSelection{
    _doneSelection = NO;
    if (_selectedAssets.count > 0) {
        [_selectedAssets removeAllObjects];

    
        for (int i = 0 ; i < _assets.count; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            PCAssetCell *cell = [_collectionView cellForItemAtIndexPath:indexPath];
            cell.stateBtnSelected = NO;
            cell.asset.selected = NO;
        }
    }
    
}


- (void)createNewAlbum{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil
                                                   message:@"请输入相册名称"
                                                  delegate:self
                                         cancelButtonTitle:@"取消"
                                         otherButtonTitles:@"确定", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

- (void)editAlbum:(UIButton *)btn{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil
                                                   message:@"请输入相册名称"
                                                  delegate:self
                                         cancelButtonTitle:@"取消"
                                         otherButtonTitles:@"修改", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    NSIndexPath *indexPath = [_tableView indexPathForSelectedRow];
    PCAlbumCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
    alert.tag = indexPath.row;
    UITextField *tf = [alert textFieldAtIndex:0];
    tf.text =[cell.titleLabel.text componentsSeparatedByString:@"   "][0];
    [alert show];

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:@"确定"]) {
        _nAlbumTitle = [alertView textFieldAtIndex:0].text;
        if (_nAlbumTitle.length > 0) {
            if([[PCPhotoPickerHelper sharedPhotoPickerHelper] createNewAlbumWithTitle:_nAlbumTitle]){
                _albums = [[PCPhotoPickerHelper sharedPhotoPickerHelper] getAlbums];
                [self.tableView reloadData];
            }
        }
    }else if ([title isEqualToString:@"修改"]){
        NSString *anotherTitle = [alertView textFieldAtIndex:0].text;
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        PCAlbumModel *model = _albums[alertView.tag];
        [[PCPhotoPickerHelper sharedPhotoPickerHelper] modifyCollection:model.collection WithTitle:anotherTitle];
    }
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance{
    _albums = [[PCPhotoPickerHelper sharedPhotoPickerHelper] getAlbums];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
    
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)pccassetCellDidSelected:(PCAssetCell *)assetCell{
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    [arr addObject:assetCell];
    [_selectedAssets addObject:arr];
    assetCell.stateBtnSelected = YES;
    assetCell.asset.selected = YES;
    
//    NSIndexPath *index = [_collectionView indexPathForCell:assetCell];
//    [_selectedIndexPathesForAssets addObject:index];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(pan:)];
//    [assetCell.contentView addGestureRecognizer:pan];
}

- (void)pccassetCellDidDeselected:(PCAssetCell *)assetCell{
    for (int i = 0; i < _selectedAssets.count; i++) {
        NSMutableArray *arr = _selectedAssets[i];
        
        if ([arr containsObject:assetCell]) {
            assetCell.asset.selected = NO;
            assetCell.stateBtnSelected = NO;
            [arr removeObject:assetCell];
        }else{
            for (PCAssetCell *temp in arr) {
                
                if (temp.indexPath.row == assetCell.indexPath.row && temp.indexPath.section == assetCell.indexPath.section) {
                    assetCell.asset.selected = NO;
                    assetCell.stateBtnSelected = NO;
                    [arr removeObject:assetCell];
                }
            } 
        }
        
        
        
        if (arr.count <= 0) {
            [_selectedAssets removeObject:arr];
        }
    }
}

- (void)sortAlbum{
//    if ([_albumSortedWay isEqualToString:@"asc"]) {
//        _albumSortedWay = @"desc";
//        
//    }else{
//        _albumSortedWay = @"asc";
//    }
    _albums = [[_albums reverseObjectEnumerator] allObjects];
    [self.tableView reloadData];
}


- (void)tapForTableView:(UITapGestureRecognizer *)tap{
    if (_tableView.contentOffset.y + _tableView.frame.size.height < _tableView.contentSize.height) {
        [_tableView setContentOffset:CGPointMake(_tableView.contentOffset.x, _tableView.contentSize.height - _tableView.frame.size.height) animated:YES];
    }
}

- (void)tapForCollectionView:(UITapGestureRecognizer *)tap{
    if (_collectionView.contentOffset.y + _collectionView.frame.size.height < _collectionView.contentSize.height) {
        [_collectionView setContentOffset:CGPointMake(_collectionView.contentOffset.x, _collectionView.contentSize.height - _collectionView.frame.size.height) animated:YES];
        
        _scrollBar.bar.center = CGPointMake(_scrollBar.bar.center.x,  (_scrollBar.frame.origin.y + _scrollBar.frame.size.height) - _scrollBar.bar.frame.size.height/2 );
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"contentSize"] && !([_collectionView isDragging] || [_collectionView isTracking]) && !_scrollBar.scrolling ) {
        _scrollBar.targetView = _collectionView;
    }
}



- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGFloat percent = scrollView.contentOffset.y / scrollView.contentSize.height;
    CGFloat yDistanceForBar = (_scrollBar.frame.size.height - _scrollBar.bar.frame.size.height) * percent + _scrollBar.bar.frame.size.height/2;
    _scrollBar.bar.center = CGPointMake(_scrollBar.bar.center.x,  yDistanceForBar);
}

@end
