//
//  JKPhotoItem.h
//  JKPhotoPicker
//
//  Created by albert on 2016/12/21.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark - 适配iOS11

#define JKPhotoPickerNavBarHeight (JKPhotoPickerIsIphoneX ? 88.0f : 64.0f)

#define JKPhotoPickerBottomSafeAreaHeight (34.0f)

#define JKPhotoPickerIsIphoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)

@class PHAsset, PHAssetCollection, PHFetchResult;

@interface JKPhotoItem : NSObject

/****************************照片相关****************************/

/* 是否选中 */
@property (nonatomic, assign) BOOL isSelected;

/** 索引 */
@property (nonatomic, strong) NSIndexPath *currentIndexPath;

/* 是否显示相机图标 */
@property (nonatomic, assign) BOOL isShowCameraIcon;

/* 当前显示的Image */
@property (nonatomic, strong) PHAsset *photoAsset;

/** 高清缩略图 */
@property (nonatomic, strong, readonly) UIImage *thumImage;

/** 原图 */
@property (nonatomic, strong, readonly) UIImage *originalImage;

/** 照片的标识 */
@property (nonatomic, copy, readonly) NSString *assetLocalIdentifier;



/****************************相册相关****************************/

/** 相册 */
@property (nonatomic, strong) PHAssetCollection *albumAssetCollection;

/** 相册的结果集 */
@property (nonatomic, strong) PHFetchResult *albumFetchResult;

/** 相册的标识 */
@property (nonatomic, copy, readonly) NSString *albumLocalIdentifier;

/* 相册的缩略图asset */
@property (nonatomic, strong) PHAsset *albumThumAsset;

/** 相册缩略图 */
@property (nonatomic, strong, readonly) UIImage *albumThumImage;

/** 相册标题 */
@property (nonatomic, copy, readonly) NSString *albumTitle;

/** 相册图片数量 */
@property (nonatomic, assign) NSInteger albumImagesCount;
@end
