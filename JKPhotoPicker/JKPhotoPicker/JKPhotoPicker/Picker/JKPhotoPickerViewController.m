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

#define JKScreenW [UIScreen mainScreen].bounds.size.width
#define JKScreenH [UIScreen mainScreen].bounds.size.height
#define JKScreenBounds [UIScreen mainScreen].bounds

@interface JKPhotoPickerViewController () <UICollectionViewDataSource, UICollectionViewDelegate, CAAnimationDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
/** collectionView */
@property (nonatomic, weak) UICollectionView *collectionView;

/** 底部的collectionView */
@property (nonatomic, weak) UICollectionView *bottomCollectionView;

/** 选中数量提示按钮 */
@property (nonatomic, weak) UIButton *selectedCountButton;

/** 相册列表view */
@property (nonatomic, weak) JKPhotoAlbumListView *albumListView;

/** titleButton */
@property (nonatomic, weak) JKPhotoTitleButton *titleButton;

/** 最多选择图片数量 默认3 */
@property (nonatomic, assign) NSUInteger maxSelectCount;

/** 监听点击完成的block */
@property (nonatomic, copy) void(^completeHandler)(NSArray *photoItems) ;

/** 所有的图片数组 */
@property (nonatomic, strong) NSMutableArray *allPhotos;

/** 选中的图片数组 */
@property (nonatomic, strong) NSMutableArray *selectedPhotos;

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
@end

@implementation JKPhotoPickerViewController

static NSString * const reuseID = @"JKPhotoCollectionViewCell"; // 重用ID
static NSString * const reuseIDSelected = @"JKPhotoSelectedCollectionViewCell"; // 选中的照片重用ID

#pragma mark - 类方法
+ (void)showWithPresentVc:(UIViewController *)presentVc maxSelectCount:(NSUInteger)maxSelectCount seletedPhotos:(NSArray <JKPhotoItem *> *)seletedPhotos isPenCameraFirst:(BOOL)isPenCameraFirst completeHandler:(void(^)(NSArray <JKPhotoItem *> *photoItems))completeHandler{
    
    [JKPhotoManager checkPhotoAccessFinished:^(BOOL isAccessed) {
        if (!isAccessed) {
            return;
        }
        
        JKPhotoPickerViewController *vc = [[self alloc] init];
        vc.maxSelectCount = maxSelectCount;
        vc.completeHandler = completeHandler;
        [vc.selectedPhotos removeAllObjects];
        [vc.selectedPhotos addObjectsFromArray:seletedPhotos];
        
        for (JKPhotoItem *itm in vc.selectedPhotos) {
            
            [vc.selectedPhotosIdentifierCache setObject:itm forKey:itm.assetLocalIdentifier];
        }
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        
        if (presentVc && [presentVc isKindOfClass:[UIViewController class]]) {
            [presentVc presentViewController:nav animated:YES completion:^{
                if (isPenCameraFirst) {
                    [vc updateIconWithSourType:(UIImagePickerControllerSourceTypeCamera)];
                }
            }];
            return;
        }
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:nav animated:YES completion:^{
            if (isPenCameraFirst) {
                [vc updateIconWithSourType:(UIImagePickerControllerSourceTypeCamera)];
            }
        }];
    }];
}

+ (void)initialize{
    [[UIView appearance] setExclusiveTouch:YES];
}

#pragma mark - 懒加载
- (NSMutableArray *)allPhotos{
    if (!_allPhotos) {
        _allPhotos = [NSMutableArray array];
    }
    return _allPhotos;
}

- (NSCache *)allPhotosIdentifierCache{
    if (!_allPhotosIdentifierCache) {
        _allPhotosIdentifierCache = [[NSCache alloc] init];
    }
    return _allPhotosIdentifierCache;
}

- (NSMutableArray *)selectedPhotos{
    if (!_selectedPhotos) {
        _selectedPhotos = [NSMutableArray array];
    }
    return _selectedPhotos;
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
        albumListView.hidden = YES;
        
        [self.titleButton setTitle:[albumListView.cameraRollItem.albumTitle stringByAppendingString:@"  "] forState:(UIControlStateNormal)];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            [self loadPhotoWithPhotoItem:albumListView.cameraRollItem];
        });
        
        __weak typeof(self) weakSelf = self;
