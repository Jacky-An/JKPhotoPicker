//
//  JKPhotoPickerViewController.m
//  JKPhotoPicker
//
//  Created by albert on 2016/12/21.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import "JKPhotoPickerViewController.h"
#import "JKPhotoSelectedCollectionViewCell.h"
#import "JKPhotoAlbumItem.h"
#import "JKPhotoItem.h"
#import "JKPhotoManager.h"
#import "JKPhotoPickerEngine.h"
#import "JKPhotoAlbumListTableView.h"
#import "JKPhotoTitleButton.h"
#import "JKPhotoBrowserViewController.h"
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>

#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "JKPhotoResourceManager.h"
#import "JKPhotoConfiguration.h"
#import "JKPhotoSelectCompleteView.h"
#import "JKPhotoResultModel.h"

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
@property (nonatomic, weak) JKPhotoAlbumListTableView *albumListView;

/** titleButton */
@property (nonatomic, weak) JKPhotoTitleButton *titleButton;

/** 监听点击完成的block */
@property (nonatomic, copy) void(^completeHandler)(NSArray *photoItems, NSArray *selectedAssetArray) ;

/** 当前选中相册所有照片的identifier映射缓存 */
@property (nonatomic, strong) NSCache *iemCache;

/** 所有的图片数组 */
@property (nonatomic, strong) NSMutableArray *itemArray;

/** 选中的照片标识和item的映射缓存 */
@property (nonatomic, strong) NSCache *selectedItemCache;

/** 选中的图片数组 */
@property (nonatomic, strong) NSMutableArray *selectedItemArray;

/** 选中的asset数组 */
@property (nonatomic, strong) NSMutableArray *selectedAssetArray;

/** 是否present了图片浏览器 */
@property (nonatomic, assign) BOOL isPhotoBrowserPresented;

/** 当前是否是所有照片相册 */
@property (nonatomic, assign) BOOL isAllPhotosAlbum;

/** configuration */
@property (nonatomic, strong) JKPhotoConfiguration *configuration;

/** currentAlbumItem */
@property (nonatomic, strong) JKPhotoAlbumItem *currentAlbumItem;

/** currentScreenWidth */
@property (nonatomic, assign) CGFloat currentScreenWidth;

/** browserVC */
@property (nonatomic, weak) JKPhotoBrowserViewController *browserVC;

/** indicatorView */
@property (nonatomic, weak) UIActivityIndicatorView *indicatorView;
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
    [vc.selectedItemArray removeAllObjects];
    [vc.selectedItemArray addObjectsFromArray:config.seletedItems];
    
    [vc.selectedAssetArray removeAllObjects];
    
    for (JKPhotoItem *itm in vc.selectedItemArray) {
        
        [vc.selectedItemCache setObject:itm forKey:itm.assetLocalIdentifier];
        
        [vc.selectedAssetArray addObject:itm.photoAsset];
    }
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [config.presentViewController presentViewController:nav animated:YES completion:^{
        
        if (config.takePhotoFirst) {
            
            [vc updateIconWithSourType:(UIImagePickerControllerSourceTypeCamera)];
        }
    }];
}

+ (void)initialize{
    [[UIView appearance] setExclusiveTouch:YES];
}

