//
//  JKPhotoResourceManager.h
//  JKPhotoPicker
//
//  Created by albert on 2019/4/20.
//  Copyright © 2019 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface JKPhotoResourceManager : NSObject

+ (NSBundle *)resourceBundle;

/** 名称和type分开 */
+ (UIImage *)jk_imageNamed:(NSString *)name type:(NSString *)type;

/** 默认type为png */
+ (UIImage *)jk_imageNamed:(NSString *)name;
@end

NS_ASSUME_NONNULL_END
