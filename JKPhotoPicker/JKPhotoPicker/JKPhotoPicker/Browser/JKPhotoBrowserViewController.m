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

@interface JKPhotoBrowserViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
/** collectionView */
@property (nonatomic, weak) UICollectionView *collectionView;

/** 传过来的collectionView */
@property (nonatomic, weak) UICollectionView *fromCollectionView;

/** 所有的图片数组 */
@property (nonatomic, strong) NSArray *allPhotoItems;

/** 需要显示的数据源数组 */
@property (nonatomic, strong) NSArray *dataSourceArr;

/** 选中的图片数组 */
@property (nonatomic, strong) NSMutableArray *selectedPhotos;

/** 点击的索引 */
@property (nonatomic, strong) NSIndexPath *indexPath;

/** 最多选择图片数量 默认3 */
@property (nonatomic, assign) NSUInteger maxSelectCount;

/** 所有的图片的数量 allPhotoItems.count 包括拍照那个item */
@property (nonatomic, assign) NSUInteger allPhotoItemsCount;

/** 弹出时已选中图片数量 */
@property (nonatomic, assign) NSUInteger initialSelectCount;

/** dismiss后需要更新的indexPath */
@property (nonatomic, strong) NSMutableArray *dismissReloadIndexPaths;

/** 监听退出图片浏览器的block */
@property (nonatomic, copy) void (^completionBlock)(NSArray <JKPhotoItem *> *seletedPhotos, NSArray <NSIndexPath *> *indexPaths, NSMutableDictionary *selectedPhotosIdentifierCache);

/** 点击的索引 */
@property (nonatomic, strong) JKPhotoBrowserPresentationManager *presentationManager;

/** 当前选中相册所有照片的identifier映射缓存 */
@property (nonatomic, strong) NSCache *allPhotosIdentifierCache;

/** 选中的照片标识和item的映射缓存 */
@property (nonatomic, strong) NSMutableDictionary *selectedPhotosIdentifierCache;

/** 是否显示的已选中的照片 */
@property (nonatomic, assign) BOOL isShowSelectedPhotos;

/** 当前是否是所有照片相册 */
@property (nonatomic, assign) BOOL isAllPhotosAlbum;
@end

@implementation JKPhotoBrowserViewController

static NSString * const reuseID = @"JKPhotoBrowserCollectionViewCell"; // 重用ID

+ (void)showWithViewController:(UIViewController *)viewController dataDict:(NSDictionary *)dataDict completion:(void(^)(NSArray <JKPhotoItem *> *seletedPhotos, NSArray <NSIndexPath *> *indexPaths, NSMutableDictionary *selectedPhotosIdentifierCache))completion{
    
    JKPhotoBrowserViewController *vc = [[self alloc] init];
    
    UIImageView *imageView = dataDict[@"imageView"];
    CGRect presentFrame = [imageView.superview convertRect:imageView.frame toView:[UIApplication sharedApplication].keyWindow];
    
    vc.transitioningDelegate  = vc.presentationManager;
    vc.modalPresentationStyle = UIModalPresentationCustom;
    
    vc.presentationManager.isSelectedCell     = [dataDict[@"isSelectedCell"] boolValue];
    vc.presentationManager.touchImage         = imageView.image;
    vc.presentationManager.fromImageView      = imageView;
    vc.presentationManager.touchImageView     = imageView;
    vc.presentationManager.fromCollectionView = dataDict[@"collectionView"];
    vc.presentationManager.presentFrame       = presentFrame;
    
    vc.indexPath            = dataDict[@"indexPath"];
    vc.maxSelectCount       = [dataDict[@"maxSelectCount"] integerValue];
    vc.completionBlock      = completion;
    vc.isAllPhotosAlbum     = [dataDict[@"isAllPhotosAlbum"] boolValue];
    vc.fromCollectionView   = dataDict[@"collectionView"];
    vc.isShowSelectedPhotos = [dataDict[@"isShowSelectedPhotos"] boolValue];
    
    vc.allPhotoItems      = dataDict[@"allPhotos"];
    vc.allPhotoItemsCount = vc.allPhotoItems.count;
    
    vc.allPhotosIdentifierCache      = dataDict[@"allPhotosCache"];
    vc.selectedPhotosIdentifierCache = dataDict[@"selectedItemsCache"];
    
    [vc.selectedPhotos removeAllObjects];
    NSArray *selectedItems = dataDict[@"selectedItems"];
    vc.initialSelectCount  = selectedItems.count;
    [vc.selectedPhotos addObjectsFromArray:selectedItems];
    
//    [vc.dismissReloadIndexPaths addObjectsFromArray:[vc.selectedPhotos valueForKeyPath:@"currentIndexPath"]];
    
    [vc addReloadIndexPaths];
    
    if (vc.isShowSelectedPhotos) {
        
        vc.dataSourceArr = selectedItems;
        
    }else{
        
        if (vc.allPhotoItemsCount > 1 && vc.isAllPhotosAlbum) {
            
            NSMutableArray *mArr = [vc.allPhotoItems mutableCopy];
            [mArr removeObjectAtIndex:0];
            vc.dataSourceArr = [mArr copy];
            
        }else{
            
            vc.dataSourceArr = vc.allPhotoItems;
        }
    }
    
    // 映射标识和item
//    [vc setupIdentifierCache];
    
    [viewController presentViewController:vc animated:YES completion:nil];
}