#pragma mark
#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance{
    NSLog(@"%@", changeInstance);
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        JKPhotoAlbumItem *previousAlbumItem = self.currentAlbumItem;
        
        // 更新相册列表
        [self.albumListView reloadAlbumList];
        
        // 标识不一致，表示当前相册被删除，已自动切换相册
        if (![previousAlbumItem.localIdentifier isEqualToString:self.albumListView.currentAlbumItem.localIdentifier]) {
            
            if (self.browserVC) {
                
                [self.browserVC dismissViewControllerAnimated:NO completion:^{
                    
                }];
            }
            
            return;
        }
        
        if (!changeInstance) { return; }
        
        //PHObjectChangeDetails *albumChanges = [changeInstance changeDetailsForObject:self.currentAlbumItem.assetCollection];
        
        PHFetchResultChangeDetails *changes = [changeInstance changeDetailsForFetchResult:previousAlbumItem.fetchResult];
        
        self.currentAlbumItem = self.albumListView.currentAlbumItem;
        
        //PHAssetCollection *coll = [albumChanges objectAfterChanges];
        
        //self.currentAlbumItem.assetCollection = [albumChanges objectAfterChanges];
        
        NSString *albumTitle = [self.currentAlbumItem.assetCollection localizedTitle];
        
        if (albumTitle) {
            
            [self.titleButton setTitle:[albumTitle stringByAppendingString:@"  "] forState:(UIControlStateNormal)];
        }
        
        if ([changes hasIncrementalChanges]) {
            
            NSIndexSet *removed = [changes removedIndexes];
            
            /*
            [removed enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                
                NSLog(@"removed-->%zd", idx);
            }]; //*/
            
            NSIndexSet *inserted = [changes insertedIndexes];
            
            /*
            [inserted enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                
                NSLog(@"inserted-->%zd", idx);
            }]; //*/
            
            NSIndexSet *changed = [changes changedIndexes];
            
            /*
            [changed enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                
                NSLog(@"changed-->%zd", idx);
            }]; //*/
            
            NSArray *reversedArray = nil;
            
            BOOL isCameraRollAlbum = (self.currentAlbumItem == self.albumListView.cameraRollAlbumItem);
            
            if (removed.count <=0 &&
                inserted.count <= 0 &&
                changed.count > 0) {
                
                reversedArray = [self.itemArray reverseObjectEnumerator].allObjects;
                
                NSInteger reversedArrayCount = reversedArray.count;
                
                PHFetchResult *fetchResult = [changes fetchResultAfterChanges];
                
                NSInteger fetchResultCount = fetchResult.count;
                
                NSMutableArray *indexPathArray = [NSMutableArray array];
                
                [changed enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                    
                    PHAsset *asset = nil;
                    
                    if (idx < fetchResultCount) {
                        
                        asset = [fetchResult objectAtIndex:idx];
                    }
                    
                    if (!asset) { return; }
                    
                    if (idx < reversedArrayCount) {
                        
                        JKPhotoItem *item = [reversedArray objectAtIndex:idx];
                        
                        if (!item) { return; }
                        
                        JKPhotoItem *replacedItem = nil;
                        
                        if ([self.itemArray containsObject:item]) {
                            
                            NSInteger realIndex = [self.itemArray indexOfObject:item];
                            
                            replacedItem = [[JKPhotoItem alloc] init];
                            replacedItem.photoAsset = asset;
                            replacedItem.currentIndexPath = [NSIndexPath indexPathForItem:realIndex inSection:0];
                            
                            [indexPathArray addObject:[NSIndexPath indexPathForItem:realIndex inSection:0]];
                            
                            [self.itemArray replaceObjectAtIndex:realIndex withObject:replacedItem];
                            
                            if ([self.selectedAssetArray containsObject:item.photoAsset]) {
                                
                                NSInteger realIndex = [self.selectedAssetArray indexOfObject:item.photoAsset];
                                
                                [self.selectedAssetArray replaceObjectAtIndex:realIndex withObject:replacedItem.photoAsset];
                            }
                            
                            if (replacedItem.assetLocalIdentifier) {

                                [self.iemCache setObject:replacedItem forKey:replacedItem.assetLocalIdentifier];
                                
                                if ([self.selectedItemArray containsObject:item]) {
                                    
                                    realIndex = [self.selectedItemArray indexOfObject:item];
                                    
                                    [self.selectedItemArray replaceObjectAtIndex:realIndex withObject:replacedItem];

                                    [self.selectedItemCache setObject:replacedItem forKey:replacedItem.assetLocalIdentifier];
                                }
                            }
                        }
                    }
                    
                    [self.collectionView performBatchUpdates:^{
                        
                        [self.collectionView reloadItemsAtIndexPaths:indexPathArray];
                        
                    } completion:^(BOOL finished) {
                        
                    }];
                    
                    [self.bottomCollectionView performBatchUpdates:^{
                     
                        [self.bottomCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
                        
                    } completion:^(BOOL finished) {
                        
                    }];
                    
                    NSLog(@"changed-->%zd", idx);
                }];
                
                return;
            }
            
            if (isCameraRollAlbum) {
                
                [self loadPhotoWithAlbumItem:self.currentAlbumItem isReload:YES];
                
                return;
            }
            
            reversedArray = [self.itemArray reverseObjectEnumerator].allObjects;
            
            NSInteger oldCount = reversedArray.count;
            
            if (removed.count > 0) {
                
                [removed enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                    
                    if (idx >= oldCount) { return; }
                    
                    JKPhotoItem *removedItem = [reversedArray objectAtIndex:idx];
                    
                    if (!removedItem.assetLocalIdentifier) { return; }
                    
                    JKPhotoItem *item = [self.selectedItemCache objectForKey:removedItem.assetLocalIdentifier];
                    
                    if ([self.selectedAssetArray containsObject:item.photoAsset]) {
                        
                        [self.selectedAssetArray removeObject:item.photoAsset];
                    }
                    
                    if (item && [self.selectedItemArray containsObject:item]) {
                        
                        [self.selectedItemArray removeObject:item];
                        
                        [self.selectedItemCache removeObjectForKey:removedItem.assetLocalIdentifier];
                    }
                }];
            }
            
            [self loadPhotoWithAlbumItem:self.currentAlbumItem isReload:YES];
            
            /*
            [self.collectionView performBatchUpdates:^{
                
                BOOL isLoadAllPhotos = 1;//[self.currentAlbumItem.localIdentifier isEqualToString:self.albumListView.cameraRollAlbumItem.localIdentifier];
                
                NSInteger count = self.itemArray.count;
                
                NSMutableArray *arrM = [NSMutableArray array];
                
                NSIndexSet *removed = [changes removedIndexes];
                
                if (removed.count > 0) {
                    
                    [arrM removeAllObjects];
                    
                    [removed enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                        
                        [arrM addObject:[NSIndexPath indexPathForItem:(count - 1 - idx + (isLoadAllPhotos ? 1 : 0)) inSection:0]];
                    }];
                    
                    [self.collectionView deleteItemsAtIndexPaths:arrM];
                }
                
                NSIndexSet *inserted = [changes insertedIndexes];
                
                if (inserted.count > 0) {
                    
                    [arrM removeAllObjects];
                    
                    [inserted enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                        
                        [arrM addObject:[NSIndexPath indexPathForItem:(count - 1 - idx + (isLoadAllPhotos ? 1 : 0)) inSection:0]];
                    }];
                    
                    [self.collectionView insertItemsAtIndexPaths:arrM];
                }
                
                NSIndexSet *changed = [changes changedIndexes];
                
                if (changed.count > 0) {
                    
                    [arrM removeAllObjects];
                    
                    [changed enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                        
                        [arrM addObject:[NSIndexPath indexPathForItem:(count - 1 - idx + (isLoadAllPhotos ? 1 : 0)) inSection:0]];
                    }];
                    
                    [self.collectionView reloadItemsAtIndexPaths:arrM];
                }
                
                [changes enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
                    
                    [self.collectionView moveItemAtIndexPath:[NSIndexPath indexPathForItem:fromIndex inSection:0] toIndexPath:[NSIndexPath indexPathForItem:toIndex inSection:0]];
                }];
                
            } completion:^(BOOL finished) {
                
            }]; //*/
            
        } else {
            
            //[self.collectionView reloadData];
        }
    });
}

