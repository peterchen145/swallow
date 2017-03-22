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
@property (assign, nonatomic) BOOL firstTimeMove;
@property (strong, nonatomic) NSMutableArray * preIndexArr;//前一次的index数组
@property (assign, nonatomic) CGPoint originLocation;//最开始时手势的location
//@property (assign, nonatomic) CGPoint preLocation;
@property (strong, nonatomic) NSMutableArray *selectedImgViewArr;//选中的图片列表
@property (strong, nonatomic) UIPanGestureRecognizer *panForCollection;
//@property (strong, nonatomic) NSIndexPath *originIndexPath;
@property (strong, nonatomic) UIButton *deleteBtn;//删除按钮
@property (strong, nonatomic) UIButton *selectAllBtn;//全选
@property (strong, nonatomic) UIButton *cancelBtn;//取消全选
@property (strong, nonatomic) UIView *bottomView;//图片的底部视图

@property (strong, nonatomic) UIView *bottomViewForTV;//相册的bottomview
@property (strong, nonatomic) UIButton *createNewAlbumBtn;//创建新相册按钮
@property (strong, nonatomic) UIButton *editBtn;//编辑相册按钮
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) PCAssetCell *originCell;//最开始选中的cell
@property (strong, nonatomic) NSIndexPath *originIndexPath;//最开始选中的cell的indexpath
@property (assign, nonatomic) CGFloat originCellY;//originCell 的y坐标
@property (assign, nonatomic) BOOL doneSelection;//选择过程结束

@property (strong, nonatomic) NSString *nAlbumTitle;//新相册的名称

@property (assign, nonatomic) BOOL tableViewMoveUp;//相册是否向上移动,在选中图片后，移动到tableview的底部或顶部时使用
@property (assign, nonatomic) BOOL collectionViewMoveUp;//collectionview是否向上移动,在选中图片后，移动到collectionview的底部或顶部时使用

@property (strong, nonatomic) ScrollBar *scrollBar;//滚动条
@property (assign, nonatomic) BOOL rolling;//当选完图片后，移动到collectionveiw（或tableview）的底部或顶部时，rolling为真
@property (assign, nonatomic) BOOL open;//collectionview的状态，展开
@property (strong, nonatomic) NSMutableArray *stateForSectionArr;//每个section的状态的数组
@property (strong, nonatomic) NSMutableArray *selectedAllForSectionArr;//保存每个section的状态，是收起还是展开
@property (strong, nonatomic) UIButton *sortBtn;//对tableivew重新排序的按钮
@property (assign, nonatomic) BOOL tableDescending;//tableview是否降序
//@property (strong, nonatomic) NSIndexPath *preMaxInd;//上一个最大的indexpath
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
#define  cellWidth  ([UIScreen mainScreen].bounds.size.width * 2/3 - scrollBarWidth) / numberPerLine - kXMNMargin

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
    _preIndexArr = [[NSMutableArray alloc]init];
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
    CGFloat width = ([UIScreen mainScreen].bounds.size.width * 2/ 3 - scrollBarWidth) / numberPerLine - kXMNMargin;
    
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
    
//    if (indexPath.row == 1) {
//        NSIndexPath *preIndexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section];
//        PCAssetCell *preCell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:preIndexPath];
//        if (preCell) {
//            _realItemInterSpace = cell.frame.origin.x - (preCell.frame.origin.x + preCell.frame.size.width);
//        }
//    }
    
    NSDictionary *dict = _assets[indexPath.section];
    NSArray *arr = dict[@"assets"];
    cell.asset = arr[indexPath.row];
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 20, 40, 20)];
    label.text = [NSString stringWithFormat:@"%ld   %ld",indexPath.section,indexPath.row];
    label.font = [UIFont systemFontOfSize:10];
    [cell.contentView addSubview:label];
    
//    for (int i = 0; i < _selectedIndexPathesForAssets.count; i++) {
//        NSMutableArray *arr = _selectedIndexPathesForAssets[i];
        for (NSIndexPath *ind  in _selectedIndexPathesForAssets) {
            if (ind.row == indexPath.row && ind.section == indexPath.section) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.stateBtnSelected = YES;
                });
                
            }else{
                cell.stateBtnSelected = NO;
            }
        }
//    }

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


