//
//  JKPhotoPickerViewController.h
//  JKPhotoPicker
//
//  Created by albert on 2016/12/21.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JKPhotoPickerMacro.h"

@class JKPhotoItem, PHAsset;

@interface JKPhotoPickerViewController : UIViewController

/**
 * presentVc         : 由哪个控制器present出来，传nil则由根控制器弹出
 * maxSelectCount    : 最多选择图片数量 默认7
 * seletedItems      : 已选择的item，数组中放的是JKPhotoItem对象
 * dataType          : 要选择的数据类型
 * completeHandler   : 选择完成的回调
 */
+ (void)showWithPresentVc:(UIViewController *)presentVc
           maxSelectCount:(NSUInteger)maxSelectCount
             seletedItems:(NSArray <JKPhotoItem *> *)seletedItems
                 dataType:(JKPhotoPickerMediaDataType)dataType
          completeHandler:(void(^)(NSArray <JKPhotoItem *> *photoItems, NSArray<PHAsset *> *selectedAssetArray))completeHandler;

/**
 * 使用UIImagePicker
 * presentVc : 由哪个控制器present出来，传nil则由根控制器弹出
 * dataType : 要选择的数据类型 仅支持JKPhotoPickerMediaDataTypeStaticImage和JKPhotoPickerMediaDataTypeVideo
 * allowsEditing : 是否允许编辑
 * completeHandler : 选择完成的回调
 */
//+ (void)showUIImagePickerWithPresentVc:(UIViewController *)presentVc dataType:(JKPhotoPickerMediaDataType)dataType allowsEditing:(BOOL)allowsEditing completeHandler:(void(^)(UIImage *image))completeHandler;
@end
