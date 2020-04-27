//
//  JKPhotoManager.m
//  JKPhotoPicker
//
//  Created by albert on 2016/12/21.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import "JKPhotoManager.h"
#import <Photos/Photos.h>

@implementation JKPhotoManager

+ (void)checkPhotoAccessWithPresentVc:(UIViewController *)presentVc finished:(void (^)(BOOL isAccessed))finished{
    
    if (![UIImagePickerController isSourceTypeAvailable:(UIImagePickerControllerSourceTypePhotoLibrary)]) {
        
        !finished ? : finished(NO);
        
        [self showRestrictAlertWithText:@"相册不支持" presentVc:presentVc];
        
        return;
    }
    
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined) {
        
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            
            NSLog(@"当前线程--->%@", [NSThread currentThread]);
            
            if (status == PHAuthorizationStatusAuthorized) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    !finished ? : finished(YES);
                });
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                !finished ? : finished(NO);
            });
        }];
        
        return;
    }
    
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) { // 有照片权限
        
        !finished ? : finished(YES);
        
        return;
    }
    
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusDenied) { // 没有照片权限
        
        [self jumpToSettingWithTip:@"当前程序未获得照片权限，是否打开？" presentVc:presentVc];
        
        return;
    }
    
    [self showRestrictAlertWithText:@"相册受限" presentVc:presentVc];
}

/** 检查相机访问权限 */
+ (void)checkCameraAccessWithPresentVc:(UIViewController *)presentVc finished:(void(^)(BOOL isAccessed))finished{
    
    if (![UIImagePickerController isSourceTypeAvailable:(UIImagePickerControllerSourceTypeCamera)]) {
        
        !finished ? : finished(NO);
        
        [self showRestrictAlertWithText:@"相机不可用" presentVc:presentVc];
        
        return;
    }
    
    AVAuthorizationStatus AVstatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];//相机权限
    switch (AVstatus) {
        case AVAuthorizationStatusAuthorized:
            //            NSLog(@"Authorized");
            
            !finished ? : finished(YES);
            break;
        case AVAuthorizationStatusDenied:
            //            NSLog(@"Denied");
            !finished ? : finished(NO);
            
            [self jumpToSettingWithTip:@"当前程序未获得相机权限，是否打开？" presentVc:presentVc];
            break;
        case AVAuthorizationStatusNotDetermined:
            //            NSLog(@"not Determined");
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {//相机权限
                if (granted) {
                    //                    NSLog(@"Authorized");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        !finished ? : finished(YES);
                    });
                } else {
                    //                    NSLog(@"Denied or Restricted");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        !finished ? : finished(NO);
                    });
                }
            }];
        }
            break;
        case AVAuthorizationStatusRestricted:
            
            !finished ? : finished(NO);
            
            [self showRestrictAlertWithText:@"相机受限" presentVc:presentVc];
            break;
        default:
            break;
    }
}

/** 检查麦克风访问权限 */
+ (void)checkMicrophoneAccessWithPresentVc:(UIViewController *)presentVc finished:(void(^)(BOOL isAccessed))finished{
    
    if ([AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio].count == 0) {
        
        !finished ? : finished(NO);
        [self showRestrictAlertWithText:@"麦克风不可用" presentVc:presentVc];
        
        return;
    }
    
    AVAuthorizationStatus AVstatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];//麦克风权限
    switch (AVstatus) {
        case AVAuthorizationStatusAuthorized:
            //            NSLog(@"Authorized");
            
            !finished ? : finished(YES);
            break;
        case AVAuthorizationStatusDenied:
            !finished ? : finished(NO);
            [self jumpToSettingWithTip:@"当前程序未获得麦克风权限，是否打开？" presentVc:presentVc];
            //            NSLog(@"Denied");
            break;
        case AVAuthorizationStatusNotDetermined:
            //            NSLog(@"not Determined");
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {//相机权限
                if (granted) {
                    //                    NSLog(@"Authorized");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        !finished ? : finished(YES);
                    });
                } else {
                    //                    NSLog(@"Denied or Restricted");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        !finished ? : finished(NO);
                    });
                }
            }];
        }
            break;
        case AVAuthorizationStatusRestricted:
            !finished ? : finished(NO);
            
            [self showRestrictAlertWithText:@"麦克风受限" presentVc:presentVc];
            break;
        default:
            break;
    }
}

+ (void)jumpToSettingWithTip:(NSString *)tip presentVc:(UIViewController *)presentVc{
    
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:tip preferredStyle:(UIAlertControllerStyleAlert)];
    
    [alertVc addAction:[UIAlertAction actionWithTitle:@"不用了" style:(UIAlertActionStyleDefault) handler:nil]];
    [alertVc addAction:[UIAlertAction actionWithTitle:@"去打开" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        // 打开本程序对应的权限设置
        [[UIApplication sharedApplication]openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }]];
    
    [(presentVc ? presentVc : [UIApplication sharedApplication].delegate.window.rootViewController) presentViewController:alertVc animated:YES completion:nil];
}

+ (void)showRestrictAlertWithText:(NSString *)text presentVc:(UIViewController *)presentVc{
    
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:text preferredStyle:(UIAlertControllerStyleAlert)];
    
    [alertVc addAction:[UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:nil]];
    
    [(presentVc ? presentVc : [UIApplication sharedApplication].delegate.window.rootViewController) presentViewController:alertVc animated:YES completion:nil];
}
@end
