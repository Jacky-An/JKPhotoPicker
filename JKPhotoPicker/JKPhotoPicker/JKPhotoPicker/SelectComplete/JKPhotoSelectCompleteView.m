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

@interface JKPhotoSelectCompleteView () <UICollectionViewDataSource, UICollectionViewDelegate>
{
    NSArray *_selectedImages;
}
/** collectionView */
@property (nonatomic, weak) UICollectionView *collectionView;

/** 选中的图片数组 */
@property (nonatomic, strong) NSMutableArray *selectedPhotoItems;

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
- (NSMutableArray *)selectedPhotoItems{
    if (!_selectedPhotoItems) {
        _selectedPhotoItems = [NSMutableArray array];
    }
    return _selectedPhotoItems;
}

- (PHCachingImageManager *)cachingImageManager{
    if (!_cachingImageManager) {
        _cachingImageManager = [[PHCachingImageManager alloc] init];
    }
    return _cachingImageManager;
}

//- (NSArray *)selectedImages{
//    if (_selectedImages.count != self.selectedPhotoItems.count) {
//        NSMutableArray *tmpArr = [NSMutableArray array];
//        
//        for (JKPhotoItem *itm in self.selectedPhotoItems) {
//            [tmpArr addObject:itm.originalImage];
//        }
//        
//        _selectedImages = tmpArr;
//    }
//    return _selectedImages;
//}

#pragma mark - 获取原图

NSMutableArray *dataArr_;

+ (void)getOriginalImagesWithItems:(NSArray <JKPhotoItem *> *)items complete:(void(^)(NSArray <UIImage *> *originalImages))complete{
    
    if (!dataArr_) {
        
        dataArr_ = [NSMutableArray array];
    }
    
    if (items.count == 0) {
        
        NSArray *arr = [dataArr_ copy];
        [dataArr_ removeAllObjects];
        dataArr_ = nil;
        
        !complete ? : complete(arr);
        
        return;
    }
    
    NSMutableArray *tmpArr = [NSMutableArray arrayWithArray:items];
    
    [self getOriginalImageWithItem:tmpArr.firstObject complete:^(UIImage *originalImage, NSDictionary *info) {
        
        [tmpArr removeObjectAtIndex:0];
        
        if (originalImage != nil) {
            
            [dataArr_ addObject:originalImage];
        }
        
        [self getOriginalImagesWithItems:tmpArr complete:complete];
    }];
}

+ (void)getOriginalImageWithItem:(JKPhotoItem *)item complete:(void(^)(UIImage *originalImage, NSDictionary * info))complete{
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc]init];
    options.synchronous = YES;
    options.networkAccessAllowed = YES;
    
    [[PHImageManager defaultManager] requestImageForAsset:item.photoAsset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            !complete ? : complete(result, info);
        });
    }];
}

#pragma mark - 获取原图data

/** 获取单张原图data */
+ (void)getOriginalImageDataWithItem:(JKPhotoItem *)item complete:(void(^)(NSData *imageData, NSDictionary * info))complete{
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc]init];
    options.synchronous = YES;
    options.networkAccessAllowed = YES;
    
    [[PHImageManager defaultManager] requestImageDataForAsset:item.photoAsset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            !complete ? : complete(imageData, info);
        });
    }];
}

/** 获取多张原图data */
+ (void)getOriginalImageDatasWithItems:(NSArray <JKPhotoItem *> *)items complete:(void(^)(NSArray <NSData *> *imageDatas))complete{
    
    if (!dataArr_) {
        
        dataArr_ = [NSMutableArray array];
    }
    
    if (items.count == 0) {
        
        NSArray *arr = [dataArr_ copy];
        [dataArr_ removeAllObjects];
        dataArr_ = nil;
        
        !complete ? : complete(arr);
        
        return;
    }
    
    NSMutableArray *tmpArr = [NSMutableArray arrayWithArray:items];
    
    [self getOriginalImageDataWithItem:tmpArr.firstObject complete:^(NSData *imageData, NSDictionary *info) {
        
        [tmpArr removeObjectAtIndex:0];
        
        if (imageData != nil) {
            
            [dataArr_ addObject:imageData];
        }
        
        [self getOriginalImageDatasWithItems:tmpArr complete:complete];
    }];
}

