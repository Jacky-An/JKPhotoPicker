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

/** popover消失时的frame */
@property (nonatomic, assign) CGRect dismissFrame;

/** popover显示的动画时长 */
//@property (nonatomic, assign) NSTimeInterval animationDuration;

/** 监听是否present的block */
@property (nonatomic, copy) void (^didPresentBlock)(BOOL isPresent);

/** 点击的图片 */
@property (nonatomic, strong) UIImage *touchImage;

/** 点击的图片view 点开时 == fromImageView，缩小返回时是点击的图片浏览器的imageView */
@property (nonatomic, weak) UIImageView *touchImageView;

/** 列表中点击的图片view */
@property (nonatomic, weak) UIImageView *fromImageView;

/** 遮盖原来图片的白色View */
@property (nonatomic, weak) UIView *whiteView;

/** 是否执行放大动画 */
@property (nonatomic, assign) BOOL isZoomUpAnimation;
@end