//第四象限
- (void)handlerForForthQuadrantWithCurrentLocation:(CGPoint)currentLocation{

    NSMutableArray *arr = [Tool layoutAttributesArrWithOriginLocation:_originLocation currentLocation:currentLocation collectionView:_collectionView];
    if (arr.count > 0) {
        NSMutableArray *group = [Tool groupFromAttributeArr:arr];
        NSMutableArray *lastPart = group.lastObject;
        UICollectionViewLayoutAttributes *att = lastPart.lastObject;

        NSIndexPath *currentIndexPath = [Tool currentIndexPathForForthQuadrantWithGroup:group numberPerLine:numberPerLine];
         NSIndexPath * preIndexPath = _selectedIndexPathesForAssets.lastObject;
        //前期处理
        [Tool preHandlerForForthQuadrantWithOriginIndexPath:_originIndexPath
                                           currentIndexPath:currentIndexPath
                                               preIndexPath:preIndexPath
                                             collectionView:_collectionView
                                           selectedIndexArr:_selectedIndexPathesForAssets
                                                     assets:_assets];
        if (arr.count > _preIndexArr.count) {
            // 增加
            [Tool handlerForForthQuadrantInAddingWithIndexArr:group
                                             currentIndexPath:currentIndexPath
                                                 preIndexPath:preIndexPath
                                              originIndexPath:_originIndexPath
                                               collectionView:_collectionView
                                             selectedIndexArr:_selectedIndexPathesForAssets
                                                       assets:_assets
                                          lastLayoutAttribute:att];
        }else if (arr.count < _preIndexArr.count){
            //减少
            [Tool handlerForForthQuadrantInSubtractionWithIndexArr:group
                                                  currentIndexPath:currentIndexPath
                                                      preIndexPath:preIndexPath
                                                   originIndexPath:_originIndexPath
                                                    collectionView:_collectionView
                                                  selectedIndexArr:_selectedIndexPathesForAssets
                                                            assets:_assets
                                               lastLayoutAttribute:att];
        }
    }
    _preIndexArr = arr;
}
// 第一象限
- (void)handlerForFirstQuadrantWithCurrentLocation:(CGPoint)currentLocation{
    NSMutableArray *arr = [Tool layoutAttributesArrWithOriginLocation:_originLocation currentLocation:currentLocation collectionView:_collectionView];
    if (arr.count > 0) {
        NSMutableArray *group = [Tool groupFromAttributeArr:arr];
        NSMutableArray *lastPart = group.lastObject;
        UICollectionViewLayoutAttributes *att = lastPart.lastObject;
        NSIndexPath *currentIndexPath = [Tool currentIndexPathForFirstQuadrantWithGroup:group numberPerLine:numberPerLine];
        NSIndexPath * preIndexPath = _selectedIndexPathesForAssets.lastObject;
        
        [Tool preHandlerForFirstQuadrantWithOriginIndexPath:_originIndexPath
                                           currentIndexPath:currentIndexPath
                                               preIndexPath:preIndexPath
                                             collectionView:_collectionView
                                           selectedIndexArr:_selectedIndexPathesForAssets];
        
         if (currentIndexPath.section < preIndexPath.section || ( currentIndexPath.section == preIndexPath.section &&  currentIndexPath.row < preIndexPath.row)) {
             // 增加
             [Tool handlerForFirstQuadrantInAddingWithIndexArr:group
                                              currentIndexPath:currentIndexPath
                                                  preIndexPath:preIndexPath
                                               originIndexPath:_originIndexPath
                                                collectionView:_collectionView
                                              selectedIndexArr:_selectedIndexPathesForAssets
                                                        assets:_assets];
         }else if (currentIndexPath.section > preIndexPath.section || ( currentIndexPath.section == preIndexPath.section &&  currentIndexPath.row > preIndexPath.row)){
             //减少
             [Tool handlerForFirstQuadrantInSubtractionWithIndexArr:group
                                                   currentIndexPath:currentIndexPath
                                                       preIndexPath:preIndexPath
                                                    originIndexPath:_originIndexPath
                                                     collectionView:_collectionView
                                                   selectedIndexArr:_selectedIndexPathesForAssets
                                                             assets:_assets
                                                lastLayoutAttribute:att];
         }
    }
 _preIndexArr = arr;
    
    
}

//第二象限

- (void)handlerForSecondQuadrantWithCurrentLocation:(CGPoint)currentLocation{
    NSMutableArray *arr = [Tool layoutAttributesArrWithOriginLocation:_originLocation currentLocation:currentLocation collectionView:_collectionView];
    
    if (arr.count > 0) {
        NSMutableArray *group = [Tool groupFromAttributeArr:arr];
        NSMutableArray *lastPart = group.lastObject;
        UICollectionViewLayoutAttributes *att = lastPart.lastObject;
        NSIndexPath *currentIndexPath = [Tool currentIndexPathForSecQuadrantWithGroup:group numberPerLine:numberPerLine];
        NSIndexPath * preIndexPath = _selectedIndexPathesForAssets.lastObject;
        [Tool preHandlerForSecondQuadrantOriginIndexPath:_originIndexPath
                                        currentIndexPath:currentIndexPath
                                            preIndexPath:preIndexPath
                                          collectionView:_collectionView
                                        selectedIndexArr:_selectedIndexPathesForAssets
                                                  assets:_assets];
        if (arr.count > _preIndexArr.count) {
            // 增加
            [Tool handlerForSecondQuadrantInAddingWithIndexArr:group
                                              currentIndexPath:currentIndexPath
                                                  preIndexPath:preIndexPath
                                               originIndexPath:_originIndexPath
                                                collectionView:_collectionView
                                              selectedIndexArr:_selectedIndexPathesForAssets
                                                        assets:_assets];
        }else if(arr.count < _preIndexArr.count){
            //减少
            [Tool handlerForSecondQuadrantInSubtractionWithIndexArr:group
                                                   currentIndexPath:currentIndexPath
                                                       preIndexPath:preIndexPath
                                                    originIndexPath:_originIndexPath
                                                     collectionView:_collectionView
                                                   selectedIndexArr:_selectedIndexPathesForAssets
                                                             assets:_assets
                                                lastLayoutAttribute:att];
        }
    }
    _preIndexArr = arr;
}



