//
//  PCPhotoPickerController.m
//  PCPhotoPicker
//
//  Created by 陈 荫华 on 2017/2/3.
//  Copyright © 2017年 陈 荫华. All rights reserved.
//

#import "PCPhotoPickerController.h"
//#import "PCAlbumListTableViewController.h"
#import "PCAlbumListViewController.h"

@interface PCPhotoPickerController ()

@end

@implementation PCPhotoPickerController

- (instancetype)initWithMaxSelectCount:(NSUInteger)maxCount {
//    PCAlbumListTableViewController *albumListTVC = [[PCAlbumListTableViewController alloc]initWithStyle:UITableViewStylePlain];
    PCAlbumListViewController *albumListTVC = [[PCAlbumListViewController alloc]init];
    if (self = [super initWithRootViewController:albumListTVC]) {
        _maxSelectCount = maxCount;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpNavigationBarAppearance];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setUpNavigationBarAppearance{
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    [UIApplication sharedApplication].statusBarHidden = NO;
    self.navigationBar.barTintColor = [UIColor colorWithRed:34/255.0 green:34/255.0 blue:34/255.0 alpha:1.0];
    self.navigationBar.tintColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    
    UINavigationBar *navigationBar;
    UIBarButtonItem *barItem;
    if ([UIDevice currentDevice].systemVersion.floatValue >= 9.0) {
        barItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[PCPhotoPickerController class]]];
       navigationBar = [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[[PCPhotoPickerController class]]];
    }else{
        barItem = [UIBarButtonItem appearanceWhenContainedIn:[PCPhotoPickerController class], nil];
        navigationBar = [UINavigationBar appearanceWhenContainedIn:[PCPhotoPickerController class], nil];
    }
    [barItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15],NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    [navigationBar setTitleTextAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:20]}];
    [navigationBar setBarStyle:UIBarStyleBlackTranslucent];
}
@end
