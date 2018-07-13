//
//  JKPhotoManager.m
//  JKPhotoPicker
//
//  Created by albert on 2016/12/21.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import "JKPhotoManager.h"
#import "JKPhotoItem.h"

@implementation JKPhotoManager

+ (void)checkPhotoAccessFinished:(void (^)(BOOL isAccessed))finished{
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined) { // 照片权限未决定状态
        finished(NO);
        
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            
            NSLog(@"当前线程--->%@", [NSThread currentThread]);
            
            if (status == PHAuthorizationStatusAuthorized) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    finished(YES);
                });
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                finished(NO);
            });
        }];
        
        return;
    }
    
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) { // 有照片权限
        
        finished(YES);
        
        return;
    }
    
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusDenied) { // 没有照片权限
        UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:@"当前程序未获得照片权限，是否打开？由于iOS系统原因，设置照片权限会导致app崩溃，请知晓。" preferredStyle:(UIAlertControllerStyleAlert)];
        
        [alertVc addAction:[UIAlertAction actionWithTitle:@"不用了" style:(UIAlertActionStyleDefault) handler:nil]];
        [alertVc addAction:[UIAlertAction actionWithTitle:@"去打开" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            // 打开本程序对应的权限设置
            [[UIApplication sharedApplication]openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }]];
        
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alertVc animated:YES completion:nil];
        
        return;
    }
    
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:@"照片权限受限" preferredStyle:(UIAlertControllerStyleAlert)];
    
    [alertVc addAction:[UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:nil]];
    
    [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alertVc animated:YES completion:nil];
}

/** 获取相机胶卷所有照片对象 倒序 数组中是PHAsset对象 */
+ (NSMutableArray *)getCameraRollAssets{
    
    return [self getPhotoAssetsWithFetchResult:[self getCameraRollFetchResult]];
}

/** 获取全部相册 数组中是PHAssetCollection对象 */
+ (NSMutableArray *)getAlbumList{
    
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
+ (NSMutableArray *)getPhotoAssetsWithFetchResult:(PHFetchResult *)fetchResult optionDict:(NSDictionary *)optionDict complete:(void(^)(NSDictionary *resultDict))complete {
    
    NSCache *allCache = [[NSCache alloc] init];
    NSDictionary *seletedCache = optionDict[@"seletedCache"];
    
    NSMutableArray *seletedNewItems = [NSMutableArray array];
    NSMutableDictionary *seletedNewCache = [NSMutableDictionary dictionary];
    
    NSMutableArray *dataArray = [NSMutableArray array];
    
    __block NSInteger i = seletedCache == nil ? -1 : 0;
    
    [fetchResult enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        
        // 只添加图片类型资源，去除视频类型资源
        // 当mediatype == 2时，资源则视为视频资源
        if (asset.mediaType == PHAssetMediaTypeImage) {
            
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
        }
    }];
    
    NSMutableDictionary *dictM = [NSMutableDictionary dictionary];
    
    dictM[@"allPhotos"] = dataArray;
    dictM[@"allCache"] = allCache;
    dictM[@"seletedItems"] = seletedNewItems;
    dictM[@"seletedCache"] = seletedNewCache;
    
    !complete ? : complete(dictM);
    
//    for (PHAsset *asset in fetchResult) {
//        // 只添加图片类型资源，去除视频类型资源
//        // 当mediatype == 2时，资源则视为视频资源
//        if (asset.mediaType != PHAssetMediaTypeImage) continue;
//        
//        i++;
//        
//        JKPhotoItem *item = [[JKPhotoItem alloc] init];
//        item.photoAsset = asset;
//        item.currentIndexPath = [NSIndexPath indexPathForItem:i inSection:0];
//        
//        if (cache != nil) {
//            
//            [cache setObject:item forKey:item.assetLocalIdentifier];
//        }
//        
//        [dataArray insertObject:item atIndex:0];
//    }
    
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

/** 从照片实体PHAsset中获取原图 */
+ (void)getOriginalImageObject:(id)asset complection:(void (^)(UIImage *image, BOOL isDegradedImage))complection{
    if (![asset isKindOfClass:[PHAsset class]]) return;
    
    [self getImageObject:asset targetSize:PHImageManagerMaximumSize complection:complection];
}

/** 从照片实体PHAsset中获取缩略图 */
+ (void)getThumImageObject:(id)asset complection:(void (^)(UIImage *image, BOOL isDegradedImage))complection{
    if (![asset isKindOfClass:[PHAsset class]]) return;
    
    PHAsset *phAsset = (PHAsset *)asset;
    
    CGFloat photoWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat aspectRatio = phAsset.pixelWidth * 1.0 / (phAsset.pixelHeight * 1.0);
    // 屏幕分辨率 scale = 1 代表 分辨率是320 * 480; = 2 代表 分辨率是 640 * 960; = 3 代表 分辨率是 1242 * 2208
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat pixelWidth = photoWidth * scale;
    CGFloat pixelHeight = pixelWidth / aspectRatio;
    
    [self getImageObject:asset targetSize:CGSizeMake(pixelWidth, pixelHeight) complection:complection];
}

/** 从照片实体PHAsset中获取照片对象 */
+ (void)getImageObject:(id)asset targetSize:(CGSize)targetSize complection:(void (^)(UIImage *image, BOOL isDegradedImage))complection{
    
    if (![asset isKindOfClass:[PHAsset class]]) return;
    
    PHAsset *phAsset = (PHAsset *)asset;
    
//    CGFloat photoWidth = [UIScreen mainScreen].bounds.size.width;
//    CGFloat aspectRatio = phAsset.pixelWidth * 1.0 / (phAsset.pixelHeight * 1.0);
//    // 屏幕分辨率 scale = 1 代表 分辨率是320 * 480; = 2 代表 分辨率是 640 * 960; = 3 代表 分辨率是 1242 * 2208
//    CGFloat scale = [UIScreen mainScreen].scale;
//    CGFloat pixelWidth = photoWidth * scale;
//    CGFloat pixelHeight = pixelWidth / aspectRatio;
    /**
     * PHImageManager 是通过请求的方式拉取图像，并可以控制请求得到的图像的尺寸、剪裁方式、质量，缓存以及请求本身的管理（发出请求、取消请求）等
     *
     * pixelWidth  : 获取图片的宽
     * pixelHeight : 获取图片的高
     * contentMode : 图片的剪裁方式
     * options : options.synchronous = YES; // 默认为NO则获取的是低清图
     *
     */
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
//    options.synchronous = YES; // 默认为NO则获取的是低清图
    options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    options.resizeMode = PHImageRequestOptionsResizeModeFast; // 不强制尺寸与目标相同
    
    [[PHImageManager defaultManager] requestImageForAsset:phAsset targetSize:(targetSize.width <= 0 || targetSize.height <= 0) ? PHImageManagerMaximumSize : targetSize contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        complection(result, [[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
//        NSLog(@"系统方法获取图片-->当前线程--->%@", [NSThread currentThread]);
        // 排除取消，错误，低清图三种情况，即已经获取到了高清图
//        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] /*&& ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]*/);
//        
//        if (downloadFinined) {
//            // 回调
//            if (complection){
//                complection(result, [[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
//            }
//        }
    }];
}
@end
