//
//  JKPhotoPickerViewController.h
//  JKPhotoPicker
//
//  Created by albert on 2016/12/21.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JKPhotoItem;

@interface JKPhotoPickerViewController : UIViewController

/* 使用示例
 
 [JKPhotoPickerViewController showWithPresentVc:self maxSelectCount:7 seletedPhotos:self.selectCompleteView.photoItems completeHandler:^(NSArray *photoItems) {
 [self.imageView removeFromSuperview];
 self.imageView = nil;
 
 // photoItems : 选好的图片asset，传给JKPhotoSelectCompleteView可获取selectedImages
 // 也可以使用类方法getSelectedImagesWithPhotoItems:获取原图自己处理
 // selectCompleteView : JKPhotoSelectCompleteView类的实例
 self.selectCompleteView.photoItems = photoItems;;
 }]; */


/**
 * presentVc        : 由哪个控制器present出来，传nil则由根控制器弹出
 * maxSelectCount   : 最多选择图片数量 默认7
 * seletedPhotos    : 已选择的图片，数组中放的是JKPhotoItem对象
 * completeHandler  : 选择完成的回调
 * isPenCameraFirst : 是否直接打开摄像头
 */
+ (void)showWithPresentVc:(UIViewController *)presentVc maxSelectCount:(NSUInteger)maxSelectCount seletedPhotos:(NSArray <JKPhotoItem *> *)seletedPhotos isPenCameraFirst:(BOOL)isPenCameraFirst completeHandler:(void(^)(NSArray <JKPhotoItem *> *photoItems))completeHandler;
@end
