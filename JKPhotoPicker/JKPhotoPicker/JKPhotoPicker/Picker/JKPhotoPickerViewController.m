//
//  JKPhotoPickerViewController.m
//  JKPhotoPicker
//
//  Created by albert on 2016/12/21.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import "JKPhotoPickerViewController.h"
#import "JKPhotoSelectedCollectionViewCell.h"
#import "JKPhotoItem.h"
#import "JKPhotoManager.h"
#import "JKPhotoAlbumListView.h"
#import "JKPhotoTitleButton.h"
#import "JKPhotoBrowserViewController.h"
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>

#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "JKPhotoResourceManager.h"
#import "JKPhotoConfiguration.h"
#import "JKPhotoSelectCompleteView.h"

@interface JKPhotoPickerViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, PHPhotoLibraryChangeObserver, UICollectionViewDelegateFlowLayout>
{
    NSInteger columnCount;
}
/** collectionView */
@property (nonatomic, weak) UICollectionView *collectionView;

/** bottomContentView */
@property (nonatomic, weak) UIView *bottomContentView;

/** 底部的collectionView */
@property (nonatomic, weak) UICollectionView *bottomCollectionView;

/** selectAllButton */
@property (nonatomic, weak) UIButton *selectAllButton;

/** 选中数量提示按钮 */
@property (nonatomic, weak) UIButton *selectedCountButton;

/** 相册列表view */
@property (nonatomic, weak) JKPhotoAlbumListView *albumListView;

/** titleButton */
@property (nonatomic, weak) JKPhotoTitleButton *titleButton;

/** 监听点击完成的block */
@property (nonatomic, copy) void(^completeHandler)(NSArray *photoItems, NSArray *selectedAssetArray) ;

/** 所有的图片数组 */
@property (nonatomic, strong) NSMutableArray *allPhotoItems;

/** 选中的图片数组 */
@property (nonatomic, strong) NSMutableArray *selectedPhotoItems;

/** 选中的asset数组 */
@property (nonatomic, strong) NSMutableArray *selectedAssetArray;

/** 当前选中相册所有照片的identifier映射缓存 */
@property (nonatomic, strong) NSCache *allPhotosIdentifierCache;

/** 选中的照片标识和item的映射缓存 */
@property (nonatomic, strong) NSMutableDictionary *selectedPhotosIdentifierCache;

/** 是否present了图片浏览器 */
@property (nonatomic, assign) BOOL isPhotoBrowserPresented;

/** 退出图片浏览器惠普是否刷新相册 */
@property (nonatomic, assign) BOOL isReloadAfterDismiss;

/** 当前是否是所有照片相册 */
@property (nonatomic, assign) BOOL isAllPhotosAlbum;

/** configuration */
@property (nonatomic, strong) JKPhotoConfiguration *configuration;

/** currentAlbumItem */
@property (nonatomic, strong) JKPhotoItem *currentAlbumItem;

/** currentScreenWidth */
@property (nonatomic, assign) CGFloat currentScreenWidth;
@end

@implementation JKPhotoPickerViewController

static NSString * const reuseID = @"JKPhotoCollectionViewCell"; // 重用ID
static NSString * const reuseIDSelected = @"JKPhotoSelectedCollectionViewCell"; // 选中的照片重用ID

- (instancetype)init{
    if (self = [super init]) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    return self;
}

#pragma mark - 类方法

+ (void)showWithConfiguration:(void(^)(JKPhotoConfiguration *configuration))configuration
              completeHandler:(void(^)(NSArray <JKPhotoItem *> *photoItems, NSArray<PHAsset *> *selectedAssetArray))completeHandler{
    
    JKPhotoConfiguration *config = [JKPhotoConfiguration new];
    
    !configuration ? : configuration(config);
    
    if (config.selectDataType == JKPhotoPickerMediaDataTypeUnknown) {
        return;
    }
    
    [JKPhotoItem setSelectDataType:config.selectDataType];
    
    UIViewController *presentVC = config.presentViewController;
    
    if (!presentVC) {
        
        presentVC = [UIApplication sharedApplication].delegate.window.rootViewController;
        
        while (presentVC.presentedViewController) {
            
            presentVC = presentVC.presentedViewController;
        }
    }
    
    config.presentViewController = presentVC;
    
    [JKPhotoManager checkPhotoAccessWithPresentVc:presentVC finished:^(BOOL isAccessed) {
        
        if (!isAccessed) { return; }
        
        [self showWithConfig:config completeHandler:completeHandler];
    }];
}

+ (void)showWithConfig:(JKPhotoConfiguration *)config completeHandler:(void (^)(NSArray<JKPhotoItem *> *, NSArray<PHAsset *> *))completeHandler{
    
    if (!config) { return; }
    
    JKPhotoPickerViewController *vc = [[self alloc] init];
    vc.configuration = config;
    vc.completeHandler = completeHandler;
    [vc.selectedPhotoItems removeAllObjects];
    [vc.selectedPhotoItems addObjectsFromArray:config.seletedItems];
    
    [vc.selectedAssetArray removeAllObjects];
    
    for (JKPhotoItem *itm in vc.selectedPhotoItems) {
        
        [vc.selectedPhotosIdentifierCache setObject:itm forKey:itm.assetLocalIdentifier];
        
        [vc.selectedAssetArray addObject:itm.photoAsset];
    }
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    [config.presentViewController presentViewController:nav animated:YES completion:^{
        
        if (config.takePhotoFirst) {
            
            [vc updateIconWithSourType:(UIImagePickerControllerSourceTypeCamera)];
        }
    }];
}

