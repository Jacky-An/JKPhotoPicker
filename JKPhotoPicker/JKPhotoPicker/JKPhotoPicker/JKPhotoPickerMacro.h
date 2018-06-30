//
//  JKPhotoPickerMacro.h
//  JKPhotoPicker
//
//  Created by albert on 2018/6/30.
//  Copyright © 2018年 安永博. All rights reserved.
//

#ifndef JKPhotoPickerMacro_h
#define JKPhotoPickerMacro_h



#define JKScreenW [UIScreen mainScreen].bounds.size.width
#define JKScreenH [UIScreen mainScreen].bounds.size.height
#define JKScreenBounds [UIScreen mainScreen].bounds


#pragma mark - 适配iOS11

#define JKPhotoPickerNavBarHeight (JKPhotoPickerIsIphoneX ? 88.0f : 64.0f)

#define JKPhotoPickerBottomSafeAreaHeight (34.0f)

#define JKPhotoPickerIsIphoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)






#endif /* JKPhotoPickerMacro_h */
