//
//  JKPhotoBrowserCollectionViewCell.m
//  JKPhotoPicker
//
//  Created by albert on 2016/12/30.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import "JKPhotoBrowserCollectionViewCell.h"
#import "JKPhotoItem.h"
#import <Photos/Photos.h>

#define JKScreenW [UIScreen mainScreen].bounds.size.width
#define JKScreenH [UIScreen mainScreen].bounds.size.height
#define JKScreenBounds [UIScreen mainScreen].bounds

@interface JKPhotoBrowserCollectionViewCell () <UIScrollViewDelegate, UIGestureRecognizerDelegate>
{
    CGFloat _screenAspectRatio;
    BOOL isGonnaDismiss;
    CGFloat originalHeight;
}
/** 照片选中按钮 */
@property (nonatomic, weak) UIButton *selectButton;

/** 选中和未选中的标识 */
@property (nonatomic, weak) UIImageView *selectIconImageView;

/** scrollView */
@property (nonatomic, weak) UIScrollView *scrollView;

/** 当前的ZoomScale */
@property (nonatomic, assign) CGFloat currentZoomScale;

/** 是否双击 */
@property (nonatomic, assign) BOOL isDoubleTap;

/** 是否正在缩放 */
@property (nonatomic, assign) BOOL isZooming;

/** 缩放比例 */
@property (nonatomic, assign) CGFloat transformScale;

/** 背景色alpha */
@property (nonatomic, assign) CGFloat bgAlpha;
@end

CGFloat const dismissDistance = 80;

@implementation JKPhotoBrowserCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self initialization];
    }
    return self;
}

- (void)initialization{
    self.currentZoomScale = 1;
    
    // 当前屏幕宽高比
    _screenAspectRatio = JKScreenW / JKScreenH;
    
    [self setupPhotoImageView];
    
    [self setupSelectedIcon];
}

- (void)setupPhotoImageView{
    
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.frame = JKScreenBounds;
    scrollView.delegate = self;
    scrollView.minimumZoomScale = 1;
    scrollView.maximumZoomScale = 3;
//    scrollView.backgroundColor = [UIColor blackColor];
    scrollView.alwaysBounceVertical = YES;
    scrollView.alwaysBounceHorizontal = YES;
    
    [self.contentView insertSubview:scrollView atIndex:0];
    self.scrollView = scrollView;
    
    SEL selector = NSSelectorFromString(@"setContentInsetAdjustmentBehavior:");
    
    if ([scrollView respondsToSelector:selector]) {
        
        IMP imp = [scrollView methodForSelector:selector];
        void (*func)(id, SEL, NSInteger) = (void *)imp;
        func(scrollView, selector, 2);
        
        // [tbView performSelector:@selector(setContentInsetAdjustmentBehavior:) withObject:@(2)];
    }
    
//    UIPanGestureRecognizer *contentPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(contentPan:)];
//    [self.contentView addGestureRecognizer:contentPan];
//    
//    contentPan.delegate = self;
    
//    self.scrollView.userInteractionEnabled = NO;
//    [self.contentView addGestureRecognizer:self.scrollView.panGestureRecognizer];
//    [self.contentView addGestureRecognizer:self.scrollView.pinchGestureRecognizer];
    
    // 照片约束
    //    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    //    NSArray *scrollViewCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[scrollView]-0-|" options:0 metrics:nil views:@{@"scrollView" : scrollView}];
    //    [self.contentView addConstraints:scrollViewCons1];
    //
    //    NSArray *scrollViewCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[scrollView]-0-|" options:0 metrics:nil views:@{@"scrollView" : scrollView}];
    //    [self.contentView addConstraints:scrollViewCons2];
    
    // 照片
    UIImageView *photoImageView = [[UIImageView alloc] init];
    photoImageView.contentMode = UIViewContentModeScaleAspectFit;
    photoImageView.clipsToBounds = YES;
    [self.scrollView insertSubview:photoImageView atIndex:0];
    self.photoImageView = photoImageView;
//    photoImageView.frame = JKScreenBounds;
    // 照片约束
    //    photoImageView.translatesAutoresizingMaskIntoConstraints = NO;
    //    NSArray *photoImageViewCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[photoImageView]-0-|" options:0 metrics:nil views:@{@"photoImageView" : photoImageView}];
    //    [self.scrollView addConstraints:photoImageViewCons1];
    //
    //    NSArray *photoImageViewCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[photoImageView]-0-|" options:0 metrics:nil views:@{@"photoImageView" : photoImageView}];
    //    [self.scrollView addConstraints:photoImageViewCons2];
    
//    self.photoImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.contentView addGestureRecognizer:doubleTap];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    singleTap.numberOfTapsRequired = 1;
    [self.contentView addGestureRecognizer:singleTap];
    
    // 只有当doubleTapGesture识别失败的时候(即识别出这不是双击操作)，singleTapGesture才能开始识别
    [singleTap requireGestureRecognizerToFail:doubleTap];
}

