//
//  JKPhotoPickerEngine.h
//  JKPhotoPicker
//
//  Created by albert on 2019/10/22.
//  Copyright © 2019 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PHAssetCollection, PHFetchResult;

NS_ASSUME_NONNULL_BEGIN

@interface JKPhotoPickerEngine : NSObject

/** 获取全部相册 数组中是JKPhotoItem对象 */
+ (NSMutableArray *)getAlbumItemListWithCache:(NSCache *)cache;

/** 获取全部相册 数组中是PHAssetCollection对象 */
+ (NSMutableArray *)getAlbumCollectionList;


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
