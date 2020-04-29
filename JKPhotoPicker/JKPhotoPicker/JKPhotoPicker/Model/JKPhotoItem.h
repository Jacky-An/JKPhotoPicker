//
//  JKPhotoItem.h
//  JKPhotoPicker
//
//  Created by albert on 2016/12/21.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JKPhotoConst.h"

@class PHAsset, PHAssetCollection, PHFetchResult;

@interface JKPhotoItem : NSObject

/****************************照片相关****************************/

/* 是否可以选中 */
@property (nonatomic, assign, readonly) BOOL shouldSelected;

/* 是否可以播放gif */
@property (nonatomic, assign, readonly) BOOL shouldPlayGif;

/** 数据类型描述 */
@property (nonatomic, copy) NSString *dataTypeDescription;

/* 媒体类型 */
@property (nonatomic, assign, readonly) JKPhotoPickerMediaDataType dataType;

/* 是否选中 */
@property (nonatomic, assign) BOOL isSelected;

/** 照片列表中的索引 在所有照片中的索引 因为有个拍照，所以 +1  */
@property (nonatomic, strong) NSIndexPath *currentIndexPath;

/** 浏览器中的索引  */
@property (nonatomic, strong) NSIndexPath *browserIndexPath;

/* 是否显示相机图标 */
@property (nonatomic, assign) BOOL isShowCameraIcon;

/* 当前显示的Image */
@property (nonatomic, strong) PHAsset *photoAsset;

/** 照片的标识 */
@property (nonatomic, copy, readonly) NSString *assetLocalIdentifier;

/** 照片的文件名 */
@property (nonatomic, copy, readonly) NSString *fileName;



/****************************相册相关****************************/




/****************************视频相关****************************/

/** 视频缓存的路径 */
@property (nonatomic, copy, readonly) NSString *videoPath;






+ (void)setSelectDataType:(JKPhotoPickerMediaDataType)selectDataType;

+ (JKPhotoPickerMediaDataType)selectDataType;
@end