#pragma mark - 单击和双击手势
- (void)singleTap:(UITapGestureRecognizer *)tap{
    
    [self selfDismiss];
}

- (void)doubleTap:(UITapGestureRecognizer *)tap{
    self.isDoubleTap = YES;
    
    CGPoint touchPoint = [tap locationInView:self.contentView];
    
    CGPoint point = [self.photoImageView convertPoint:touchPoint fromView:self.contentView];
    
    if (![self.photoImageView pointInside:point withEvent:nil]) {
        return;
    }
    
    // 双击缩小
    if (self.scrollView.zoomScale > 1) {
        [self.scrollView setZoomScale:1 animated:YES];
        return;
    }
    
    // 双击放大
    [self.scrollView zoomToRect:CGRectMake(touchPoint.x - 5, touchPoint.y - 5, 10, 10) animated:YES];
}

- (void)setupSelectedIcon{
    // 照片选中按钮
    UIButton *selectButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [selectButton addTarget:self action:@selector(selectImageClick) forControlEvents:(UIControlEventTouchUpInside)];
    [self.contentView addSubview:selectButton];
    self.selectButton = selectButton;
    
    // 照片选中按钮约束
    selectButton.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *selectButtonCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[selectButton(70)]-0-|" options:0 metrics:nil views:@{@"selectButton" : selectButton}];
    [self.contentView addConstraints:selectButtonCons1];
    
    NSArray *selectButtonCons2 = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[selectButton(70)]-%.0f-|", (JKPhotoPickerIsIphoneX ? JKPhotoPickerBottomSafeAreaHeight : 0)] options:0 metrics:nil views:@{@"selectButton" : selectButton}];
    [self.contentView addConstraints:selectButtonCons2];
    
    // 照片选中标识
    UIImageView *selectIconImageView = [[UIImageView alloc] init];
    selectIconImageView.contentMode = PHImageContentModeAspectFit;
    selectIconImageView.image = [UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"JKPhotoPickerResource.bundle/images/deselected_icon@3x.png"]];
    selectIconImageView.highlightedImage = [UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"JKPhotoPickerResource.bundle/images/selected_icon@3x.png"]];
    [self.contentView addSubview:selectIconImageView];
    self.selectIconImageView = selectIconImageView;
    
    // 照片选中标识约束
    selectIconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *selectIconImageViewCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[selectIconImageView(25)]-10-|" options:0 metrics:nil views:@{@"selectIconImageView" : selectIconImageView}];
    [self.contentView addConstraints:selectIconImageViewCons1];
    
    NSArray *selectIconImageViewCons2 = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[selectIconImageView(25)]-%.0f-|", (JKPhotoPickerIsIphoneX ? JKPhotoPickerBottomSafeAreaHeight : 0) + 10] options:0 metrics:nil views:@{@"selectIconImageView" : selectIconImageView}];
    [self.contentView addConstraints:selectIconImageViewCons2];
}

- (void)setHighlighted:(BOOL)highlighted{}

- (void)setSelected:(BOOL)selected{
    [super setSelected:selected];
    
    //    self.selectIconImageView.highlighted = self.selectIconImageView.highlighted;
}

