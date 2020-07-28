//
//  JKPhotoUtility.m
//  JKPhotoPicker
//
//  Created by albert on 2019/4/20.
//  Copyright © 2019 安永博. All rights reserved.
//

#import "JKPhotoUtility.h"
#import <AudioToolbox/AudioToolbox.h>

#pragma mark
#pragma mark - 适配

/// 颜色适配
UIColor * JKPhotoAdaptColor (UIColor *lightColor, UIColor *darkColor) {
    
    if (@available(iOS 13.0, *)) {
        
        UIColor *color = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            
            if ([traitCollection userInterfaceStyle] == UIUserInterfaceStyleLight) {
                
                return lightColor;
            }

            return darkColor;
        }];
        
        return color;
        
    } else {
        
        return lightColor;
    }
}

#pragma mark
#pragma mark - JKPhotoUtility

@implementation JKPhotoUtility

/// 是否X设备
+ (BOOL)isDeviceX {
    
    static BOOL isDeviceX_ = NO;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (@available(iOS 11.0, *)) {
            
            if (!self.isDeviceiPad) {
                
                isDeviceX_ = self.keyWindow.safeAreaInsets.bottom > 0.0;
            }
        }
    });
    
    return isDeviceX_;
}

/// 是否iPad
+ (BOOL)isDeviceiPad {
    
    static BOOL isDeviceiPad_ = NO;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        isDeviceiPad_ = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    });
    
    return isDeviceiPad_;
}

/// 当前是否横屏
+ (BOOL)isLandscape {
    
    return [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
}

/// keyWindow
+ (UIWindow *)keyWindow {
    
    UIWindow *keyWindow = nil;
    
    if ([[UIApplication sharedApplication].delegate respondsToSelector:@selector(window)]) {
        
        keyWindow = [[UIApplication sharedApplication].delegate window];
        
    } else {
        
        NSArray *windows = [UIApplication sharedApplication].windows;
        
        for (UIWindow *window in windows) {
            
            if (window.hidden) { continue; }
            
            keyWindow = window;
            
            break;
        }
    }
    
    return keyWindow;
}

/// 导航条高度
+ (CGFloat)navigationBarHeight {
    
    if (self.isDeviceiPad) { // iPad
        
        return self.isLandscape ? 70.f : 64.f;
        
    } else { // iPhone
        
        return self.isLandscape ? (self.isDeviceX ? 44.f : 32.f) : (self.isDeviceX ? 88.f : 64.f);
    }
}

/// 当前HomeIndicator高度
+ (CGFloat)currentHomeIndicatorHeight {
    
    return self.isDeviceX ? (self.isLandscape ? 21.0 : 34.0) : 0.0;
}

/// 缩略图尺寸
+ (CGSize)thumbSize {
    
    static CGSize thumbSize_ = {0, 0};
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        CGFloat wh = 100 * JKPhotoScreenScale;
        
        thumbSize_ = CGSizeMake(wh, wh);
    });
    
    return thumbSize_;
}

@end
