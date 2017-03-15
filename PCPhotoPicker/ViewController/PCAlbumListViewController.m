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
#import "PCCollectionReusableHeaderView.h"
#import "Tool.h"


@interface PCAlbumListViewController ()<UITableViewDelegate,UITableViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UICollectionViewDataSource,UIGestureRecognizerDelegate,PCAssetCellDelegate,UIActionSheetDelegate,PHPhotoLibraryChangeObserver,ScrollBarDelegate,PCCollectionReusableHeaderViewDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray * assets;

@property (assign, nonatomic) CGPoint originLocation;

@property (strong, nonatomic) NSMutableArray *selectedImgViewArr;
@property (strong, nonatomic) UIPanGestureRecognizer *panForCollection;
//@property (strong, nonatomic) NSIndexPath *originIndexPath;
@property (strong, nonatomic) UIButton *deleteBtn;
@property (strong, nonatomic) UIButton *selectAllBtn;
@property (strong, nonatomic) UIButton *cancelBtn;
@property (strong, nonatomic) UIView *bottomView;

@property (strong, nonatomic) UIView *bottomViewForTV;//相册的bottomview
@property (strong, nonatomic) UIButton *createNewAlbumBtn;
@property (strong, nonatomic) UIButton *editBtn;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) PCAssetCell *originCell;
//@property (assign, nonatomic) CGFloat originCellY;//originCell 的y坐标
@property (assign, nonatomic) BOOL doneSelection;//选择过程结束

@property (strong, nonatomic) NSString *nAlbumTitle;

@property (assign, nonatomic) BOOL tableViewMoveUp;
@property (assign, nonatomic) BOOL collectionViewMoveUp;

@property (strong, nonatomic) ScrollBar *scrollBar;
@property (assign, nonatomic) CGFloat realItemInterSpace;//两个item之间真实的距离
@property (assign, nonatomic) BOOL rolling;
@property (assign, nonatomic) BOOL open;//collectionview的状态，展开
@property (strong, nonatomic) NSMutableArray *stateForSectionArr;//每个section的状态的数组
@property (strong, nonatomic) NSMutableArray *selectedAllForSectionArr;
@property (strong, nonatomic) UIButton *sortBtn;
@property (assign, nonatomic) BOOL tableDescending;//
@end

static  NSString *PCAlbumListCellIdentifier = @"PCAlbumListCellIdentifier";
static NSString * const reuseIdentifier = @"Cell";
NSString *headerIdentifier = @"collectionHeader";
const NSInteger numberPerLine = 4; //每行的图片cell的个数
const CGFloat scrollBarWidth = 30;
const CGFloat collectionHeaderHeight = 30;
const CGFloat minLineSpacing = 1;
const CGFloat minInterItemSpacing = 1; //item之间的距离

#define  kXMNMargin  1
#define  cellWidth  ([UIScreen mainScreen].bounds.size.width/2 ) / numberPerLine - kXMNMargin

@implementation PCAlbumListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"相册";
    _tableDescending = YES;
    _open = YES;
    _stateForSectionArr = [[NSMutableArray alloc]init];
    _selectedAllForSectionArr = [[NSMutableArray alloc]init];
    [self setUpRightNavBtn];
    [self setUpTableView];
    [self setUpCollectionView];
    [self setUpBottomView];
    [self setUpBottomVieForTV];
    [self initScrollBar];
    [self setLeftBarButton];
    _selectedIndexPathesForAssets = [[NSMutableArray alloc]init];
    _selectedImgViewArr = [[NSMutableArray alloc]init];
    _originLocation = CGPointZero;
}

#pragma ui
- (void)setUpRightNavBtn{
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(0, 0, 40, 20);
    [closeBtn setTitle:@"收缩" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *closeItem = [[UIBarButtonItem alloc]initWithCustomView:closeBtn];
    
    UIButton *openBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    openBtn.frame = CGRectMake(0, 0, 40, 20);
    [openBtn setTitle:@"展开" forState:UIControlStateNormal];
    [openBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [openBtn addTarget:self action:@selector(open:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *openItem = [[UIBarButtonItem alloc]initWithCustomView:openBtn];
    
    self.navigationItem.rightBarButtonItems = @[closeItem,openItem];
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
        [_tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    [self.view addSubview:_tableView];
}

- (void)setUpCollectionView{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
    //宽度为其他值行不行？
    CGFloat width = ([UIScreen mainScreen].bounds.size.width * 2/ 3 - scrollBarWidth) / 4 - kXMNMargin;
    
    layout.itemSize = CGSizeMake(cellWidth,cellWidth);
    layout.minimumInteritemSpacing = minInterItemSpacing;
    layout.minimumLineSpacing = minLineSpacing;
    layout.headerReferenceSize = CGSizeMake(width, collectionHeaderHeight);
    self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/3, 64,[UIScreen mainScreen].bounds.size.width * 2 / 3 - scrollBarWidth, self.view.frame.size.height - 64 - 40) collectionViewLayout:layout];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.alwaysBounceHorizontal = NO;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    //    self.collectionView.contentSize = CGSizeMake(self.view.frame.size.width, )
    PCAlbumModel *model = _albums[0];
    _assets = [[PCPhotoPickerHelper sharedPhotoPickerHelper] assetsFromAlbum:model.fetchResult].mutableCopy;
    
    for (NSInteger i = 0 ; i < _assets.count; i++) {
        NSString *n = @"1";
        _stateForSectionArr[i] = n;
        _selectedAllForSectionArr[i] = @"0";
    }
    
     [self.collectionView registerClass:[PCAssetCell class] forCellWithReuseIdentifier:reuseIdentifier];
    [self.collectionView registerClass:[PCCollectionReusableHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerIdentifier];
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
    _sortBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _sortBtn.frame = CGRectMake(0, 0, 30, 20);
    [_sortBtn setBackgroundImage:[UIImage imageNamed:@"down_arrow"] forState:UIControlStateNormal];
    [_sortBtn addTarget:self action:@selector(sortAlbum) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *openItem = [[UIBarButtonItem alloc]initWithCustomView:_sortBtn];
    self.navigationItem.leftBarButtonItem = openItem;
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
    
//    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPress:)];
//    longPress.minimumPressDuration = 1.0;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (_selectedIndexPathesForAssets.count > 0) {
        
        [_selectedIndexPathesForAssets removeAllObjects];
    }
    [_collectionView setContentOffset:CGPointMake(0, 0)];
    
    for (NSInteger i = 0 ; i < _assets.count; i++) {
        NSString *n = @"1";
        _stateForSectionArr[i] = n;
        _selectedAllForSectionArr[i] = @"0";
    }
    
    _doneSelection = NO;
    PCAlbumModel *model = _albums[indexPath.row];
    _assets = [[PCPhotoPickerHelper sharedPhotoPickerHelper] assetsFromAlbum:model.fetchResult].mutableCopy;
    [_collectionView reloadData];
    
    if (!_editBtn) {
        _editBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _editBtn.frame =  CGRectMake(_bottomViewForTV.frame.size.width - 50, 5, 25, 25);
        _editBtn.tag = indexPath.row;
        [_editBtn setBackgroundImage:[UIImage imageNamed:@"edit"] forState:UIControlStateNormal];

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
    return _assets.count;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSDictionary *dict = _assets[section];
    NSArray *arr = dict[@"assets"];
    if (_open) {
        
        return arr.count;
    }else{
        NSString *state = _stateForSectionArr[section];
        if ([state isEqualToString:@"1"]) {
            return arr.count;
        }else{
            return 0;
        }
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    PCAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    [cell initGUI];
    cell.indexPath = indexPath;
    cell.delegate = self;
    
    if (indexPath.row == 1) {
        NSIndexPath *preIndexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section];
        PCAssetCell *preCell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:preIndexPath];
        if (preCell) {
            _realItemInterSpace = cell.frame.origin.x - (preCell.frame.origin.x + preCell.frame.size.width);
        }
    }
    
    NSDictionary *dict = _assets[indexPath.section];
    NSArray *arr = dict[@"assets"];
    cell.asset = arr[indexPath.row];
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 20, 40, 20)];
    label.text = [NSString stringWithFormat:@"%ld   %ld",indexPath.section,indexPath.row];
    label.font = [UIFont systemFontOfSize:10];
    [cell.contentView addSubview:label];
    
    for (int i = 0; i < _selectedIndexPathesForAssets.count; i++) {
        NSMutableArray *arr = _selectedIndexPathesForAssets[i];
        for (NSIndexPath *ind  in arr) {
            if (ind.row == indexPath.row && ind.section == indexPath.section) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.stateBtnSelected = YES;
                });
                
            }
        }
    }

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    if (kind == UICollectionElementKindSectionHeader) {
        PCCollectionReusableHeaderView *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                              withReuseIdentifier:headerIdentifier
                                                                                     forIndexPath:indexPath];
        NSDictionary *dict = _assets[indexPath.section];
        NSString *date = dict[@"date"];
        header.contentLabel.text = date;
        header.state = _stateForSectionArr[indexPath.section];
        header.selectedAll = _selectedAllForSectionArr[indexPath.section];
        header.delegate = self;
        header.tag = indexPath.section;
        return header;
    }else{
        return nil;
    }
}