#pragma mark - 选中相册
        [albumListView setSelectRowBlock:^(JKPhotoItem *photoItem) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [weakSelf.titleButton setTitle:[photoItem.albumTitle stringByAppendingString:@"  "] forState:(UIControlStateNormal)];
                weakSelf.titleButton.selected = NO;
                weakSelf.isAllPhotosAlbum = [photoItem.albumLocalIdentifier isEqualToString:weakSelf.albumListView.cameraRollItem.albumLocalIdentifier];
            });
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                [weakSelf loadPhotoWithPhotoItem:photoItem];
            });
        }];
        
        [self.view addSubview:albumListView];
        
        _albumListView = albumListView;
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
    
    [self.albumListView performSelector:@selector(reloadAlbum) withObject:nil afterDelay:0.8];
}

#pragma mark - 初始化
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    
    _isAllPhotosAlbum = YES;
    
    if (self.maxSelectCount <= 0) {
        self.maxSelectCount = 3;
    }
    
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
    [titleButton setTitleColor:[UIColor blackColor] forState:(UIControlStateNormal)];
//    [titleButton setTitle:@"相机胶卷  " forState:(UIControlStateNormal)];
    [titleButton setImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"JKPhotoPickerResource.bundle/images/arrow_down@2x.png"]] forState:(UIControlStateNormal)];
    [titleButton setImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"JKPhotoPickerResource.bundle/images/arrow_up@2x.png"]] forState:(UIControlStateSelected)];
    
    [titleButton addTarget:self action:@selector(titleViewClick:) forControlEvents:(UIControlEventTouchUpInside)];
    
    self.navigationItem.titleView = titleButton;
    self.titleButton = titleButton;
}

- (void)titleViewClick:(UIButton *)button{
    
    __weak typeof(self) weakSelf = self;
    
    [self.albumListView executeAlbumListViewAnimationCompletion:^{
        weakSelf.titleButton.selected = !weakSelf.albumListView.hidden;
    }];
}

- (void)done{
    !self.completeHandler ? : self.completeHandler(self.selectedPhotos);
    [self dismiss];
}

- (void)dismiss{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setupCollectionView{
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake((JKScreenW - 3) / 4, (JKScreenW - 3) / 4);
    flowLayout.minimumLineSpacing = 1;
    flowLayout.minimumInteritemSpacing = 1;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 70 - (JKPhotoPickerIsIphoneX ? JKPhotoPickerBottomSafeAreaHeight : 0)) collectionViewLayout:flowLayout];
    collectionView.contentInset = UIEdgeInsetsMake(JKPhotoPickerNavBarHeight, 0, 0, 0);
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
    bottomContentView.frame = CGRectMake(0, CGRectGetMaxY(collectionView.frame), self.view.frame.size.width, 70 + (JKPhotoPickerIsIphoneX ? JKPhotoPickerBottomSafeAreaHeight : 0));
    bottomContentView.backgroundColor = [UIColor colorWithRed:250.0 / 255.0 green:250.0 / 255.0 blue:250.0 / 255.0 alpha:1];
    [self.view addSubview:bottomContentView];
    
    // 底部的collectionView
    UICollectionViewFlowLayout *flowLayout2 = [[UICollectionViewFlowLayout alloc] init];
    flowLayout2.itemSize = CGSizeMake(60, 70);
    flowLayout2.minimumLineSpacing = 1;
    flowLayout2.minimumInteritemSpacing = 1;
    flowLayout2.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    UICollectionView *bottomCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 70, 70) collectionViewLayout:flowLayout2];
    bottomCollectionView.backgroundColor = [UIColor clearColor];
    bottomCollectionView.alwaysBounceHorizontal = YES;
    bottomCollectionView.showsHorizontalScrollIndicator = NO;
    bottomCollectionView.dataSource = self;
    bottomCollectionView.delegate = self;
    bottomCollectionView.contentInset = UIEdgeInsetsMake(0, 5, 0, 0);
    [bottomContentView addSubview:bottomCollectionView];
    self.bottomCollectionView = bottomCollectionView;
    
    // 注册cell
    [bottomCollectionView registerClass:[JKPhotoSelectedCollectionViewCell class] forCellWithReuseIdentifier:reuseIDSelected];
    
    UIButton *selectedCountButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
    selectedCountButton.frame = CGRectMake(CGRectGetMaxX(bottomCollectionView.frame) + 10, 10, 50, 50);
    selectedCountButton.backgroundColor = [UIColor redColor];
    selectedCountButton.layer.cornerRadius = 25;
    selectedCountButton.layer.masksToBounds = YES;
    [selectedCountButton setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
    [bottomContentView addSubview:selectedCountButton];
    self.selectedCountButton = selectedCountButton;
    
    [selectedCountButton addTarget:self action:@selector(done) forControlEvents:(UIControlEventTouchUpInside)];
    
    [self changeSelectedCount];
}