#pragma mark - 懒加载
- (NSMutableArray *)itemArray{
    if (!_itemArray) {
        _itemArray = [NSMutableArray array];
    }
    return _itemArray;
}

- (NSMutableArray *)selectedItemArray{
    if (!_selectedItemArray) {
        _selectedItemArray = [NSMutableArray array];
    }
    return _selectedItemArray;
}

- (NSMutableArray *)selectedAssetArray{
    if (!_selectedAssetArray) {
        _selectedAssetArray = [NSMutableArray array];
    }
    return _selectedAssetArray;
}

- (NSCache *)selectedItemCache{
    if (!_selectedItemCache) {
        _selectedItemCache = [[NSCache alloc] init];//[NSMutableDictionary dictionary];//;
    }
    return _selectedItemCache;
}

- (JKPhotoAlbumListTableView *)albumListView{
    if (!_albumListView) {
        JKPhotoAlbumListTableView *albumListTableView = [[JKPhotoAlbumListTableView alloc] init];
        albumListTableView.navigationController = self.navigationController;
        albumListTableView.hidden = YES;
        [self.view addSubview:albumListTableView];
        _albumListView = albumListTableView;
        
        __weak typeof(self) weakSelf = self;
        
        [albumListTableView setAlbumListDidShowHandler:^{
            
            weakSelf.titleButton.selected = YES;
        }];
        
        [albumListTableView setAlbumListDidDismissHandler:^{
            
            weakSelf.titleButton.selected = NO;
        }];
        
#pragma mark - 选中相册
        [albumListTableView setDidselectAlbumHandler:^(JKPhotoAlbumItem *albumItem, BOOL isReload) {
            
            [weakSelf.titleButton setTitle:[albumItem.albumTitle stringByAppendingString:@"  "] forState:(UIControlStateNormal)];
            
            weakSelf.currentAlbumItem = albumItem;
            
            weakSelf.titleButton.hidden = NO;
            weakSelf.isAllPhotosAlbum = [albumItem.localIdentifier isEqualToString:weakSelf.albumListView.cameraRollAlbumItem.localIdentifier];
            
            if (weakSelf.configuration.shouldSelectAll) {
                
//                [weakSelf.selectedItemArray removeAllObjects];
//                [weakSelf.selectedAssetArray removeAllObjects];
//                [weakSelf.selectedItemCache removeAllObjects];
                
                //[weakSelf.selectAllButton setTitle:@"全选" forState:(UIControlStateNormal)];
            }
            
            [weakSelf loadPhotoWithAlbumItem:albumItem isReload:isReload];
        }];
    }
    return _albumListView;
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
    self.view.backgroundColor = JKPhotoAdaptColor([UIColor whiteColor], [UIColor blackColor]);
    
    _isAllPhotosAlbum = YES;
    
    [self setupNav];
    
    [self setupCollectionView];
    
    UIActivityIndicatorViewStyle style = UIActivityIndicatorViewStyleGray;
    
    if (@available(iOS 13.0, *)) {
        
        style = UIActivityIndicatorViewStyleMedium;
    }
    
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
    indicatorView.center = self.view.center;
    [self.view addSubview:indicatorView];
    _indicatorView = indicatorView;
    
    [self albumListView];
}