#pragma mark - 获取livePhoto

/** 获取单个livePhoto */
+ (void)getLivePhotoPathWithItem:(JKPhotoItem *)item complete:(void(^)(PHLivePhoto *livePhoto))complete{
    
    PHLivePhotoRequestOptions *options = [[PHLivePhotoRequestOptions alloc]init];
    options.networkAccessAllowed = YES;
    
    [[PHImageManager defaultManager] requestLivePhotoForAsset:item.photoAsset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (livePhoto) {
                
                !complete ? : complete(livePhoto);
                
                return;
            }
            
            !complete ? : complete(nil);
        });
    }];
}

/** 获取多个livePhoto */
+ (void)getLivePhotoPathWithItems:(NSArray <JKPhotoItem *> *)items complete:(void(^)(NSArray <PHLivePhoto *> *livePhotos))complete{
    
    if (!dataArr_) {
        
        dataArr_ = [NSMutableArray array];
    }
    
    if (items.count == 0) {
        
        NSArray *arr = [dataArr_ copy];
        [dataArr_ removeAllObjects];
        dataArr_ = nil;
        
        !complete ? : complete(arr);
        
        return;
    }
    
    NSMutableArray *tmpArr = [NSMutableArray arrayWithArray:items];
    
    [self getLivePhotoPathWithItem:tmpArr.firstObject complete:^(PHLivePhoto *livePhoto) {
        
        [tmpArr removeObjectAtIndex:0];
        
        if (livePhoto != nil) {
            
            [dataArr_ addObject:livePhoto];
        }
        
        [self getLivePhotoPathWithItems:tmpArr complete:complete];
    }];
}

#pragma mark - 获取原视频文件

static NSString *videoCacheDirectoryPath_;

+ (NSString *)videoCacheDirectoryPath{
    
    if (!videoCacheDirectoryPath_) {
        
        videoCacheDirectoryPath_ = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"JKPhotoPickerVideoCache"];
    }
    
    return videoCacheDirectoryPath_;
}

+ (void)getVideoDataPathWithItem:(JKPhotoItem *)item complete:(void(^)(NSString *videoPath))complete{
    
    NSString *path = [self videoCacheDirectoryPath];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        NSError *error = nil;
        
        BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (!success) {
            
            NSLog(@"创建文件路径失败");
            
            return;
        }
    }
    
    NSString *identifier = item.photoAsset.localIdentifier;
    
    if ([identifier containsString:@"/"]) {
        
        identifier = [identifier stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    }
    
    identifier = [identifier stringByAppendingString:@".mp4"];
    
    path = [path stringByAppendingPathComponent:identifier];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        !complete ? : complete(path);
        
        return;
    }
    
    PHAssetResourceRequestOptions *options = [[PHAssetResourceRequestOptions alloc] init];
    
    PHAssetResource *resource = [PHAssetResource assetResourcesForAsset:item.photoAsset].firstObject;
    
    [[PHAssetResourceManager defaultManager] writeDataForAssetResource:resource toFile:[NSURL fileURLWithPath:path] options:options completionHandler:^(NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            if (error) {
                
                !complete ? : complete(nil);
                
                return;
            }
            
            !complete ? : complete(path);
        });
    }];
}

+ (void)getVideoDataPathWithItems:(NSArray <JKPhotoItem *> *)items complete:(void(^)(NSArray <NSString *> *videoPaths))complete{
    
    if (!dataArr_) {
        
        dataArr_ = [NSMutableArray array];
    }
    
    if (items.count == 0) {
        
        NSArray *arr = [dataArr_ copy];
        [dataArr_ removeAllObjects];
        dataArr_ = nil;
        
        !complete ? : complete(arr);
        
        return;
    }
    
    NSMutableArray *tmpArr = [NSMutableArray arrayWithArray:items];
    
    [self getVideoDataPathWithItem:tmpArr.firstObject complete:^(NSString *videoPath) {
        
        [tmpArr removeObjectAtIndex:0];
        
        if (videoPath) {
            
            [dataArr_ addObject:videoPath];
        }
        
        [self getVideoDataPathWithItems:tmpArr complete:complete];
    }];
}