#pragma mark - 加载数据
- (void)loadPhotoWithPhotoItem:(JKPhotoItem *)photoItem{
    
    [self.allPhotosIdentifierCache removeAllObjects];
    
    NSMutableArray *photoItems = [JKPhotoManager getPhotoAssetsWithFetchResult:photoItem.albumFetchResult optionDict:@{@"allCache" : self.allPhotosIdentifierCache, @"seletedCache" : self.selectedPhotosIdentifierCache} complete:^(NSDictionary *resultDict) {
        
        self.allPhotosIdentifierCache = resultDict[@"allCache"];
        self.selectedPhotos = [resultDict[@"seletedItems"] mutableCopy];
        self.selectedPhotosIdentifierCache = resultDict[@"seletedCache"];
    }];
    
    if ([photoItems.firstObject isShowCameraIcon] == NO && self.isAllPhotosAlbum) {
        JKPhotoItem *item1 = [[JKPhotoItem alloc] init];
        item1.isShowCameraIcon = YES;
        [photoItems insertObject:item1 atIndex:0];
    }
    
    self.allPhotos = photoItems;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        !self.albumListView.reloadCompleteBlock ? : self.albumListView.reloadCompleteBlock();
        self.albumListView.reloadCompleteBlock = nil;
        
        [self.collectionView reloadData];
        [self.bottomCollectionView reloadData];
        
        [self changeSelectedCount];
        
        [self.collectionView setContentOffset:CGPointMake(0, -self.collectionView.contentInset.top) animated:YES];
    });
}

#pragma mark - collectionView数据源
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return (collectionView == self.bottomCollectionView) ? self.selectedPhotos.count : self.allPhotos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    JKPhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:(collectionView == self.bottomCollectionView) ? reuseIDSelected : reuseID forIndexPath:indexPath];
    
    JKPhotoItem *item = (collectionView == self.bottomCollectionView) ? self.selectedPhotos[indexPath.row] : self.allPhotos[indexPath.item];
    
    item.isSelected = NO;
    
    if ([self.selectedPhotosIdentifierCache objectForKey:item.assetLocalIdentifier] != nil) {
        
        item.isSelected = YES;
    }
    
//    for (JKPhotoItem *it in self.selectedPhotos) {
//        if (![it.assetLocalIdentifier isEqualToString:item.assetLocalIdentifier]) continue;
//
//        item.isSelected = YES;
//    }
    
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
            
            if (weakSelf.selectedPhotos.count < weakSelf.maxSelectCount) {
                
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
    
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (videoAuthStatus == AVAuthorizationStatusNotDetermined) {// 未询问用户是否授权
        
    }else if(videoAuthStatus == AVAuthorizationStatusRestricted || videoAuthStatus == AVAuthorizationStatusDenied) {// 未授权
        
    }else{// 已授权
        
    }
    
    if (videoAuthStatus == AVAuthorizationStatusDenied) {
        UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:@"当前程序未获得相机权限，是否打开？由于iOS系统原因，设置相机权限会导致app崩溃，请知晓。" preferredStyle:(UIAlertControllerStyleAlert)];
        
        [alertVc addAction:[UIAlertAction actionWithTitle:@"不用了" style:(UIAlertActionStyleDefault) handler:nil]];
        [alertVc addAction:[UIAlertAction actionWithTitle:@"去打开" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            // 打开本程序对应的权限设置
            [[UIApplication sharedApplication]openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }]];
        
        [self presentViewController:alertVc animated:YES completion:nil];
        
        return;
    }
    
    //    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
    //
    //        if (granted){// 用户同意授权
    //
    //        }else {// 用户拒绝授权
    //
    //        }
    //
    //    }];
    
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        
        return;
    }
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = sourceType;
    
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

#pragma mark - 选中照片