+ (void)initialize{
    [[UIView appearance] setExclusiveTouch:YES];
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance{
    NSLog(@"%@", changeInstance);
}

#pragma mark - 懒加载
- (NSMutableArray *)allPhotoItems{
    if (!_allPhotoItems) {
        _allPhotoItems = [NSMutableArray array];
    }
    return _allPhotoItems;
}

- (NSCache *)allPhotosIdentifierCache{
    if (!_allPhotosIdentifierCache) {
        _allPhotosIdentifierCache = [[NSCache alloc] init];
    }
    return _allPhotosIdentifierCache;
}

- (NSMutableArray *)selectedPhotoItems{
    if (!_selectedPhotoItems) {
        _selectedPhotoItems = [NSMutableArray array];
    }
    return _selectedPhotoItems;
}

- (NSMutableArray *)selectedAssetArray{
    if (!_selectedAssetArray) {
        _selectedAssetArray = [NSMutableArray array];
    }
    return _selectedAssetArray;
}

- (NSMutableDictionary *)selectedPhotosIdentifierCache{
    if (!_selectedPhotosIdentifierCache) {
        _selectedPhotosIdentifierCache = [NSMutableDictionary dictionary];//[[NSCache alloc] init];
    }
    return _selectedPhotosIdentifierCache;
}

- (JKPhotoAlbumListView *)albumListView{
    if (!_albumListView) {
        JKPhotoAlbumListView *albumListView = [[JKPhotoAlbumListView alloc] init];
        albumListView.navigationController = self.navigationController;
        albumListView.hidden = YES;
        [self.view addSubview:albumListView];
        _albumListView = albumListView;
        
        [self.titleButton setTitle:[albumListView.cameraRollItem.albumTitle stringByAppendingString:@"  "] forState:(UIControlStateNormal)];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            [self loadPhotoWithAlbumItem:albumListView.cameraRollItem isReload:NO];
        });
        
        __weak typeof(self) weakSelf = self;
#pragma mark - 选中相册
        [albumListView setSelectRowBlock:^(JKPhotoItem *photoItem, BOOL isReload) {
            
            [weakSelf.titleButton setTitle:[photoItem.albumTitle stringByAppendingString:@"  "] forState:(UIControlStateNormal)];
            weakSelf.titleButton.selected = NO;
            weakSelf.isAllPhotosAlbum = [photoItem.albumLocalIdentifier isEqualToString:weakSelf.albumListView.cameraRollItem.albumLocalIdentifier];
            
            if (weakSelf.configuration.shouldSelectAll) {
                
                [weakSelf.selectedPhotoItems removeAllObjects];
                [weakSelf.selectedAssetArray removeAllObjects];
                [weakSelf.selectedPhotosIdentifierCache removeAllObjects];
                
                [weakSelf.selectAllButton setTitle:@"全选" forState:(UIControlStateNormal)];
            }
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                [weakSelf loadPhotoWithAlbumItem:photoItem isReload:isReload];
            });
        }];
    }
    return _albumListView;
}

#pragma mark - 监听通知

- (void)applicationDidBecomeActive{
    
    if (self.isPhotoBrowserPresented) {
        
        self.isReloadAfterDismiss = YES;
        
        return;
    }
    
    [self.albumListView reloadAlbum];
}

- (void)userDidTakeScreenshot{
    
    if (self.isPhotoBrowserPresented) {
        
        self.isReloadAfterDismiss = YES;
        
        return;
    }
    
    if (@available(iOS 11.0, *)) {
        
        [self.albumListView performSelector:@selector(reloadAlbum) withObject:nil afterDelay:3];
        
    } else {
        
        [self.albumListView performSelector:@selector(reloadAlbum) withObject:nil afterDelay:1];
    }
}

#pragma mark
#pragma mark - 监听屏幕旋转

- (void)deviceOrientationDidChange:(NSNotification *)noti{
    
    switch ([UIDevice currentDevice].orientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            
            [self solveOrientationChanged];
            
            break;
            
        default:
            break;
    }
}

- (void)solveOrientationChanged{
    
    if (_currentScreenWidth == [UIScreen mainScreen].bounds.size.width) {
        
        return;
    }
    
    _currentScreenWidth = [UIScreen mainScreen].bounds.size.width;
    
    [self.collectionView reloadData];
}

#pragma mark - 初始化
- (void)viewDidLoad {
    [super viewDidLoad];
    
    columnCount = JKPhotoScreenWidth > 414 ? 6 : 4;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    
    _isAllPhotosAlbum = YES;
    
    [self setupNav];
    
    [self setupCollectionView];
    
    [self albumListView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidTakeScreenshot) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
}

- (void)setupNav{
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:(UIBarButtonItemStylePlain) target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItems = @[leftItem];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:(UIBarButtonItemStylePlain) target:self action:@selector(done)];
    self.navigationItem.rightBarButtonItems = @[rightItem];
    
    JKPhotoTitleButton *titleButton = [JKPhotoTitleButton buttonWithType:(UIButtonTypeCustom)];
    titleButton.frame = CGRectMake(0, 0, 200, 40);
    [titleButton setTitleColor:[UIColor colorWithRed:51.0/255.0 green:51.0/255.0 blue:51.0/255.0 alpha:1] forState:(UIControlStateNormal)];
    
    [titleButton setImage:[JKPhotoResourceManager jk_imageNamed:@"arrow_down@2x"] forState:(UIControlStateNormal)];
    [titleButton setImage:[JKPhotoResourceManager jk_imageNamed:@"arrow_up@2x"] forState:(UIControlStateSelected)];
    
    [titleButton addTarget:self action:@selector(titleViewClick:) forControlEvents:(UIControlEventTouchUpInside)];
    
    self.navigationItem.titleView = titleButton;
    self.titleButton = titleButton;
    
    NSDictionary *attrDict = @{NSFontAttributeName : [UIFont systemFontOfSize:15]};
    
    [self.navigationItem.leftBarButtonItem setTitleTextAttributes:attrDict forState:(UIControlStateNormal)];
    [self.navigationItem.leftBarButtonItem setTitleTextAttributes:attrDict forState:(UIControlStateDisabled)];
    [self.navigationItem.leftBarButtonItem setTitleTextAttributes:attrDict forState:(UIControlStateHighlighted)];
    if (@available(iOS 9.0, *)) {
        [self.navigationItem.leftBarButtonItem setTitleTextAttributes:attrDict forState:(UIControlStateFocused)];
    } else {
        // Fallback on earlier versions
    }
    
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:attrDict forState:(UIControlStateNormal)];
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:attrDict forState:(UIControlStateDisabled)];
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:attrDict forState:(UIControlStateHighlighted)];
    if (@available(iOS 9.0, *)) {
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes:attrDict forState:(UIControlStateFocused)];
    } else {
        // Fallback on earlier versions
    }
}

