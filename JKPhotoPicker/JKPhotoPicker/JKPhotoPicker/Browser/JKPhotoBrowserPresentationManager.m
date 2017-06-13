//
//  JKPhotoBrowserPresentationManager.m
//  JKPhotoPicker
//
//  Created by albert on 2017/1/1.
//  Copyright © 2017年 安永博. All rights reserved.
//

#import "JKPhotoBrowserPresentationManager.h"
#import "JKPhotoBrowserPresentationController.h"

#define JKScreenW [UIScreen mainScreen].bounds.size.width
#define JKScreenH [UIScreen mainScreen].bounds.size.height
#define JKScreenBounds [UIScreen mainScreen].bounds

@interface JKPhotoBrowserPresentationManager ()
/** 是否已经被present */
@property (nonatomic, assign) BOOL isPresent;
@end

@implementation JKPhotoBrowserPresentationManager

#pragma mark - UIViewControllerTransitioningDelegate协议方法
// 该方法返回一个负责转场动画的对象
- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source{
    
    JKPhotoBrowserPresentationController *pc = [[JKPhotoBrowserPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
    pc.presentFrame = self.presentFrame;
    return pc;
}

// 该方法用于返回一个负责转场如何出现的对象
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    self.isPresent = YES;
    
    !self.didPresentBlock ? : self.didPresentBlock(self.isPresent);
    
    //self要遵守UIViewControllerAnimatedTransitioning协议，并实现对应方法
    return self;
}

// 该方法用于返回一个负责转场如何消失的对象
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    self.isPresent = NO;
    
    !self.didPresentBlock ? : self.didPresentBlock(self.isPresent);
    
    //self要遵守UIViewControllerAnimatedTransitioning协议，并实现对应方法
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning协议方法
// 告诉系统展现和消失的动画时长。在这里统一控制动画时长
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext{
    
    return 0.3;
}

// 专门用于管理modal如何展现和消失的，无论是展现还是消失都会调用该方法
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext{
    
    if (self.isPresent) {// 展现
        [self willPresentController:transitionContext];
        
    }else {//消失
        [self willDismissController:transitionContext];
    }
}

#pragma mark - 执行展现的动画
- (void)willPresentController:(id<UIViewControllerContextTransitioning>)transitionContext{
    // 1.获取要弹出的视图
    // 通过ToViewKey取出来的就是toVc对应的view
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    if (toView == nil) return;
    
    UIView *blackBgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    blackBgView.backgroundColor = [UIColor blackColor];
    [[transitionContext containerView] addSubview:blackBgView];
    
    CGFloat Y = self.presentFrame.origin.y < 64 ? 64 : self.presentFrame.origin.y;
    CGFloat H = (CGRectGetMaxY(self.presentFrame) > JKScreenH - 70 ? JKScreenH - 70 : CGRectGetMaxY(self.presentFrame)) - Y;
    
    UIView *whiteView = [[UIView alloc] initWithFrame:CGRectMake(self.presentFrame.origin.x, Y, self.presentFrame.size.width, H)];
    whiteView.backgroundColor = [UIColor whiteColor];
    [[transitionContext containerView] insertSubview:whiteView atIndex:0];
    self.whiteView = whiteView;
    
    // 2.将需要弹出的视图添加到containerView上
    [[transitionContext containerView] addSubview:toView];
    [[transitionContext containerView] setBackgroundColor:[UIColor blackColor]];
    
    // 3.执行动画
//    toView.transform = CGAffineTransformMakeScale(1, 0);
    toView.hidden = YES;
    
    // 默认动画是从中间慢慢放大的，这是因为图层默认的锚点是(0.5，0.5)
//    toView.layer.anchorPoint = CGPointMake(0.5, 0);
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.clipsToBounds = YES;
    imageView.image = self.touchImage;
    imageView.frame = self.presentFrame;
    [[transitionContext containerView] addSubview:imageView];
    toView.userInteractionEnabled = NO;
//    self.fromImageView.hidden = YES;
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
//        toView.transform = CGAffineTransformIdentity;
        imageView.frame = [self calculateImageViewSizeWithImage:imageView.image];//[UIScreen mainScreen].bounds;
        
    } completion:^(BOOL finished) {
        
        // 注意：自定义转场动画，在执行完动画之后一定要告诉系统动画执行完毕了！！
        [[transitionContext containerView] setBackgroundColor:[UIColor clearColor]];
        [transitionContext completeTransition:YES];
        toView.hidden = NO;
        [imageView removeFromSuperview];
        [blackBgView removeFromSuperview];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            toView.userInteractionEnabled = YES;
        });
        
