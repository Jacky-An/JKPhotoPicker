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

+ (void)checkPhotoAccessWithPresentVc:(UIViewController *)presentVc finished:(void (^)(BOOL isAccessed))finished{
    
    if (![UIImagePickerController isSourceTypeAvailable:(UIImagePickerControllerSourceTypePhotoLibrary)]) {
        
        !finished ? : finished(NO);
        
        [self showRestrictAlertWithText:@"相册不支持" presentVc:presentVc];
        
        return;
    }
    
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined) {
        
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            
            NSLog(@"当前线程--->%@", [NSThread currentThread]);
            
            if (status == PHAuthorizationStatusAuthorized) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    !finished ? : finished(YES);
                });
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                !finished ? : finished(NO);
            });
        }];
        
        return;
    }
    
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) { // 有照片权限
        
        !finished ? : finished(YES);
        
        return;
    }
    
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusDenied) { // 没有照片权限
        
        [self jumpToSettingWithTip:@"当前程序未获得照片权限，是否打开？" presentVc:presentVc];
        
        return;
    }
    
    [self showRestrictAlertWithText:@"相册受限" presentVc:presentVc];
}

/** 检查相机访问权限 */
+ (void)checkCameraAccessWithPresentVc:(UIViewController *)presentVc finished:(void(^)(BOOL isAccessed))finished{
    
    if (![UIImagePickerController isSourceTypeAvailable:(UIImagePickerControllerSourceTypeCamera)]) {
        
        !finished ? : finished(NO);
        
        [self showRestrictAlertWithText:@"相机不可用" presentVc:presentVc];
        
        return;
    }
    
    AVAuthorizationStatus AVstatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];//相机权限
    switch (AVstatus) {
        case AVAuthorizationStatusAuthorized:
            //            NSLog(@"Authorized");
            
            !finished ? : finished(YES);
            break;
        case AVAuthorizationStatusDenied:
            //            NSLog(@"Denied");
            !finished ? : finished(NO);
            
            [self jumpToSettingWithTip:@"当前程序未获得相机权限，是否打开？" presentVc:presentVc];
            break;
        case AVAuthorizationStatusNotDetermined:
            //            NSLog(@"not Determined");
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {//相机权限
                if (granted) {
                    //                    NSLog(@"Authorized");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        !finished ? : finished(YES);
                    });
                }else{
                    //                    NSLog(@"Denied or Restricted");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        !finished ? : finished(NO);
                    });
                }
            }];
        }
            break;
        case AVAuthorizationStatusRestricted:
            
            !finished ? : finished(NO);
            
            [self showRestrictAlertWithText:@"相机受限" presentVc:presentVc];
            break;
        default:
            break;
    }
}

/** 检查麦克风访问权限 */
+ (void)checkMicrophoneAccessWithPresentVc:(UIViewController *)presentVc finished:(void(^)(BOOL isAccessed))finished{
    
    if ([AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio].count == 0) {
        
        !finished ? : finished(NO);
        [self showRestrictAlertWithText:@"麦克风不可用" presentVc:presentVc];
        
        return;
    }
    
    AVAuthorizationStatus AVstatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];//麦克风权限
    switch (AVstatus) {
        case AVAuthorizationStatusAuthorized:
            //            NSLog(@"Authorized");
            
            !finished ? : finished(YES);
            break;
        case AVAuthorizationStatusDenied:
            !finished ? : finished(NO);
            [self jumpToSettingWithTip:@"当前程序未获得麦克风权限，是否打开？" presentVc:presentVc];
            //            NSLog(@"Denied");
            break;
        case AVAuthorizationStatusNotDetermined:
            //            NSLog(@"not Determined");
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {//相机权限
                if (granted) {
                    //                    NSLog(@"Authorized");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        !finished ? : finished(YES);
                    });
                }else{
                    //                    NSLog(@"Denied or Restricted");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        !finished ? : finished(NO);
                    });
                }
            }];
        }
            break;
        case AVAuthorizationStatusRestricted:
            !finished ? : finished(NO);
            
            [self showRestrictAlertWithText:@"麦克风受限" presentVc:presentVc];
            break;
        default:
            break;
    }
}

+ (void)jumpToSettingWithTip:(NSString *)tip presentVc:(UIViewController *)presentVc{
    
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:tip preferredStyle:(UIAlertControllerStyleAlert)];
    
    [alertVc addAction:[UIAlertAction actionWithTitle:@"不用了" style:(UIAlertActionStyleDefault) handler:nil]];
    [alertVc addAction:[UIAlertAction actionWithTitle:@"去打开" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        // 打开本程序对应的权限设置
        [[UIApplication sharedApplication]openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }]];
    
    [(presentVc ? presentVc : [UIApplication sharedApplication].delegate.window.rootViewController) presentViewController:alertVc animated:YES completion:nil];
}

+ (void)showRestrictAlertWithText:(NSString *)text presentVc:(UIViewController *)presentVc{
    
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:text preferredStyle:(UIAlertControllerStyleAlert)];
    
    [alertVc addAction:[UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:nil]];
    
    [(presentVc ? presentVc : [UIApplication sharedApplication].delegate.window.rootViewController) presentViewController:alertVc animated:YES completion:nil];
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
    
    BOOL showTakePhotoIcon = [optionDict[@"showTakePhotoIcon"] boolValue];
    
    NSMutableArray *seletedNewItems = [NSMutableArray array];
    NSMutableDictionary *seletedNewCache = [NSMutableDictionary dictionary];
    
    NSMutableArray *dataArray = [NSMutableArray array];
    
    __block NSInteger i = ((showTakePhotoIcon && seletedCache != nil) ? 0 : -1);
    
    [fetchResult enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        
        // 只添加图片类型资源，去除视频类型资源
        // 当mediatype == 2时，资源则视为视频资源
        //        if (1 || asset.mediaType == PHAssetMediaTypeImage) {
        
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
        //        }
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