- (void)selectPhotoWithCell:(JKPhotoCollectionViewCell *)currentCell {
    
    currentCell.photoItem.isSelected = YES;
    
    [self.selectedPhotosIdentifierCache setObject:currentCell.photoItem forKey:currentCell.photoItem.assetLocalIdentifier];
    
    [self.selectedPhotos addObject:currentCell.photoItem];
    
    [self.bottomCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.selectedPhotos.count - 1 inSection:0]]];
    //                [weakSelf.bottomCollectionView reloadData];
    
    [self.bottomCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedPhotos.count - 1 inSection:0] atScrollPosition:(UICollectionViewScrollPositionCenteredHorizontally) animated:YES];
    
    [self changeSelectedCount];
    
    NSLog(@"选中了%ld个", (unsigned long)self.selectedPhotos.count);
}

#pragma mark - 最大选择数量提示

- (void)showMaxSelectCountTip{
    
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:[NSString stringWithFormat:@"最多选择%ld张图片哦~~", (unsigned long)self.maxSelectCount] preferredStyle:(UIAlertControllerStyleAlert)];
    
    [alertVc addAction:[UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:nil]];
    
    [self presentViewController:alertVc animated:YES completion:nil];
}

#pragma mark - 取消选中

- (void)deSelectedPhotoWithCell:(JKPhotoCollectionViewCell *)currentCell {
    
    currentCell.photoItem.isSelected = NO;
    
    NSIndexPath *indexPath = nil;
    
    JKPhotoItem *itm = [self.selectedPhotosIdentifierCache objectForKey:currentCell.photoItem.assetLocalIdentifier];
    
    if (itm == nil) {
        
        for (JKPhotoItem *it in self.selectedPhotos) {
            
            if ([it.assetLocalIdentifier isEqualToString:currentCell.photoItem.assetLocalIdentifier]) {
                
                itm = it;
                
                break;
            }
        }
        
    }else{
        
        [self.selectedPhotosIdentifierCache removeObjectForKey:itm.assetLocalIdentifier];
    }
    
    itm.isSelected = NO;
    
    indexPath = [NSIndexPath indexPathForItem:[self.selectedPhotos indexOfObject:itm] inSection:0];
    
    if (indexPath != nil && indexPath.item < self.allPhotos.count) {
        
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
                
                if ([self.selectedPhotos containsObject:itm]) {
                    
                    [self.selectedPhotos removeObject:itm];
                    
                    [self.bottomCollectionView deleteItemsAtIndexPaths:@[indexPath]];
                }
                
                [self changeSelectedCount];
                NSLog(@"取消选中,当前选中了%ld个", (unsigned long)self.selectedPhotos.count);
            }];
        }];
        
        return;
    }
    
    if ([self.selectedPhotos containsObject:itm]) {
        
        [self.selectedPhotos removeObject:itm];
    }
    
    [self.collectionView reloadData];
    
    [self.bottomCollectionView reloadData];
    
    [self changeSelectedCount];
    NSLog(@"取消选中,当前选中了%ld个", (unsigned long)self.selectedPhotos.count);
}

#pragma mark - 底部删除选中的照片

- (void)deleteSelectedPhotoWithCell:(JKPhotoCollectionViewCell *)currentCell{
    
    currentCell.photoItem.isSelected = NO;
    
    [self.selectedPhotosIdentifierCache removeObjectForKey:currentCell.photoItem.assetLocalIdentifier];
    
    NSIndexPath *indexPath = [self.bottomCollectionView indexPathForCell:currentCell];
    
    if (indexPath.item < self.selectedPhotos.count) {
        
        [self.selectedPhotos removeObject:currentCell.photoItem];
        
        [self.bottomCollectionView deleteItemsAtIndexPaths:@[indexPath]];
        
    }else{
        
        [self.selectedPhotos removeObject:currentCell.photoItem];
        
        [self.collectionView performBatchUpdates:^{
            
            [self.bottomCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            
        } completion:^(BOOL finished) {
            
            [self changeSelectedCount];
        }];
    }
    
    // 在全部照片中取消选中
    JKPhotoItem *itm = [self.allPhotosIdentifierCache objectForKey:currentCell.photoItem.assetLocalIdentifier];
    
    itm.isSelected = NO;
    
    if (itm != nil && [self.allPhotos containsObject:itm]) {
        
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self.allPhotos indexOfObject:itm] inSection:0]]];
        
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
//    CAKeyframeAnimation *rotationAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.y"];
    rotationAnimation.toValue = @(M_PI * 2);
    rotationAnimation.repeatCount = 1;
    rotationAnimation.duration = 0.5;
    rotationAnimation.delegate = self;
    
    [self.selectedCountButton.layer addAnimation:rotationAnimation forKey:nil];
    
    [self.selectedCountButton setTitle:[NSString stringWithFormat:@"%ld/%ld", (unsigned long)self.selectedPhotos.count, (unsigned long)self.maxSelectCount] forState:(UIControlStateNormal)];
}