//处理第四象限的情况

- (void)handlerForForthQuadrantWithCurrentLocation:(CGPoint)currentLocation{
    NSIndexPath *currentIndexPath = [_collectionView indexPathForItemAtPoint:currentLocation];
    NSMutableArray *arr = [_selectedIndexPathesForAssets lastObject];
    NSIndexPath *preIndexPath = (NSIndexPath *)arr.lastObject;
    NSInteger preRow = preIndexPath.row;
    PCAssetCell *preCell = (PCAssetCell *) [_collectionView cellForItemAtIndexPath:preIndexPath];
     CGFloat itemCellWidth = preCell.frame.size.width;
    if (!currentIndexPath) {
        //滑到空白地带
        if (   currentLocation.y >= preCell.frame.origin.y && currentLocation.y < preCell.frame.origin.y + preCell.frame.size.height) {
            //跟前一个cell在同一行，滑动到item之间的空白地带
            if (currentLocation.x > preCell.frame.origin.x + itemCellWidth) {
                currentIndexPath = [NSIndexPath indexPathForRow:preIndexPath.row inSection:preIndexPath.section];
            }else if(currentLocation.x < preCell.frame.origin.x ){
                NSInteger row = preIndexPath.row - 1 >= 0 ? preIndexPath.row - 1 : 0;
                currentIndexPath = [NSIndexPath indexPathForRow:row inSection:preIndexPath.section];
            }
        }else if(currentLocation.y >= preCell.frame.origin.y + preCell.frame.size.height  && currentLocation.y < preCell.frame.origin.y + preCell.frame.size.height + minLineSpacing){
            //滑到下部 在每行的中间的空白地带  ，
            currentIndexPath = [NSIndexPath indexPathForRow:preIndexPath.row inSection:preIndexPath.section];
        }else if (currentLocation.y >= preCell.frame.origin.y + preCell.frame.size.height + minLineSpacing && currentLocation.y < preCell.frame.origin.y + preCell.frame.size.height + minLineSpacing + collectionHeaderHeight){
            //滑到下一行，这分为几种情况
            //1:滑到下面的headerview了，上一个section已经结束
            //2:滑到最后一行，该section没有结束，此时，lastcell是存在的
            //3:没到最后一行，lastcell已经生成的情况
            //4:没到最后一行，lastcell还没生成的情况
            
            NSDictionary *dict = _assets[preIndexPath.section ];
            NSArray *preSectionArr = dict[@"assets"];
            NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:preSectionArr.count-1 inSection:preIndexPath.section];
            PCAssetCell *lastCell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:lastIndexPath];
            if (lastCell  && preCell.indexPath.row <= lastIndexPath.row  && currentLocation.y > lastCell.frame.origin.y + lastCell.frame.size.height ) {
                
                //判断该section是展开还是收起，收起的话要特别处理
                NSInteger preSection = preIndexPath.section;
                if([_stateForSectionArr[preSection + 1] isEqualToString:@"1"]){
                    //展开
                    //1:进入到headerview
                    currentIndexPath = [NSIndexPath indexPathForRow:lastIndexPath.row inSection:lastIndexPath.section];
                }
            }else if (lastCell && currentLocation.y >= lastCell.frame.origin.y && currentLocation.y <= lastCell.frame.origin.y + lastCell.frame.size.height){
                //2:滑到最后一行，该section没有结束，此时，lastcell是存在的
                CGFloat  low = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace)) ;
                CGFloat row = (preIndexPath.row /numberPerLine ) + 1;
                NSInteger currentRow = row * numberPerLine + low;
                if (currentRow > lastIndexPath.row) {
                    currentRow = lastIndexPath.row;
                }
                currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:lastIndexPath.section];
            }else if (lastCell && currentLocation.y < lastCell.frame.origin.y){
                //3:没到最后一行，lastcell已经生成的情况
                CGFloat  low = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace)) ;
                CGFloat row = (preIndexPath.row /numberPerLine ) + 1;
                NSInteger currentRow = row * numberPerLine + low ;
                currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:lastIndexPath.section];
            }else if (!lastCell && preIndexPath.row < preSectionArr.count - 1){
                //4:没到最后一行，lastcell还没生成的情况
                CGFloat  low = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace)) ;
                CGFloat row = (preIndexPath.row /numberPerLine ) + 1;
                NSInteger currentRow = row * numberPerLine + low ;
                currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section];
            }
        }else if(currentLocation.y >= preCell.frame.origin.y + preCell.frame.size.height + minLineSpacing + collectionHeaderHeight && currentLocation.y <= preCell.frame.origin.y + preCell.frame.size.height + minLineSpacing + collectionHeaderHeight + itemCellWidth){
            //通过headerview进入下一个section
            //1:进入该section的右边
            //2:进入该section的item的中间空白地带
            
            NSDictionary *dict = _assets[preIndexPath.section ];
            NSArray *preSectionArr = dict[@"assets"];
            NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:preSectionArr.count-1 inSection:preIndexPath.section];
            PCAssetCell *lastCell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:lastIndexPath];
            if ( currentLocation.y >= lastCell.frame.origin.y + lastCell.frame.size.height) {
                //超过上个section的最后一个cell，才是进入下一个section
                
                NSIndexPath *firstIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section + 1];
                PCAssetCell *firstCell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:firstIndexPath];
                
                CGFloat firstCellX = firstCell.frame.origin.x;
                NSInteger currentRow = floor( (currentLocation.x - firstCellX) / (itemCellWidth + _realItemInterSpace));
                
                if (_assets.count > preIndexPath.section + 1) {
                    NSDictionary *dict = _assets[preIndexPath.section + 1];
                    NSArray *currentSectionArr = dict[@"assets"];
                    if (currentRow > currentSectionArr.count - 1) {
                        currentRow = currentSectionArr.count - 1;
                    }
                    currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section + 1];
                }
                
            }else{
                
                if (lastCell  && preCell.indexPath.row <= lastIndexPath.row  && currentLocation.y > lastCell.frame.origin.y + lastCell.frame.size.height ) {
                    //1:进入到headerview
                    currentIndexPath = [NSIndexPath indexPathForRow:lastIndexPath.row inSection:lastIndexPath.section];
                    
                }else if (lastCell && currentLocation.y >= lastCell.frame.origin.y && currentLocation.y < lastCell.frame.origin.y + lastCell.frame.size.height){
                    //2:滑到最后一行，该section没有结束，此时，lastcell是存在的
                    NSInteger currentRow = preIndexPath.row + numberPerLine;
                    if (currentRow > lastIndexPath.row) {
                        currentRow = lastIndexPath.row;
                    }
                    currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:lastIndexPath.section];
                }else if (lastCell && currentLocation.y < lastCell.frame.origin.y){
                    //3:没到最后一行，lastcell已经生成的情况
                    NSInteger currentRow = preIndexPath.row + numberPerLine;
                    currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:lastIndexPath.section];
                }else if (!lastCell && preIndexPath.row < preSectionArr.count - 1){
                    //4:没到最后一行，lastcell还没生成的情况
                    NSInteger currentRow = preIndexPath.row + numberPerLine;
                    currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section];
                }
            }
        }else if (currentLocation.y <= preCell.frame.origin.y  && currentLocation.y > preCell.frame.origin.y - minLineSpacing){
            //向上滑 在每行的中间的空白地带  ，
             currentIndexPath = [NSIndexPath indexPathForRow:preIndexPath.row inSection:preIndexPath.section];
        }else if (currentLocation.y <= preCell.frame.origin.y- minLineSpacing  && currentLocation.y > preCell.frame.origin.y - minLineSpacing - collectionHeaderHeight){
            //1:滑到上面的headerview了，上一个section已经结束
            //2:滑到最后一行，该section没有结束，此时，firstCell是存在的
            //3:没到最后一行，firstCell已经生成的情况
            //4:没到最后一行，firstCell还没生成的情况
            NSIndexPath *firstIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section];
            PCAssetCell *firstCell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:firstIndexPath];
            if(firstCell && preIndexPath.row >= firstIndexPath.row && currentLocation.y < firstCell.frame.origin.y){
                //1:滑到上面的headerview了，上一个section已经结束
                            NSDictionary *dict = _assets[preIndexPath.section - 1 ];
                            NSArray *preSectionArr = dict[@"assets"];
                currentIndexPath = [NSIndexPath indexPathForRow:preSectionArr.count - 1 inSection:preIndexPath.section - 1];
            }else if(firstCell && currentLocation.y >= firstCell.frame.origin.y && currentLocation.y < firstCell.frame.origin.y + firstCell.frame.size.height){
                //2:滑到最后一行，该section没有结束，此时，firstCell是存在的
                NSIndexPath *firstIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section + 1];
                PCAssetCell *firstCell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:firstIndexPath];
                CGFloat firstCellX = firstCell.frame.origin.x;
                NSInteger currentRow = floor( (currentLocation.x - firstCellX) / (itemCellWidth + _realItemInterSpace));
                currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section];
            }else if(firstCell && currentLocation.y >= firstCell.frame.origin.y + firstCell.frame.size.height){
               // 3:没到最后一行，firstCell已经生成的情况
                NSIndexPath *firstIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section ];
                PCAssetCell *firstCell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:firstIndexPath];
                CGFloat firstCellY = firstCell.frame.origin.y;
                CGFloat firstCellX = firstCell.frame.origin.x;
                CGFloat  row =  floor((currentLocation.y - firstCellY) / (itemCellWidth + minLineSpacing)) ;
                CGFloat  low = floor( (currentLocation.x - firstCellX) / (itemCellWidth + _realItemInterSpace)) ;
                NSInteger currentRow = row * numberPerLine + low;
                 currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section];
            }else if (!firstCell ){
                //4:没到最后一行，firstCell还没生成的情况
                CGFloat  low = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace)) ;
                CGFloat row = (preIndexPath.row /numberPerLine ) - 1;
                NSInteger currentRow = row * numberPerLine + low;
                currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section];
            }
        }else if(currentLocation.y <= preCell.frame.origin.y - minLineSpacing - collectionHeaderHeight && currentLocation.y >= preCell.frame.origin.y - minLineSpacing - collectionHeaderHeight - itemCellWidth){
            //透过headerview进入上一个section
            //1:进入该section的右边
            //2:进入该section的item的中间空白地带
            NSIndexPath *firstIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section ];
            PCAssetCell *firstCell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:firstIndexPath];
            if (firstCell &&  currentLocation.y < firstCell.frame.origin.y ) {
                //只有小于前一个section的第一个cell的y坐标时，才是真正的进入到上一个section
                
                NSInteger currentRow = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace));
                
                NSDictionary *dict = _assets[preIndexPath.section - 1];
                NSArray *currentSectionArr = dict[@"assets"];
                if (currentRow > currentSectionArr.count - 1) {
                    currentRow = currentSectionArr.count - 1;
                }
                currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section - 1];
            }else{
                if(firstCell && preIndexPath.row >= firstIndexPath.row && currentLocation.y < firstCell.frame.origin.y){
                    //1:滑到上面的headerview了，上一个section已经结束
                    NSDictionary *dict = _assets[preIndexPath.section - 1 ];
                    NSArray *preSectionArr = dict[@"assets"];
                    currentIndexPath = [NSIndexPath indexPathForRow:preSectionArr.count - 1 inSection:preIndexPath.section - 1];
                }else if(firstCell && currentLocation.y >= firstCell.frame.origin.y && currentLocation.y < firstCell.frame.origin.y + firstCell.frame.size.height){
                    //2:滑到最后一行，该section没有结束，此时，firstCell是存在的
                    NSIndexPath *firstIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section + 1];
                    PCAssetCell *firstCell =(PCAssetCell *) [_collectionView cellForItemAtIndexPath:firstIndexPath];
                    CGFloat firstCellX = firstCell.frame.origin.x;
                    NSInteger currentRow = floor( (currentLocation.x - firstCellX) / (itemCellWidth + _realItemInterSpace));
                    currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section];
                    //                NSLog(@"2");
                }else if(firstCell && currentLocation.y >= firstCell.frame.origin.y + firstCell.frame.size.height){
                    // 3:没到最后一行，firstCell已经生成的情况
                    NSIndexPath *firstIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section ];
                    PCAssetCell *firstCell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:firstIndexPath];
                    CGFloat firstCellY = firstCell.frame.origin.y;
                    CGFloat firstCellX = firstCell.frame.origin.x;
                    CGFloat  row =  floor((currentLocation.y - firstCellY) / (itemCellWidth + minLineSpacing)) ;
                    CGFloat  low = floor( (currentLocation.x - firstCellX) / (itemCellWidth + _realItemInterSpace)) ;
                    NSInteger currentRow = row * numberPerLine + low;
                    currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section];
                }else if (!firstCell ){
                    //4:没到最后一行，firstCell还没生成的情况
                    CGFloat  low = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace)) ;
                    CGFloat row = (preIndexPath.row /numberPerLine ) - 1;
                    NSInteger currentRow = row * numberPerLine + low;
                    currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section];
                }
            }
        }else{
            
            currentIndexPath = [NSIndexPath indexPathForRow:preIndexPath.row inSection:preIndexPath.section];
        }
    }
    if(!currentIndexPath){
        //  如果这时currentindexpath还是空，就设此值
        currentIndexPath = [NSIndexPath indexPathForRow:preIndexPath.row inSection:preIndexPath.section];
    }
    //说明滑到了一个cell上
    if (currentIndexPath.section == preIndexPath.section) {
        //同一个section的情况
        if (currentIndexPath.section == _originCell.indexPath.section) {
            if (preIndexPath.row < _originCell.indexPath.row) {
                //从第一象限进入第四象限
                for (NSInteger i = preIndexPath.row; i <_originCell.indexPath.row; i++) {
                    [Tool removeCellsInLoopWithIndex:i section:currentIndexPath.section collectionView:_collectionView fromArray:_selectedIndexPathesForAssets];
                }
                for (NSInteger i = _originCell.indexPath.row+ 1; i<= currentIndexPath.row; i++) {
                    [Tool addCellInLoopToCollectionView:_collectionView WithIndex:i section:currentIndexPath.section array:_selectedIndexPathesForAssets];
                }
            }else{
                //原始section的普通情况
                if (currentIndexPath.row > preRow) {
                    for (NSInteger i = preRow + 1; i <= currentIndexPath.row ; i++) {
                        [Tool addCellInLoopToCollectionView:_collectionView WithIndex:i section:preIndexPath.section array:_selectedIndexPathesForAssets];
                    }
                }else if(currentIndexPath.row < preRow){
                    for (NSInteger i = preRow; i > currentIndexPath.row; i--) {
                         [Tool removeCellsInLoopWithIndex:i section:preIndexPath.section collectionView:_collectionView fromArray:_selectedIndexPathesForAssets];
                    }
                }
            }
        }else{
            //不是原始section的情况
            if (currentIndexPath.row > preRow) {
                for (NSInteger i = preRow + 1; i <= currentIndexPath.row ; i++) {
                    [Tool addCellInLoopToCollectionView:_collectionView WithIndex:i section:preIndexPath.section array:_selectedIndexPathesForAssets];
                }
            }else if(currentIndexPath.row < preRow){
                for (NSInteger i = preRow; i > currentIndexPath.row; i--) {
                    [Tool removeCellsInLoopWithIndex:i section:preIndexPath.section collectionView:_collectionView fromArray:_selectedIndexPathesForAssets];
                }
            }
        }
    }else if (currentIndexPath.section > preIndexPath.section){
        //下部  滑到新的section
        for (NSInteger i = 0; i <= currentIndexPath.row; i++) {
             [Tool addCellInLoopToCollectionView:_collectionView WithIndex:i section:currentIndexPath.section array:_selectedIndexPathesForAssets];
        }
    }else if (currentIndexPath.section < preIndexPath.section){
        //上滑到新的section
        for (NSInteger i = preIndexPath.row; i>= 0; i--) {
             [Tool removeCellsInLoopWithIndex:i section:preIndexPath.section collectionView:_collectionView fromArray:_selectedIndexPathesForAssets];
        }
    }
}



