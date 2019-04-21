//
//  JKPhotoConfiguration.h
//  JKPhotoPicker
//
//  Created by albert on 2019/4/20.
//  Copyright © 2019 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JKPhotoConst.h"

@class JKPhotoItem;

NS_ASSUME_NONNULL_BEGIN

@interface JKPhotoConfiguration : NSObject

/** presentViewController */
@property (nonatomic, weak) UIViewController *presentViewController;

/** 最多选择图片数量 <= 0表示无限制 默认9 */
@property (nonatomic, assign) NSInteger maxSelectCount;

/** 是否在底部预览 默认YES */
@property (nonatomic, assign) BOOL shouldBottomPreview;

/** 已经选择的item */
@property (nonatomic, strong) NSArray <JKPhotoItem *> *seletedItems;

/**
 * 是否支持全选 默认NO
 * 若置为YES
 * 1、shouldBottomPreview将被忽略，不在底部预览
 * 2、seletedItems将被忽视
 * 3、切换相册将清空已选择项目
 */
@property (nonatomic, assign) BOOL shouldSelectAll;

/** 是否显示拍照按钮 默认YES */
@property (nonatomic, assign) BOOL showTakePhotoIcon;

/**
 * 是否先打开相机拍照 默认NO
 * 若showTakePhotoIcon为NO，不显示拍照图标 则此项无效
 */
@property (nonatomic, assign) BOOL takePhotoFirst;

/** 要选择的媒体类型 默认静态图片JKPhotoPickerMediaDataTypeStaticImage */
@property (nonatomic, assign) JKPhotoPickerMediaDataType selectDataType;
@end

NS_ASSUME_NONNULL_END
