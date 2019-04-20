//
//  JKPhotoConst.h
//  JKPhotoPicker
//
//  Created by albert on 2019/4/20.
//  Copyright © 2019 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>


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

/// 当前导航条高度
#define JKPhotoCurrentNavigationBarHeight (JKPhotoIsLandscape() ? CGRectGetMaxY(self.navigationController.navigationBar.frame) : JKPhotoNavigationBarHeight())

/// 当前导航条高度
#define JKPhotoCurrentTabBarHeight (JKPhotoIsLandscape() ? self.tabBarController.tabBar.frame.size.height : JKPhotoTabBarHeight())

// 快速设置颜色
#define JKPhotoColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define JKPhotoColorAlpha(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]

#define JKPhotoSystemBlueColor [UIColor colorWithRed:0.f green:122.0/255.0 blue:255.0/255.0 alpha:1]

#define JKPhotoSystemRedColor [UIColor colorWithRed:255.0/255.0 green:59.0/255.0 blue:48.0/255.0 alpha:1]


#pragma mark
#pragma mark - 适配

/// 是否X设备
BOOL JKPhotoIsDeviceX (void);

/// 是否iPad
BOOL JKPlayerIsDeviceiPad (void);

/// 当前是否横屏
BOOL JKPhotoIsLandscape (void);

/// 状态栏高度
CGFloat JKPhotoStatusBarHeight (void);

/// 导航条高度
CGFloat JKPhotoNavigationBarHeight (void);

/// tabBar高度
CGFloat JKPhotoTabBarHeight (void);

/// X设备底部indicator高度
UIKIT_EXTERN CGFloat const JKPhotoHomeIndicatorHeight;

/// 当前设备底部indicator高度 非X为0
CGFloat JKPhotoCurrentHomeIndicatorHeight (void);

/// 使用KVC获取当前的状态栏的view
UIView * JKPhotoStatusBarView (void);


/// 让手机振动一下
void JKPhotoCibrateDevice (void);