//第一象限的情况

- (void)handlerForFirstQuadrantWithCurrentLocation:(CGPoint)currentLocation{
    CGFloat itemCellWidth = ([UIScreen mainScreen].bounds.size.width/2 ) / numberPerLine - kXMNMargin;
    
    NSIndexPath *currentIndexPath = [_collectionView indexPathForItemAtPoint:currentLocation];
    
    NSMutableArray *arr = [_selectedIndexPathesForAssets lastObject];
    NSIndexPath *preIndexPath = (NSIndexPath *)arr.lastObject;
    
    PCAssetCell *preCell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:preIndexPath];
    
    if (!currentIndexPath) {
        //空白地带
        if (currentLocation.y >preCell.frame.origin.y && currentLocation.y <= preCell.frame.origin.y + preCell.frame.size.height) {
            if (currentLocation.x > preCell.frame.origin.x + preCell.frame.size.width) {
                currentIndexPath = [NSIndexPath indexPathForRow:preIndexPath.row + 1 inSection:preIndexPath.section];
            }else if (currentLocation.x < preCell.frame.origin.x){
                NSInteger currentRow = preIndexPath.row > 0 ? preIndexPath.row : 0;
                currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section];
            }
        }else if (currentLocation.y <= preCell.frame.origin.y && currentLocation.y > preCell.frame.origin.y - minLineSpacing ){
            currentIndexPath = [NSIndexPath indexPathForRow:preIndexPath.row  inSection:preIndexPath.section];
        }else if( currentLocation.y <= preCell.frame.origin.y- minLineSpacing  ){
            //向上滑
            //判断precell是不是在该section的 第一行上
            
            if (preIndexPath.row < numberPerLine && preIndexPath.row >= 0) {
                if (currentLocation.y < preCell.frame.origin.y && currentLocation.y > preCell.frame.origin.y - collectionHeaderHeight) {
                    //向上滑则进入headerview
                    currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section];
                    
                }else if(currentLocation.y <= preCell.frame.origin.y - collectionHeaderHeight ){
                    //通过headerview进入上一个section
                    //判断该section有多少行，如果只有一行，那么继续向上滑就又进入一个headerview，如果多于一行，则进入sectin内部
                    NSDictionary *dict = _assets[preIndexPath.section - 1 ];
                    NSArray *currentSectionArr = dict[@"assets"];
                if (currentSectionArr.count > numberPerLine) {
                    //多于一行
                    CGFloat  low = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace)) ;
                    CGFloat row = (currentSectionArr.count - 1)/numberPerLine ;
                    NSInteger currentRow = row * numberPerLine + low + 1;;
                    if (currentRow > currentSectionArr.count - 1) {
                        //在section的右边
                        currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section ];
                    }else{
                        currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section - 1];
                    }
                    if (currentLocation.y < preCell.frame.origin.y - collectionHeaderHeight - itemCellWidth - minLineSpacing) {
                        //进入倒数第二行
                        CGFloat  low = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace)) ;
                        CGFloat row = (currentSectionArr.count - 1)/numberPerLine - 1 ;
                        NSInteger currentRow = row * numberPerLine + low + 1;;
                        currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section - 1];
                    }
                }else{
                    //只有一行
                    CGFloat  low = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace)) ;
                    CGFloat row = (currentSectionArr.count - 1)/numberPerLine ;
                    NSInteger currentRow = row * numberPerLine + low + 1;;
                    if (currentRow > currentSectionArr.count - 1) {
                        //在section的右边
                        currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section ];
                    }else{
                        currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section - 1];
                    }
                    if (currentLocation.y <= preCell.frame.origin.y - collectionHeaderHeight - itemCellWidth ){
                        //再继续向上滑
                        NSDictionary *dict = _assets[preIndexPath.section - 1 ];
                        NSArray *currentSectionArr = dict[@"assets"];
                        if (currentSectionArr.count < numberPerLine) {
                            currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section - 1 ];
                        }
                    }
                }
                }
            }else{
                //不在第一行
                if(currentLocation.y < preCell.frame.origin.y - minLineSpacing  && currentLocation.y >= preCell.frame.origin.y - minLineSpacing - itemCellWidth){
                    CGFloat  low = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace)) ;
                    CGFloat row = (preIndexPath.row /numberPerLine ) - 1;
                    NSInteger currentRow = row * numberPerLine + low + 1;
                    currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section];
                }
            }
        }else if(currentLocation.y > preCell.frame.origin.y + preCell.frame.size.height ){
            //向下滑
            //判断precell在不在最后一行
            NSDictionary *dict = _assets[preIndexPath.section  ];
            NSArray *preSectionArr = dict[@"assets"];
            if ((preIndexPath.row / numberPerLine)  == ((preSectionArr.count - 1 )/ numberPerLine) ) {
                //在最后一行
                //向下滑进入headerview
                if (currentLocation.y > preCell.frame.origin.y + preCell.frame.size.height && currentLocation.y <= preCell.frame.origin.y + preCell.frame.size.height + collectionHeaderHeight) {
                    currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section + 1];
                }else{
                    //通过headerview进入下一个section
                    //判断该section有多少行，如果只有一行，那么继续向上滑就又进入一个headerview，如果多于一行，则进入sectin内部
                    NSDictionary *dict = _assets[preIndexPath.section + 1 ];
                    NSArray *currentSectionArr = dict[@"assets"];
                    if (currentSectionArr.count > numberPerLine) {
                        //多于一行
                        CGFloat  low = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace)) ;
                        CGFloat row = (currentSectionArr.count - 1)/numberPerLine ;
                        NSInteger currentRow = row * numberPerLine + low + 1;;
                        if (currentRow > currentSectionArr.count - 1) {
                            //在section的右边
                            currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section ];
                        }else{
                            currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section - 1];
                        }
                    }else{
                        //只有一行
                        CGFloat  low = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace)) ;
                        CGFloat row = (currentSectionArr.count - 1)/numberPerLine ;
                        NSInteger currentRow = row * numberPerLine + low + 1;;
                        if (currentRow > currentSectionArr.count - 1) {
                            //在section的右边
                            currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section ];
                        }else{
                            currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section - 1];
                        }
                    }
                }
            }else{
                //不在最后一行
                CGFloat  low = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace)) ;
                CGFloat row = (preIndexPath.row /numberPerLine ) + 1;
                NSInteger currentRow = row * numberPerLine + low + 1;
                currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section];
            }
        }
        else{
            currentIndexPath = [NSIndexPath indexPathForRow:preIndexPath.row inSection:preIndexPath.section];
        }
    }
    if(!currentIndexPath){
        //  如果这时currentindexpath还是空，就设此值
        currentIndexPath = [NSIndexPath indexPathForRow:preIndexPath.row inSection:preIndexPath.section];
    }