- (void)titleViewClick:(UIButton *)button{
    
    __weak typeof(self) weakSelf = self;
    
    [self.albumListView executeAlbumListViewAnimationCompletion:^{
        weakSelf.titleButton.selected = !weakSelf.albumListView.hidden;
    }];
}

- (void)done{
    !self.completeHandler ? : self.completeHandler(self.selectedPhotoItems, self.selectedAssetArray);
    [self dismiss];
}

- (void)dismiss{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    
    columnCount = size.width > 414 ? 6 : 4;
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    
    if (@available(iOS 11.0, *)) {
        
        safeAreaInsets = self.view.safeAreaInsets;
    }
    
    self.collectionView.frame = CGRectMake(safeAreaInsets.left, JKPhotoCurrentNavigationBarHeight, self.view.frame.size.width - safeAreaInsets.left - safeAreaInsets.right, self.view.frame.size.height - JKPhotoCurrentNavigationBarHeight - JKPhotoCurrentHomeIndicatorHeight() - 70);
    
    self.bottomContentView.frame = CGRectMake(0, CGRectGetMaxY(self.collectionView.frame), self.view.frame.size.width, 70 + JKPhotoCurrentHomeIndicatorHeight());
    
    self.selectedCountButton.frame = CGRectMake(CGRectGetMaxX(self.collectionView.frame) - 60, 10, 50, 50);
    
    self.bottomCollectionView.frame = CGRectMake(safeAreaInsets.left, 0, self.selectedCountButton.frame.origin.x - 10 - safeAreaInsets.left, 70);
    
    self.albumListView.frame = CGRectMake(self.albumListView.frame.origin.x, self.albumListView.frame.origin.y, self.collectionView.frame.size.width, self.albumListView.frame.size.height);
}

- (void)setupCollectionView{
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 70 - JKPhotoCurrentHomeIndicatorHeight()) collectionViewLayout:flowLayout];
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.alwaysBounceVertical = YES;
    collectionView.dataSource = self;
    collectionView.delegate = self;
    [self.view insertSubview:collectionView atIndex:0];
    self.collectionView = collectionView;
    
    SEL selector = NSSelectorFromString(@"setContentInsetAdjustmentBehavior:");
    
    if ([collectionView respondsToSelector:selector]) {
        
        IMP imp = [collectionView methodForSelector:selector];
        void (*func)(id, SEL, NSInteger) = (void *)imp;
        func(collectionView, selector, 2);
        
        // [tbView performSelector:@selector(setContentInsetAdjustmentBehavior:) withObject:@(2)];
    }
    
    // 注册cell
    [collectionView registerClass:[JKPhotoCollectionViewCell class] forCellWithReuseIdentifier:reuseID];
    
    UIView *bottomContentView = [[UIView alloc] init];
    bottomContentView.frame = CGRectMake(0, CGRectGetMaxY(collectionView.frame), self.view.frame.size.width, 70 + JKPhotoCurrentHomeIndicatorHeight());
    bottomContentView.backgroundColor = [UIColor colorWithRed:250.0 / 255.0 green:250.0 / 255.0 blue:250.0 / 255.0 alpha:1];
    [self.view addSubview:bottomContentView];
    _bottomContentView = bottomContentView;
    
    if (self.configuration.shouldSelectAll) {
        
        UIButton *selectAllButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
        selectAllButton.frame = CGRectMake(15, 10, 100, 50);
        selectAllButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [selectAllButton setTitle:@"全选" forState:(UIControlStateNormal)];
        
        [selectAllButton addTarget:self action:@selector(selectAllButtonClick:) forControlEvents:(UIControlEventTouchUpInside)];
        
        [bottomContentView addSubview:selectAllButton];
        _selectAllButton = selectAllButton;
        
    } else if (self.configuration.shouldBottomPreview) {
        
        // 底部的collectionView
        UICollectionViewFlowLayout *flowLayout2 = [[UICollectionViewFlowLayout alloc] init];
        flowLayout2.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        UICollectionView *bottomCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 70, 70) collectionViewLayout:flowLayout2];
        bottomCollectionView.backgroundColor = [UIColor clearColor];
        bottomCollectionView.alwaysBounceHorizontal = YES;
        bottomCollectionView.showsHorizontalScrollIndicator = NO;
        bottomCollectionView.dataSource = self;
        bottomCollectionView.delegate = self;
        bottomCollectionView.contentInset = UIEdgeInsetsMake(0, 5, 0, 0);
        [bottomContentView addSubview:bottomCollectionView];
        _bottomCollectionView = bottomCollectionView;
        
        // 注册cell
        [bottomCollectionView registerClass:[JKPhotoSelectedCollectionViewCell class] forCellWithReuseIdentifier:reuseIDSelected];
    }
    
    UIButton *selectedCountButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
    selectedCountButton.frame = CGRectMake(CGRectGetMaxX(self.collectionView.frame) - 65, 10, 50, 50);
    selectedCountButton.backgroundColor = JKPhotoSystemRedColor;
    selectedCountButton.layer.cornerRadius = 25;
    selectedCountButton.layer.masksToBounds = YES;
    [selectedCountButton setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
    [bottomContentView addSubview:selectedCountButton];
    self.selectedCountButton = selectedCountButton;
    
    [selectedCountButton addTarget:self action:@selector(done) forControlEvents:(UIControlEventTouchUpInside)];
    
    [self changeSelectedCount];
}

