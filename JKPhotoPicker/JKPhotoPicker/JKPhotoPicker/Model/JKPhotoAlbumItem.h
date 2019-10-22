//
//  JKPhotoAlbumItem.h
//  JKPhotoPicker
//
//  Created by albert on 2019/10/22.
//  Copyright © 2019 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PHAssetCollection, PHFetchResult, PHAsset;

@interface JKPhotoAlbumItem : NSObject

/** 相册 */
@property (nonatomic, strong) PHAssetCollection *assetCollection;

/** 相册的结果集 */
@property (nonatomic, strong) PHFetchResult *fetchResult;

/** 相册的标识 */
@property (nonatomic, copy, readonly) NSString *localIdentifier;

/* 相册的缩略图asset */
@property (nonatomic, strong) PHAsset *thumbAsset;

/** 相册标题 */
@property (nonatomic, copy, readonly) NSString *albumTitle;

/** 相册图片数量 */
@property (nonatomic, assign) NSInteger imagesCount;
@end