- (void)addReloadIndexPaths{
    
    for (JKPhotoItem *itm in self.selectedPhotos) {
        
        JKPhotoItem *item = [self.allPhotosIdentifierCache objectForKey:itm.assetLocalIdentifier];
        
        NSIndexPath *indexPath = item.currentIndexPath;
        
        itm.currentIndexPath = indexPath;
        
        if (indexPath != nil) {
            
            [self.dismissReloadIndexPaths addObject:indexPath];
        }
    }
}

- (void)setupIdentifierCache{
    
    [self.selectedPhotosIdentifierCache removeAllObjects];
    
    for (JKPhotoItem *itm in self.selectedPhotos) {
        
        [self.selectedPhotosIdentifierCache setObject:itm forKey:itm.assetLocalIdentifier];
    }
}

//- (BOOL)prefersStatusBarHidden{
//    return YES;
//}

#pragma mark - 懒加载
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

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
//    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
//    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    [self setupCollectionView];
    [self.collectionView scrollToItemAtIndexPath:self.indexPath atScrollPosition:(UICollectionViewScrollPositionNone) animated:YES];
}

- (void)setupCollectionView{
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(JKScreenW, JKScreenH);
    flowLayout.minimumLineSpacing = 0;
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) collectionViewLayout:flowLayout];
    collectionView.backgroundColor = [UIColor blackColor];
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.pagingEnabled = YES;
    collectionView.dataSource = self;
    collectionView.delegate = self;
    [self.view insertSubview:collectionView atIndex:0];
    self.collectionView = collectionView;
    
    // 布局collectionView
//    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
//    NSArray *collectionViewCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[collectionView]-0-|" options:0 metrics:nil views:@{@"collectionView" : collectionView}];
//    [self.view addConstraints:collectionViewCons1];
//    
//    NSArray *collectionViewCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[collectionView]-0-|" options:0 metrics:nil views:@{@"collectionView" : collectionView}];
//    [self.view addConstraints:collectionViewCons2];
    
    // 注册cell
    [collectionView registerClass:[JKPhotoBrowserCollectionViewCell class] forCellWithReuseIdentifier:reuseID];
}

#pragma mark - collectionView数据源
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.dataSourceArr.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    JKPhotoBrowserCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseID forIndexPath:indexPath];
    
    cell.indexPath = indexPath;
    
    JKPhotoItem *item = self.dataSourceArr[indexPath.item];
    
//    item.isSelected = NO;
    
