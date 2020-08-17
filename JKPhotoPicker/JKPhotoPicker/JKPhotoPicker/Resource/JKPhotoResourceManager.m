//
//  JKPhotoResourceManager.m
//  JKPhotoPicker
//
//  Created by albert on 2019/4/20.
//  Copyright © 2019 安永博. All rights reserved.
//

#import "JKPhotoResourceManager.h"

@implementation JKPhotoResourceManager

+ (NSBundle *)resourceBundle {
    
    static NSBundle *jk_photoPickerBundle = nil;
    
    if (jk_photoPickerBundle == nil) {
        
        // 这里不使用mainBundle是为了适配pod 1.x和0.x
        jk_photoPickerBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"JKPhotoPickerResource" ofType:@"bundle"]];
    }
    
    return jk_photoPickerBundle;
}

/** 名称和type分开 */
+ (UIImage *)jk_imageNamed:(NSString *)name type:(NSString *)type {
    
    return [self jk_imageNamed:(type == nil ? name : [name stringByAppendingPathExtension:type])];
}

/** 默认type为png */
+ (UIImage *)jk_imageNamed:(NSString *)name {
    
    return [UIImage imageNamed:name inBundle:[self resourceBundle] compatibleWithTraitCollection:nil];
}
@end