#pragma mark - 清理缓存的视频

+ (BOOL)clearVideoCache{
    
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"JKPhotoPickerVideoCache"] error:nil];
    
    return success;
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
    _collectionView = collectionView;
    
    // 注册cell
    [collectionView registerClass:[JKPhotoSelectCompleteCollectionViewCell class] forCellWithReuseIdentifier:reuseID];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    self.collectionView.frame = self.bounds;
}

- (void)setPhotoItems:(NSArray *)photoItems{
    
    [self.selectedPhotoItems removeAllObjects];
    [self.selectedPhotoItems addObjectsFromArray:photoItems];
    
    _photoItems = self.selectedPhotoItems;
    
    // 缓存原图
    if (self.selectedPhotoItems.count <= 0) return;
    
    [self.cachingImageManager startCachingImagesForAssets:[self.selectedPhotoItems valueForKeyPath:@"photoAsset"] targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:nil];
    
    [self.collectionView reloadData];
}

#pragma mark - collectionView数据源
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.selectedPhotoItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    JKPhotoSelectCompleteCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseID forIndexPath:indexPath];
    
    JKPhotoItem *item = self.selectedPhotoItems[indexPath.row];
    
    cell.photoItem = item;
    
    [self solveSelectBlockWithCell:cell];
    
    return cell;
}

- (void)solveSelectBlockWithCell:(JKPhotoSelectCompleteCollectionViewCell *)cell{
#pragma mark - 删除选中的照片
    if (!cell.deleteButtonClickBlock) {
        
        __weak typeof(self) weakSelf = self;
        
        [cell setDeleteButtonClickBlock:^(JKPhotoCollectionViewCell *currentCell) {
            
            [weakSelf deleteSelectedPhotoWithCell:currentCell];
        }];
    }
}

- (void)deleteSelectedPhotoWithCell:(JKPhotoCollectionViewCell *)currentCell{
    
    currentCell.photoItem.isSelected = NO;
    [self.selectedPhotoItems removeObject:currentCell.photoItem];
    
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:currentCell];
    
    if (indexPath != nil) {
        
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
        
    }else{
        
        [self.collectionView performBatchUpdates:^{
            
            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            
        } completion:^(BOOL finished) {
            
        }];
    }
    
    !self.selectCompleteViewDidDeletePhotoBlock ? : self.selectCompleteViewDidDeletePhotoBlock(self.selectedPhotoItems);
}

#pragma mark - collectionView代理
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    JKPhotoSelectCompleteCollectionViewCell *cell = (JKPhotoSelectCompleteCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"allPhotos"] = nil;
    dict[@"selectedItems"] = self.selectedPhotoItems;
    dict[@"maxSelectCount"] = @(NSIntegerMax);
    dict[@"imageView"] = cell.photoImageView;
    dict[@"collectionView"] = collectionView;
    dict[@"indexPath"] = indexPath;
    dict[@"isSelectedCell"] = @(YES);
    dict[@"isShowSelectedPhotos"] = @(YES);
    
    [JKPhotoBrowserViewController showWithViewController:self.superViewController dataDict:dict completion:^(NSArray <JKPhotoItem *> *seletedPhotos, NSArray <NSIndexPath *> *indexPaths, NSMutableDictionary *selectedPhotosIdentifierCache) {
        
        if (self.selectedPhotoItems.count == seletedPhotos.count) {
            return;
        }
        
        [self.selectedPhotoItems removeAllObjects];
        [self.selectedPhotoItems addObjectsFromArray:seletedPhotos];
        
        [self.collectionView performBatchUpdates:^{
            
            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            
        } completion:^(BOOL finished) {
            
        }];
        
        !self.selectCompleteViewDidDeletePhotoBlock ? : self.selectCompleteViewDidDeletePhotoBlock(self.selectedPhotoItems);
    }];
}

- (void)dealloc{
    NSLog(@"%d, %s",__LINE__, __func__);
}
@end
