//
//  JKPhotoResultModel.h
//  JKPhotoPicker
//
//  Created by albertcc on 2020/4/29.
//  Copyright © 2020 安永博. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PHAsset, JKPhotoItem;

@interface JKPhotoResultModel : NSObject

/** assetList */
@property (nonatomic, strong) NSArray <PHAsset *> *assetList;

/** assetList */
@property (nonatomic, strong) NSArray <JKPhotoItem *> *itemList;

/** assetList */
@property (nonatomic, strong) NSCache *itemCache;

/** selectedAssetList */
@property (nonatomic, strong) NSArray <JKPhotoItem *> *selectedAssetList;

/** selectedItemList */
@property (nonatomic, strong) NSArray <JKPhotoItem *> *selectedItemList;

/** selectedItemCache */
@property (nonatomic, strong) NSCache *selectedItemCache;
@end
