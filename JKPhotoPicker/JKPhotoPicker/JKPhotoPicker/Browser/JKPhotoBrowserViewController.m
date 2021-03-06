//
//  JKPhotoBrowserViewController.m
//  JKPhotoPicker
//
//  Created by albert on 2016/12/30.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import "JKPhotoBrowserViewController.h"
#import "JKPhotoBrowserCollectionViewCell.h"
#import "JKPhotoItem.h"
#import "JKPhotoBrowserPresentationManager.h"
#import <Photos/Photos.h>
#import "JKPhotoCollectionViewCell.h"
#import <AVKit/AVKit.h>
#import "JKPhotoConfiguration.h"

@interface JKPhotoBrowserViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

/** browserContentView */
@property (nonatomic, weak) UIView *browserContentView;

/** collectionView */
@property (nonatomic, weak) UICollectionView *collectionView;

/** 传过来的collectionView */
@property (nonatomic, weak) UICollectionView *fromCollectionView;

/** 所有的图片数组 */
@property (nonatomic, strong) NSArray *allPhotoItems;

/** 需要显示的数据源数组 */
@property (nonatomic, strong) NSArray *dataSourceArr;

/** 选中的图片数组 */
@property (nonatomic, strong) NSMutableArray *selectedPhotoItems;

/** 选中的asset数组 */
@property (nonatomic, strong) NSMutableArray *selectedAssetArray;

/** 点击的索引 */
@property (nonatomic, strong) NSIndexPath *indexPath;

/** 最多选择图片数量 默认3 */
//@property (nonatomic, assign) NSUInteger maxSelectCount;

/** 所有的图片的数量 allPhotoItems.count 包括拍照那个item */
@property (nonatomic, assign) NSUInteger allPhotoItemsCount;

/** 数据源数量 */
@property (nonatomic, assign) NSUInteger dataSourceArrCount;

/** 弹出时已选中图片数量 */
@property (nonatomic, assign) NSUInteger initialSelectCount;

/** dismiss后需要更新的indexPath */
@property (nonatomic, strong) NSMutableArray *dismissReloadIndexPaths;

/** 监听退出图片浏览器的block */
@property (nonatomic, copy) void (^completionBlock)(NSArray <JKPhotoItem *> *seletedPhotos, NSArray<PHAsset *> *selectedAssetArray, NSArray <NSIndexPath *> *indexPaths, NSCache *selectedItemCache);

/** 点击的索引 */
@property (nonatomic, strong) JKPhotoBrowserPresentationManager *presentationManager;

/** 当前选中相册所有照片的identifier映射缓存 */
@property (nonatomic, strong) NSCache *allPhotosIdentifierCache;

/** 选中的照片标识和item的映射缓存 */
@property (nonatomic, strong) NSCache *selectedItemCache;

/** 是否显示的已选中的照片 */
@property (nonatomic, assign) BOOL isShowSelectedPhotos;

/** 当前是否是所有照片相册 */
@property (nonatomic, assign) BOOL isAllPhotosAlbum;

/** configuration */
@property (nonatomic, strong) JKPhotoConfiguration *configuration;

/** 缓存管理对象 */
@property (nonatomic, strong) PHCachingImageManager *cachingImageManager;

/** currentScreenWidth */
@property (nonatomic, assign) CGFloat currentScreenWidth;
@end

@implementation JKPhotoBrowserViewController

static NSString * const reuseID = @"JKPhotoBrowserCollectionViewCell"; // 重用ID