//第三象限

- (void)handlerForThirdQuadrantWithCurrentLocation:(CGPoint)currentLocation{
    NSMutableArray *arr = [Tool layoutAttributesArrWithOriginLocation:_originLocation currentLocation:currentLocation collectionView:_collectionView];
    if (arr.count > 0) {
        //先按section进行分类
       NSMutableArray *group = [Tool groupFromAttributeArr:arr];
        
        NSMutableArray *lastPart = group.lastObject;
        UICollectionViewLayoutAttributes *att = lastPart.lastObject;
        NSIndexPath *currentIndexPath = [Tool currentIndexPathForThirdQuadrantWithGroup:group numberPerLine:numberPerLine];
        NSIndexPath * preIndexPath = _selectedIndexPathesForAssets.lastObject;
        //判断是增加还是减少
        if (currentIndexPath.section > preIndexPath.section || ( currentIndexPath.section == preIndexPath.section &&  currentIndexPath.row > preIndexPath.row)) {
            //增加
            [Tool handlerForThirdQuadrantInAddingWithIndexArr:group
                                             currentIndexPath:currentIndexPath
                                                 preIndexPath:preIndexPath
                                              originIndexPath:_originIndexPath
                                               collectionView:_collectionView
                                             selectedIndexArr:_selectedIndexPathesForAssets
                                                       assets:_assets
                                          lastLayoutAttribute:att];
            
        }else{
            [Tool handlerForThirdQuadrantInSubtractionWithCollectionView:_collectionView
                                                        currentIndexPath:currentIndexPath
                                                            preIndexPath:preIndexPath
                                                        selectedIndexArr:_selectedIndexPathesForAssets
                                                         originIndexPath:_originIndexPath
                                                                  assets:_assets
                                                     lastLayoutAttribute:att];
        }
    }
     _preIndexArr = arr;
}





