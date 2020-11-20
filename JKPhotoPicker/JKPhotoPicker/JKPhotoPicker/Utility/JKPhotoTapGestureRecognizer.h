//
//  JKPhotoTapGestureRecognizer.h
//  JKPhotoPicker
//
//  Created by albert on 2020/11/20.
//  Copyright © 2020 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface JKPhotoTapGestureRecognizer : UITapGestureRecognizer

/// 最长点击间隔，default is 0.25
@property(nonatomic, assign) CGFloat maxDelay;
@end

NS_ASSUME_NONNULL_END
