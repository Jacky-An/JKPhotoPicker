//
//  JKPhotoPickerViewController.h
//  JKPhotoPicker
//
//  Created by albert on 2016/12/21.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JKPhotoPickerViewController : UIViewController
/** maxSelectCount : 最多选择图片数量 默认3 */
+ (void)showWithMaxSelectCount:(NSUInteger)maxSelectCount seletedPhotos:(NSArray *)seletedPhotos completeHandler:(void(^)(NSArray *photoItems))completeHandler;
@end
