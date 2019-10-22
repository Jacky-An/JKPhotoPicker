//
//  JKPhotoPickerEngine.m
//  JKPhotoPicker
//
//  Created by albert on 2019/10/22.
//  Copyright © 2019 安永博. All rights reserved.
//

#import "JKPhotoPickerEngine.h"
#import <Photos/Photos.h>
#import "JKPhotoAlbumItem.h"
#import "JKPhotoItem.h"

@implementation JKPhotoPickerEngine

/** 获取全部相册 数组中是JKPhotoItem对象 */
+ (NSMutableArray *)getAlbumItemListWithCache:(NSCache *)cache{
    
    NSMutableArray *arr = [JKPhotoPickerEngine getAlbumCollectionList];
    
    NSMutableArray *albumItemArray = [NSMutableArray array];
    
    NSInteger index = 0;
    
    for (PHAssetCollection *assetCollection in arr) {
        
        PHFetchResult *result = [JKPhotoPickerEngine getFetchResultWithAssetCollection:assetCollection];
        
        if (index > 0 && result.count <= 0) continue;
        
        JKPhotoAlbumItem *albumItem = [[JKPhotoAlbumItem alloc] init];
        
        albumItem.assetCollection = assetCollection;
        albumItem.fetchResult = result;
        albumItem.imagesCount = result.count;
        albumItem.thumbAsset = result.lastObject;
        
        [albumItemArray addObject:albumItem];
        
        index++;
        
        if (cache == nil || albumItem.localIdentifier == nil) { continue; }
        
        [cache setObject:albumItem forKey:albumItem.localIdentifier];
    }
    
    return albumItemArray;
}

/** 获取全部相册 数组中是PHAssetCollection对象 */
+ (NSMutableArray *)getAlbumCollectionList{
    
    NSMutableArray *dataArray = [NSMutableArray array];
    
    // 获取资源时的参数，为nil时则是使用系统默认值
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    
    // 列出所有的智能相册
    PHFetchResult *smartAlbumsFetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:fetchOptions];
    
    for (PHAssetCollection *sub in smartAlbumsFetchResult) {
        
        if (sub.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
            
            [dataArray insertObject:sub atIndex:0];
            
            continue;
        }
        
        [dataArray addObject:sub];
    }
    
    // 列出所有用户创建的相册
    PHFetchResult *smartAlbumsFetchResult1 = [PHAssetCollection fetchTopLevelUserCollectionsWithOptions:fetchOptions];
    
    // 遍历
    for (PHAssetCollection *sub in smartAlbumsFetchResult1) {
        
        [dataArray addObject:sub];
    }
    
    return dataArray;
}

/** 获取相机胶卷所有照片对象 倒序 数组中是PHAsset对象 */
+ (NSMutableArray *)getCameraRollAssets{
    
    return [self getPhotoAssetsWithFetchResult:[self getCameraRollFetchResult]];
}

/** 获取某一个相册的所有照片对象 倒序 数组中是PHAsset对象 */
+ (NSMutableArray *)getPhotoAssetsWithAssetCollection:(PHAssetCollection *)assetCollection{
    
    return [self getPhotoAssetsWithFetchResult:[self getFetchResultWithAssetCollection:assetCollection]];
}

/** 获取某一个相册的结果集 */
+ (PHFetchResult *)getFetchResultWithAssetCollection:(PHAssetCollection *)assetCollection{
    
    return [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
}

/** 从某一个相册结果集中获取图片实体，并把图片结果存放到数组中，返回值数组中是PHAsset对象 */
+ (NSMutableArray *)getPhotoAssetsWithFetchResult:(PHFetchResult *)fetchResult{
    
    return [self getPhotoAssetsWithFetchResult:fetchResult optionDict:nil complete:nil];
}

/** 从某一个相册结果集中获取图片实体，并把图片结果存放到数组中，返回值数组中是PHAsset对象 */
+ (NSMutableArray *)getPhotoAssetsWithFetchResult:(PHFetchResult *)fetchResult
                                       optionDict:(NSDictionary * _Nullable)optionDict
                                         complete:(void(^ _Nullable)(NSDictionary *resultDict))complete {
    
    NSCache *allCache = [[NSCache alloc] init];
    NSDictionary *seletedCache = optionDict[@"seletedCache"];
    
    BOOL showTakePhotoIcon = [optionDict[@"showTakePhotoIcon"] boolValue];
    
    NSMutableArray *seletedNewItems = [NSMutableArray array];
    NSMutableDictionary *seletedNewCache = [NSMutableDictionary dictionary];
    
    NSMutableArray *dataArray = [NSMutableArray array];
    
    __block NSInteger i = ((showTakePhotoIcon && seletedCache != nil) ? 0 : -1);
    
    [fetchResult enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        
        i++;
        
        JKPhotoItem *item = [[JKPhotoItem alloc] init];
        item.photoAsset = asset;
        item.currentIndexPath = [NSIndexPath indexPathForItem:i inSection:0];
        
        if (allCache != nil) {
            
            [allCache setObject:item forKey:item.assetLocalIdentifier];
        }
        
        if ([seletedCache objectForKey:item.assetLocalIdentifier] != nil) {
            
            [seletedNewItems addObject:item];
            [seletedNewCache setObject:item forKey:item.assetLocalIdentifier];
        }
        
        [dataArray addObject:item];
    }];
    
    NSMutableDictionary *dictM = [NSMutableDictionary dictionary];
    
    dictM[@"allPhotos"] = dataArray;
    dictM[@"allCache"] = allCache;
    dictM[@"seletedItems"] = seletedNewItems;
    dictM[@"seletedCache"] = seletedNewCache;
    
    !complete ? : complete(dictM);
    
    return dataArray;
}

/** 只获取相机胶卷结果集 */
+ (PHFetchResult *)getCameraRollFetchResult{
    
    // 获取系统相册CameraRoll 的结果集
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    
    PHFetchResult *smartAlbumsFetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:fetchOptions];
    
    PHFetchResult *fetch = [PHAsset fetchAssetsInAssetCollection:[smartAlbumsFetchResult objectAtIndex:0] options:fetchOptions];
    
    return fetch;
}
@end

/* 参数说明
 1、asset，图像对应的 PHAsset。
 
 2、targetSize，需要获取的图像的尺寸，如果输入的尺寸大于资源原图的尺寸，则只返回原图。需要注意在 PHImageManager 中，所有的尺寸都是用 Pixel 作为单位（Note that all sizes are in pixels），因此这里想要获得正确大小的图像，需要把输入的尺寸转换为 Pixel。如果需要返回原图尺寸，可以传入 PhotoKit 中预先定义好的常量?PHImageManagerMaximumSize，表示返回可选范围内的最大的尺寸，即原图尺寸。
 
 3、contentMode，图像的剪裁方式，与?UIView 的 contentMode 参数相似，控制照片应该以按比例缩放还是按比例填充的方式放到最终展示的容器内。注意如果 targetSize 传入?PHImageManagerMaximumSize，则 contentMode 无论传入什么值都会被视为?PHImageContentModeDefault。
 
 4、options，一个?PHImageRequestOptions 的实例，可以控制的内容相当丰富，包括图像的质量、版本，也会有参数控制图像的剪裁，下面再展开说明。
 
 5、resultHandler，请求结束后被调用的 block，返回一个包含资源对于图像的 UIImage 和包含图像信息的一个 NSDictionary，在整个请求的周期中，这个 block 可能会被多次调用，关于这点连同 options 参数在下面展开说明。
 */
