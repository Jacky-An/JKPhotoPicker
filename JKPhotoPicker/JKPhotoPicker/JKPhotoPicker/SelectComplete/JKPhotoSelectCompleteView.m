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

/** 选中的asset数组 */
@property (nonatomic, strong) NSMutableArray *selectedAssetArray;

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

- (NSMutableArray *)selectedAssetArray{
    if (!_selectedAssetArray) {
        _selectedAssetArray = [NSMutableArray array];
    }
    return _selectedAssetArray;
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
        
        videoCacheDirectoryPath_ = [NSTemporaryDirectory() stringByAppendingPathComponent:@"JKPhotoPickerVideoCache"];
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
    
    if (@available(iOS 9.0, *)) {
        
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
    } else {
        
    }
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

#pragma mark
#pragma mark - 写入沙盒

/** 将单个PHAsset写入某一目录 */
+ (void)writeAsset:(PHAsset *)asset
       toDirectory:(NSString *)directory
          complete:(void(^)(NSString *filePath, NSError *error))complete{
    
    if (!asset || !directory) {
        
        !complete ? : complete(nil, nil);
        
        return;
    }
    
    NSString *fileName = [asset valueForKeyPath:@"filename"];
    
    if (!fileName) {
        
        NSString *identifier = asset.localIdentifier;
        
        if ([identifier containsString:@"/"]) {
            
            identifier = [identifier stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
        }
        
        fileName = identifier;
    }
    
    if (!fileName) {
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
        
        fileName = [NSString stringWithFormat:@"%@.jpg", [formatter stringFromDate:[NSDate new]]];
    }
    
    NSString *filePath = [directory stringByAppendingPathComponent:fileName];
    
    filePath = [self checkDuplicationNameWithFilePath:filePath isFolder:NO];
    
    NSURL *URL = [NSURL fileURLWithPath:filePath];
    
    if (@available(iOS 9.0, *)) {
        
        PHAssetResourceRequestOptions *options = [[PHAssetResourceRequestOptions alloc] init];
        options.networkAccessAllowed = YES;
        
        PHAssetResource *resource = [PHAssetResource assetResourcesForAsset:asset].firstObject;
        
        [[PHAssetResourceManager defaultManager] writeDataForAssetResource:resource toFile:URL options:options completionHandler:^(NSError * _Nullable error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (error) {
                    
                    !complete ? : complete(filePath, error);
                    
                    return;
                }
                
                !complete ? : complete(filePath, nil);
            });
        }];
    }
}

/** 将多个PHAsset写入某一目录 */
+ (void)writeAssets:(NSArray <PHAsset *> *)assets
        toDirectory:(NSString *)directory
           progress:(void(^)(NSInteger completeCout, NSInteger totalCount))progress
           complete:(void(^)(NSArray <NSString *> *successFilePaths, NSArray <PHAsset *> *successAssets, NSArray <NSString *> *failureFilePaths))complete{
    
    if (!assets || !directory) {
        
        !complete ? : complete(nil, nil, nil);
        
        return;
    }
    
    static NSMutableArray *successArr = nil;
    static NSMutableArray *successAssetArr = nil;
    static NSMutableArray *failureArr = nil;
    static NSInteger totalCount = 0;
    
    if (!successArr) {
        
        successArr = [NSMutableArray array];
    }
    
    if (!successAssetArr) {
        
        successAssetArr = [NSMutableArray array];
    }
    
    if (!failureArr) {
        
        failureArr = [NSMutableArray array];
    }
    
    if (!totalCount) {
        
        totalCount = assets.count;
    }
    
    if (assets.count <= 0) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            !complete ? : complete([successArr copy], [successAssetArr copy], [failureArr copy]);
            
            [successArr removeAllObjects];
            [failureArr removeAllObjects];
            
            successArr = nil;
            failureArr = nil;
            totalCount = 0;
        });
        
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSMutableArray *tmpArr = [NSMutableArray arrayWithArray:assets];
        
        [self writeAsset:tmpArr.firstObject toDirectory:directory complete:^(NSString *filePath, NSError *error) {
            
            if (filePath) {
                
                if (error) {
                    
                    [failureArr addObject:filePath];
                    
                } else {
                    
                    [successArr addObject:filePath];
                    [successAssetArr addObject:tmpArr.firstObject];
                }
            }
            
            [tmpArr removeObjectAtIndex:0];
            
            CGFloat finishCount = (successArr.count + failureArr.count) * 1.0 ;
            
            !progress ? : progress(finishCount, totalCount);
            
            [self writeAssets:tmpArr toDirectory:directory progress:progress complete:complete];
        }];
    });
}