- (void)selectAllButtonClick:(UIButton *)button{
    
    BOOL isSelectAll = [button.currentTitle isEqualToString:@"全选"];
    
    [self.selectedAssetArray removeAllObjects];
    [self.selectedPhotoItems removeAllObjects];
    [self.selectedPhotosIdentifierCache removeAllObjects];
    
    if (isSelectAll) {
        
        [button setTitle:@"取消全选" forState:(UIControlStateNormal)];
        
        if (self.isAllPhotosAlbum && self.configuration.showTakePhotoIcon) {
            
            NSMutableArray *arrM = [NSMutableArray arrayWithArray:self.allPhotoItems];
            [arrM removeObjectAtIndex:0];
            
            self.selectedPhotoItems = arrM;
            
        } else {
            
            [self.selectedPhotoItems addObjectsFromArray:self.allPhotoItems];
        }
        
    } else {
        
        [button setTitle:@"全选" forState:(UIControlStateNormal)];
    }
    
    [self.allPhotoItems enumerateObjectsUsingBlock:^(JKPhotoItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.isShowCameraIcon) { return; }
        
        if (isSelectAll) {
            
            obj.isSelected = YES;
            
            [self.selectedPhotosIdentifierCache setObject:obj forKey:obj.assetLocalIdentifier];
            
            [self.selectedAssetArray addObject:obj.photoAsset];
            
        } else {
            
            obj.isSelected = NO;
        }
    }];
    
    [self changeSelectedCount];
    
    [self.collectionView reloadData];
    [self.bottomCollectionView reloadData];
}

#pragma mark - 加载数据
- (void)loadPhotoWithAlbumItem:(JKPhotoItem *)photoItem isReload:(BOOL)isReload{
    _currentAlbumItem = photoItem;
    
    [self.allPhotosIdentifierCache removeAllObjects];
    
    BOOL isLoadAllPhotos = [photoItem.albumLocalIdentifier isEqualToString:_albumListView.cameraRollItem.albumLocalIdentifier];
    
    NSMutableArray *photoItems = [JKPhotoManager getPhotoAssetsWithFetchResult:photoItem.albumFetchResult optionDict:(isLoadAllPhotos ? @{@"seletedCache" : self.selectedPhotosIdentifierCache} : nil) complete:^(NSDictionary *resultDict) {
        
        self.allPhotosIdentifierCache = resultDict[@"allCache"];
        
        if (isLoadAllPhotos) {
            
            self.selectedPhotoItems = [resultDict[@"seletedItems"] mutableCopy];
            self.selectedPhotosIdentifierCache = resultDict[@"seletedCache"];
        }
    }];
    
    if ([photoItems.firstObject isShowCameraIcon] == NO && self.configuration.showTakePhotoIcon) {
        
        JKPhotoItem *item1 = [[JKPhotoItem alloc] init];
        item1.isShowCameraIcon = YES;
        [photoItems insertObject:item1 atIndex:0];
    }
    
    self.allPhotoItems = photoItems;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        !self.albumListView.reloadCompleteBlock ? : self.albumListView.reloadCompleteBlock();
        self.albumListView.reloadCompleteBlock = nil;
        
        [self.collectionView reloadData];
        [self.bottomCollectionView reloadData];
        
        [self changeSelectedCount];
        
        if (!isReload) {
            
            [self.collectionView setContentOffset:CGPointMake(0, -self.collectionView.contentInset.top) animated:YES];
        }
    });
}

#pragma mark - collectionView数据源
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return (collectionView == self.bottomCollectionView) ? self.selectedPhotoItems.count : self.allPhotoItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    JKPhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:(collectionView == self.bottomCollectionView) ? reuseIDSelected : reuseID forIndexPath:indexPath];
    
    JKPhotoItem *item = (collectionView == self.bottomCollectionView) ? self.selectedPhotoItems[indexPath.row] : self.allPhotoItems[indexPath.item];
    
    item.isSelected = NO;
    
    if ([self.selectedPhotosIdentifierCache objectForKey:item.assetLocalIdentifier] != nil) {
        
        item.isSelected = YES;
    }
    
    cell.photoItem = item;
    
    [self solveSelectBlockWithCell:cell];
    
    return cell;
}