- (void)setupNav{
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:(UIBarButtonItemStylePlain) target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItems = @[leftItem];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:(UIBarButtonItemStylePlain) target:self action:@selector(done)];
    self.navigationItem.rightBarButtonItems = @[rightItem];
    
    JKPhotoTitleButton *titleButton = [JKPhotoTitleButton buttonWithType:(UIButtonTypeCustom)];
    titleButton.hidden = YES;
    titleButton.frame = CGRectMake(0, 0, 200, 40);
    [titleButton setTitleColor:JKPhotoAdaptColor([UIColor blackColor], [UIColor whiteColor]) forState:(UIControlStateNormal)];
    [titleButton setTitle:@" " forState:(UIControlStateNormal)];
    self.navigationItem.titleView = titleButton;
    self.titleButton = titleButton;
    
    [self updateNavButton];
    
    [titleButton addTarget:self action:@selector(titleViewClick:) forControlEvents:(UIControlEventTouchUpInside)];
    
    NSDictionary *attrDict = @{NSFontAttributeName : [UIFont systemFontOfSize:15], NSForegroundColorAttributeName : JKPhotoAdaptColor([UIColor blackColor], [UIColor whiteColor])};
    
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

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self updateNavButton];
}

- (void)updateNavButton{
    
    BOOL isLight = YES;
    
    if (@available(iOS 13.0, *)) {
        
        isLight = (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight);
    }
    
    if (isLight) {
        
        [self.titleButton setImage:[JKPhotoResourceManager jk_imageNamed:@"arrow_down@3x"] forState:(UIControlStateNormal)];
        [self.titleButton setImage:[JKPhotoResourceManager jk_imageNamed:@"arrow_up@3x"] forState:(UIControlStateSelected)];
        [self.titleButton setImage:[JKPhotoResourceManager jk_imageNamed:@"arrow_up@3x"] forState:(UIControlStateHighlighted | UIControlStateSelected)];
        
        return;
    }
    
    [self.titleButton setImage:[JKPhotoResourceManager jk_imageNamed:@"arrow_down_white@3x"] forState:(UIControlStateNormal)];
    [self.titleButton setImage:[JKPhotoResourceManager jk_imageNamed:@"arrow_up_white@3x"] forState:(UIControlStateSelected)];
    [self.titleButton setImage:[JKPhotoResourceManager jk_imageNamed:@"arrow_up_white@3x"] forState:(UIControlStateHighlighted | UIControlStateSelected)];
}

- (void)titleViewClick:(UIButton *)button {
    
    if (button.selected) {
        
        [self.albumListView executeDismissAlbumListAnimation];
        
        return;
    }
    
    [self.albumListView executeShowAlbumListAnimation];
}

- (void)done{
    !self.completeHandler ? : self.completeHandler(self.selectedItemArray, self.selectedAssetArray);
    [self dismiss];
}