//    NSLog(@"row:%@   pre index:%@",currentIndexPath,preIndexPath);
    
    if (currentIndexPath.section == preIndexPath.section) {
        if (currentIndexPath.section == _originCell.indexPath.section) {
            //跟原始cell在一个section
            if (preIndexPath.row >= _originCell.indexPath.row) {
                //从第四象限进入第一象限
                //先把第四象限的删除
                for (NSInteger i = preIndexPath.row; i>_originCell.indexPath.row; i--) {
                     [Tool removeCellsInLoopWithIndex:i section:preIndexPath.section collectionView:_collectionView fromArray:_selectedIndexPathesForAssets];
                }
                
                //再把原始cell左边的  以及第一象限的选上
                for (NSInteger i = _originCell.indexPath.row - 1; i >= currentIndexPath.row; i--) {
                     [Tool addCellInLoopToCollectionView:_collectionView WithIndex:i section:currentIndexPath.section array:_selectedIndexPathesForAssets];
                }
                
            }else{
                //原始section的普通情况
                if (currentIndexPath.row < preIndexPath.row) {
                    for (NSInteger i = preIndexPath.row - 1; i>= currentIndexPath.row; i--) {
                         [Tool addCellInLoopToCollectionView:_collectionView WithIndex:i section:currentIndexPath.section array:_selectedIndexPathesForAssets];
                    }
                }else if(currentIndexPath.row > preIndexPath.row){
                    for (NSInteger i = preIndexPath.row; i < currentIndexPath.row; i++) {
                        [Tool removeCellsInLoopWithIndex:i section:currentIndexPath.section collectionView:_collectionView fromArray:_selectedIndexPathesForAssets];
                    }
                }
            }
        }else{
            //同一个section的情况
            if (currentIndexPath.row < preIndexPath.row) {
                for (NSInteger i = preIndexPath.row - 1; i>= currentIndexPath.row; i--) {
                     [Tool addCellInLoopToCollectionView:_collectionView WithIndex:i section:currentIndexPath.section array:_selectedIndexPathesForAssets];
                }
            }else if(currentIndexPath.row > preIndexPath.row){
                for (NSInteger i = preIndexPath.row; i < currentIndexPath.row; i++) {
                    [Tool removeCellsInLoopWithIndex:i section:currentIndexPath.section collectionView:_collectionView fromArray:_selectedIndexPathesForAssets];
                }
            }
        }
    }else if(currentIndexPath.section < preIndexPath.section) {
        //上滑到新的section
        NSDictionary *dict = _assets[currentIndexPath.section];
        NSArray *currentSectionArr = dict[@"assets"];
        if (currentIndexPath.row <= currentSectionArr.count - 1) {
            for (NSInteger i = currentSectionArr.count - 1; i >= currentIndexPath.row; i--) {
                 [Tool addCellInLoopToCollectionView:_collectionView WithIndex:i section:currentIndexPath.section array:_selectedIndexPathesForAssets];
            }
        }
    }else if(currentIndexPath.section > preIndexPath.section){
        //下滑到新的section
        NSDictionary *dict = _assets[preIndexPath.section];
        NSArray *currentSectionArr = dict[@"assets"];
        for (NSInteger i = preIndexPath.row; i <= currentSectionArr.count - 1 ; i++) {
            [Tool removeCellsInLoopWithIndex:i section:preIndexPath.section collectionView:_collectionView fromArray:_selectedIndexPathesForAssets];
        }
    }
}


//第三象限