- (void)solveSelectBlockWithCell:(JKPhotoCollectionViewCell *)cell{
    
    __weak typeof(self) weakSelf = self;
    
    if (!cell.cameraButtonClickBlock) {
        
        [cell setCameraButtonClickBlock:^{
            
            NSLog(@"点击拍照");
            
            [weakSelf updateIconWithSourType:(UIImagePickerControllerSourceTypeCamera)];
        }];
    }
    
    if (!cell.selectBlock) {
        
        [cell setSelectBlock:^BOOL(BOOL selected, JKPhotoCollectionViewCell *currentCell) {
            
            if (selected) { // 已选中，表示要取消选中
                
                [weakSelf deSelectedPhotoWithCell:currentCell];
                
                return !selected;
            }
            
            if (weakSelf.configuration.maxSelectCount <= 0 ||
                weakSelf.selectedPhotoItems.count < weakSelf.configuration.maxSelectCount) {
                
                [weakSelf selectPhotoWithCell:currentCell];
                
                return !selected;
            }
            
            [weakSelf showMaxSelectCountTip];
            
            return NO;
        }];
    }
    
    if (!cell.deleteButtonClickBlock) {
        
        [cell setDeleteButtonClickBlock:^(JKPhotoCollectionViewCell *currentCell) {
            
            [weakSelf deleteSelectedPhotoWithCell:currentCell];
        }];
    }
}

#pragma mark - 点击拍照

- (void)updateIconWithSourType:(UIImagePickerControllerSourceType)sourceType{
    
    JKPhotoPickerMediaDataType type = [JKPhotoItem selectDataType];
    
    switch (type) {
        case JKPhotoPickerMediaDataTypeGif:
        {  // 仅选中gif时，不允许拍照
            
            UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:@"暂不支持gif拍摄" preferredStyle:(UIAlertControllerStyleAlert)];
            
            [alertVc addAction:[UIAlertAction actionWithTitle:@"知道了" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                
            }]];
            
            [self presentViewController:alertVc animated:YES completion:nil];
        }
            break;
        case JKPhotoPickerMediaDataTypePhotoLive:
        {
            
            UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:@"暂不支持livePhoto拍摄" preferredStyle:(UIAlertControllerStyleAlert)];
            
            [alertVc addAction:[UIAlertAction actionWithTitle:@"知道了" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                
            }]];
            
            [self presentViewController:alertVc animated:YES completion:nil];
        }
            break;
        case JKPhotoPickerMediaDataTypeUnknown:
        {
            
        }
            break;
            
        default:
        {
            [JKPhotoManager checkCameraAccessWithPresentVc:self finished:^(BOOL isAccessed) {
                
                if (!isAccessed) { return; }
                
                if ([JKPhotoItem selectDataType] == JKPhotoPickerMediaDataTypeVideo) {
                    
                    [JKPhotoManager checkMicrophoneAccessWithPresentVc:self finished:^(BOOL isAccessed) {
                        
                        if (!isAccessed) {
                            
                            UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:@"当前程序未获得麦克风权限，会导致拍摄没有声音。是否打开？由于iOS系统原因，设置麦克风权限会导致app崩溃，请知晓。" preferredStyle:(UIAlertControllerStyleAlert)];
                            
                            [alertVc addAction:[UIAlertAction actionWithTitle:@"无声拍摄" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                                
                                [self showImagePickerControllerWithSourceType:sourceType];
                            }]];
                            
                            [alertVc addAction:[UIAlertAction actionWithTitle:@"去打开" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                                
                                // 打开本程序对应的权限设置
                                [[UIApplication sharedApplication]openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                            }]];
                            
                            [self presentViewController:alertVc animated:YES completion:nil];
                            
                            return;
                        }
                        
                        [self showImagePickerControllerWithSourceType:sourceType];
                    }];
                    return;
                }
                
                [self showImagePickerControllerWithSourceType:sourceType];
            }];
        }
            break;
    }
    
    
}


/**
 * 使用UIImagePicker
 * presentVc : 由哪个控制器present出来，传nil则由根控制器弹出
 * dataType : 要选择的数据类型 仅支持JKPhotoPickerMediaDataTypeStaticImage和JKPhotoPickerMediaDataTypeVideo
 * allowsEditing : 是否允许编辑
 * completeHandler : 选择完成的回调
 */
+ (void)showUIImagePickerWithConfig:(void(^)(UIImagePickerController *imagPicker))config presentVc:(UIViewController *)presentVc dataType:(JKPhotoPickerMediaDataType)dataType allowsEditing:(BOOL)allowsEditing completeHandler:(void(^)(UIImage *image))completeHandler{
    
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [JKPhotoItem setSelectDataType:dataType];
    
    switch (dataType) {
        case JKPhotoPickerMediaDataTypeStaticImage:
        {
            [JKPhotoManager checkCameraAccessWithPresentVc:presentVc finished:^(BOOL isAccessed) {
                
                if (!isAccessed) { return; }
                
                [self showWithConfig:config presentVc:presentVc sourceType:sourceType allowsEditing:allowsEditing completeHandler:completeHandler];
            }];
        }
            break;
        case JKPhotoPickerMediaDataTypeVideo:
        {
            sourceType = UIImagePickerControllerSourceTypeCamera;
            
            [JKPhotoManager checkCameraAccessWithPresentVc:presentVc finished:^(BOOL isAccessed) {
                
                if (!isAccessed) { return; }
                
            }];
        }
            break;
            
        default:
            return;
            break;
    }
}

+ (void)showWithConfig:(void(^)(UIImagePickerController *imagPicker))config presentVc:(UIViewController *)presentVc sourceType:(UIImagePickerControllerSourceType)sourceType allowsEditing:(BOOL)allowsEditing completeHandler:(void(^)(UIImage *image))completeHandler{
    
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = sourceType;
    imagePicker.allowsEditing = allowsEditing;
    !config ? : config(imagePicker);
}