//        [toView performSelector:@selector(setUserInteractionEnabled:) withObject:@(YES) afterDelay:0.3];
//        [imageView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.2];
    }];
}

- (CGRect)calculateImageViewSizeWithImage:(UIImage *)image{
    //图片要显示的尺寸
    CGFloat pictureX = 0;
    CGFloat pictureY = 0;
    CGFloat pictureW = JKScreenW;
    CGFloat pictureH = JKScreenW * image.size.height / image.size.width;
    
    if (pictureH > JKScreenH) {//图片高过屏幕
        //        self.imageView.frame = CGRectMake(0, 0, pictureW, pictureH);
        //设置scrollView的contentSize
        //        self.scrollView.contentSize = CGSizeMake(pictureW, pictureH);
        //        NSLog(@"更新了contentSize");
        
    }else{//图片不高于屏幕
        pictureY = (JKScreenH - pictureH) * 0.5;
        //        self.imageView.frame = CGRectMake(0, 0, pictureW, pictureH);//CGSizeMake(pictureW, pictureH);
        //图片显示在中间
        //        self.imageView.center= CGPointMake(JKScreenW * 0.5, JKScreenH * 0.5);
    }
    
    return CGRectMake(pictureX, pictureY, pictureW, pictureH);
}

#pragma mark - 执行消失的动画
- (void)willDismissController:(id<UIViewControllerContextTransitioning>)transitionContext{
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    if (fromView == nil) return;
    
    // 默认动画是从中间慢慢放大的，这是因为图层默认的锚点是(0.5，0.5)
//    fromView.layer.anchorPoint = CGPointMake(0.5, 0);
//    self.fromImageView.hidden = YES;
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.image = self.touchImage;
    imageView.frame = self.dismissFrame;//[self calculateImageCoverViewFrameWithImageView:self.touchImageView];
    [[transitionContext containerView] addSubview:imageView];
    
    self.touchImageView.hidden = YES;
    
//    fromView.hidden = YES;
    [[transitionContext containerView] setBackgroundColor:[UIColor clearColor]];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        if (self.isZoomUpAnimation) {
            imageView.transform = CGAffineTransformMakeScale(1.3, 1.3);
            imageView.alpha = 0;
            
        }else{
            
            imageView.frame = self.presentFrame;
        }
        
    } completion:^(BOOL finished) {
        [self.whiteView removeFromSuperview];
        [imageView removeFromSuperview];
        
        // 注意：自定义转场动画，在执行完动画之后一定要告诉系统动画执行完毕了！！
        [transitionContext completeTransition:YES];
//        self.fromImageView.hidden = NO;
    }];
}

- (CGRect)calculateImageCoverViewFrameWithImageView:(UIImageView *)imageView{
    
    CGRect rect = [imageView.superview convertRect:imageView.frame toView:[UIApplication sharedApplication].keyWindow];
    
    return rect;
    
//    CGFloat imageW = imageView.image.size.width;
//    CGFloat imageH = imageView.image.size.height;
//    CGFloat imageAspectRatio = imageW / imageH;
//    
//    if (imageW / imageH >= JKScreenW / JKScreenH) { // 宽高比大于屏幕宽高比，基于宽度缩放
//        imageView.frame = CGRectMake(0, 0, JKScreenW, JKScreenW / imageAspectRatio);
//        
//    }else{
//        
//        // 宽高比小于屏幕宽高比，基于高度缩放
//        imageView.frame = CGRectMake(0, 0, JKScreenH * imageAspectRatio, JKScreenH);
//    }
//    
//    imageView.center = CGPointMake(JKScreenW * 0.5, JKScreenH * 0.5);
}
@end