//选择结束后，开始拖动
- (void)handlerWhenSelectionDoneWithPanInTheBeginState:(UIGestureRecognizer *)pan{
    CGFloat itemCellWidth = ([UIScreen mainScreen].bounds.size.width/2 ) / numberPerLine - kXMNMargin;
    if (_selectedImgViewArr.count > 0) {
        [_selectedImgViewArr removeAllObjects];
    }
    
    if (_selectedIndexPathesForAssets.count > 0) {
        for ( int i = 0; i < _selectedIndexPathesForAssets.count ; i++) {
            NSIndexPath *index = _selectedIndexPathesForAssets[i];
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
        
        for (int j = 0; j < _selectedIndexPathesForAssets.count; j++) {
            NSIndexPath *ind = _selectedIndexPathesForAssets[j];
            
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
        [_selectedIndexPathesForAssets removeAllObjects];
    }else{
        for (int j = 0; j < _selectedIndexPathesForAssets.count; j++) {
            NSIndexPath *index = _selectedIndexPathesForAssets[j];
            PCAssetCell *cell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:index];
            cell.alpha = 1.0;
        }
        for (UIImageView *imgV in _selectedImgViewArr) {
            imgV.hidden = YES;
        }
        [_selectedImgViewArr removeAllObjects];
    }
}


- (void)currentLocationDidChange:(CGPoint)currentLocation{
    if (_firstTimeMove) {
        //第一次滑动选择时的index数组
        CGRect rect = CGRectMake(_originLocation.x, _originLocation.y,  currentLocation.x - _originLocation.x,  currentLocation.y - _originLocation.y    );
        NSMutableArray *arr = [_collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect].mutableCopy;
        NSSortDescriptor *s1 = [NSSortDescriptor sortDescriptorWithKey:@"indexPath" ascending:YES];
        NSSortDescriptor *s2 = [NSSortDescriptor sortDescriptorWithKey:@"representedElementCategory" ascending:NO];
        NSArray *sorts = @[s1,s2];
        [arr sortUsingDescriptors:sorts];
        _firstTimeMove = NO;
        _preIndexArr = arr;
    }
    
    if (_originCell && _selectedIndexPathesForAssets.count > 0) {
        //先按起始点的x坐标分为左右两边 右边的处于第一象限 和第四象限 左边的处于第二象限和第三象限
        if (currentLocation.x >= _originLocation.x ) {
            //如果y坐标大于起始cell的y坐标，处于第四象限,否则，处于第一象限（注意不是起始y坐标，因为起始的y坐标是大于起始cell的y坐标的，即使比起始y坐标小也有可能处于第四象限， ）
            if (currentLocation.y >= _originCellY ) {
                [self handlerForForthQuadrantWithCurrentLocation:currentLocation];
            }else if(currentLocation.y < _originCellY - minLineSpacing  && currentLocation.y > 0){
                [self handlerForFirstQuadrantWithCurrentLocation:currentLocation];
            }
        }
        else if (currentLocation.x < _originLocation.x  ){
            //如果y坐标大于起始cell的y+cell的高度，则位于第三象限，否则，位于第二象限
            if (currentLocation.y >= _originCellY + cellWidth) {
                [self handlerForThirdQuadrantWithCurrentLocation:currentLocation];
            }else if(currentLocation.y > 0){
                 [self handlerForSecondQuadrantWithCurrentLocation:currentLocation];
            }
        }
    }
}


//开始选择图片时的手势操作
- (void)handlerForPanWhenSelectionBegin:(UIPanGestureRecognizer *)pan{
    CGPoint currentLocation = [pan locationInView:self.collectionView];
    NSIndexPath *currentIndexPath = [_collectionView indexPathForItemAtPoint:currentLocation];
    _firstTimeMove = YES;
    if (currentIndexPath) {
        _originLocation = [pan locationInView:self.collectionView];
        _originIndexPath = [_collectionView indexPathForItemAtPoint:_originLocation];
        _originCell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:_originIndexPath];
        
        if (_originCell ) {
            
            if (![Tool cellIsSelected:_originCell inArrary:_selectedIndexPathesForAssets]) {
                _doneSelection = NO;
                NSMutableArray *currentSelectedArr = [[NSMutableArray alloc]init];
                [currentSelectedArr addObject:_originIndexPath];
                _originCell.stateBtnSelected = YES;
                [_selectedIndexPathesForAssets addObject:_originIndexPath];
                _originCellY = _originCell.frame.origin.y;
//                _preMaxInd = _originIndexPath;
//                _preLocation = _originLocation;
            }else{
                //选择过程结束，开始拖动复制
                _doneSelection = YES;
                [self handlerWhenSelectionDoneWithPanInTheBeginState:pan];
            }
        }
    }else{
        
        if (_originCell) {
            _originCell = nil;
        }
        if (_originIndexPath) {
            _originIndexPath = nil;
        }
        _originCellY = 0;
//        _preMaxInd = nil;
//        _preLocation = CGPointZero;
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
        _firstTimeMove = NO;
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
                                                              [Tool autoAddVisibleItemsForMoveUpWithArray:_selectedIndexPathesForAssets collectionView:_collectionView originIndexPath:_originIndexPath];
                                                             
                                                          }

                                                      }else{
                                                          yOffset += 4;
                                                          if (_collectionView.contentOffset.y + _collectionView.frame.size.height < _collectionView.contentSize.height) {
                                                              [_collectionView setContentOffset:CGPointMake(_collectionView.contentOffset.x, yOffset)];
                                                              _rolling = YES;
                                                              [Tool autoAddVisibleItemsForMoveDownWithArray:_selectedIndexPathesForAssets collectionView:_collectionView originIndexPath:_originIndexPath];
                                                              
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
            return YES;
        }
        if (point.x == 0 || fabs(point.y / point.x) > 5.0) {
            //上下方向
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
        _doneSelection = NO;
        if (_selectedIndexPathesForAssets.count > 0) {
           
            for (NSIndexPath *index in _selectedIndexPathesForAssets) {
                PCAssetCell *cell = (PCAssetCell *)[_collectionView cellForItemAtIndexPath:index];
                cell.stateBtnSelected = NO;
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
    NSIndexPath *index = [_collectionView indexPathForCell:assetCell];
    [Tool addCellInLoopToCollectionView:_collectionView WithIndex:index.row section:index.section array:_selectedIndexPathesForAssets];
}
//取消cell
- (void)pccassetCellDidDeselected:(PCAssetCell *)assetCell{
    [Tool removeCellsInLoopWithIndex:assetCell.indexPath.row section:assetCell.indexPath.section collectionView:_collectionView fromArray:_selectedIndexPathesForAssets];
    
}
@end