- (void)showImagePickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType{
    
    JKPhotoPickerMediaDataType type = [JKPhotoItem selectDataType];
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = sourceType;
    
    switch (type) {
        case JKPhotoPickerMediaDataTypeUnknown:
            
            break;
        case JKPhotoPickerMediaDataTypeStaticImage:
            
            imagePicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString*)kUTTypeImage, nil];
            break;
        case JKPhotoPickerMediaDataTypeImageIncludeGif:
            
            imagePicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString*)kUTTypeImage, nil];
            
            break;
        case JKPhotoPickerMediaDataTypeVideo:
            
            imagePicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString*)kUTTypeMovie, nil];
            
            // 设置摄像图像品质
            imagePicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
            
            // 设置最长摄像时间
            imagePicker.videoMaximumDuration = INFINITY;
            
            // 允许用户进行编辑
            imagePicker.allowsEditing = YES;
            
            break;
        case JKPhotoPickerMediaDataTypePhotoLive:
            
            if (@available(iOS 9.1, *)) {
                
                imagePicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString*)kUTTypeLivePhoto, (NSString*)kUTTypeImage, nil];
            }
            
            break;
            
        default:
            break;
    }
    
    //    imagePicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString*)kUTTypeImage, nil];
    
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

#pragma mark - 选中照片

- (void)checkSelectAllButton{
    
    NSInteger totalCount = self.allPhotoItems.count - ((self.isAllPhotosAlbum && self.configuration.showTakePhotoIcon) ? 1 : 0);
    
    NSString *title = (self.selectedPhotoItems.count == totalCount) ? @"取消全选" : @"全选";
    
    [self.selectAllButton setTitle:title forState:(UIControlStateNormal)];
}

- (void)selectPhotoWithCell:(JKPhotoCollectionViewCell *)currentCell {
    
    currentCell.photoItem.isSelected = YES;
    
    [self.selectedPhotosIdentifierCache setObject:currentCell.photoItem forKey:currentCell.photoItem.assetLocalIdentifier];
    
    [self.selectedPhotoItems addObject:currentCell.photoItem];
    
    [self.selectedAssetArray addObject:currentCell.photoItem.photoAsset];
    
    [self checkSelectAllButton];
    
    [self.bottomCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.selectedPhotoItems.count - 1 inSection:0]]];
    //                [weakSelf.bottomCollectionView reloadData];
    
    [self.bottomCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedPhotoItems.count - 1 inSection:0] atScrollPosition:(UICollectionViewScrollPositionCenteredHorizontally) animated:YES];
    
    [self changeSelectedCount];
    
    NSLog(@"选中了%ld个", (unsigned long)self.selectedPhotoItems.count);
}

#pragma mark - 最大选择数量提示

- (void)showMaxSelectCountTip{
    
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:[NSString stringWithFormat:@"最多选择%ld张图片哦~~", (unsigned long)self.configuration.maxSelectCount] preferredStyle:(UIAlertControllerStyleAlert)];
    
    [alertVc addAction:[UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:nil]];
    
    [self presentViewController:alertVc animated:YES completion:nil];
}

#pragma mark - 取消选中

- (void)deSelectedPhotoWithCell:(JKPhotoCollectionViewCell *)currentCell {
    
    currentCell.photoItem.isSelected = NO;
    
    NSIndexPath *indexPath = nil;
    
    JKPhotoItem *itm = [self.selectedPhotosIdentifierCache objectForKey:currentCell.photoItem.assetLocalIdentifier];
    
    if (itm == nil) {
        
        for (JKPhotoItem *it in self.selectedPhotoItems) {
            
            if ([it.assetLocalIdentifier isEqualToString:currentCell.photoItem.assetLocalIdentifier]) {
                
                itm = it;
                
                break;
            }
        }
        
    }else{
        
        [self.selectedPhotosIdentifierCache removeObjectForKey:itm.assetLocalIdentifier];
    }
    
    itm.isSelected = NO;
    
    indexPath = [NSIndexPath indexPathForItem:[self.selectedPhotoItems indexOfObject:itm] inSection:0];
    
    if (indexPath != nil && indexPath.item < self.allPhotoItems.count) {
        
        [UIView animateWithDuration:0.25 animations:^{
            
            [self.bottomCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:(UICollectionViewScrollPositionCenteredHorizontally) animated:false];
            
        } completion:^(BOOL finished) {
            
            JKPhotoCollectionViewCell *bottomCell = (JKPhotoCollectionViewCell *)[self.bottomCollectionView cellForItemAtIndexPath:indexPath];
            
            [UIView animateWithDuration:0.25 animations:^{
                
                bottomCell.contentView.transform = CGAffineTransformMakeScale(0.001, 0.001);
                bottomCell.contentView.alpha = 0;
                
            } completion:^(BOOL finished) {
                
                bottomCell.contentView.hidden = YES;
                bottomCell.contentView.alpha = 1;
                bottomCell.contentView.transform = CGAffineTransformIdentity;
                
                if ([self.selectedPhotoItems containsObject:itm]) {
                    
                    [self.selectedPhotoItems removeObject:itm];
                    
                    if ([self.selectedAssetArray containsObject:itm.photoAsset]) {
                        
                        [self.selectedAssetArray removeObject:itm.photoAsset];
                    }
                    
                    [self checkSelectAllButton];
                    
                    [self.bottomCollectionView deleteItemsAtIndexPaths:@[indexPath]];
                }
                
                [self changeSelectedCount];
                NSLog(@"取消选中,当前选中了%ld个", (unsigned long)self.selectedPhotoItems.count);
            }];
        }];
        
        return;
    }
    
    if ([self.selectedPhotoItems containsObject:itm]) {
        
        [self.selectedPhotoItems removeObject:itm];
        
        if ([self.selectedAssetArray containsObject:itm.photoAsset]) {
            
            [self.selectedAssetArray removeObject:itm.photoAsset];
        }
        
        [self checkSelectAllButton];
    }
    
    [self.collectionView reloadData];
    
    [self.bottomCollectionView reloadData];
    
    [self changeSelectedCount];
    NSLog(@"取消选中,当前选中了%ld个", (unsigned long)self.selectedPhotoItems.count);
}

