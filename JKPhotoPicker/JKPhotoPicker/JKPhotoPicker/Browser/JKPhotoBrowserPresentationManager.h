//
//  JKPhotoBrowserPresentationManager.h
//  JKPhotoPicker
//
//  Created by albert on 2017/1/1.
//  Copyright © 2017年 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JKPhotoBrowserPresentationManager : NSObject <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>
/** popover显示的frame */
@property (nonatomic, assign) CGRect presentFrame;

/** popover显示的动画时长 */
//@property (nonatomic, assign) NSTimeInterval animationDuration;

/** 监听是否present的block */
@property (nonatomic, copy) void (^didPresentBlock)(BOOL isPresent);

/** 点击的图片 */
@property (nonatomic, strong) UIImage *touchImage;

/** 是否执行放大动画 */
@property (nonatomic, assign) BOOL isZoomUpAnimation;
@end
