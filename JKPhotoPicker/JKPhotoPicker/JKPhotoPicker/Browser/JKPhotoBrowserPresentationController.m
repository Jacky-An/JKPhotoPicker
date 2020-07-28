//
//  JKPhotoBrowserPresentationController.m
//  JKPhotoPicker
//
//  Created by albert on 2016/12/31.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import "JKPhotoBrowserPresentationController.h"
#import "JKPhotoUtility.h"

@interface JKPhotoBrowserPresentationController ()
/** dismissButton */
@property (nonatomic, weak) UIButton *dismissButton;

/** 是否已经被present */
@property (nonatomic, assign) BOOL isPresent;
@end

@implementation JKPhotoBrowserPresentationController

- (UIButton *)dismissButton{
    if (!_dismissButton) {
        UIButton *dismissButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
        dismissButton.frame = [UIScreen mainScreen].bounds;
        [self.containerView insertSubview:dismissButton atIndex:0];
        _dismissButton = dismissButton;
    }
    return _dismissButton;
}

- (void)containerViewWillLayoutSubviews{
    [super containerViewWillLayoutSubviews];
    
    /**
     1.如果不自定义转场，modal的控制器会移除原有的控制器
     2.如果自定义转场，modal出来的控制器不会移除原有的控制器
     
     3.如果不自定义转场，modal的控制器的尺寸和屏幕一样
     4.如果自定义转场，modal的控制器的尺寸我们可以自己在containerViewWillLayoutSubviews方法汇总控制
     
     5.containerView 非常重要，容器视图，所有modal出来的视图都是添加到containerView上的
     6.presentedView() 非常重要，通过该方法能够拿到弹出的视图
     */
    
    // 设置presentedView的frame
    self.presentedView.frame = JKPhotoUtility.keyWindow.bounds;
    
    self.presentedView.userInteractionEnabled = YES;
    
//    [self.dismissButton addTarget:self action:@selector(dismissButtonClick) forControlEvents:(UIControlEventTouchUpInside)];
}

- (void)dismissButtonClick{
//    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}
@end