/** 将多个JKPhotoItem写入某一目录 */
+ (void)writePhotoItems:(NSArray <JKPhotoItem *> *)items
            toDirectory:(NSString *)directory
               progress:(void(^)(NSInteger completeCout, NSInteger totalCount))progress
               complete:(void(^)(NSArray <NSString *> *successFilePaths, NSArray <JKPhotoItem *> *successItemss, NSArray <NSString *> *failureFilePaths))complete{
    
    if (!items || !directory) {
        
        !complete ? : complete(nil, nil, nil);
        
        return;
    }
    
    static NSMutableArray *successArr = nil;
    static NSMutableArray *successItemArr = nil;
    static NSMutableArray *failureArr = nil;
    static NSInteger totalCount = 0;
    
    if (!successArr) {
        
        successArr = [NSMutableArray array];
    }
    
    if (!successItemArr) {
        
        successItemArr = [NSMutableArray array];
    }
    
    if (!failureArr) {
        
        failureArr = [NSMutableArray array];
    }
    
    if (!totalCount) {
        
        totalCount = items.count;
    }
    
    if (items.count <= 0) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            !complete ? : complete([successArr copy], [successItemArr copy], [failureArr copy]);
            
            [successArr removeAllObjects];
            [successItemArr removeAllObjects];
            [failureArr removeAllObjects];
            
            successArr = nil;
            successItemArr = nil;
            failureArr = nil;
            
            totalCount = 0;
        });
        
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSMutableArray *tmpArr = [NSMutableArray arrayWithArray:items];
        
        JKPhotoItem *item = tmpArr.firstObject;
        
        [self writeAsset:item.photoAsset toDirectory:directory complete:^(NSString *filePath, NSError *error) {
            
            if (filePath) {
                
                if (error) {
                    
                    [failureArr addObject:filePath];
                    
                } else {
                    
                    [successArr addObject:filePath];
                    [successItemArr addObject:item];
                }
            }
            
            [tmpArr removeObjectAtIndex:0];
            
            CGFloat finishCount = (successArr.count + failureArr.count) * 1.0 ;
            
            !progress ? : progress(finishCount, totalCount);
            
            [self writeAssets:tmpArr toDirectory:directory progress:progress complete:complete];
        }];
    });
}


#pragma mark
#pragma mark - 检查重名

/**
 * 检查重名，并返回合适的文件路径
 * filePath : 要检查重名的路径
 * sourceFilePath : 源文件，用于判断是否文件夹，来决定重名后的命名方式
 * 如果是文件夹，则直接加(1)，文件则在后缀前加(1)
 */
+ (NSString *)checkDuplicationNameWithFilePath:(NSString *)filePath sourceFilePath:(NSString *)sourceFilePath{
    
    BOOL isDirectory = NO;
    
    // 检查源文件路径
    if (![[NSFileManager defaultManager] fileExistsAtPath:sourceFilePath isDirectory:&isDirectory]) {
        
        return filePath;
    }
    
    return [self checkDuplicationNameWithFilePath:filePath isFolder:isDirectory];
}

/**
 * 检查重名，并返回合适的文件路径
 * filePath : 要检查重名的路径
 * isFolder : 是否文件夹，决定重名后的命名方式
 * 如果是文件夹，则直接加(1)，文件则在后缀前加(1)
 */
+ (NSString *)checkDuplicationNameWithFilePath:(NSString *)filePath isFolder:(BOOL)isFolder{
    
    NSString *destinationPath = [filePath copy];
    
    // 检查目标文件路径
    if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
        
        return destinationPath;
    }
    
    NSString *jointString1 = @"";
    NSString *jointString2 = @"";
    
    if (isFolder) {
        
        jointString1 = destinationPath;
        
    } else {
        
        // 判断是否重名
        
        // 文件后缀
        NSString *pathExtension = [destinationPath pathExtension];
        
        // 文件后缀是空字符串
        if (!pathExtension || [pathExtension isEqualToString:@""]) {
            
            NSString *lastCharacter = [destinationPath substringFromIndex:destinationPath.length - 1];
            
            if ([lastCharacter isEqualToString:@"."]) {
                
                if (destinationPath.length <= 1) {
                    
                    jointString1 = @"";
                    
                } else {
                    
                    jointString1 = [destinationPath substringToIndex:destinationPath.length - 1];
                }
                
                jointString2 = lastCharacter;
                
            } else {
                
                jointString1 = destinationPath;
                jointString2 = @"";
            }
            
        } else {
            
            jointString1 = [destinationPath substringToIndex:destinationPath.length - pathExtension.length - 1];
            
            jointString2 = [destinationPath substringFromIndex:destinationPath.length - pathExtension.length - 1];
        }
        
    }
    
    int index = 0;
    
    while ([[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
        
        index++;
        
        destinationPath = [[jointString1 stringByAppendingString:[NSString stringWithFormat:@"(%d)", index]] stringByAppendingString:jointString2];
    }
    
    return destinationPath;
}

#pragma mark - 清理缓存的视频

+ (BOOL)clearVideoCache{
    
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"JKPhotoPickerVideoCache"] error:nil];
    
    return success;
}

