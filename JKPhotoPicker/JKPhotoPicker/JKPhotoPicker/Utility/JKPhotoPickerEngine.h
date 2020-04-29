//
//  JKPhotoPickerEngine.h
//  JKPhotoPicker
//
//  Created by albert on 2019/10/22.
//  Copyright © 2019 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PHAssetCollection, PHFetchResult, PHAsset, JKPhotoAlbumItem, JKPhotoItem;

NS_ASSUME_NONNULL_BEGIN

@interface JKPhotoPickerEngine : NSObject

#pragma mark
#pragma mark - 队列

+ (dispatch_queue_t)engineQueue;

+ (void)destroyEngineQueue;

#pragma mark
#pragma mark - 获取相册列表

/// 获取所有相册 PHAssetCollection
+ (void)fetchAllAlbumCollectionIncludeHiddenAlbum:(BOOL)includeHiddenAlbum
                                         complete:(void(^)(NSArray <PHAssetCollection *> *albumCollectionList))complete;

/// 获取所有相册 JKPhotoAlbumItem
+ (void)fetchAllAlbumItemIncludeHiddenAlbum:(BOOL)includeHiddenAlbum
                                   complete:(void(^)(NSArray <PHAssetCollection *> *albumCollectionList, NSArray <JKPhotoAlbumItem *> *albumItemList, NSCache *albumItemCache))complete;

#pragma mark
#pragma mark - 获取相册中照片集

/// 获取相册PHAsset合集
+ (void)fetchPhotoAssetListWithCollection:(PHAssetCollection *)collection
                                 complete:(void(^)(NSArray <PHAsset *> *assetList))complete;

/// 获取相册JKPhotoItem合集
+ (void)fetchPhotoItemListWithCollection:(PHAssetCollection *)collection
                      reverseResultArray:(BOOL)reverseResultArray
                       selectedItemCache:(NSCache *)selectedItemCache
                       showTakePhotoIcon:(BOOL)showTakePhotoIcon
                         completeHandler:(void(^)(NSArray <PHAssetCollection *> *albumCollectionList, NSArray <JKPhotoAlbumItem *> *albumItemList, NSCache *albumItemCache))completeHandler;





/** 获取全部相册 数组中是JKPhotoItem对象 */
+ (NSMutableArray *)getAlbumItemListWithCache:(NSCache *)cache;


/** 获取相机胶卷所有照片对象 倒序 数组中是PHAsset对象 */
+ (NSMutableArray *)getCameraRollAssets;

/** 获取某一个相册的所有照片对象 倒序 数组中是PHAsset对象 */
+ (NSMutableArray *)getPhotoAssetsWithAssetCollection:(PHAssetCollection *)assetCollection;

/** 获取某一个相册的结果集 */
+ (PHFetchResult *)getFetchResultWithAssetCollection:(PHAssetCollection *)assetCollection;

/** 从某一个相册结果集中获取图片实体，并把图片结果存放到数组中，返回值数组中是PHAsset对象 */
+ (NSMutableArray *)getPhotoAssetsWithFetchResult:(PHFetchResult *)fetchResult;

/** 从某一个相册结果集中获取图片实体，并把图片结果存放到数组中，返回值数组中是PHAsset对象 */
+ (NSMutableArray *)getPhotoAssetsWithFetchResult:(PHFetchResult *)fetchResult
                                       optionDict:(NSDictionary * _Nullable)optionDict
                                         complete:(void(^ _Nullable)(NSDictionary *resultDict))complete ;

/** 只获取相机胶卷结果集 */
+ (PHFetchResult *)getCameraRollFetchResult;
@end

NS_ASSUME_NONNULL_END