- (void)dismiss{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    columnCount = size.width > 414 ? 6 : 4;
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    
    if (@available(iOS 11.0, *)) {
        
        safeAreaInsets = self.view.safeAreaInsets;
    }
    
    self.collectionView.frame = CGRectMake(safeAreaInsets.left, JKPhotoNavigationBarHeight(), self.view.frame.size.width - safeAreaInsets.left - safeAreaInsets.right, self.view.frame.size.height - JKPhotoNavigationBarHeight() - JKPhotoCurrentHomeIndicatorHeight() - 70);
    
    self.bottomContentView.frame = CGRectMake(0, CGRectGetMaxY(self.collectionView.frame), self.view.frame.size.width, 70 + JKPhotoCurrentHomeIndicatorHeight());
    
    self.selectedCountButton.frame = CGRectMake(CGRectGetMaxX(self.collectionView.frame) - 60, 10, 50, 50);
    
    _selectAllButton.frame = CGRectMake(safeAreaInsets.left, 10, 70, 50);
    
    CGFloat X = (_selectAllButton ? CGRectGetMaxX(_selectAllButton.frame) : safeAreaInsets.left);
    
    self.bottomCollectionView.frame = CGRectMake(X, 0, self.selectedCountButton.frame.origin.x - 10 - X, 70);
    
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
    
    if (@available(iOS 11.0, *)) {
        
        collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    if (@available(iOS 13.0, *)) {
        
        collectionView.automaticallyAdjustsScrollIndicatorInsets = NO;
    }
    
    // 注册cell
    [collectionView registerClass:[JKPhotoCollectionViewCell class] forCellWithReuseIdentifier:reuseID];
    
    UIView *bottomContentView = [[UIView alloc] init];
    bottomContentView.frame = CGRectMake(0, CGRectGetMaxY(collectionView.frame), self.view.frame.size.width, 70 + JKPhotoCurrentHomeIndicatorHeight());
    bottomContentView.backgroundColor = JKPhotoAdaptColor([UIColor colorWithRed:250.0 / 255.0 green:250.0 / 255.0 blue:250.0 / 255.0 alpha:1], [UIColor colorWithRed:5.0 / 255.0 green:5.0 / 255.0 blue:5.0 / 255.0 alpha:1]);
    [self.view addSubview:bottomContentView];
    _bottomContentView = bottomContentView;
    
    if (self.configuration.shouldSelectAll) {
        
        UIButton *selectAllButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
        selectAllButton.titleLabel.font = [UIFont systemFontOfSize:14];
        //selectAllButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [selectAllButton setTitle:@"全选" forState:(UIControlStateNormal)];
        
        //selectAllButton.backgroundColor = JKPhotoAdaptColor([UIColor whiteColor], [UIColor blackColor]);
        
        [selectAllButton addTarget:self action:@selector(selectAllButtonClick:) forControlEvents:(UIControlEventTouchUpInside)];
        
        [bottomContentView addSubview:selectAllButton];
        _selectAllButton = selectAllButton;
    }
    
    if (self.configuration.shouldBottomPreview) {
        
        // 底部的collectionView
        UICollectionViewFlowLayout *flowLayout2 = [[UICollectionViewFlowLayout alloc] init];
        flowLayout2.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        UICollectionView *bottomCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake((_selectAllButton ? CGRectGetMaxX(_selectAllButton.frame) : 0), 0, self.view.frame.size.width - 70, 70) collectionViewLayout:flowLayout2];
        bottomCollectionView.backgroundColor = [UIColor clearColor];
        bottomCollectionView.alwaysBounceHorizontal = YES;
        bottomCollectionView.showsHorizontalScrollIndicator = NO;
        bottomCollectionView.dataSource = self;
        bottomCollectionView.delegate = self;
        bottomCollectionView.contentInset = UIEdgeInsetsMake(0, (_selectAllButton ? -5 : 5), 0, 0);
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
    [self.selectedItemArray removeAllObjects];
    [self.selectedItemCache removeAllObjects];
    
    if (isSelectAll) {
        
        [button setTitle:@"取消全选" forState:(UIControlStateNormal)];
        
        if (self.isAllPhotosAlbum && self.configuration.showTakePhotoIcon) {
            
            NSMutableArray *arrM = [NSMutableArray arrayWithArray:self.itemArray];
            [arrM removeObjectAtIndex:0];
            
            self.selectedItemArray = arrM;
            
        } else {
            
            [self.selectedItemArray addObjectsFromArray:self.itemArray];
        }
        
    } else {
        
        [button setTitle:@"全选" forState:(UIControlStateNormal)];
    }
    
    [self.itemArray enumerateObjectsUsingBlock:^(JKPhotoItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.isShowCameraIcon) { return; }
        
        if (isSelectAll) {
            
            obj.isSelected = YES;
            
            [self.selectedItemCache setObject:obj forKey:obj.assetLocalIdentifier];
            
            [self.selectedAssetArray addObject:obj.photoAsset];
            
        } else {
            
            obj.isSelected = NO;
        }
    }];
    
    [self changeSelectedCount];
    
    [self.collectionView performBatchUpdates:^{
       
        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        
    } completion:^(BOOL finished) {
        
    }];
    
    [self.bottomCollectionView performBatchUpdates:^{
       
        [self.bottomCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - 加载数据

- (void)loadPhotoWithAlbumItem:(JKPhotoAlbumItem *)albumItem isReload:(BOOL)isReload{
    
    [self.indicatorView startAnimating];
    
    BOOL isLoadAllPhotos = [albumItem.localIdentifier isEqualToString:_albumListView.cameraRollAlbumItem.localIdentifier];
    
    [JKPhotoPickerEngine fetchPhotoItemListWithCollection:albumItem.assetCollection reverseResultArray:YES selectedItemCache:(isLoadAllPhotos ? self.selectedItemCache : nil) showTakePhotoIcon:self.configuration.showTakePhotoIcon completeHandler:^(JKPhotoResultModel * _Nonnull resultModel) {
        
        [self.indicatorView stopAnimating];
        
        [self.itemArray removeAllObjects];
        
        if ([resultModel.itemList.firstObject isShowCameraIcon] == NO &&
            self.configuration.showTakePhotoIcon &&
            isLoadAllPhotos) {
            
            JKPhotoItem *item1 = [[JKPhotoItem alloc] init];
            item1.isShowCameraIcon = YES;
            [self.itemArray addObject:item1];
        }
        
        [self.itemArray addObjectsFromArray:resultModel.itemList];
        
        self.iemCache = resultModel.itemCache;
        
        if (isLoadAllPhotos) {
            
            [self.selectedItemArray removeAllObjects];
            [self.selectedItemArray addObjectsFromArray:resultModel.selectedItemList];
            
            [self.selectedAssetArray removeAllObjects];
            [self.selectedAssetArray addObjectsFromArray:resultModel.selectedAssetList];
            
            self.selectedItemCache = resultModel.selectedItemCache;
        }
        
        !self.albumListView.reloadCompleteBlock ? : self.albumListView.reloadCompleteBlock();
        self.albumListView.reloadCompleteBlock = nil;
        
        if (isReload) {
            
            [self.collectionView performBatchUpdates:^{
               
                [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
                
            } completion:^(BOOL finished) {
                
            }];
            
            [self.bottomCollectionView performBatchUpdates:^{
               
                [self.bottomCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
                
            } completion:^(BOOL finished) {
                
            }];
            
        } else {
            
            [self.collectionView reloadData];
            [self.bottomCollectionView reloadData];
            
            [self.collectionView setContentOffset:CGPointMake(0, -self.collectionView.contentInset.top) animated:YES];
        }
        
        [self changeSelectedCount];
    }];
}

#pragma mark - collectionView数据源 
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return (collectionView == self.bottomCollectionView) ? self.selectedItemArray.count : self.itemArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    JKPhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:(collectionView == self.bottomCollectionView) ? reuseIDSelected : reuseID forIndexPath:indexPath];
    
    JKPhotoItem *item = (collectionView == self.bottomCollectionView) ? self.selectedItemArray[indexPath.row] : self.itemArray[indexPath.item];
    
    item.isSelected = NO;
    
    if ([self.selectedItemCache objectForKey:item.assetLocalIdentifier] != nil) {
        
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
                weakSelf.selectedItemArray.count < weakSelf.configuration.maxSelectCount) {
                
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
    
    NSInteger totalCount = self.itemArray.count - ((self.isAllPhotosAlbum && self.configuration.showTakePhotoIcon) ? 1 : 0);
    
    NSString *title = (self.selectedItemArray.count == totalCount) ? @"取消全选" : @"全选";
    
    [self.selectAllButton setTitle:title forState:(UIControlStateNormal)];
}

- (void)selectPhotoWithCell:(JKPhotoCollectionViewCell *)currentCell {
    
    currentCell.photoItem.isSelected = YES;
    
    [self.selectedItemCache setObject:currentCell.photoItem forKey:currentCell.photoItem.assetLocalIdentifier];
    
    [self.selectedItemArray addObject:currentCell.photoItem];
    
    [self.selectedAssetArray addObject:currentCell.photoItem.photoAsset];
    
    [self checkSelectAllButton];
    
    [self.bottomCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.selectedItemArray.count - 1 inSection:0]]];
    //                [weakSelf.bottomCollectionView reloadData];
    
    [self.bottomCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedItemArray.count - 1 inSection:0] atScrollPosition:(UICollectionViewScrollPositionCenteredHorizontally) animated:YES];
    
    [self changeSelectedCount];
    
    NSLog(@"选中了%ld个", (unsigned long)self.selectedItemArray.count);
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
    
    JKPhotoItem *itm = [self.selectedItemCache objectForKey:currentCell.photoItem.assetLocalIdentifier];
    
    if (itm == nil) {
        
        for (JKPhotoItem *it in self.selectedItemArray) {
            
            if ([it.assetLocalIdentifier isEqualToString:currentCell.photoItem.assetLocalIdentifier]) {
                
                itm = it;
                
                break;
            }
        }
        
    } else {
        
        [self.selectedItemCache removeObjectForKey:itm.assetLocalIdentifier];
    }
    
    itm.isSelected = NO;
    
    indexPath = [NSIndexPath indexPathForItem:[self.selectedItemArray indexOfObject:itm] inSection:0];
    
    if (indexPath != nil && indexPath.item < self.itemArray.count) {
        
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
                
                if ([self.selectedItemArray containsObject:itm]) {
                    
                    [self.selectedItemArray removeObject:itm];
                    
                    if ([self.selectedAssetArray containsObject:itm.photoAsset]) {
                        
                        [self.selectedAssetArray removeObject:itm.photoAsset];
                    }
                    
                    [self checkSelectAllButton];
                    
                    [self.bottomCollectionView deleteItemsAtIndexPaths:@[indexPath]];
                }
                
                [self changeSelectedCount];
                NSLog(@"取消选中,当前选中了%ld个", (unsigned long)self.selectedItemArray.count);
            }];
        }];
        
        return;
    }
    
    if ([self.selectedItemArray containsObject:itm]) {
        
        [self.selectedItemArray removeObject:itm];
        
        if ([self.selectedAssetArray containsObject:itm.photoAsset]) {
            
            [self.selectedAssetArray removeObject:itm.photoAsset];
        }
        
        [self checkSelectAllButton];
    }
    
    [self.collectionView reloadData];
    
    [self.bottomCollectionView reloadData];
    
    [self changeSelectedCount];
    NSLog(@"取消选中,当前选中了%ld个", (unsigned long)self.selectedItemArray.count);
}