+ (JKPhotoBrowserViewController *)showWithViewController:(UIViewController *)viewController
                                                dataDict:(NSDictionary *)dataDict
                                              completion:(void(^)(NSArray <JKPhotoItem *> *seletedPhotos, NSArray<PHAsset *> *selectedAssetArray, NSArray <NSIndexPath *> *indexPaths, NSCache *selectedItemCache))completion{
    
    JKPhotoBrowserViewController *vc = [[self alloc] init];
    
    UIImageView *imageView = dataDict[@"imageView"];
    CGRect presentFrame = [imageView.superview convertRect:imageView.frame toView:JKPhotoUtility.keyWindow];
    
    vc.transitioningDelegate  = vc.presentationManager;
    vc.presentationManager.navigationController = viewController.navigationController;
    vc.modalPresentationStyle = UIModalPresentationCustom;
    
    vc.presentationManager.isSelectedCell     = [dataDict[@"isSelectedCell"] boolValue];
    vc.presentationManager.touchImage         = imageView.image;
    vc.presentationManager.fromImageView      = imageView;
    vc.presentationManager.touchImageView     = imageView;
    vc.presentationManager.fromCollectionView = dataDict[@"collectionView"];
    vc.presentationManager.presentFrame       = presentFrame;
    
    UIWindow *keyWindow = JKPhotoUtility.keyWindow;
    
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    
    if (@available(iOS 11.0, *)) {
        
        safeAreaInsets = keyWindow.safeAreaInsets;
    }
    
    CGFloat width = keyWindow.frame.size.width - safeAreaInsets.left - safeAreaInsets.right;
    CGFloat height = keyWindow.frame.size.height;
    
    vc.presentationManager.calculateFrameSize = CGSizeMake(width, height);
    
    vc.indexPath            = dataDict[@"indexPath"];
    vc.configuration        = dataDict[@"configuration"];
    vc.completionBlock      = completion;
    vc.isAllPhotosAlbum     = [dataDict[@"isAllPhotosAlbum"] boolValue];
    vc.fromCollectionView   = dataDict[@"collectionView"];
    vc.isShowSelectedPhotos = [dataDict[@"isShowSelectedPhotos"] boolValue];
    
    vc.allPhotoItems      = dataDict[@"allPhotos"];
    vc.allPhotoItemsCount = vc.allPhotoItems.count;
    
    vc.allPhotosIdentifierCache      = dataDict[@"allPhotosCache"];
    vc.selectedItemCache = dataDict[@"selectedItemsCache"];
    
    [vc.selectedPhotoItems removeAllObjects];
    NSArray *selectedItems = dataDict[@"selectedItems"];
    vc.initialSelectCount  = selectedItems.count;
    [vc.selectedPhotoItems addObjectsFromArray:selectedItems];
    
    [vc.selectedAssetArray removeAllObjects];
    NSArray *selectedAssets = dataDict[@"selectedAssets"];
    [vc.selectedAssetArray addObjectsFromArray:selectedAssets];
    
    //    [vc.dismissReloadIndexPaths addObjectsFromArray:[vc.selectedPhotoItems valueForKeyPath:@"currentIndexPath"]];
    
    [vc addReloadIndexPaths];
    
    if (vc.isShowSelectedPhotos) {
        
        vc.dataSourceArr = selectedItems;
        
    } else {
        
        if (vc.allPhotoItemsCount > 1 && (vc.isAllPhotosAlbum && vc.configuration.showTakePhotoIcon)) {
            
            NSMutableArray *mArr = [vc.allPhotoItems mutableCopy];
            [mArr removeObjectAtIndex:0];
            vc.dataSourceArr = [mArr copy];
            
        } else {
            
            vc.dataSourceArr = vc.allPhotoItems;
        }
    }
    
    vc.dataSourceArrCount = vc.dataSourceArr.count;
    
    // 映射标识和item
    //    [vc setupIdentifierCache];
    
    [viewController presentViewController:vc animated:YES completion:nil];
    
    return vc;
}

- (void)addReloadIndexPaths{
    
    for (JKPhotoItem *itm in self.selectedPhotoItems) {
        
        JKPhotoItem *item = [self.allPhotosIdentifierCache objectForKey:itm.assetLocalIdentifier];
        
        NSIndexPath *indexPath = item.currentIndexPath;
        
        itm.currentIndexPath = indexPath;
        
        if (indexPath != nil) {
            
            [self.dismissReloadIndexPaths addObject:indexPath];
        }
    }
}

