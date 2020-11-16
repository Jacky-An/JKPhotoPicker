//
//  JKPhotoUtility.h
//  JKPhotoPicker
//
//  Created by albert on 2019/4/20.
//  Copyright © 2019 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark
#pragma mark - 枚举

typedef NS_ENUM(NSUInteger, JKPhotoPickerMediaDataType) {
    JKPhotoPickerMediaDataTypeUnknown = 0,
    JKPhotoPickerMediaDataTypeStaticImage,
    JKPhotoPickerMediaDataTypeGif,
    JKPhotoPickerMediaDataTypeImageIncludeGif,
    JKPhotoPickerMediaDataTypeVideo,
    JKPhotoPickerMediaDataTypePhotoLive,
    JKPhotoPickerMediaDataTypeAll,
};

typedef NS_ENUM(NSUInteger, JKPhotoPickerScrollDirection) {
    JKPhotoPickerScrollDirectionNone,
    JKPhotoPickerScrollDirectionUp,
    JKPhotoPickerScrollDirectionDown,
};



#pragma mark
#pragma mark - 宏定义

/** 屏幕bounds */
#define JKPhotoScreenBounds ([UIScreen mainScreen].bounds)
/** 屏幕宽度 */
#define JKPhotoScreenWidth ([UIScreen mainScreen].bounds.size.width)
/** 屏幕高度 */
#define JKPhotoScreenHeight ([UIScreen mainScreen].bounds.size.height)
/** 屏幕scale */
#define JKPhotoScreenScale ([UIScreen mainScreen].scale)

/** 屏幕bounds */
#define JKPhotoKeyWindowBounds (JKPhotoUtility.keyWindow.bounds)
/** 屏幕宽度 */
#define JKPhotoKeyWindowWidth (JKPhotoUtility.keyWindow.frame.size.width)
/** 屏幕高度 */
#define JKPhotoKeyWindowHeight (JKPhotoUtility.keyWindow.frame.size.height)

// 快速设置颜色
#define JKPhotoColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define JKPhotoColorAlpha(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]

#define JKPhotoSystemBlueColor [UIColor colorWithRed:0.f green:122.0/255.0 blue:255.0/255.0 alpha:1]

#define JKPhotoSystemRedColor [UIColor colorWithRed:255.0/255.0 green:59.0/255.0 blue:48.0/255.0 alpha:1]



#pragma mark
#pragma mark - 适配

/// 颜色适配
UIColor * JKPhotoAdaptColor (UIColor *lightColor, UIColor *darkColor);



#pragma mark
#pragma mark - JKPhotoUtility

@interface JKPhotoUtility : NSObject

/// 是否X设备
@property (class, nonatomic, readonly) BOOL isDeviceX;

/// 是否iPad
@property (class, nonatomic, readonly) BOOL isDeviceiPad;

/// 当前是否横屏
@property (class, nonatomic, readonly) BOOL isLandscape;

/** keyWindow */
@property (class, nonatomic, readonly) UIWindow *keyWindow;

/// 导航条高度
@property (class, nonatomic, readonly) CGFloat navigationBarHeight;

/// 当前HomeIndicator高度
@property (class, nonatomic, readonly) CGFloat currentHomeIndicatorHeight;

/// 缩略图尺寸
@property (class, nonatomic, readonly) CGSize thumbSize;

/// 目前iPhone屏幕最大宽度
@property (class, nonatomic, readonly) CGFloat iPhoneMaxScreenWidth;
@end