//    for (JKPhotoItem *it in self.selectedPhotos) {
//
//        if (![it.assetLocalIdentifier isEqualToString:item.assetLocalIdentifier]) continue;
//
//        item.isSelected = YES;
//    }
    
    cell.photoItem = item;
    
    [self solveSelectBlockWithCell:cell];
    
    cell.collectionView = self.collectionView;
    
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
            
            if (weakSelf.selectedPhotos.count < weakSelf.maxSelectCount) {
                
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
//            [weakSelf.selectedPhotos removeObject:currentCell.photoItem];
//            [weakSelf.bottomCollectionView reloadData];
//            [weakSelf.collectionView reloadData];
//            [weakSelf changeSelectedCount];
//        }];
//    }
}

#pragma mark - 选中照片

- (void)selectPhotoWithCell:(JKPhotoBrowserCollectionViewCell *)currentCell {
    
    currentCell.photoItem.isSelected = YES;
    
    if (![self.dismissReloadIndexPaths containsObject:currentCell.photoItem.currentIndexPath]) {
        
        if (currentCell.photoItem.currentIndexPath != nil) {
            
            [self.dismissReloadIndexPaths addObject:currentCell.photoItem];
        }
        
//        JKPhotoItem *itm = [self.allPhotosIdentifierCache objectForKey:currentCell.photoItem.assetLocalIdentifier];
//
//        if (itm != nil) {
//
//            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self.allPhotoItems indexOfObject:itm] inSection:0];
//            [self.dismissReloadIndexPaths addObject:indexPath];
//        }
    }
    
    [self.selectedPhotosIdentifierCache setObject:currentCell.photoItem forKey:currentCell.photoItem.assetLocalIdentifier];
    
    [self.selectedPhotos addObject:currentCell.photoItem];
    
    NSLog(@"选中了%ld个", (unsigned long)self.selectedPhotos.count);
}

#pragma mark - 最大选择数量提示

- (void)showMaxSelectCountTip{
    
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:[NSString stringWithFormat:@"最多选择%ld张图片哦~~", (unsigned long)self.maxSelectCount] preferredStyle:(UIAlertControllerStyleAlert)];
    
    [alertVc addAction:[UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:nil]];
    
    [self presentViewController:alertVc animated:YES completion:nil];
}

#pragma mark - 取消选中

- (void)deSelectedPhotoWithCell:(JKPhotoBrowserCollectionViewCell *)currentCell {
    
    currentCell.photoItem.isSelected = NO;
    
    if (![self.dismissReloadIndexPaths containsObject:currentCell.photoItem.currentIndexPath]) {
        
        if (currentCell.photoItem.currentIndexPath != nil) {
            
            [self.dismissReloadIndexPaths addObject:currentCell.photoItem.currentIndexPath];
        }
    }
    
    if ([self.selectedPhotos containsObject:currentCell.photoItem]) {
        
        [self.selectedPhotos removeObject:currentCell.photoItem];
        
        if ([self.selectedPhotosIdentifierCache objectForKey:currentCell.photoItem.assetLocalIdentifier] != nil) {
            
            [self.selectedPhotosIdentifierCache removeObjectForKey:currentCell.photoItem.assetLocalIdentifier];
        }
        
    }else{
        
        JKPhotoItem *itm = [self.selectedPhotosIdentifierCache objectForKey:currentCell.photoItem.assetLocalIdentifier];
        
        if (itm == nil) {
            
            for (JKPhotoItem *it in self.selectedPhotos) {
                
                if ([it.assetLocalIdentifier isEqualToString:currentCell.photoItem.assetLocalIdentifier]) {
                    
                    itm = it;
                    
                    break;
                }
            }
            
        }else{
            
            [self.selectedPhotosIdentifierCache removeObjectForKey:currentCell.photoItem.assetLocalIdentifier];
        }
        
        if ([self.selectedPhotos containsObject:itm]) {
            
            [self.selectedPhotos removeObject:itm];
        }
    }
    
    NSLog(@"取消选中,当前选中了%ld个", (unsigned long)self.selectedPhotos.count);
}