#pragma mark - 底部删除选中的照片

- (void)deleteSelectedPhotoWithCell:(JKPhotoCollectionViewCell *)currentCell{
    
    currentCell.photoItem.isSelected = NO;
    
    [self.selectedPhotosIdentifierCache removeObjectForKey:currentCell.photoItem.assetLocalIdentifier];
    
    NSIndexPath *indexPath = [self.bottomCollectionView indexPathForCell:currentCell];
    
    if (indexPath.item < self.selectedPhotoItems.count) {
        
        [self.selectedPhotoItems removeObject:currentCell.photoItem];
        
        if ([self.selectedAssetArray containsObject:currentCell.photoItem.photoAsset]) {
            
            [self.selectedAssetArray removeObject:currentCell.photoItem.photoAsset];
        }
        
        [self checkSelectAllButton];
        
        [self.bottomCollectionView deleteItemsAtIndexPaths:@[indexPath]];
        
    }else{
        
        [self.selectedPhotoItems removeObject:currentCell.photoItem];
        
        if ([self.selectedAssetArray containsObject:currentCell.photoItem.photoAsset]) {
            
            [self.selectedAssetArray removeObject:currentCell.photoItem.photoAsset];
        }
        
        [self checkSelectAllButton];
        
        [self.collectionView performBatchUpdates:^{
            
            [self.bottomCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            
        } completion:^(BOOL finished) {
            
            [self changeSelectedCount];
        }];
    }
    
    // 在全部照片中取消选中
    JKPhotoItem *itm = [self.allPhotosIdentifierCache objectForKey:currentCell.photoItem.assetLocalIdentifier];
    
    itm.isSelected = NO;
    
    if (itm != nil && [self.allPhotoItems containsObject:itm]) {
        
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self.allPhotoItems indexOfObject:itm] inSection:0]]];
        
        [self changeSelectedCount];
        
    }else{
        
        [self.collectionView performBatchUpdates:^{
            
            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            
        } completion:^(BOOL finished) {
            
            [self changeSelectedCount];
        }];
    }
}

- (void)changeSelectedCount{
    
    // 旋转动画
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
    rotationAnimation.toValue = @(M_PI * 2);
    rotationAnimation.repeatCount = 1;
    rotationAnimation.duration = 0.5;
    
    [self.selectedCountButton.layer addAnimation:rotationAnimation forKey:nil];
    
    if (self.configuration.maxSelectCount <= 0) {
        
        [self.selectedCountButton setTitle:[NSString stringWithFormat:@"%ld", (unsigned long)self.selectedPhotoItems.count] forState:(UIControlStateNormal)];
        
        return;
    }
    
    [self.selectedCountButton setTitle:[NSString stringWithFormat:@"%ld/%ld", (unsigned long)self.selectedPhotoItems.count, (unsigned long)self.configuration.maxSelectCount] forState:(UIControlStateNormal)];
}

#pragma mark - collectionView代理

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (collectionView == self.bottomCollectionView) {
        
        return CGSizeMake(60, 70);
    }
    
    CGFloat WH = (collectionView.frame.size.width - (columnCount - 1)) / columnCount;
    
    return  CGSizeMake(WH, WH);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    
    return 1;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    
    return 1;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    JKPhotoCollectionViewCell *cell = (JKPhotoCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"allPhotos"] = self.allPhotoItems;
    dict[@"selectedItems"] = self.selectedPhotoItems;
    dict[@"selectedAssets"] = self.selectedAssetArray;
    
    dict[@"allPhotosCache"] = self.allPhotosIdentifierCache;
    dict[@"selectedItemsCache"] = self.selectedPhotosIdentifierCache;
    dict[@"isAllPhotosAlbum"] = @(self.isAllPhotosAlbum);
    dict[@"configuration"] = self.configuration;
    
    dict[@"imageView"] = cell.photoImageView;
    dict[@"collectionView"] = collectionView;
    dict[@"indexPath"] = (collectionView == self.collectionView && (self.isAllPhotosAlbum && self.configuration.showTakePhotoIcon)) ? [NSIndexPath indexPathForItem:indexPath.item - 1 inSection:indexPath.section] : indexPath;
    dict[@"isSelectedCell"] = @([cell isMemberOfClass:[JKPhotoSelectedCollectionViewCell class]]);
    dict[@"isShowSelectedPhotos"] = @(collectionView == self.bottomCollectionView);
    
    [JKPhotoBrowserViewController showWithViewController:self dataDict:dict completion:^(NSArray <JKPhotoItem *> *seletedPhotos, NSArray<PHAsset *> *selectedAssetArray, NSArray <NSIndexPath *> *indexPaths, NSMutableDictionary *selectedPhotosIdentifierCache) {
        
        NSInteger preCount = self.selectedPhotoItems.count;
        NSInteger currentCount = seletedPhotos.count;
        
        self.selectedPhotosIdentifierCache = selectedPhotosIdentifierCache;
        
        JKPhotoItem *preLastItem = nil;
        
        if (preCount > 0) {
            
            preLastItem = self.selectedPhotoItems.lastObject;
        }
        
        [self.selectedPhotoItems removeAllObjects];
        [self.selectedPhotoItems addObjectsFromArray:seletedPhotos];
        
        [self.selectedAssetArray removeAllObjects];
        [self.selectedAssetArray addObjectsFromArray:selectedAssetArray];
        
        [self checkSelectAllButton];
        
        [self.collectionView performBatchUpdates:^{
            
            [self.collectionView reloadItemsAtIndexPaths:indexPaths];
            
        } completion:^(BOOL finished) {
            
            self.isPhotoBrowserPresented = NO;
            
            if (self.isReloadAfterDismiss) {
                
                self.isReloadAfterDismiss = NO;
                
                [self.albumListView reloadAlbum];
            }
        }];
        
        [self.bottomCollectionView performBatchUpdates:^{
            
            [self.bottomCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            
        } completion:^(BOOL finished) {
            
            if (self.selectedPhotoItems.count > 0 && (preCount != currentCount || ![preLastItem.assetLocalIdentifier isEqualToString:[self.selectedPhotoItems.lastObject assetLocalIdentifier]])) {
                
                [self.bottomCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedPhotoItems.count - 1 inSection:0] atScrollPosition:(UICollectionViewScrollPositionCenteredHorizontally) animated:YES];
            }
        }];
        
        [self changeSelectedCount];
        
        /*
         dispatch_async(dispatch_get_global_queue(0, 0), ^{
         
         NSMutableArray *indexArr = [NSMutableArray array];
         
         for (JKPhotoItem *itm in self.selectedPhotos) {
         
         if (itm.isSelected) { continue; }
         
         [indexArr addObject:[NSIndexPath indexPathForItem:[self.allPhotoItems indexOfObject:itm] inSection:0]];
         }
         
         [self.selectedPhotos removeAllObjects];
         
         for (JKPhotoItem *itm in seletedPhotos) {
         
         [self.selectedPhotos addObject:itm];
         
         [indexArr addObject:[NSIndexPath indexPathForItem:[self.allPhotoItems indexOfObject:itm] inSection:0]];
         }
         
         dispatch_async(dispatch_get_main_queue(), ^{
         
         [self.collectionView performBatchUpdates:^{
         
         [self.collectionView reloadItemsAtIndexPaths:indexArr];
         
         } completion:^(BOOL finished) {
         
         }];
         
         [self.bottomCollectionView performBatchUpdates:^{
         
         [self.bottomCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
         
         } completion:^(BOOL finished) {
         
         if (self.selectedPhotos.count > 0) {
         
         [self.bottomCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedPhotos.count - 1 inSection:0] atScrollPosition:(UICollectionViewScrollPositionCenteredHorizontally) animated:YES];
         }
         }];
         
         [self changeSelectedCount];
         });
         }); */
    }];
    
    self.isPhotoBrowserPresented = YES;
}