#pragma mark - CAAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    
}

#pragma mark - collectionView代理
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    NSLog(@"hehheehhehe");
    
    JKPhotoCollectionViewCell *cell = (JKPhotoCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"allPhotos"] = self.allPhotos;
    dict[@"selectedItems"] = self.selectedPhotos;
    
    dict[@"allPhotosCache"] = self.allPhotosIdentifierCache;
    dict[@"selectedItemsCache"] = self.selectedPhotosIdentifierCache;
    dict[@"isAllPhotosAlbum"] = @(self.isAllPhotosAlbum);
    
    dict[@"maxSelectCount"] = @(self.maxSelectCount);
    dict[@"imageView"] = cell.photoImageView;
    dict[@"collectionView"] = collectionView;
    dict[@"indexPath"] = (collectionView == self.collectionView && self.isAllPhotosAlbum) ? [NSIndexPath indexPathForItem:indexPath.item - 1 inSection:indexPath.section] : indexPath;
    dict[@"isSelectedCell"] = @([cell isMemberOfClass:[JKPhotoSelectedCollectionViewCell class]]);
    dict[@"isShowSelectedPhotos"] = @(collectionView == self.bottomCollectionView);
    
    [JKPhotoBrowserViewController showWithViewController:self dataDict:dict completion:^(NSArray<JKPhotoItem *> *seletedPhotos, NSArray<NSIndexPath *> *indexPaths, NSMutableDictionary *selectedPhotosIdentifierCache) {
        
        NSInteger preCount = self.selectedPhotos.count;
        NSInteger currentCount = seletedPhotos.count;
        
        self.selectedPhotosIdentifierCache = selectedPhotosIdentifierCache;
        
        JKPhotoItem *preLastItem = nil;
        
        if (preCount > 0) {
            
            preLastItem = self.selectedPhotos.lastObject;
        }
        
        [self.selectedPhotos removeAllObjects];
        [self.selectedPhotos addObjectsFromArray:seletedPhotos];
        
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
            
            if (self.selectedPhotos.count > 0 && (preCount != currentCount || ![preLastItem.assetLocalIdentifier isEqualToString:[self.selectedPhotos.lastObject assetLocalIdentifier]])) {
                
                [self.bottomCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedPhotos.count - 1 inSection:0] atScrollPosition:(UICollectionViewScrollPositionCenteredHorizontally) animated:YES];
            }
        }];
        
        [self changeSelectedCount];
        
        /*
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            NSMutableArray *indexArr = [NSMutableArray array];
            
            for (JKPhotoItem *itm in self.selectedPhotos) {
                
                if (itm.isSelected) { continue; }
                
                [indexArr addObject:[NSIndexPath indexPathForItem:[self.allPhotos indexOfObject:itm] inSection:0]];
            }
            
            [self.selectedPhotos removeAllObjects];
            
            for (JKPhotoItem *itm in seletedPhotos) {
                
                [self.selectedPhotos addObject:itm];
                
                [indexArr addObject:[NSIndexPath indexPathForItem:[self.allPhotos indexOfObject:itm] inSection:0]];
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
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Adds a photo to the saved photos album.  The optional completionSelector should have the form:
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (error) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    [self.albumListView setReloadCompleteBlock:^{
        
        if (weakSelf.selectedPhotos.count >= weakSelf.maxSelectCount) {
            return;
        }
        
        JKPhotoItem *itm = weakSelf.allPhotos[1];
        itm.isSelected = YES;
        
        [weakSelf.selectedPhotos addObject:itm];
        [weakSelf.selectedPhotosIdentifierCache setObject:itm forKey:itm.assetLocalIdentifier];
        
//        [weakSelf.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:1 inSection:0]]];
        [weakSelf.bottomCollectionView reloadData];
        [weakSelf changeSelectedCount];
    }];
    
    [self.albumListView reloadAlbum];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
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
