//
//  JKPhotoPicker.m
//  JKPhotoPicker
//
//  Created by albert on 2019/4/20.
//  Copyright © 2019 安永博. All rights reserved.
//

#import "JKPhotoPicker.h"
#import "JKPhotoPickerViewController.h"

@implementation JKPhotoPicker

+ (void)showWithConfiguration:(void(^)(JKPhotoConfiguration *configuration))configuration
              completeHandler:(void(^)(NSArray <JKPhotoItem *> *photoItems, NSArray<PHAsset *> *selectedAssetArray))completeHandler{
    
    [JKPhotoPickerViewController showWithConfiguration:configuration completeHandler:completeHandler];
}
@end