- (void)handlerForThirdQuadrantWithCurrentLocation:(CGPoint)currentLocation{

    NSIndexPath *currentIndexPath = [_collectionView indexPathForItemAtPoint:currentLocation];
    
    NSMutableArray *arr = [_selectedIndexPathesForAssets lastObject];
    
    NSIndexPath *preIndexPath = (NSIndexPath *)arr.lastObject;
    NSInteger preRow = preIndexPath.row;
    PCAssetCell *preCell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:preIndexPath];
    
    if (!currentIndexPath) {

        if (currentLocation.y >=preCell.frame.origin.y && currentLocation.y <= preCell.frame.origin.y + preCell.frame.size.height) {
            
            if (currentLocation.x > preCell.frame.origin.x + preCell.frame.size.width) {
                currentIndexPath = [NSIndexPath indexPathForRow:preIndexPath.row  inSection:preIndexPath.section];
            }else if (currentLocation.x < preCell.frame.origin.x){
                NSInteger currentRow = preIndexPath.row - 1> 0 ? preIndexPath.row -1  : 0;
                currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section];
            }
        }else {
            if (currentLocation.y > preCell.frame.origin.y + preCell.frame.size.height ) {
               
                //向下滑
                //判断precell是不是在最后一行
                NSDictionary *dict = _assets[preIndexPath.section  ];
                NSArray *preSectionArr = dict[@"assets"];
                if ((preIndexPath.row / numberPerLine)  == ((preSectionArr.count - 1 )/ numberPerLine) ) {
                 //在最后一行
                   
                    //向下滑进入headerview
                    if ( currentLocation.y <= preCell.frame.origin.y + preCell.frame.size.height + collectionHeaderHeight) {
                        currentIndexPath = [NSIndexPath indexPathForRow:preSectionArr.count - 1 inSection:preIndexPath.section ];
                    }else{
                        //通过headerview进入下一个section
                        //判断该section有多少行，如果只有一行，那么继续向上滑就又进入一个headerview，如果多于一行，则进入sectin内部
                        
                        if (_assets.count > preIndexPath.section + 1) {
                            NSDictionary *dict = _assets[preIndexPath.section + 1 ];
                            NSArray *currentSectionArr = dict[@"assets"];
                            if (currentSectionArr.count > numberPerLine) {
                                //多于一行
                                CGFloat  currentRow = floor( (currentLocation.x - 0) / (cellWidth + _realItemInterSpace)) ;
                                currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section + 1];
                                
                            }else{
                                //只有一行
                                CGFloat  currentRow = floor( (currentLocation.x - 0) / (cellWidth + _realItemInterSpace)) ;
                                if (currentRow > currentSectionArr.count - 1) {
                                    currentRow = currentSectionArr.count - 1;
                                }
                                currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section + 1];
                            }

                        }
                    }
                }else{
                    //不在最后一行
                    
                    CGFloat  low = floor( (currentLocation.x - 0) / (cellWidth + _realItemInterSpace)) ;
                    CGFloat row = (preIndexPath.row /numberPerLine ) + 1;
                    NSInteger currentRow = row * numberPerLine + low;
                    currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section];
                }
            }
            else if(currentLocation.y < preCell.frame.origin.y){
                //向上滑
                //判断precell是不是在该section的 第一行上
                
                if (preIndexPath.row < numberPerLine && preIndexPath.row >= 0) {
                    //在第一行
                    if ( currentLocation.y > preCell.frame.origin.y - collectionHeaderHeight) {
                        //向上滑则进入headerview
                        NSDictionary *dict = _assets[preIndexPath.section - 1 ];
                        NSArray *preSectionArr = dict[@"assets"];
                        currentIndexPath = [NSIndexPath indexPathForRow:preSectionArr.count - 1 inSection:preIndexPath.section - 1];
                        
                    }else if(currentLocation.y <= preCell.frame.origin.y - collectionHeaderHeight ){
                        //通过headerview进入上一个section
                        //判断该section有多少行，如果只有一行，那么继续向上滑就又进入一个headerview，如果多于一行，则进入sectin内部
                        NSDictionary *dict = _assets[preIndexPath.section - 1 ];
                        NSArray *currentSectionArr = dict[@"assets"];

                        
                        CGFloat  low = floor( (currentLocation.x - 0) / (cellWidth + _realItemInterSpace)) ;
                        CGFloat row = (currentSectionArr.count - 1)/numberPerLine ;
                        NSInteger currentRow = row * numberPerLine + low + 1;;
                        if (currentRow > currentSectionArr.count - 1) {
                            
                            //在section的右边
                            currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section ];
                        }else{
                            currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section - 1];
                        }
                    }
                }else{
                    //不在第一行
                    if(currentLocation.y < preCell.frame.origin.y - minLineSpacing  && currentLocation.y >= preCell.frame.origin.y - minLineSpacing - cellWidth){
                        CGFloat  low = floor( (currentLocation.x - 0) / (cellWidth + _realItemInterSpace)) ;
                        CGFloat row = (preIndexPath.row /numberPerLine ) - 1;
                        NSInteger currentRow = row * numberPerLine + low + 1;
                        currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section];
                    }
                }
            }
            else{
//                NSLog(@"shei");
                currentIndexPath = [NSIndexPath indexPathForRow:preIndexPath.row inSection:preIndexPath.section];
            }
        }
    }
    if(!currentIndexPath){
        //  如果这时currentindexpath还是空，就设此值
        currentIndexPath = [NSIndexPath indexPathForRow:preIndexPath.row inSection:preIndexPath.section];
    }
//    NSLog(@"row:%ld   pre index:%@",currentIndexPath.row,preIndexPath);
    //滑到一个cell上
    if (currentIndexPath.section == preIndexPath.section) {
        if (currentIndexPath.section == _originCell.indexPath.section) {
            if (preIndexPath.row <= _originCell.indexPath.row) {
                //从第二象限进入
                for (NSInteger i = preIndexPath.row; i <_originCell.indexPath.row; i++) {
                    [Tool removeCellsInLoopWithIndex:i section:_originCell.indexPath.section collectionView:_collectionView fromArray:_selectedIndexPathesForAssets];
                }
                
                for (NSInteger i = _originCell.indexPath.row + 1; i <= currentIndexPath.row; i++) {
                     [Tool addCellInLoopToCollectionView:_collectionView WithIndex:i section:_originCell.indexPath.section array:_selectedIndexPathesForAssets];
                }
                
                
            }else{
                //一直在第三象限
                //原始section的普通情况
                if (currentIndexPath.row > preRow) {
                    for (NSInteger i = preRow + 1; i <= currentIndexPath.row ; i++) {
                        [Tool addCellInLoopToCollectionView:_collectionView WithIndex:i section:preIndexPath.section array:_selectedIndexPathesForAssets];
                    }
                }else if(currentIndexPath.row < preRow){
                    for (NSInteger i = preRow; i > currentIndexPath.row; i--) {
                        [Tool removeCellsInLoopWithIndex:i section:preIndexPath.section collectionView:_collectionView fromArray:_selectedIndexPathesForAssets];
                    }
                }
            }
        }else{
            //不是原始section的情况
            if (currentIndexPath.row > preRow) {
                for (NSInteger i = preRow + 1; i <= currentIndexPath.row ; i++) {
                    [Tool addCellInLoopToCollectionView:_collectionView WithIndex:i section:preIndexPath.section array:_selectedIndexPathesForAssets];
                }
            }else if(currentIndexPath.row < preRow){
                for (NSInteger i = preRow; i > currentIndexPath.row; i--) {
                    [Tool removeCellsInLoopWithIndex:i section:preIndexPath.section collectionView:_collectionView fromArray:_selectedIndexPathesForAssets];
                }
            }
        }
    }
    else if (currentIndexPath.section > preIndexPath.section){
        //下部  滑到新的section
        for (NSInteger i = 0; i <= currentIndexPath.row; i++) {
            [Tool addCellInLoopToCollectionView:_collectionView WithIndex:i section:currentIndexPath.section array:_selectedIndexPathesForAssets];
        }
    }else if (currentIndexPath.section < preIndexPath.section){
        //上滑到新的section
        for (NSInteger i = preIndexPath.row; i>= 0; i--) {
            [Tool removeCellsInLoopWithIndex:i section:preIndexPath.section collectionView:_collectionView fromArray:_selectedIndexPathesForAssets];
        }
    }
}


//第二象限