- (void)setupIdentifierCache{
    
    [self.selectedItemCache removeAllObjects];
    
    for (JKPhotoItem *itm in self.selectedPhotoItems) {
        
        [self.selectedItemCache setObject:itm forKey:itm.assetLocalIdentifier];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    
    return UIInterfaceOrientationPortrait;
}

- (BOOL)prefersHomeIndicatorAutoHidden{
    return JKPhotoUtility.isLandscape;
}

- (BOOL)shouldAutorotate{
    return NO;
}

#pragma mark - 懒加载

- (PHCachingImageManager *)cachingImageManager{
    if (!_cachingImageManager) {
        _cachingImageManager = [[PHCachingImageManager alloc] init];
    }
    return _cachingImageManager;
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

- (NSCache *)selectedItemCache{
    if (!_selectedItemCache) {
        _selectedItemCache = [[NSCache alloc] init];//[NSMutableDictionary dictionary];//;
    }
    return _selectedItemCache;
}

- (NSMutableArray *)dismissReloadIndexPaths{
    if (!_dismissReloadIndexPaths) {
        _dismissReloadIndexPaths = [NSMutableArray array];
    }
    return _dismissReloadIndexPaths;
}

- (JKPhotoBrowserPresentationManager *)presentationManager{
    if (!_presentationManager) {
        _presentationManager = [[JKPhotoBrowserPresentationManager alloc] init];
    }
    return _presentationManager;
}

#pragma mark - 生命周期函数

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self.collectionView scrollToItemAtIndexPath:self.indexPath atScrollPosition:(UICollectionViewScrollPositionNone) animated:NO];
    });
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    
    if (!CGSizeEqualToSize(size, self.view.frame.size)) {
        
        [self.collectionView reloadData];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            if (self.indexPath) {
                
                [self.collectionView scrollToItemAtIndexPath:self.indexPath atScrollPosition:(UICollectionViewScrollPositionCenteredHorizontally) animated:NO];
            }
        });
    }
}

#pragma mark - 初始化

- (BOOL)modalPresentationCapturesStatusBarAppearance{
    return YES;
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self setupCollectionView];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self.collectionView scrollToItemAtIndexPath:self.indexPath atScrollPosition:(UICollectionViewScrollPositionNone) animated:NO];
    });
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    
    if (@available(iOS 11.0, *)) {
        
        safeAreaInsets = self.view.safeAreaInsets;
    }
    
    self.browserContentView.frame = CGRectMake(safeAreaInsets.left, 0, self.view.frame.size.width - safeAreaInsets.left - safeAreaInsets.right, self.view.frame.size.height);
    self.collectionView.frame = CGRectMake(-10, 0, self.browserContentView.frame.size.width + 20, self.browserContentView.frame.size.height);
    
    self.presentationManager.calculateFrameSize = self.browserContentView.frame.size;
}

- (void)setupCollectionView{
    
    UIView *browserContentView = [[UIView alloc] init];
    [self.view insertSubview:browserContentView atIndex:0];
    _browserContentView = browserContentView;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(-10, 0, self.view.frame.size.width + 20, self.view.frame.size.height) collectionViewLayout:flowLayout];
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.pagingEnabled = YES;
    collectionView.dataSource = self;
    collectionView.delegate = self;
    [self.browserContentView insertSubview:collectionView atIndex:0];
    self.collectionView = collectionView;
    
    // 注册cell
    [collectionView registerClass:[JKPhotoBrowserCollectionViewCell class] forCellWithReuseIdentifier:reuseID];
}