#pragma mark
#pragma mark - 删除相册或照片

/// 删除照片
+ (void)deleteAssets:(NSArray<PHAsset *> *)assets completeHandler:(void(^)(BOOL success, NSError *error))completeHandler{
    
    if (!assets || assets.count <= 0) {
        
        !completeHandler ? : completeHandler(NO, nil);
        
        return;
    }
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        
        [PHAssetChangeRequest deleteAssets:assets];
        
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            !completeHandler ? : completeHandler(success, error);
        });
    }];
}

/// 删除相册
+ (void)deleteAssetCollections:(NSArray<PHAssetCollection *> *)assetCollections completeHandler:(void(^)(BOOL success, NSError *error))completeHandler{
    
    if (!assetCollections || assetCollections.count <= 0) {
        
        !completeHandler ? : completeHandler(NO, nil);
        
        return;
    }
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        
        [PHAssetCollectionChangeRequest deleteAssetCollections:assetCollections];
        
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            !completeHandler ? : completeHandler(success, error);
        });
    }];
}

#pragma mark
#pragma mark - 写入相册

/// 将视频/图片等写入相册
+ (void)saveMediaToAlbumWithURLArray:(NSArray <NSURL *> *)URLArray
                   completionHandler:(void(^)(BOOL success, NSError *error))completionHandler{
    
    if (!URLArray || URLArray.count <= 0) { return; }
    
    // 首先获取相册的集合
    PHFetchResult *collectonResuts = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    
    PHAssetCollection *assetCollection = collectonResuts.firstObject;
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        
        NSMutableArray *arrM = [NSMutableArray array];
        
        [URLArray enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            // 请求创建一个Asset
            PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:obj];
            
            // 为Asset创建一个占位符，放到相册编辑请求中
            PHObjectPlaceholder *placeHolder = [assetRequest placeholderForCreatedAsset];
            
            [arrM addObject:placeHolder];
        }];
        
        // 请求编辑相册
        PHAssetCollectionChangeRequest *collectonRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
        
        // 相册中添加媒体
        [collectonRequest addAssets:arrM];
        
    } completionHandler:^(BOOL success, NSError *error) {
        
        NSLog(@"%@", [NSThread currentThread]);
        
        if (success) {
            
            NSLog(@"保存视频成功!");
            
        } else {
            
            NSLog(@"保存视频失败:%@", error);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            !completionHandler ? : completionHandler(success, error);
        });
    }];
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

- (void)setAssets:(NSArray<PHAsset *> *)assets{
    
    [self.selectedAssetArray removeAllObjects];
    [self.selectedAssetArray addObjectsFromArray:assets];
}

- (NSArray<PHAsset *> *)assets{
    
    return self.selectedAssetArray;
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
    dict[@"selectedAssets"] = self.selectedAssetArray;
    dict[@"maxSelectCount"] = @(NSIntegerMax);
    dict[@"imageView"] = cell.photoImageView;
    dict[@"collectionView"] = collectionView;
    dict[@"indexPath"] = indexPath;
    dict[@"isSelectedCell"] = @(YES);
    dict[@"isShowSelectedPhotos"] = @(YES);
    
    [JKPhotoBrowserViewController showWithViewController:self.superViewController dataDict:dict completion:^(NSArray <JKPhotoItem *> *seletedPhotos, NSArray<PHAsset *> *selectedAssetArray, NSArray <NSIndexPath *> *indexPaths, NSMutableDictionary *selectedPhotosIdentifierCache) {
        
        if (self.selectedPhotoItems.count == seletedPhotos.count) {
            return;
        }
        
        [self.selectedPhotoItems removeAllObjects];
        [self.selectedPhotoItems addObjectsFromArray:seletedPhotos];
        
        [self.selectedAssetArray removeAllObjects];
        [self.selectedAssetArray addObjectsFromArray:seletedPhotos];
        
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