- (void)handlerForSecondQuadrantWithCurrentLocation:(CGPoint)currentLocation{
    CGFloat itemCellWidth = ([UIScreen mainScreen].bounds.size.width/2 ) / numberPerLine - kXMNMargin;
    NSIndexPath *currentIndexPath = [_collectionView indexPathForItemAtPoint:currentLocation];
    NSMutableArray *arr = [_selectedIndexPathesForAssets lastObject];
    NSIndexPath *preIndexPath = (NSIndexPath *)arr.lastObject;
    NSInteger preRow = preIndexPath.row;
    PCAssetCell *preCell =(PCAssetCell *) [_collectionView cellForItemAtIndexPath:preIndexPath];
        if (!currentIndexPath) {
            if (currentLocation.y >preCell.frame.origin.y && currentLocation.y <= preCell.frame.origin.y + preCell.frame.size.height) {
                if (currentLocation.x > preCell.frame.origin.x + preCell.frame.size.width) {
                    currentIndexPath = [NSIndexPath indexPathForRow:preIndexPath.row + 1 inSection:preIndexPath.section];
                }else if (currentLocation.x < preCell.frame.origin.x){
                    NSInteger currentRow = preIndexPath.row > 0 ? preIndexPath.row : 0;
                    currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section];
                }
            }else if (currentLocation.y <= preCell.frame.origin.y && currentLocation.y > preCell.frame.origin.y - minLineSpacing ){
                currentIndexPath = [NSIndexPath indexPathForRow:preIndexPath.row  inSection:preIndexPath.section];
            }else if(currentLocation.y < preCell.frame.origin.y - minLineSpacing){
                //向上滑
                //判断precell是不是在该section的 第一行上
                
                if (preIndexPath.row < numberPerLine && preIndexPath.row >= 0) {
                    //在第一行
                    if (currentLocation.y < preCell.frame.origin.y && currentLocation.y > preCell.frame.origin.y - collectionHeaderHeight) {
                        //向上滑则进入headerview
                        currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section];
                        
                    }else if(currentLocation.y <= preCell.frame.origin.y - collectionHeaderHeight ){
                        //通过headerview进入上一个section
                        //判断该section有多少行，如果只有一行，那么继续向上滑就又进入一个headerview，如果多于一行，则进入sectin内部
                        NSDictionary *dict = _assets[preIndexPath.section - 1 ];
                        NSArray *currentSectionArr = dict[@"assets"];
                        if (currentSectionArr.count > numberPerLine) {
                            //多于一行
                            CGFloat  low = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace)) ;
                            CGFloat row = (currentSectionArr.count - 1)/numberPerLine ;
                            NSInteger currentRow = row * numberPerLine + low + 1;;
                            if (currentRow > currentSectionArr.count - 1) {
                                //在section的右边
                                currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section ];
                            }else{
                                currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section - 1];
                            }
                            if (currentLocation.y < preCell.frame.origin.y - collectionHeaderHeight - itemCellWidth - minLineSpacing) {
                                //进入倒数第二行
                                CGFloat  low = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace)) ;
                                CGFloat row = (currentSectionArr.count - 1)/numberPerLine - 1 ;
                                NSInteger currentRow = row * numberPerLine + low + 1;;
                                currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section - 1];
                            }
                        }else{
                            //只有一行
                            CGFloat  low = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace)) ;
                            CGFloat row = (currentSectionArr.count - 1)/numberPerLine ;
                            NSInteger currentRow = row * numberPerLine + low + 1;;
                            if (currentRow > currentSectionArr.count - 1) {
                                //在section的右边
                                currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section ];
                            }else{
                                currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section - 1];
                            }
                            if (currentLocation.y <= preCell.frame.origin.y - collectionHeaderHeight - itemCellWidth ){
                                //再继续向上滑
                                NSDictionary *dict = _assets[preIndexPath.section - 1 ];
                                NSArray *currentSectionArr = dict[@"assets"];
                                if (currentSectionArr.count < numberPerLine) {
                                    currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section - 1 ];
                                }
                            }
                        }
                    }
                }else{
                    //不在第一行
                    if(currentLocation.y < preCell.frame.origin.y - minLineSpacing  && currentLocation.y >= preCell.frame.origin.y - minLineSpacing - itemCellWidth){
                        CGFloat  low = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace)) ;
                        CGFloat row = (preIndexPath.row /numberPerLine ) - 1;
                        NSInteger currentRow = row * numberPerLine + low + 1;
                        currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section];
                    }
                }
            }else if(currentLocation.y > preCell.frame.origin.y + preCell.frame.size.height){
                //向下滑
                //判断precell在不在最后一行
                NSDictionary *dict = _assets[preIndexPath.section  ];
                NSArray *preSectionArr = dict[@"assets"];
                if ((preIndexPath.row / numberPerLine)  == ((preSectionArr.count - 1 )/ numberPerLine) ) {
                    //在最后一行
                    //向下滑进入headerview
                    if (currentLocation.y > preCell.frame.origin.y + preCell.frame.size.height && currentLocation.y <= preCell.frame.origin.y + preCell.frame.size.height + collectionHeaderHeight) {
                        currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section + 1];
                    }else{
                        //通过headerview进入下一个section
                        //判断该section有多少行，如果只有一行，那么继续向上滑就又进入一个headerview，如果多于一行，则进入sectin内部
                        NSDictionary *dict = _assets[preIndexPath.section + 1 ];
                        NSArray *currentSectionArr = dict[@"assets"];
                        if (currentSectionArr.count > numberPerLine) {
                            //多于一行
                            CGFloat  low = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace)) ;
                            CGFloat row = (currentSectionArr.count - 1)/numberPerLine ;
                            NSInteger currentRow = row * numberPerLine + low + 1;;
                            if (currentRow > currentSectionArr.count - 1) {
                                //在section的右边
                                currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section ];
                            }else{
                                currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section - 1];
                            }
                        }else{
                            //只有一行
                            CGFloat  low = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace)) ;
                            CGFloat row = (currentSectionArr.count - 1)/numberPerLine ;
                            NSInteger currentRow = row * numberPerLine + low + 1;;
                            if (currentRow > currentSectionArr.count - 1) {
                                //在section的右边
                                currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:preIndexPath.section ];
                            }else{
                                currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section - 1];
                            }
                        }
                    }
                }else{
                    //不在最后一行
                    
                    CGFloat  low = floor( (currentLocation.x - 0) / (itemCellWidth + _realItemInterSpace)) ;
                    CGFloat row = (preIndexPath.row /numberPerLine ) + 1;
                    NSInteger currentRow = row * numberPerLine + low + 1;
                    currentIndexPath = [NSIndexPath indexPathForRow:currentRow inSection:preIndexPath.section];
                }
            }else{
                currentIndexPath = [NSIndexPath indexPathForRow:preIndexPath.row inSection:preIndexPath.section];
            }
        }
    if(!currentIndexPath){
        //  如果这时currentindexpath还是空，就设此值
        currentIndexPath = [NSIndexPath indexPathForRow:preIndexPath.row inSection:preIndexPath.section];
    }
    //滑到一个cell上
    if (currentIndexPath.section == preIndexPath.section) {
        if (currentIndexPath.section == _originCell.indexPath.section) {
            //跟原始cell在一个section
            if (preIndexPath.row >= _originCell.indexPath.row) {
                //从第三象限进入
                for (NSInteger i = preIndexPath.row; i>_originCell.indexPath.row; i--) {
                    [Tool removeCellsInLoopWithIndex:i section:_originCell.indexPath.section collectionView:_collectionView fromArray:_selectedIndexPathesForAssets];
                }
                for (NSInteger i = _originCell.indexPath.row - 1; i >= currentIndexPath.row; i--) {
                    [Tool addCellInLoopToCollectionView:_collectionView WithIndex:i section:_originCell.indexPath.section array:_selectedIndexPathesForAssets];
                }
            }else{
                if (currentIndexPath.row < preRow) {
                    for (NSInteger i = preRow - 1; i >= currentIndexPath.row ; i--) {
                        [Tool addCellInLoopToCollectionView:_collectionView WithIndex:i section:preIndexPath.section array:_selectedIndexPathesForAssets];
                    }
                }else if(currentIndexPath.row > preRow){
                    for (NSInteger i = preRow; i < currentIndexPath.row; i++) {
                        [Tool removeCellsInLoopWithIndex:i section:preIndexPath.section collectionView:_collectionView fromArray:_selectedIndexPathesForAssets];
                    }
                }
            }
        }else {
            
            if (currentIndexPath.row < preRow) {
                for (NSInteger i = preRow - 1; i >= currentIndexPath.row ; i--) {
                    [Tool addCellInLoopToCollectionView:_collectionView WithIndex:i section:preIndexPath.section array:_selectedIndexPathesForAssets];
                }
            }else if(currentIndexPath.row > preRow){
                for (NSInteger i = preRow; i < currentIndexPath.row; i++) {
                    [Tool removeCellsInLoopWithIndex:i section:preIndexPath.section collectionView:_collectionView fromArray:_selectedIndexPathesForAssets];
                }
            }
        }
    }else if (currentIndexPath.section < preIndexPath.section){
        //从headerview进入一个新的section
        NSDictionary *dict = _assets[preIndexPath.section - 1];
        NSArray *currentSectionArr = dict[@"assets"];
        
        for (NSInteger i = currentSectionArr.count - 1; i>=currentIndexPath.row; i--) {
            [Tool addCellInLoopToCollectionView:_collectionView WithIndex:i section:preIndexPath.section - 1 array:_selectedIndexPathesForAssets];
        }
    }else if(currentIndexPath.section > preIndexPath.section){
        //下滑到新的section
        NSDictionary *dict = _assets[preIndexPath.section];
        NSArray *currentSectionArr = dict[@"assets"];
        for (NSInteger i = preIndexPath.row; i <= currentSectionArr.count - 1 ; i++) {
            [Tool removeCellsInLoopWithIndex:i section:preIndexPath.section collectionView:_collectionView fromArray:_selectedIndexPathesForAssets];
        }
    }
}


