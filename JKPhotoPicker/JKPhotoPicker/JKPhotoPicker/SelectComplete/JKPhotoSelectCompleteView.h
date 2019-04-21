//
//  JKPhotoSelectCompleteView.h
//  JKPhotoPicker
//
//  Created by albert on 2016/12/29.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@class JKPhotoItem, PHAsset;

@interface JKPhotoSelectCompleteView : UIView

/** 选中的图片模型数组 JKPhotoItem */
@property (nonatomic, strong) NSArray <JKPhotoItem *> *photoItems;

/** 选中的图片模型数组 PHAsset */
@property (nonatomic, strong) NSArray <PHAsset *> *assets;

/** 流水布局 */
@property (nonatomic, strong, readonly) UICollectionViewFlowLayout *flowLayout;

/** 监听删除选中的图片的block */
@property (nonatomic, copy) void (^selectCompleteViewDidDeletePhotoBlock)(NSArray <JKPhotoItem *> *photoItems);

/** 获取单张原图 */
+ (void)getOriginalImageWithItem:(JKPhotoItem *)item complete:(void(^)(UIImage *originalImage, NSDictionary * info))complete;

/** 获取多张原图 */
+ (void)getOriginalImagesWithItems:(NSArray <JKPhotoItem *> *)items complete:(void(^)(NSArray <UIImage *> *originalImages))complete;

/** 获取单张原图data */
+ (void)getOriginalImageDataWithItem:(JKPhotoItem *)item complete:(void(^)(NSData *imageData, NSDictionary * info))complete;

/** 获取多张原图data */
+ (void)getOriginalImageDatasWithItems:(NSArray <JKPhotoItem *> *)items complete:(void(^)(NSArray <NSData *> *imageDatas))complete;

/** 获取单个livePhoto */
+ (void)getLivePhotoPathWithItem:(JKPhotoItem *)item complete:(void(^)(PHLivePhoto *livePhoto))complete API_AVAILABLE(ios(9.1));

/** 获取多个livePhoto */
+ (void)getLivePhotoPathWithItems:(NSArray <JKPhotoItem *> *)items complete:(void(^)(NSArray <PHLivePhoto *> *livePhotos))complete API_AVAILABLE(ios(9.1));

/** 获取单个视频data缓存路径 */
+ (void)getVideoDataPathWithItem:(JKPhotoItem *)item complete:(void(^)(NSString *videoPath))complete;

/** 获取多个视频data缓存路径 */
+ (void)getVideoDataPathWithItems:(NSArray <JKPhotoItem *> *)items complete:(void(^)(NSArray <NSString *> *videoPaths))complete;

/** 将单个PHAsset写入某一目录 */
+ (void)writeAsset:(PHAsset *)asset
       toDirectory:(NSString *)directory
          complete:(void(^)(NSString *filePath, NSError *error))complete;

/** 将多个PHAsset写入某一目录 */
+ (void)writeAssets:(NSArray <PHAsset *> *)assets
        toDirectory:(NSString *)directory
           progress:(void(^)(NSInteger completeCout, NSInteger totalCount))progress
           complete:(void(^)(NSArray <NSString *> *successFilePaths, NSArray <PHAsset *> *successAssets, NSArray <NSString *> *failureFilePaths))complete;

/** 将多个JKPhotoItem写入某一目录 */
+ (void)writePhotoItems:(NSArray <JKPhotoItem *> *)items
            toDirectory:(NSString *)directory
               progress:(void(^)(NSInteger completeCout, NSInteger totalCount))progress
               complete:(void(^)(NSArray <NSString *> *successFilePaths, NSArray <JKPhotoItem *> *successItemss, NSArray <NSString *> *failureFilePaths))complete;

/** 选择视频的缓存文件夹路径 */
+ (NSString *)videoCacheDirectoryPath;

/** 清理缓存的视频，直接清除缓存文件夹 */
+ (BOOL)clearVideoCache;

#pragma mark
#pragma mark - 删除相册或照片

/// 删除照片
+ (void)deleteAssets:(NSArray<PHAsset *> *)assets completeHandler:(void(^)(BOOL success, NSError *error))completeHandler;

/// 删除相册
+ (void)deleteAssetCollections:(NSArray<PHAssetCollection *> *)assetCollections completeHandler:(void(^)(BOOL success, NSError *error))completeHandler;

#pragma mark
#pragma mark - 写入相册

/// 将视频/图片等写入相册
+ (void)saveMediaToAlbumWithURLArray:(NSArray <NSURL *> *)URLArray
                             isVideo:(BOOL)isVideo
                   completionHandler:(void(^)(BOOL success, NSError *error))completionHandler;

/// 将视频/图片等写入指定相册
+ (void)saveMediaToAlbumWithName:(NSString *)albumName
                        URLArray:(NSArray <NSURL *> *)URLArray
                         isVideo:(BOOL)isVideo
               completionHandler:(void(^)(BOOL success, NSError *error))completionHandler;

/**
 * 类方法
 * superView : 父控件
 * viewController : 父控件所在的控制器，不传则无法预览已选择好的图片
 * frame : 设置frame
 * itemSize : cell的尺寸，注意高度要比宽度多10，图片才会是正方形
 */
+ (instancetype)completeViewWithSuperView:(UIView *)superView viewController:(UIViewController *)viewController frame:(CGRect)frame itemSize:(CGSize)itemSize scrollDirection:(UICollectionViewScrollDirection)scrollDirection;
@end