- (void)setPhotoItem:(JKPhotoItem *)photoItem{
    _photoItem = photoItem;
    
    [self resetView];
    
    self.selectIconImageView.highlighted = _photoItem.isSelected;
    
    [[PHImageManager defaultManager] requestImageForAsset:_photoItem.photoAsset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        
        self.photoImageView.image = result;
        [self calculateImageViewSizeWithImage:result];
    }];
    
    // 这样会很卡，而且内存警告直接崩，还不清晰
    //    self.photoImageView.image = _photoItem.thumImage;
}



- (void)calculateImageViewSizeWithImage:(UIImage *)image{
    //图片要显示的尺寸
    CGFloat pictureW = JKScreenW;
    CGFloat pictureH = JKScreenW * image.size.height / image.size.width;
    
    if (pictureH > JKScreenH) {//图片高过屏幕
        self.photoImageView.frame = CGRectMake(0, 0, pictureW, pictureH);
        //设置scrollView的contentSize
        //        self.scrollView.contentSize = CGSizeMake(pictureW, pictureH);
        //        NSLog(@"更新了contentSize");
        
    }else{//图片不高于屏幕
        
        self.photoImageView.frame = CGRectMake(0, 0, pictureW, pictureH);//CGSizeMake(pictureW, pictureH);
        //图片显示在中间
        //        self.imageView.center= CGPointMake(JKScreenW * 0.5, JKScreenH * 0.5);
    }
    self.scrollView.contentSize = CGSizeMake(pictureW, pictureH);
    [self setInset];
    originalHeight = pictureH;
}

- (void)calculateImageCoverViewFrame{
    
    CGFloat imageW = self.photoImageView.image.size.width;
    CGFloat imageH = self.photoImageView.image.size.height;
    CGFloat imageAspectRatio = imageW / imageH;
    
    if (imageW / imageH >= _screenAspectRatio) { // 宽高比大于屏幕宽高比，基于宽度缩放
        self.photoImageView.frame = CGRectMake(0, 0, JKScreenW, JKScreenW / imageAspectRatio);
    }else{
        
        // 宽高比小于屏幕宽高比，基于高度缩放
        self.photoImageView.frame = CGRectMake(0, 0, JKScreenH * imageAspectRatio, JKScreenH);
    }
    
    CGFloat offsetX = (JKScreenW - self.photoImageView.frame.size.width) * 0.5;
    CGFloat offsetY = (JKScreenH - self.photoImageView.frame.size.height) * 0.5;
    self.scrollView.contentInset = UIEdgeInsetsMake(offsetY, offsetX, offsetY, offsetX);
}

- (void)resetView{
    self.currentZoomScale = 1;
    
    self.scrollView.contentOffset = CGPointZero;
    self.scrollView.contentInset = UIEdgeInsetsZero;
    self.scrollView.contentSize = CGSizeZero;
    
    // 放大图片实质就是transform形变
    self.photoImageView.transform = CGAffineTransformIdentity;
    self.photoImageView.frame = JKScreenBounds;
}

#pragma mark - 点击事件
// 选中照片
- (void)selectImageClick{
    
    if (!(!self.selectBlock ? : self.selectBlock(self.selectIconImageView.highlighted, self))) {
        
        self.selectIconImageView.highlighted = NO;
        
        return;
    }
    
    self.selectIconImageView.highlighted = YES;
    
    [UIView animateWithDuration:0.25 animations:^{
        
        self.selectIconImageView.transform = CGAffineTransformMakeScale(1.3, 1.3);
        
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.25 animations:^{
            
            self.selectIconImageView.transform = CGAffineTransformIdentity;
        }];
    }];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    self.isDoubleTap = NO;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    
    if (self.isZooming) { return; }
    
    if (scrollView.contentOffset.y + scrollView.contentInset.top < -dismissDistance) {
        
        isGonnaDismiss = YES;
        
        [self selfDismiss];
        
    }else{
        
        [UIView animateWithDuration:0.25 animations:^{
            [UIView setAnimationCurve:(7)];
            
            CGAffineTransform transform = CGAffineTransformMakeScale(self.currentZoomScale, self.currentZoomScale);//CGAffineTransformTranslate(self.photoImageView.transform, 0, 0);
            self.photoImageView.transform = CGAffineTransformTranslate(transform, 0, 0);
            
        } completion:^(BOOL finished) {
            
            scrollView.pinchGestureRecognizer.enabled = YES;
            self.collectionView.scrollEnabled = YES;
        }];
    }
}

