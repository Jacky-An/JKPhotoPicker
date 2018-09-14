//
//  JKPhotoManager.h
//  JKPhotoPicker
//
//  Created by albert on 2016/12/21.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Photos/Photos.h>

@interface JKPhotoManager : NSObject
/** 检查相册访问权限 */
+ (void)checkPhotoAccessFinished:(void(^)(BOOL isAccessed))finished;

/** 检查相机访问权限 */
+ (void)checkCameraAccessFinished:(void(^)(BOOL isAccessed))finished;

/** 检查麦克风访问权限 */
+ (void)checkMicrophoneAccessFinished:(void(^)(BOOL isAccessed))finished;

/** 获取相机胶卷所有照片对象 倒序 数组中是PHAsset对象 */
+ (NSMutableArray *)getCameraRollAssets;

/** 获取全部相册 数组中是PHAssetCollection对象 */
+ (NSMutableArray *)getAlbumList;

/** 获取某一个相册的所有照片对象 倒序 数组中是PHAsset对象 */
+ (NSMutableArray *)getPhotoAssetsWithAssetCollection:(PHAssetCollection *)assetCollection;

/** 获取某一个相册的结果集 */
+ (PHFetchResult *)getFetchResultWithAssetCollection:(PHAssetCollection *)assetCollection;

/** 从某一个相册结果集中获取图片实体，并把图片结果存放到数组中，返回值数组中是PHAsset对象 */
+ (NSMutableArray *)getPhotoAssetsWithFetchResult:(PHFetchResult *)fetchResult;

/** 从某一个相册结果集中获取图片实体，并把图片结果存放到数组中，返回值数组中是PHAsset对象 */
+ (NSMutableArray *)getPhotoAssetsWithFetchResult:(PHFetchResult *)fetchResult optionDict:(NSDictionary *)optionDict complete:(void(^)(NSDictionary *resultDict))complete ;

/** 只获取相机胶卷结果集 */
+ (PHFetchResult *)getCameraRollFetchResult;


/** 从照片实体PHAsset中获取缩略图 不推荐，不知道为什么封装起来很卡 */
+ (void)getThumImageObject:(id)asset complection:(void (^)(UIImage *image, BOOL isDegradedImage))complection;

/** 从照片实体PHAsset中获取原图 不推荐，不知道为什么封装起来很卡 */
+ (void)getOriginalImageObject:(id)asset complection:(void (^)(UIImage *image, BOOL isDegradedImage))complection;

/** 
 * 从照片实体PHAsset中获取照片对象 不推荐，不知道为什么封装起来很卡
 * targetSize : 获取目标像素大小
 * isDegradedImage : 是否低清图
 */
+ (void)getImageObject:(id)asset targetSize:(CGSize)targetSize complection:(void (^)(UIImage *image, BOOL isDegradedImage))complection;
@end

/* 参数说明
 1、asset，图像对应的 PHAsset。
 
 2、targetSize，需要获取的图像的尺寸，如果输入的尺寸大于资源原图的尺寸，则只返回原图。需要注意在 PHImageManager 中，所有的尺寸都是用 Pixel 作为单位（Note that all sizes are in pixels），因此这里想要获得正确大小的图像，需要把输入的尺寸转换为 Pixel。如果需要返回原图尺寸，可以传入 PhotoKit 中预先定义好的常量?PHImageManagerMaximumSize，表示返回可选范围内的最大的尺寸，即原图尺寸。
 
 3、contentMode，图像的剪裁方式，与?UIView 的 contentMode 参数相似，控制照片应该以按比例缩放还是按比例填充的方式放到最终展示的容器内。注意如果 targetSize 传入?PHImageManagerMaximumSize，则 contentMode 无论传入什么值都会被视为?PHImageContentModeDefault。
 
 4、options，一个?PHImageRequestOptions 的实例，可以控制的内容相当丰富，包括图像的质量、版本，也会有参数控制图像的剪裁，下面再展开说明。
 
 5、resultHandler，请求结束后被调用的 block，返回一个包含资源对于图像的 UIImage 和包含图像信息的一个 NSDictionary，在整个请求的周期中，这个 block 可能会被多次调用，关于这点连同 options 参数在下面展开说明。
 */