#pragma mark - 底部删除选中的照片

- (void)deleteSelectedPhotoWithCell:(JKPhotoCollectionViewCell *)currentCell{
    
    currentCell.photoItem.isSelected = NO;
    
    [self.selectedItemCache removeObjectForKey:currentCell.photoItem.assetLocalIdentifier];
    
    NSIndexPath *indexPath = [self.bottomCollectionView indexPathForCell:currentCell];
    
    if (indexPath.item < self.selectedItemArray.count) {
        
        [self.selectedItemArray removeObject:currentCell.photoItem];
        
        if ([self.selectedAssetArray containsObject:currentCell.photoItem.photoAsset]) {
            
            [self.selectedAssetArray removeObject:currentCell.photoItem.photoAsset];
        }
        
        [self checkSelectAllButton];
        
        [self.bottomCollectionView deleteItemsAtIndexPaths:@[indexPath]];
        
    } else {
        
        [self.selectedItemArray removeObject:currentCell.photoItem];
        
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
    JKPhotoItem *itm = [self.iemCache objectForKey:currentCell.photoItem.assetLocalIdentifier];
    
    itm.isSelected = NO;
    
    if (itm != nil && [self.itemArray containsObject:itm]) {
        
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self.itemArray indexOfObject:itm] inSection:0]]];
        
        [self changeSelectedCount];
        
    } else {
        
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
        
        [self.selectedCountButton setTitle:[NSString stringWithFormat:@"%ld", (unsigned long)self.selectedItemArray.count] forState:(UIControlStateNormal)];
        
        return;
    }
    
    [self.selectedCountButton setTitle:[NSString stringWithFormat:@"%ld/%ld", (unsigned long)self.selectedItemArray.count, (unsigned long)self.configuration.maxSelectCount] forState:(UIControlStateNormal)];
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
    
    BOOL isShowSelectedPhotos = (collectionView == self.bottomCollectionView);
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"allPhotos"] = self.itemArray;
    dict[@"selectedItems"] = self.selectedItemArray;
    dict[@"selectedAssets"] = self.selectedAssetArray;
    
    dict[@"allPhotosCache"] = self.iemCache;
    dict[@"selectedItemsCache"] = self.selectedItemCache;
    dict[@"isAllPhotosAlbum"] = @(self.isAllPhotosAlbum);
    dict[@"configuration"] = self.configuration;
    
    dict[@"imageView"] = cell.photoImageView;
    dict[@"collectionView"] = collectionView;
    dict[@"indexPath"] = isShowSelectedPhotos ? indexPath : cell.photoItem.browserIndexPath;
    dict[@"isSelectedCell"] = @([cell isMemberOfClass:[JKPhotoSelectedCollectionViewCell class]]);
    dict[@"isShowSelectedPhotos"] = @(isShowSelectedPhotos);
    
    self.browserVC = [JKPhotoBrowserViewController showWithViewController:self dataDict:dict completion:^(NSArray <JKPhotoItem *> *seletedPhotos, NSArray<PHAsset *> *selectedAssetArray, NSArray <NSIndexPath *> *indexPaths, NSCache *selectedItemCache) {
        
        NSInteger preCount = self.selectedItemArray.count;
        NSInteger currentCount = seletedPhotos.count;
        
        self.selectedItemCache = selectedItemCache;
        
        JKPhotoItem *preLastItem = nil;
        
        if (preCount > 0) {
            
            preLastItem = self.selectedItemArray.lastObject;
        }
        
        [self.selectedItemArray removeAllObjects];
        [self.selectedItemArray addObjectsFromArray:seletedPhotos];
        
        [self.selectedAssetArray removeAllObjects];
        [self.selectedAssetArray addObjectsFromArray:selectedAssetArray];
        
        [self checkSelectAllButton];
        
        [self.collectionView performBatchUpdates:^{
            
            [self.collectionView reloadItemsAtIndexPaths:indexPaths];
            
        } completion:^(BOOL finished) {
            
            self.isPhotoBrowserPresented = NO;
        }];
        
        [self.bottomCollectionView performBatchUpdates:^{
            
            [self.bottomCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            
        } completion:^(BOOL finished) {
            
            if (self.selectedItemArray.count > 0 && (preCount != currentCount || ![preLastItem.assetLocalIdentifier isEqualToString:[self.selectedItemArray.lastObject assetLocalIdentifier]])) {
                
                [self.bottomCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedItemArray.count - 1 inSection:0] atScrollPosition:(UICollectionViewScrollPositionCenteredHorizontally) animated:YES];
            }
        }];
        
        [self changeSelectedCount];
        
        /*
         dispatch_async(dispatch_get_global_queue(0, 0), ^{
         
         NSMutableArray *indexArr = [NSMutableArray array];
         
         for (JKPhotoItem *itm in self.selectedPhotos) {
         
         if (itm.isSelected) { continue; }
         
         [indexArr addObject:[NSIndexPath indexPathForItem:[self.itemArray indexOfObject:itm] inSection:0]];
         }
         
         [self.selectedPhotos removeAllObjects];
         
         for (JKPhotoItem *itm in seletedPhotos) {
         
         [self.selectedPhotos addObject:itm];
         
         [indexArr addObject:[NSIndexPath indexPathForItem:[self.itemArray indexOfObject:itm] inSection:0]];
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
                    
                } else {
                    
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
    
    [self.albumListView setReloadCompleteBlock:^{
        
        if (weakSelf.configuration.maxSelectCount > 0 &&
            weakSelf.selectedItemArray.count >= weakSelf.configuration.maxSelectCount) {
            return;
        }
        
        JKPhotoItem *itm = weakSelf.itemArray[1];
        itm.isSelected = YES;
        
        [weakSelf.selectedItemArray addObject:itm];
        [weakSelf.selectedItemCache setObject:itm forKey:itm.assetLocalIdentifier];
        
        [weakSelf.selectedAssetArray addObject:itm.photoAsset];
        
        [self checkSelectAllButton];
        
        //        [weakSelf.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:1 inSection:0]]];
        [weakSelf.bottomCollectionView reloadData];
        [weakSelf changeSelectedCount];
    }];
    
    [self.albumListView reloadAlbumList];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
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