#pragma mark - collectionView数据源
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.dataSourceArr.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    JKPhotoBrowserCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseID forIndexPath:indexPath];
    
    cell.collectionView = self.collectionView;
    cell.browserContentView = self.browserContentView;
    cell.controllerView = self.view;
    
    cell.cachingImageManager = self.cachingImageManager;
    
    cell.indexPath = indexPath;
    
    JKPhotoItem *item = self.dataSourceArr[indexPath.item];
    
    if (indexPath.item == self.indexPath.item) {
        
        __weak typeof(self) weakSelf = self;
        
        [cell setImageLoadFinishBlock:^(JKPhotoBrowserCollectionViewCell *currentCell) {
            
            weakSelf.presentationManager.canRemoveAnimationImageView = YES;
        }];
    }
    
    cell.photoItem = item;
    
    [self solveSelectBlockWithCell:cell];
    
    return cell;
}

- (void)solveSelectBlockWithCell:(JKPhotoBrowserCollectionViewCell *)cell{
    
    __weak typeof(self) weakSelf = self;
    
    if (!cell.selectBlock) {
        
        [cell setSelectBlock:^BOOL(BOOL selected, JKPhotoBrowserCollectionViewCell *currentCell) {
            
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
    
    if (!cell.dismissBlock) {
        
        [cell setDismissBlock:^(JKPhotoBrowserCollectionViewCell *currentCell, CGRect dismissFrame) {
            
            [weakSelf prepareToDismissWithCell:currentCell dismissFrame:dismissFrame];
        }];
    }
    
#pragma mark - 删除选中的照片
    //    if (!cell.deleteButtonClickBlock) {
    //        [cell setDeleteButtonClickBlock:^(JKPhotoCollectionViewCell *currentCell) {
    //            currentCell.photoItem.isSelected = NO;
    //            [weakSelf.selectedPhotoItems removeObject:currentCell.photoItem];
    //            [weakSelf.bottomCollectionView reloadData];
    //            [weakSelf.collectionView reloadData];
    //            [weakSelf changeSelectedCount];
    //        }];
    //    }
    
    if (!cell.playVideoBlock) {
        
        [cell setPlayVideoBlock:^(AVPlayerItem *item) {
            
            [weakSelf playVideoWithItem:item];
        }];
    }
}

#pragma mark - 选中照片

- (void)selectPhotoWithCell:(JKPhotoBrowserCollectionViewCell *)currentCell {
    
    currentCell.photoItem.isSelected = YES;
    
    JKPhotoItem *itm = [self.allPhotosIdentifierCache objectForKey:currentCell.photoItem.assetLocalIdentifier];
    
    itm.isSelected = YES;
    
    if (![self.dismissReloadIndexPaths containsObject:itm.currentIndexPath]) {
        
        if (itm != nil) {
            
            [self.dismissReloadIndexPaths addObject:itm.currentIndexPath];
        }
        
        //        JKPhotoItem *itm = [self.iemCache objectForKey:currentCell.photoItem.assetLocalIdentifier];
        //
        //        if (itm != nil) {
        //
        //            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self.allPhotoItems indexOfObject:itm] inSection:0];
        //            [self.dismissReloadIndexPaths addObject:indexPath];
        //        }
    }
    
    [self.selectedItemCache setObject:currentCell.photoItem forKey:currentCell.photoItem.assetLocalIdentifier];
    
    [self.selectedPhotoItems addObject:currentCell.photoItem];
    [self.selectedAssetArray addObject:currentCell.photoItem.photoAsset];
    
    NSLog(@"选中了%ld个", (unsigned long)self.selectedPhotoItems.count);
}

#pragma mark - 最大选择数量提示

- (void)showMaxSelectCountTip{
    
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:[NSString stringWithFormat:@"最多选择%ld张图片哦~~", (unsigned long)self.configuration.maxSelectCount] preferredStyle:(UIAlertControllerStyleAlert)];
    
    [alertVc addAction:[UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:nil]];
    
    [self presentViewController:alertVc animated:YES completion:nil];
}

#pragma mark - 取消选中

- (void)deSelectedPhotoWithCell:(JKPhotoBrowserCollectionViewCell *)currentCell {
    
    currentCell.photoItem.isSelected = NO;
    
    JKPhotoItem *itm = [self.allPhotosIdentifierCache objectForKey:currentCell.photoItem.assetLocalIdentifier];
    
    itm.isSelected = NO;
    
    if (![self.dismissReloadIndexPaths containsObject:itm.currentIndexPath]) {
        
        if (itm.currentIndexPath != nil) {
            
            [self.dismissReloadIndexPaths addObject:itm.currentIndexPath];
        }
    }
    
    if ([self.selectedPhotoItems containsObject:currentCell.photoItem]) {
        
        [self.selectedPhotoItems removeObject:currentCell.photoItem];
        
        if ([self.selectedAssetArray containsObject:currentCell.photoItem.photoAsset]) {
            
            [self.selectedAssetArray removeObject:currentCell.photoItem.photoAsset];
        }
        
        if ([self.selectedItemCache objectForKey:currentCell.photoItem.assetLocalIdentifier] != nil) {
            
            [self.selectedItemCache removeObjectForKey:currentCell.photoItem.assetLocalIdentifier];
        }
        
    } else {
        
        JKPhotoItem *itm = [self.selectedItemCache objectForKey:currentCell.photoItem.assetLocalIdentifier];
        
        if (itm == nil) {
            
            for (JKPhotoItem *it in self.selectedPhotoItems) {
                
                if ([it.assetLocalIdentifier isEqualToString:currentCell.photoItem.assetLocalIdentifier]) {
                    
                    itm = it;
                    
                    break;
                }
            }
            
        } else {
            
            [self.selectedItemCache removeObjectForKey:currentCell.photoItem.assetLocalIdentifier];
        }
        
        if ([self.selectedPhotoItems containsObject:itm]) {
            
            [self.selectedPhotoItems removeObject:itm];
            
            if ([self.selectedAssetArray containsObject:itm.photoAsset]) {
                
                [self.selectedAssetArray removeObject:itm.photoAsset];
            }
        }
    }
    
    NSLog(@"取消选中,当前选中了%ld个", (unsigned long)self.selectedPhotoItems.count);
}

#pragma mark - 退出

- (void)prepareToDismissWithCell:(JKPhotoBrowserCollectionViewCell *)currentCell dismissFrame:(CGRect)dismissFrame{
    
    self.presentationManager.touchImageView = currentCell.photoImageView;
    self.presentationManager.touchImage = currentCell.photoImageView.image;
    self.presentationManager.dismissFrame = dismissFrame;
    
    self.indexPath = (self.isShowSelectedPhotos || (!self.isAllPhotosAlbum) || !self.configuration.showTakePhotoIcon) ? currentCell.indexPath : [NSIndexPath indexPathForItem:currentCell.indexPath.item + 1 inSection:currentCell.indexPath.section];
    
    JKPhotoCollectionViewCell *fromCell = (JKPhotoCollectionViewCell *)[self.fromCollectionView cellForItemAtIndexPath:self.indexPath];
    self.presentationManager.fromImageView = fromCell.photoImageView;
    
    CGRect presentFrame = (fromCell.frame.size.width != fromCell.photoImageView.frame.size.width) ? [JKPhotoUtility.keyWindow convertRect:fromCell.photoImageView.frame fromView:fromCell.photoImageView.superview] : [JKPhotoUtility.keyWindow convertRect:fromCell.frame fromView:fromCell.superview];
    NSLog(@"presentFrame--->%@", NSStringFromCGRect(presentFrame));
    //    CGRect presentFrame = [fromCell.superview convertRect:fromCell.frame toView:JKPhotoUtility.keyWindow];
    
    //    CGRect fromCollectionViewFrame = [self.fromCollectionView.superview convertRect:self.fromCollectionView.frame toView:JKPhotoUtility.keyWindow];
    
    CGRect rect = CGRectMake(0, JKPhotoUtility.navigationBarHeight, JKPhotoScreenWidth, JKPhotoScreenHeight - JKPhotoUtility.navigationBarHeight - (70 + JKPhotoUtility.currentHomeIndicatorHeight));
    
    CGRect bottomOrCompleteRect = [JKPhotoUtility.keyWindow convertRect:self.fromCollectionView.frame fromView:self.fromCollectionView.superview];
    
    self.presentationManager.isZoomUpAnimation = NO;
    
    if (self.isShowSelectedPhotos) {
        
        self.presentationManager.isZoomUpAnimation = !CGRectIntersectsRect(presentFrame, bottomOrCompleteRect) || (self.initialSelectCount != self.selectedPhotoItems.count);
        
    } else {
        
        self.presentationManager.isZoomUpAnimation = !CGRectIntersectsRect(presentFrame, rect);
    }
    
    if (fromCell == nil) {
        
        self.presentationManager.isZoomUpAnimation = YES;
    }
    
    self.presentationManager.presentFrame = presentFrame;
    
    [self dismiss];
}

- (void)changeSelectedCount{
    // 旋转动画
    //    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
    //    //    CAKeyframeAnimation *rotationAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.y"];
    //    rotationAnimation.toValue = @(M_PI * 2);
    //    rotationAnimation.repeatCount = 1;
    //    rotationAnimation.duration = 0.5;
    //
    //    [self.selectedCountButton.layer addAnimation:rotationAnimation forKey:nil];
    //
    //    [self.selectedCountButton setTitle:[NSString stringWithFormat:@"%ld/%ld", (unsigned long)self.selectedPhotos.count, (unsigned long)self.maxSelectCount] forState:(UIControlStateNormal)];
}

#pragma mark - 播放视频

+ (void)initialize{
    
    // 静音也可以有声音
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
}

- (void)playVideoWithItem:(AVPlayerItem *)item{
    
    AVPlayerViewController *playerVc = [[AVPlayerViewController alloc] init];
    playerVc.player = [AVPlayer playerWithPlayerItem:item];
    
    [self presentViewController:playerVc animated:YES completion:^{
        [playerVc.player play];
    }];
}

#pragma mark - collectionView代理
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
}

- (void)dismiss{
    
    [self dismissViewControllerAnimated:YES completion:^{
        
        !self.completionBlock ? : self.completionBlock(self.selectedPhotoItems, self.selectedAssetArray, self.dismissReloadIndexPaths, self.selectedItemCache);
    }];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    return self.collectionView.frame.size;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    
    return 0;
}

#pragma mark - scrollView代理

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    
    !self.draggingBlock ? : self.draggingBlock(YES);
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    !self.draggingBlock ? : self.draggingBlock(NO);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    NSLog(@"可见cell--->%zd", self.collectionView.visibleCells.count);
    
    self.indexPath = [NSIndexPath indexPathForItem:(self.isShowSelectedPhotos || (!self.isAllPhotosAlbum) || !self.configuration.showTakePhotoIcon) ? scrollView.contentOffset.x / JKPhotoScreenWidth : scrollView.contentOffset.x / JKPhotoScreenWidth + 1 inSection:0];
    
    JKPhotoCollectionViewCell *fromCell = (JKPhotoCollectionViewCell *)[self.fromCollectionView cellForItemAtIndexPath:self.indexPath];
    
    CGRect presentFrame = (fromCell.frame.size.width != fromCell.photoImageView.frame.size.width) ? [JKPhotoUtility.keyWindow convertRect:fromCell.photoImageView.frame fromView:fromCell.photoImageView.superview] : [JKPhotoUtility.keyWindow convertRect:fromCell.frame fromView:fromCell.superview];
    
    self.presentationManager.presentFrame = presentFrame;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[PHImageManager defaultManager] cancelImageRequest:PHInvalidImageRequestID];
    
    //    [self.cachingImageManager stopCachingImagesForAllAssets];
    
    NSLog(@"%d, %s",__LINE__, __func__);
}
@end