//选择结束后，开始拖动
- (void)handlerWhenSelectionDoneWithPanInTheBeginState:(UIGestureRecognizer *)pan{
    CGFloat itemCellWidth = ([UIScreen mainScreen].bounds.size.width/2 ) / numberPerLine - kXMNMargin;
    if (_selectedImgViewArr.count > 0) {
        [_selectedImgViewArr removeAllObjects];
    }
    
    if (_selectedIndexPathesForAssets.count > 0) {
        for (NSArray *arr in _selectedIndexPathesForAssets) {
            
           
            for ( int i = 0; i < arr.count ; i++) {
                NSIndexPath *index = arr[i];
                PCAssetCell *cell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:index];
                cell.alpha = 0.2;
                if (i <= 15) { 
                    CGPoint cellCenter = CGPointMake(cell.frame.origin.x, cell.frame.origin.y - _collectionView.contentOffset.y);
                    UIImageView *imgV = [[UIImageView alloc]initWithFrame:CGRectMake(cellCenter.x + _collectionView.frame.origin.x + 5, cellCenter.y + _collectionView.frame.origin.y - 5 , itemCellWidth, itemCellWidth)];
                    NSDictionary *dict = _assets[index.section];
                    NSArray *assets = dict[@"assets"];
                    PCAssetModel *asset = assets[index.row];
                    
                    imgV.image = asset.thumbnail;
                    imgV.hidden = NO;
                    [_selectedImgViewArr addObject:imgV];
                    [self.view addSubview:imgV];
                }
                
            }
        }
    }
}
//选择结束后，开始拖动，pan手势的change阶段
- (void)handlerWhenSelctionDoneWithPanInTheChangeState:(UIGestureRecognizer *)pan{
    CGPoint point = [pan locationInView:self.view];
    
    for (int i = 0; i< _selectedImgViewArr.count; i++) {
        UIImageView *imgV = _selectedImgViewArr[i];
        [UIView animateWithDuration:0.1
                         animations:^{
                             imgV.center = CGPointMake(point.x + i*2, point.y + i*2);
                         }];
        
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
        
        for (int i = 0; i < _selectedIndexPathesForAssets.count; i++) {
            NSArray *arr = _selectedIndexPathesForAssets[i];
            for (int j = 0; j < arr.count; j++) {
                NSIndexPath *ind = arr[j];
                
                NSDictionary *dict = _assets[ind.section];
                NSArray *assets = dict[@"assets"];
                PCAssetModel *assetModel = assets[ind.row];
                
                PCAssetCell *cell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:ind];
                if (cell) {
                    cell.alpha = 1.0;
                }
                
                PHAsset * asset = assetModel.asset;
                
                if (asset) {
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
        
        [_selectedIndexPathesForAssets removeAllObjects];
    }else{
        for (int i = 0; i < _selectedIndexPathesForAssets.count; i++) {
            NSArray *arr = _selectedIndexPathesForAssets[i];
            for (int j = 0; j < arr.count; j++) {
                NSIndexPath *index = arr[j];
                PCAssetCell *cell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:index];
                cell.alpha = 1.0;
            }
        }
        for (UIImageView *imgV in _selectedImgViewArr) {
            imgV.hidden = YES;
        }
        
        [_selectedImgViewArr removeAllObjects];
        
        
    }
}


- (void)currentLocationDidChange:(CGPoint)currentLocation{
    //先按起始点的x坐标分为左右两边 右边的处于第一象限 和第四象限 左边的处于第二象限和第三象限
    if (currentLocation.x >= _originLocation.x ) {
        //如果y坐标大于起始cell的y坐标，处于第四象限,否则，处于第一象限（注意不是起始y坐标，因为起始的y坐标是大于起始cell的y坐标的，即使比起始y坐标小也有可能处于第四象限， ）
        if (currentLocation.y >= _originCell.frame.origin.y ) {
            //                    NSLog(@"forth");
            
//            [self handlerForForthQuadrantWithCurrentLocation:currentLocation];
            [self handlerForThirdQuadrantWithCurrentLocation:currentLocation];
        }else if(currentLocation.y < _originCell.frame.origin.y - minLineSpacing  && currentLocation.y > 0){
//            [self handlerForFirstQuadrantWithCurrentLocation:currentLocation];
            [self handlerForSecondQuadrantWithCurrentLocation:currentLocation];
        }
    }
    else if (currentLocation.x < _originLocation.x  ){
        //如果y坐标大于起始cell的y+cell的高度，则位于第三象限，否则，位于第二象限
        if (currentLocation.y >= _originCell.frame.origin.y + _originCell.frame.size.height) {
            [self handlerForThirdQuadrantWithCurrentLocation:currentLocation];
        }else if(currentLocation.y > 0){
            [self handlerForSecondQuadrantWithCurrentLocation:currentLocation];
            
        }
    }
}

//开始选择图片时的手势操作
- (void)handlerForPanWhenSelectionBegin:(UIPanGestureRecognizer *)pan{
    CGPoint currentLocation = [pan locationInView:self.collectionView];
    NSIndexPath *currentIndexPath = [_collectionView indexPathForItemAtPoint:currentLocation];
    
    if (currentIndexPath) {
        _originLocation = [pan locationInView:self.collectionView];
        NSIndexPath *originIndexPath = [_collectionView indexPathForItemAtPoint:_originLocation];
        _originCell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:originIndexPath];
        if (_originCell ) {
            if (![Tool cellIsSelected:_originCell inArrary:_selectedIndexPathesForAssets]) {
                _doneSelection = NO;
                NSMutableArray *currentSelectedArr = [[NSMutableArray alloc]init];
                [currentSelectedArr addObject:originIndexPath];
                _originCell.stateBtnSelected = YES;
                [_selectedIndexPathesForAssets addObject:currentSelectedArr];
            }else{
                //选择过程结束，开始拖动复制
                _doneSelection = YES;
                [self handlerWhenSelectionDoneWithPanInTheBeginState:pan];
            }
        }
    }else{
        //如果滑动的位置位于item cell的中间地带，则indexpath.row会返回0，但是此时未必选中row为0的item，所以要做个判断，
        return;
    }
    
}


//选择图片等手势
- (void)panForCollection:(UIPanGestureRecognizer *)pan{
    if (pan.state == UIGestureRecognizerStateBegan) {
        [self handlerForPanWhenSelectionBegin:pan];
    }else if (pan.state == UIGestureRecognizerStateChanged) {
        if (!_doneSelection) {
            if (_originCell) {
                if (!_rolling) {
                    CGPoint currentLocation = [pan locationInView:self.collectionView];
                    [self currentLocationDidChange:currentLocation];
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
        [self collectionViewStartScroll];
    }
    else{
        _rolling = NO;
        if (_timer) {
            [_timer invalidate];
        }
    }
}

//collectionveiw自动滑动
- (void)collectionViewStartScroll{
    if (!_timer || !_timer.isValid) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                repeats:YES
                                                  block:^(NSTimer * _Nonnull timer) {
                                                      CGFloat yOffset = _collectionView.contentOffset.y;
                                                      
                                                      if (_collectionViewMoveUp ) {
                                                          yOffset -= 4;
                                                          _rolling = YES;
                                                          if (_collectionView.contentOffset.y > 0) {
                                                              [_collectionView setContentOffset:CGPointMake(_collectionView.contentOffset.x, yOffset)];
                                                              
                                                              [Tool autoAddVisibleItemsWithArray:_selectedIndexPathesForAssets collectionView:_collectionView];
                                                              
                                                          }

                                                      }else{
                                                          yOffset += 4;
                                                          if (_collectionView.contentOffset.y + _collectionView.frame.size.height < _collectionView.contentSize.height) {
                                                              [_collectionView setContentOffset:CGPointMake(_collectionView.contentOffset.x, yOffset)];
                                                              _rolling = YES;
                                                              [Tool autoAddVisibleItemsWithArray:_selectedIndexPathesForAssets collectionView:_collectionView];
                                                              
                                                          }
                                                          
                                                      }
                                                      
                                                  }];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
}


//左边的相册table自动滚动
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

//判断手势，如果是左右滑动的pan就当作是选择图片手势，如果是上下滑动就是滚动collectinview的手势
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
            if (cell && [Tool cellIsSelected:cell inArrary:_selectedIndexPathesForAssets]) {
                _doneSelection = YES;
                return YES;
            }else{
                return NO;
            }
        }
    }
    return YES;
}

