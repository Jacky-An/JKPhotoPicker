//
//  JKPhotoPicker.h
//  JKPhotoPicker
//
//  Created by albert on 2019/4/20.
//  Copyright © 2019 安永博. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JKPhotoConfiguration.h"
#import "JKPhotoSelectCompleteView.h"

NS_ASSUME_NONNULL_BEGIN

@interface JKPhotoPicker : NSObject

+ (void)showWithConfiguration:(void(^)(JKPhotoConfiguration *configuration))configuration
              completeHandler:(void(^)(NSArray <JKPhotoItem *> *photoItems, NSArray<PHAsset *> *selectedAssetArray))completeHandler;
@end

NS_ASSUME_NONNULL_END
