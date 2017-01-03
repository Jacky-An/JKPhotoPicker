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
}
/** 照片选中按钮 */
@property (nonatomic, weak) UIButton *selectButton;

/** 选中和未选中的标识 */
@property (nonatomic, weak) UIImageView *selectIconImageView;

/** scrollView */
@property (nonatomic, weak) UIScrollView *scrollView;
@end

@implementation JKPhotoBrowserCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self initialization];
    }
    return self;
}

- (void)initialization{
    
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
    [self.contentView insertSubview:scrollView atIndex:0];
    self.scrollView = scrollView;
    
    self.scrollView.userInteractionEnabled = NO;
    [self.contentView addGestureRecognizer:self.scrollView.panGestureRecognizer];
    [self.contentView addGestureRecognizer:self.scrollView.pinchGestureRecognizer];
    
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
    
    !self.dismissBlock ? : self.dismissBlock(self);
}

- (void)doubleTap:(UITapGestureRecognizer *)tap{
    
    CGPoint touchPoint = [tap locationInView:self.contentView];
    
    CGPoint point = [self.photoImageView convertPoint:touchPoint fromView:self.contentView];
    
    if (![self.photoImageView pointInside:point withEvent:nil]) {
        return;
    }
    
    // 双击缩小
    if (self.photoImageView.frame.size.width > JKScreenW) {
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
    
    NSArray *selectButtonCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[selectButton(70)]-0-|" options:0 metrics:nil views:@{@"selectButton" : selectButton}];
    [self.contentView addConstraints:selectButtonCons2];
    
    // 照片选中标识
    UIImageView *selectIconImageView = [[UIImageView alloc] init];
    selectIconImageView.image = [UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"resource.bundle/images/deselected_icon.png"]];
    selectIconImageView.highlightedImage = [UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"resource.bundle/images/selected_icon.png"]];
    [self.contentView addSubview:selectIconImageView];
    self.selectIconImageView = selectIconImageView;
    
    // 照片选中标识约束
    selectIconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *selectIconImageViewCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[selectIconImageView(40)]-3-|" options:0 metrics:nil views:@{@"selectIconImageView" : selectIconImageView}];
    [self.contentView addConstraints:selectIconImageViewCons1];
    
    NSArray *selectIconImageViewCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[selectIconImageView(40)]-3-|" options:0 metrics:nil views:@{@"selectIconImageView" : selectIconImageView}];
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
        [self calculateImageCoverViewFrame];
    }];
    
    // 这样会很卡，而且内存警告直接崩，还不清晰
    //    self.photoImageView.image = _photoItem.thumImage;
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
@end
