//
//  JKPhotoConfiguration.m
//  JKPhotoPicker
//
//  Created by albert on 2019/4/20.
//  Copyright © 2019 安永博. All rights reserved.
//

#import "JKPhotoConfiguration.h"

@implementation JKPhotoConfiguration

- (instancetype)init{
    if (self = [super init]) {
        _maxSelectCount = 9;
        _shouldBottomPreview = YES;
        _showTakePhotoIcon = YES;
        _selectDataType = JKPhotoPickerMediaDataTypeStaticImage;
    }
    return self;
}
@end
