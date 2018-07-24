//
//  JKPhotoPickerViewController.h
//  JKPhotoPicker
//
//  Created by albert on 2016/12/21.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JKPhotoPickerMacro.h"

@class JKPhotoItem;

@interface JKPhotoPickerViewController : UIViewController

/**
 * presentVc         : 由哪个控制器present出来，传nil则由根控制器弹出
 * maxSelectCount    : 最多选择图片数量 默认7
 * seletedItems      : 已选择的item，数组中放的是JKPhotoItem对象
 * dataType          : 要选择的数据类型，暂时仅支持staticImage和video
 * completeHandler   : 选择完成的回调
 * isOpenCameraFirst : 是否直接打开摄像头
 */
+ (void)showWithPresentVc:(UIViewController *)presentVc maxSelectCount:(NSUInteger)maxSelectCount seletedItems:(NSArray <JKPhotoItem *> *)seletedItems dataType:(JKPhotoPickerMediaDataType)dataType isOpenCameraFirst:(BOOL)isOpenCameraFirst completeHandler:(void(^)(NSArray <JKPhotoItem *> *photoItems))completeHandler;
@end