#pragma
//删除照片
- (void)delete{
    if (_selectedIndexPathesForAssets.count > 0) {
        UIActionSheet *sheet = [[UIActionSheet alloc]initWithTitle:nil
                                                          delegate:self
                                                 cancelButtonTitle:@"取消"
                                            destructiveButtonTitle:@"从相簿删除"
                                                 otherButtonTitles: nil];
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
        for (int i = 0; i < _selectedIndexPathesForAssets.count; i++) {
            NSArray *arr = _selectedIndexPathesForAssets[i];
            for (int j = 0; j < arr.count; j++) {
                NSIndexPath *index = arr[j];
                PCAssetCell *cell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:index];
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
            
           
            if (self.tableView.indexPathForSelectedRow.row == 0) {
                //相机胶卷 相册
                 [PHAssetChangeRequest deleteAssets:assets];
            }else{
                PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:model.collection];
                [request removeAssets:assets];
            }
           
        
        } error:&err];
        
        
        if (err) {
            NSLog(@"err:%@",[err localizedDescription]);
        }else{
            NSLog(@"delete success");
            
            NSInteger index = [_tableView indexPathForSelectedRow].row;
            _albums = [[PCPhotoPickerHelper sharedPhotoPickerHelper] getAlbums];
            PCAlbumModel *model = _albums[index];
            
            _assets = [[PCPhotoPickerHelper sharedPhotoPickerHelper] assetsFromAlbum:model.fetchResult].mutableCopy;

            [_collectionView reloadData];
            [_tableView reloadData];
            [_selectedIndexPathesForAssets removeAllObjects];
        }
        
    }
   
}


#pragma 
//全选
- (void)selectAll{
    if (!_doneSelection) {
        if (_selectedIndexPathesForAssets.count > 0) {
            [_selectedIndexPathesForAssets removeAllObjects];
        }
        NSInteger totalNumber = 0;
        for (NSInteger i = 0; i < _assets.count; i++) {
            NSDictionary *item = _assets[i];
            NSArray *arr = item[@"assets"];
            totalNumber += arr.count;
        }
        
        if (totalNumber <= 500) {
            for (NSInteger i = 0; i < _assets.count; i++) {
                NSDictionary *item = _assets[i];
                NSArray *arr = item[@"assets"];
                for (NSInteger j = 0; j <arr.count; j++) {
                     [Tool addCellInLoopToCollectionView:_collectionView WithIndex:j section:i array:_selectedIndexPathesForAssets];
                }
                _selectedAllForSectionArr[i] = @"1";
                
            }
        [_collectionView reloadData];
        }else{
            NSLog(@"超过500张");
        }
    }
}
//取消
- (void)cancelSelection{
//    if (_doneSelection) {
        _doneSelection = NO;
        if (_selectedIndexPathesForAssets.count > 0) {
           
            for (NSArray *arr in _selectedIndexPathesForAssets) {
                for (NSIndexPath *index in arr) {
                    PCAssetCell *cell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:index];
                    cell.stateBtnSelected = NO;
                }
            }
            
            for (NSInteger i = 0; i < _selectedAllForSectionArr.count; i++) {
                _selectedAllForSectionArr[i] = @"0";
            }
            
            [_collectionView reloadData];
            
            [_selectedIndexPathesForAssets removeAllObjects];

        }

}

#pragma 相册操作
//创建相册
- (void)createNewAlbum{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil
                                                   message:@"请输入相册名称"
                                                  delegate:self
                                         cancelButtonTitle:@"取消"
                                         otherButtonTitles:@"确定", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}
//编辑相册
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



//重新排列相册顺序
- (void)sortAlbum{
    _albums = [[_albums reverseObjectEnumerator] allObjects];
    [self.tableView reloadData];
    
    _tableDescending = !_tableDescending;
    if (_tableDescending) {
        [_sortBtn setBackgroundImage:[UIImage imageNamed:@"down_arrow"] forState:UIControlStateNormal];
    }else{
       [_sortBtn setBackgroundImage:[UIImage imageNamed:@"up_arrow"] forState:UIControlStateNormal];
    }
}


- (void)tapForTableView:(UITapGestureRecognizer *)tap{
    if (_tableView.contentOffset.y + _tableView.frame.size.height < _tableView.contentSize.height) {
        [_tableView setContentOffset:CGPointMake(_tableView.contentOffset.x, _tableView.contentSize.height - _tableView.frame.size.height) animated:YES];
    }
}

- (void)tapForCollectionView:(UITapGestureRecognizer *)tap{
    if (_collectionView.contentOffset.y + _collectionView.frame.size.height < _collectionView.contentSize.height) {
        [_collectionView setContentOffset:CGPointMake(_collectionView.contentOffset.x, _collectionView.contentSize.height - _collectionView.frame.size.height) animated:YES];
        
        _scrollBar.bar.center = CGPointMake(_scrollBar.bar.center.x,  (_scrollBar.contentView.frame.origin.y + _scrollBar.contentView.frame.size.height) - _scrollBar.bar.frame.size.height/2 );
    }
}


#pragma kvo
//监控collectionview的contentsize，高度变化时改变滚动条的高度
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"contentSize"] && !([_collectionView isDragging] || [_collectionView isTracking]) && !_scrollBar.scrolling ) {
        _scrollBar.targetView = _collectionView;
    }
}


//collectionview滚动的时候，滚动条跟着滚动
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if ([scrollView isKindOfClass:[UICollectionView class]]) {
        CGFloat percent = scrollView.contentOffset.y / (scrollView.contentSize.height - scrollView.frame.size.height);
        CGFloat yDistanceForBar = (_scrollBar.contentView.frame.size.height - _scrollBar.bar.frame.size.height) * percent ;
        if (percent <= 0) {
            _scrollBar.bar.frame = CGRectMake(0, 0, _scrollBar.bar.frame.size.width, _scrollBar.bar.frame.size.height);
        }else if (percent >= 1.0){
            _scrollBar.bar.frame = CGRectMake(0, _scrollBar.contentView.frame.size.height - _scrollBar.bar.frame.size.height, _scrollBar.bar.frame.size.width, _scrollBar.bar.frame.size.height);
        }else{
            _scrollBar.bar.frame = CGRectMake(0, yDistanceForBar, _scrollBar.bar.frame.size.width, _scrollBar.bar.frame.size.height);
        }
    }
}

#pragma 
//收缩
- (void)close:(UIButton *)sender{
    _open = NO;
        for (NSInteger i = 0; i < _assets.count; i++) {
            NSString *n = @"0";
            _stateForSectionArr[i] = n;
        }
    [_collectionView reloadData];
}

//展开
- (void)open:(UIButton *)sender{
    _open = YES;
        for (NSInteger i = 0; i < _assets.count; i++) {
            NSString *n = @"1";
            _stateForSectionArr[i] = n;
        }
    [_collectionView reloadData];
}

#pragma PCCollectionReusableHeaderViewDelegate
//headerview的展开与收缩
- (void)pcCollectionReusableHeaderViewBtnClick:(PCCollectionReusableHeaderView *)header{
    _stateForSectionArr[header.tag] = header.state;
    for (NSString *n  in _stateForSectionArr) {
        if ([n isEqualToString:@"0"]) {
            _open = NO;
        }
    }
    [_collectionView reloadData];
}
//headerview 全选该section
- (void)pcCollectionReusableHeaderViewSelectAll:(PCCollectionReusableHeaderView *)header{
    if ([_selectedAllForSectionArr[header.tag] isEqualToString:@"0"]) {
        _selectedAllForSectionArr[header.tag] = @"1";
        NSDictionary *dict = _assets[header.tag];
        NSArray *sectionArr = dict[@"assets"];
        for (NSInteger i = 0; i < sectionArr.count; i++) {
            [Tool addCellInLoopToCollectionView:_collectionView WithIndex:i section:header.tag array:_selectedIndexPathesForAssets];
        }
    }else if ([_selectedAllForSectionArr[header.tag] isEqualToString:@"1"]){
        _selectedAllForSectionArr[header.tag] = @"0";
        NSDictionary *dict = _assets[header.tag];
        NSArray *sectionArr = dict[@"assets"];
        for (NSInteger i = 0; i < sectionArr.count; i++) {
            [Tool removeCellsInLoopWithIndex:i section:header.tag collectionView:_collectionView fromArray:_selectedIndexPathesForAssets];
        }
    }
     [_collectionView reloadData];
}

#pragma PCAssetCellDelegate
//选中cell
- (void)pccassetCellDidSelected:(PCAssetCell *)assetCell{
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    NSIndexPath *index = [_collectionView indexPathForCell:assetCell];
    [arr addObject:index];
    [_selectedIndexPathesForAssets addObject:arr];
}
//取消cell
- (void)pccassetCellDidDeselected:(PCAssetCell *)assetCell{
    for (int i = 0; i < _selectedIndexPathesForAssets.count; i++) {
        NSMutableArray *arr = _selectedIndexPathesForAssets[i];
        for (int j = 0; j<arr.count; j++) {
            NSIndexPath *temp = arr[j];
            if (temp.row == assetCell.indexPath.row && temp.section == assetCell.indexPath.section) {
                [arr removeObject:temp];
            }
        }
        if (arr.count <= 0) {
            [_selectedIndexPathesForAssets removeObject:arr];
        }
    }
}
@end
