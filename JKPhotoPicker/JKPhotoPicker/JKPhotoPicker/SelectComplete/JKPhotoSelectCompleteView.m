//
//  JKPhotoSelectCompleteView.m
//  JKPhotoPicker
//
//  Created by albert on 2016/12/29.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import "JKPhotoSelectCompleteView.h"
#import "JKPhotoSelectCompleteCollectionViewCell.h"
#import "JKPhotoItem.h"
#import "JKPhotoBrowserViewController.h"
#import <Photos/Photos.h>

@interface JKPhotoSelectCompleteView () <UICollectionViewDataSource, UICollectionViewDelegate>
{
    NSArray *_selectedImages;
}
/** collectionView */
@property (nonatomic, weak) UICollectionView *collectionView;

/** 选中的图片数组 */
@property (nonatomic, strong) NSMutableArray *selectedPhotos;

/** 父控件所在的控制器 */
@property (nonatomic, weak) UIViewController *superViewController;

/** 缓存管理对象 */
@property (nonatomic, strong) PHCachingImageManager *cachingImageManager;
@end

@implementation JKPhotoSelectCompleteView

static NSString * const reuseID = @"JKPhotoSelectCompleteCollectionViewCell"; // 重用ID

+ (instancetype)completeViewWithSuperView:(UIView *)superView viewController:(UIViewController *)viewController frame:(CGRect)frame itemSize:(CGSize)itemSize scrollDirection:(UICollectionViewScrollDirection)scrollDirection{
    JKPhotoSelectCompleteView *view = [[JKPhotoSelectCompleteView alloc] initWithFrame:frame];
    
    [superView addSubview:view];
    view.superViewController = viewController;
    view.flowLayout.itemSize = itemSize;
    view.flowLayout.scrollDirection = scrollDirection;
    
    if (scrollDirection == UICollectionViewScrollDirectionVertical) {
        
        view.collectionView.alwaysBounceVertical = YES;
        
    }else{
        view.collectionView.alwaysBounceHorizontal = YES;
    }
    
    return view;
}

#pragma mark - 懒加载
- (NSMutableArray *)selectedPhotos{
    if (!_selectedPhotos) {
        _selectedPhotos = [NSMutableArray array];
    }
    return _selectedPhotos;
}

- (PHCachingImageManager *)cachingImageManager{
    if (!_cachingImageManager) {
        _cachingImageManager = [[PHCachingImageManager alloc] init];
    }
    return _cachingImageManager;
}

- (NSArray *)selectedImages{
    if (_selectedImages.count != self.selectedPhotos.count) {
        NSMutableArray *tmpArr = [NSMutableArray array];
        
        for (JKPhotoItem *itm in self.selectedPhotos) {
            [tmpArr addObject:itm.originalImage];
        }
        
        _selectedImages = tmpArr;
    }
    return _selectedImages;
}

#pragma mark - 初始化
- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        [self initialization];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self initialization];
    }
    return self;
}

- (void)initialization{
    self.backgroundColor = [UIColor whiteColor];
    
    [self setupCollectionView];
}

- (void)setupCollectionView{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
//    flowLayout.itemSize = (self.itemSize.width <= 0 || self.itemSize.height <= 0) ? CGSizeMake((self.frame.size.width - 3) / 4, (self.frame.size.width - 3) / 4 + 10) : self.itemSize;
    flowLayout.minimumLineSpacing = 1;
    flowLayout.minimumInteritemSpacing = 1;
    _flowLayout = flowLayout;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) collectionViewLayout:flowLayout];
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.showsVerticalScrollIndicator = NO;
    collectionView.showsHorizontalScrollIndicator = NO;
    [self insertSubview:collectionView atIndex:0];
    self.collectionView = collectionView;
    
    // 注册cell
    [collectionView registerClass:[JKPhotoSelectCompleteCollectionViewCell class] forCellWithReuseIdentifier:reuseID];
}

- (void)setPhotoItems:(NSArray *)photoItems{
    _photoItems = nil;
    _photoItems = [photoItems copy];
    photoItems = nil;
    
    [self.selectedPhotos removeAllObjects];
    [self.selectedPhotos addObjectsFromArray:_photoItems];
    _photoItems = nil;
    _photoItems = self.selectedPhotos;
    
    // 缓存原图
    if (self.selectedPhotos.count <= 0) return;
    
    [self.cachingImageManager startCachingImagesForAssets:[self.selectedPhotos valueForKeyPath:@"photoAsset"] targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:nil];
    
    [self.collectionView reloadData];
}

#pragma mark - collectionView数据源
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.selectedPhotos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    JKPhotoSelectCompleteCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseID forIndexPath:indexPath];
    
    JKPhotoItem *item = self.selectedPhotos[indexPath.row];
    
    cell.photoItem = item;
    
    [self solveSelectBlockWithCell:cell];
    
    return cell;
}

- (void)solveSelectBlockWithCell:(JKPhotoSelectCompleteCollectionViewCell *)cell{
#pragma mark - 删除选中的照片
    if (!cell.deleteButtonClickBlock) {
        
        __weak typeof(self) weakSelf = self;
        
        [cell setDeleteButtonClickBlock:^(JKPhotoCollectionViewCell *currentCell) {
            currentCell.photoItem.isSelected = NO;
            [weakSelf.selectedPhotos removeObject:currentCell.photoItem];
            [weakSelf.collectionView reloadData];
        }];
    }
}

#pragma mark - collectionView代理
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    NSLog(@"hehheehhehe");
    
    JKPhotoSelectCompleteCollectionViewCell *cell = (JKPhotoSelectCompleteCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"allPhotos"] = nil;
    dict[@"selectedItems"] = self.selectedPhotos;
    dict[@"maxSelectCount"] = @(NSIntegerMax);
    dict[@"imageView"] = cell.photoImageView;
    dict[@"collectionView"] = collectionView;
    dict[@"indexPath"] = indexPath;
    
    [JKPhotoBrowserViewController showWithViewController:self.superViewController dataDict:dict completion:^(NSArray *seletedPhotos) {
        
        if (self.selectedPhotos.count == seletedPhotos.count) {
            return;
        }
        
        [self.selectedPhotos removeAllObjects];
        [self.selectedPhotos addObjectsFromArray:seletedPhotos];
        [self.collectionView reloadData];
    }];
}

- (void)dealloc{
    NSLog(@"%d, %s",__LINE__, __func__);
}
@end
