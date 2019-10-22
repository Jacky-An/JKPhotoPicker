//
//  JKPhotoManager.h
//  JKPhotoPicker
//
//  Created by albert on 2016/12/21.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface JKPhotoManager : NSObject

/** 检查相册访问权限 */
+ (void)checkPhotoAccessWithPresentVc:(UIViewController *)presentVc finished:(void (^)(BOOL isAccessed))finished;

/** 检查相机访问权限 */
+ (void)checkCameraAccessWithPresentVc:(UIViewController *)presentVc finished:(void(^)(BOOL isAccessed))finished;

/** 检查麦克风访问权限 */
+ (void)checkMicrophoneAccessWithPresentVc:(UIViewController *)presentVc finished:(void(^)(BOOL isAccessed))finished;
@end