- (void)selfDismiss{
    
    CGRect rect = [self.photoImageView.superview convertRect:self.photoImageView.frame toView:[UIApplication sharedApplication].keyWindow];
    
    self.photoImageView.frame = rect;
    [self.contentView addSubview:self.photoImageView];
    [self.scrollView removeFromSuperview];
    self.scrollView = nil;
    self.selectButton.hidden = YES;
    
//    self.scrollView.contentInset = UIEdgeInsetsMake(rect.origin.y, 0, 0, 0);
    
    [UIView animateWithDuration:0.3 animations:^{
        
        self.selectIconImageView.hidden = YES;
        self.collectionView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    }];
    
    !self.dismissBlock ? : self.dismissBlock(self, rect);
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    //    scrollView.userInteractionEnabled = YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    NSLog(@"contentOffset --> %@", NSStringFromCGPoint(scrollView.contentOffset));
    if (scrollView.contentOffset.y + scrollView.contentInset.top >= 0) {
        return;
    }
    
    if (self.isZooming || isGonnaDismiss || self.isDoubleTap) {
        return;
    }
    
    self.bgAlpha = 1 - ((-scrollView.contentOffset.y - scrollView.contentInset.top) / dismissDistance * 0.2);
    
    self.collectionView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:self.bgAlpha];
    
    if (!scrollView.isDragging) { return; }
    
    scrollView.pinchGestureRecognizer.enabled = NO;
    self.collectionView.scrollEnabled = NO;
    
    CGPoint point = [scrollView.panGestureRecognizer translationInView:scrollView.panGestureRecognizer.view.superview];
    NSLog(@"%@", NSStringFromCGPoint(point));
    
    NSLog(@"正在形变！！！");
    
    self.transformScale = self.currentZoomScale - (scrollView.contentOffset.y + scrollView.contentInset.top) / (-350 - scrollView.contentInset.top) * 1.0;
    self.transformScale = self.transformScale < 0.2 ? 0.2 : self.transformScale;
    CGAffineTransform transform = CGAffineTransformMakeScale(self.transformScale, self.transformScale);
    
    self.photoImageView.transform = CGAffineTransformTranslate(transform, self.currentZoomScale > 1 ? 0 : point.x, self.currentZoomScale > 1 ? 0 : (originalHeight > JKScreenH + 100 ? 0 : point.y * 0.5));
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
//    if (!isGonnaDismiss && self.transformScale <= 1) {
//        [UIView animateWithDuration:0.25 animations:^{
//            self.photoImageView.transform = CGAffineTransformIdentity;
//        }];
//    }
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view{
    self.isZooming = YES;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale{
    self.currentZoomScale = scale;
    self.isZooming = NO;
    [self setInset];
    NSLog(@"当前zoomScale ---> %.2f", scale);
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.photoImageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
    [self setInset];
}

- (void)setInset{
    // 计算内边距，注意只能使用frame
    CGFloat offsetX = (JKScreenW - self.photoImageView.frame.size.width) * 0.5;
    CGFloat offsetY = (JKScreenH - self.photoImageView.frame.size.height) * 0.5;
    
    // 当小于0的时候，放大的图片将无法滚动，因为内边距为负数时限制了它可以滚动的范围
    offsetX = (offsetX < 0) ? 0 : offsetX;
    offsetY = (offsetY < 0) ? 0 : offsetY;
    
    self.scrollView.contentInset = UIEdgeInsetsMake(offsetY, offsetX, offsetY, offsetX);//UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        
        UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)gestureRecognizer;
        CGPoint pos = [pan velocityInView:pan.view];
        NSLog(@"手势--->%@", NSStringFromCGPoint(pos));
//        if (pos.y > 0) {
//            self.scrollView.scrollEnabled = NO;
//            return YES;
//        }
        return YES;
    }
    
    return NO;
}
@end