#pragma mark - <UIImagePickerControllerDelegate>

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
    // 获取媒体类型
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    // 判断是静态图像还是视频
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) { // 图片
        
        // 获取用户编辑之后的图像
        UIImage *orinalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        
        // 将该图像保存到媒体库中
        UIImageWriteToSavedPhotosAlbum(orinalImage, self,@selector(image:didFinishSavingWithError:contextInfo:), NULL);
        
    }else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) { // 视频
        
        // 获取视频文件的url
        NSURL *mediaURL = [info objectForKey:UIImagePickerControllerMediaURL];
        
        [self saveVideoToAlbumWithURL:mediaURL completionHandler:^(BOOL success, NSError *error) {
            
            if (success) {
                
                [self reloadAfterTakePhoto];
            }
        }];
        
    } else if (@available(iOS 9.1, *)) {
        
        if ([mediaType isEqualToString:(NSString *)kUTTypeLivePhoto]) { // livePhoto
            
            // 获取视频文件的url
            NSURL *imageURL = [info objectForKey:UIImagePickerControllerReferenceURL];
            NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
            
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                
                PHAssetCreationRequest *req = [PHAssetCreationRequest creationRequestForAsset];
                
                [req addResourceWithType:PHAssetResourceTypePhoto fileURL:imageURL options:nil];
                [req addResourceWithType:PHAssetResourceTypePairedVideo fileURL:videoURL options:nil];
                
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                
                if (success) {
                    
                    NSLog(@"已保存至相册");
                    
                    [self reloadAfterTakePhoto];
                    
                }else{
                    
                    NSLog(@"保存失败");
                }
            }];
            
        }
    } else {
        // Fallback on earlier versions
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveVideoToAlbumWithURL:(NSURL *)URL
              completionHandler:(void(^)(BOOL success, NSError *error))completionHandler{
    
    if (!URL) { !completionHandler ? : completionHandler(NO, nil); return; }
    
    [JKPhotoSelectCompleteView saveMediaToAlbumWithURLArray:@[URL] isVideo:YES completionHandler:completionHandler];
}

// Adds a photo to the saved photos album.  The optional completionSelector should have the form:
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (error) {
        return;
    }
    
    [self reloadAfterTakePhoto];
}

- (void)reloadAfterTakePhoto{
    
    __weak typeof(self) weakSelf = self;
    
    if (!self.albumListView.reloadCompleteBlock) {
        
        [self.albumListView setReloadCompleteBlock:^{
            
            if (weakSelf.configuration.maxSelectCount > 0 &&
                weakSelf.selectedPhotoItems.count >= weakSelf.configuration.maxSelectCount) {
                return;
            }
            
            JKPhotoItem *itm = weakSelf.allPhotoItems[1];
            itm.isSelected = YES;
            
            [weakSelf.selectedPhotoItems addObject:itm];
            [weakSelf.selectedPhotosIdentifierCache setObject:itm forKey:itm.assetLocalIdentifier];
            
            [weakSelf.selectedAssetArray addObject:itm.photoAsset];
            
            [self checkSelectAllButton];
            
            //        [weakSelf.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:1 inSection:0]]];
            [weakSelf.bottomCollectionView reloadData];
            [weakSelf changeSelectedCount];
        }];
    }
    
    [self.albumListView reloadAlbum];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    
    NSLog(@"%d, %s",__LINE__, __func__);
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