#pragma mark - 退出

- (void)prepareToDismissWithCell:(JKPhotoBrowserCollectionViewCell *)currentCell dismissFrame:(CGRect)dismissFrame{
    
    self.presentationManager.touchImageView = currentCell.photoImageView;
    self.presentationManager.touchImage = currentCell.photoImageView.image;
    self.presentationManager.dismissFrame = dismissFrame;
    
    self.indexPath = (self.isShowSelectedPhotos || (!self.isAllPhotosAlbum)) ? currentCell.indexPath : [NSIndexPath indexPathForItem:currentCell.indexPath.item + 1 inSection:currentCell.indexPath.section];
    
    JKPhotoCollectionViewCell *fromCell = (JKPhotoCollectionViewCell *)[self.fromCollectionView cellForItemAtIndexPath:self.indexPath];
    self.presentationManager.fromImageView = fromCell.photoImageView;
    
    CGRect presentFrame = (fromCell.frame.size.width != fromCell.photoImageView.frame.size.width) ? [[UIApplication sharedApplication].keyWindow convertRect:fromCell.photoImageView.frame fromView:fromCell.photoImageView.superview] : [[UIApplication sharedApplication].keyWindow convertRect:fromCell.frame fromView:fromCell.superview];
    NSLog(@"presentFrame--->%@", NSStringFromCGRect(presentFrame));
    //    CGRect presentFrame = [fromCell.superview convertRect:fromCell.frame toView:[UIApplication sharedApplication].keyWindow];
    
    //    CGRect fromCollectionViewFrame = [self.fromCollectionView.superview convertRect:self.fromCollectionView.frame toView:[UIApplication sharedApplication].keyWindow];
    
    CGRect rect = CGRectMake(0, JKPhotoPickerNavBarHeight, JKScreenW, JKScreenH - JKPhotoPickerNavBarHeight - (70 + (JKPhotoPickerIsIphoneX ? JKPhotoPickerBottomSafeAreaHeight : 0)));
    
    CGRect bottomOrCompleteRect = [[UIApplication sharedApplication].keyWindow convertRect:self.fromCollectionView.frame fromView:self.fromCollectionView.superview];
    
    self.presentationManager.isZoomUpAnimation = NO;
    
    if (self.isShowSelectedPhotos) {
        
        self.presentationManager.isZoomUpAnimation = !CGRectIntersectsRect(presentFrame, bottomOrCompleteRect) || (self.initialSelectCount != self.selectedPhotos.count);
        
    }else{
        
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

#pragma mark - collectionView代理
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
}

- (void)dismiss{
    
    [self dismissViewControllerAnimated:YES completion:^{
        
        !self.completionBlock ? : self.completionBlock(self.selectedPhotos, self.dismissReloadIndexPaths, self.selectedPhotosIdentifierCache);
    }];
}

#pragma mark - scrollView代理
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    NSLog(@"可见cell--->%zd", self.collectionView.visibleCells.count);
    
    self.indexPath = [NSIndexPath indexPathForItem:(!self.isAllPhotosAlbum || self.isShowSelectedPhotos) ? scrollView.contentOffset.x / JKScreenW : scrollView.contentOffset.x / JKScreenW + 1 inSection:0];

    JKPhotoCollectionViewCell *fromCell = (JKPhotoCollectionViewCell *)[self.fromCollectionView cellForItemAtIndexPath:self.indexPath];

    CGRect presentFrame = (fromCell.frame.size.width != fromCell.photoImageView.frame.size.width) ? [[UIApplication sharedApplication].keyWindow convertRect:fromCell.photoImageView.frame fromView:fromCell.photoImageView.superview] : [[UIApplication sharedApplication].keyWindow convertRect:fromCell.frame fromView:fromCell.superview];
    
    self.presentationManager.presentFrame = presentFrame;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    [[PHImageManager defaultManager] cancelImageRequest:PHInvalidImageRequestID];
    NSLog(@"%d, %s",__LINE__, __func__);
}
@end
