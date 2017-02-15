//
//  PCAlbumListTableViewController.m
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/3.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import "PCAlbumListTableViewController.h"
#import "PCPhotoPickerHelper.h"
#import "PCAlbumCell.h"
#import "PCAlbumModel.h"
#import "PCPhotosViewController.h"

@interface PCAlbumListTableViewController ()<UIAlertViewDelegate,PHPhotoLibraryChangeObserver>
@property (strong, nonatomic) NSString *nAlbumTitle;
@property (strong, nonatomic) NSString *albumSortedWay;
@end
static const NSString *PCAlbumListCellIdentifier = @"PCAlbumListCellIdentifier";
@implementation PCAlbumListTableViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"相册";
    [self setRightBarButton];
    [self.tableView registerClass:[PCAlbumCell class] forCellReuseIdentifier:PCAlbumListCellIdentifier];
    self.tableView.rowHeight = 75.0f;
    _albums = [[PCPhotoPickerHelper sharedPhotoPickerHelper] getAlbums];
    [self.tableView reloadData];
    _albumSortedWay = @"asc";
}

- (void)setRightBarButton {
    UIBarButtonItem *add = [[UIBarButtonItem alloc]initWithTitle:@"新增" style:UIBarButtonItemStylePlain target:self action:@selector(addAlbum)];
    UIBarButtonItem *sort = [[UIBarButtonItem alloc]initWithTitle:@"排序" style:UIBarButtonItemStylePlain target:self action:@selector(sortAlbum)];
    self.navigationItem.rightBarButtonItems = @[add,sort];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

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
    
    PCPhotosViewController *collectionVC = [[PCPhotosViewController alloc]init];
    collectionVC.album = _albums[indexPath.row];
    [self.navigationController pushViewController:collectionVC animated:YES];
}


- (NSArray <UITableViewRowAction*>*)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewRowAction *edit = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault
                                                                    title:@"修改名称"
                                                                  handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                                                                      PCAlbumCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                                                                      UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil
                                                                                                                     message:@"请输入相册名称"
                                                                                                                    delegate:self
                                                                                                           cancelButtonTitle:@"取消"
                                                                                                           otherButtonTitles:@"修改", nil];
                                                                      alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                                                                      alert.tag = indexPath.row;
                                                                      UITextField *tf = [alert textFieldAtIndex:0];
                                                                      tf.text =[cell.titleLabel.text componentsSeparatedByString:@"   "][0];
                                                                      [alert show];
                                                                  }];
    return @[edit];
}

- (void)addAlbum{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil
                                                   message:@"请输入相册名称"
                                                  delegate:self
                                         cancelButtonTitle:@"取消"
                                         otherButtonTitles:@"确定", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
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

- (void)sortAlbum{
    if ([_albumSortedWay isEqualToString:@"asc"]) {
        _albumSortedWay = @"desc";
       
    }else{
        _albumSortedWay = @"asc";
    }
     _albums = [[_albums reverseObjectEnumerator] allObjects];
    [self.tableView reloadData];
}
@end
