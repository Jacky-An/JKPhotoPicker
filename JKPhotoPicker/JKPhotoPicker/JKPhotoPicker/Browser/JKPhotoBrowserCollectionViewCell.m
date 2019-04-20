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
#import <PhotosUI/PhotosUI.h>
#import <WebKit/WebKit.h>

@interface JKPhotoBrowserCollectionViewCell () <UIScrollViewDelegate, UIGestureRecognizerDelegate>
{
    CGFloat _screenAspectRatio;
    BOOL isGonnaDismiss;
    CGFloat originalHeight;
    
    BOOL isDragging;
    CGFloat lastOffsetY;
    CGFloat currentOffsetY;
    
    CGPoint beginDraggingOffset;
    
    BOOL isFirstScroll;
    BOOL shouldZoomdown;
    
    JKPhotoPickerScrollDirection beginScrollDirection;
    JKPhotoPickerScrollDirection endScrollDirection;
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

/** indicator */
@property (nonatomic, weak) UIActivityIndicatorView *indicatorView;

/** playVideoButton */
@property (nonatomic, weak) UIButton *playVideoButton;
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
    _screenAspectRatio = JKPhotoPickerScreenW / JKPhotoPickerScreenH;
    
    [self setupPhotoImageView];
    
    [self setupSelectedIcon];
    
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] init];
    indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [self.contentView addSubview:indicatorView];
    self.indicatorView = indicatorView;
    
    indicatorView.center = CGPointMake(JKPhotoPickerScreenW * 0.5 + 10, JKPhotoPickerScreenH * 0.5);
}

- (void)setupPhotoImageView{
    
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.frame = CGRectMake(10, 0, JKPhotoPickerScreenW, JKPhotoPickerScreenH);
    scrollView.delegate = self;
    scrollView.minimumZoomScale = 1;
    scrollView.maximumZoomScale = 3;
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
    
    // 照片
    UIImageView *photoImageView = [[UIImageView alloc] init];
    photoImageView.userInteractionEnabled = YES;
    photoImageView.contentMode = UIViewContentModeScaleAspectFit;
    photoImageView.clipsToBounds = YES;
    [self.scrollView insertSubview:photoImageView atIndex:0];
    self.photoImageView = photoImageView;
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.contentView addGestureRecognizer:doubleTap];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    singleTap.numberOfTapsRequired = 1;
    [self.contentView addGestureRecognizer:singleTap];
    
    // 只有当doubleTapGesture识别失败的时候(即识别出这不是双击操作)，singleTapGesture才能开始识别
    [singleTap requireGestureRecognizerToFail:doubleTap];
    
    // 播放按钮
    UIButton *playVideoButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
    [self.contentView insertSubview:playVideoButton aboveSubview:photoImageView];
    self.playVideoButton = playVideoButton;
    self.playVideoButton.hidden = YES;
    
    [playVideoButton addTarget:self action:@selector(playVideoButtonClick:) forControlEvents:(UIControlEventTouchUpInside)];
    
    [playVideoButton setBackgroundImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"JKPhotoPickerResource.bundle/images/video-play@3x"]] forState:(UIControlStateNormal)];
    
    // 播放按钮约束
    playVideoButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *cons1 = [NSLayoutConstraint constraintWithItem:playVideoButton attribute:(NSLayoutAttributeCenterX) relatedBy:(NSLayoutRelationEqual) toItem:self.contentView attribute:(NSLayoutAttributeCenterX) multiplier:1 constant:0];
    
    NSLayoutConstraint *cons2 = [NSLayoutConstraint constraintWithItem:playVideoButton attribute:(NSLayoutAttributeCenterY) relatedBy:(NSLayoutRelationEqual) toItem:self.contentView attribute:(NSLayoutAttributeCenterY) multiplier:1 constant:0];
    
    NSLayoutConstraint *cons3 = [NSLayoutConstraint constraintWithItem:playVideoButton attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:71];
    
    NSLayoutConstraint *cons4 = [NSLayoutConstraint constraintWithItem:playVideoButton attribute:(NSLayoutAttributeHeight) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:71];
    
    [self.contentView addConstraints:@[cons1, cons2, cons3, cons4]];
    
    // 照片
    if (@available(iOS 9.1, *)) {
        
        PHLivePhotoView *livePhotoView = [[PHLivePhotoView alloc] init];
        
        [self.photoImageView insertSubview:livePhotoView atIndex:0];
        _livePhotoView = livePhotoView;
        
        // 照片约束
        livePhotoView.translatesAutoresizingMaskIntoConstraints = NO;
        NSArray *livePhotoViewCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[livePhotoView]-0-|" options:0 metrics:nil views:@{@"livePhotoView" : livePhotoView}];
        [self.photoImageView addConstraints:livePhotoViewCons1];
        
        NSArray *livePhotoViewCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[livePhotoView]-0-|" options:0 metrics:nil views:@{@"livePhotoView" : livePhotoView}];
        [self.photoImageView addConstraints:livePhotoViewCons2];
    }
    
    // 播放gif的webView
    WKWebView *gifWebView = [[WKWebView alloc] init];
    gifWebView.userInteractionEnabled = NO;
//    gifWebView.scalesPageToFit = YES;
    gifWebView.backgroundColor = nil;
    gifWebView.opaque = NO;
    gifWebView.hidden = YES;
    [self.photoImageView addSubview:gifWebView];
    self.gifWebView = gifWebView;
}

- (void)loadGifData:(NSData *)gifData{
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (@available(iOS 9.0, *)) {
            
            [self.gifWebView loadData:gifData MIMEType:@"image/gif" characterEncodingName:@"UTF-8" baseURL:[NSURL new]];
        }
    });
//    [self.gifWebView loadData:gifData MIMEType:@"image/gif" textEncodingName:@"UTF-8" baseURL:[NSURL new]];
}

#pragma mark - 点击播放视频

- (void)playVideoButtonClick:(UIButton *)button{
    
    [[PHImageManager defaultManager] requestPlayerItemForVideo:self.photoItem.photoAsset options:nil resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            !self.playVideoBlock ? : self.playVideoBlock(playerItem);
        });
    }];
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
    
//    CGPoint scrollPoint = [self.scrollView convertPoint:touchPoint fromView:self.contentView];
    
    // 双击放大
    [self.scrollView zoomToRect:CGRectMake(point.x - 5, point.y - 5, 10, 10) animated:YES];
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
    
    [self.gifWebView stopLoading];
    self.gifWebView.hidden = !_photoItem.shouldPlayGif;
    
    self.selectIconImageView.hidden = !_photoItem.shouldSelected;
    self.selectButton.hidden = !_photoItem.shouldSelected;
    
    self.playVideoButton.hidden = _photoItem.dataType != JKPhotoPickerMediaDataTypeVideo;
    
    self.selectIconImageView.highlighted = _photoItem.isSelected;
    
    self.livePhotoView.hidden = _photoItem.dataType != JKPhotoPickerMediaDataTypePhotoLive;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.networkAccessAllowed = YES;
        
        [[PHImageManager defaultManager] requestImageForAsset:_photoItem.photoAsset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
               
                !self.imageLoadFinishBlock ? : self.imageLoadFinishBlock(self);
                
                if ([info[PHImageResultIsInCloudKey] boolValue]) {
                    
                    [self.indicatorView startAnimating];
                    self.selectButton.userInteractionEnabled = NO;
                }
                
                if (result == nil) { return; }
                self.selectButton.userInteractionEnabled = YES;
                
                [self.indicatorView stopAnimating];
                
                // block内是主线程
                self.photoImageView.image = result;
                [self calculateImageViewSizeWithImage:result];
            });
        }];
        
        if (photoItem.dataType == JKPhotoPickerMediaDataTypePhotoLive) {
            
            if (@available(iOS 9.1, *)) {
                
                PHLivePhotoRequestOptions *options = [[PHLivePhotoRequestOptions alloc]init];
                options.networkAccessAllowed = YES;
                
                [[PHImageManager defaultManager] requestLivePhotoForAsset:_photoItem.photoAsset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        !self.imageLoadFinishBlock ? : self.imageLoadFinishBlock(self);
                        
                        if ([info[PHImageResultIsInCloudKey] boolValue]) {
                            
                            [self.indicatorView startAnimating];
                            self.selectButton.userInteractionEnabled = NO;
                        }
                        
                        if (livePhoto == nil) { return; }
                        self.selectButton.userInteractionEnabled = YES;
                        
                        [self.indicatorView stopAnimating];
                        
                        // block内是主线程
                        self.livePhotoView.livePhoto = livePhoto;
                    });
                }];
            }
        }
        
        if (photoItem.shouldPlayGif) {
            
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.networkAccessAllowed = YES;
            
            [[PHImageManager defaultManager] requestImageDataForAsset:_photoItem.photoAsset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                   
                    if (imageData != nil) {
                        
                        [self loadGifData:imageData];
                    }
                });
            }];
        }
    });
    
    // 这样会很卡，而且内存警告直接崩，还不清晰
    //    self.photoImageView.image = _photoItem.thumImage;
}

- (void)calculateImageViewSizeWithImage:(UIImage *)image{
    
    //图片要显示的尺寸
    CGFloat pictureW = JKPhotoPickerScreenW;
    CGFloat pictureH = JKPhotoPickerScreenW * image.size.height / image.size.width;
    
    self.photoImageView.frame = CGRectMake(0, 0, pictureW, pictureH);
    
    if (self.photoItem.shouldPlayGif) {
        
        self.gifWebView.transform = CGAffineTransformIdentity;
        self.gifWebView.frame = self.photoImageView.bounds;
        
        if (image.size.width < JKPhotoPickerScreenW) {
            
            self.gifWebView.frame = CGRectMake((pictureW - image.size.width) * 0.5, (pictureH - image.size.height) * 0.5, image.size.width, image.size.height);
            self.gifWebView.transform = CGAffineTransformMakeScale(pictureW / image.size.width, pictureH / image.size.height);
        }
    }
    
    self.scrollView.contentSize = CGSizeMake(pictureW, pictureH);
    
    [self calculateInset];
    
    originalHeight = pictureH;
                      
    [self.scrollView setContentOffset:CGPointMake(0, -self.scrollView.contentInset.top) animated:NO];
}

- (void)calculateImageCoverViewFrame{
    
    CGFloat imageW = self.photoImageView.image.size.width;
    CGFloat imageH = self.photoImageView.image.size.height;
    CGFloat imageAspectRatio = imageW / imageH;
    
    if (imageW / imageH >= _screenAspectRatio) { // 宽高比大于屏幕宽高比，基于宽度缩放
        
        self.photoImageView.frame = CGRectMake(0, 0, JKPhotoPickerScreenW, JKPhotoPickerScreenW / imageAspectRatio);
        
    } else {
        
        // 宽高比小于屏幕宽高比，基于高度缩放
        self.photoImageView.frame = CGRectMake(0, 0, JKPhotoPickerScreenH * imageAspectRatio, JKPhotoPickerScreenH);
    }
    
    CGFloat offsetX = (JKPhotoPickerScreenW - self.photoImageView.frame.size.width) * 0.5;
    CGFloat offsetY = (JKPhotoPickerScreenH - self.photoImageView.frame.size.height) * 0.5;
    self.scrollView.contentInset = UIEdgeInsetsMake(offsetY, offsetX, offsetY, offsetX);
}

- (void)resetView{
    self.currentZoomScale = 1;
    
    self.scrollView.contentOffset = CGPointZero;
    self.scrollView.contentInset = UIEdgeInsetsZero;
    self.scrollView.contentSize = CGSizeZero;
    
    // 放大图片实质就是transform形变
    self.photoImageView.transform = CGAffineTransformIdentity;
    self.photoImageView.frame = JKPhotoPickerScreenBounds;
    self.photoImageView.image = nil;
    
    [self.indicatorView stopAnimating];
    self.selectButton.userInteractionEnabled = YES;
    
    
    [self.gifWebView loadHTMLString:@"" baseURL:nil];
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
    
    [(UICollectionView *)self.superview setScrollEnabled:NO];
    
    self.isDoubleTap = NO;
    
    isDragging = YES;
    
    isFirstScroll = NO;
    shouldZoomdown = YES;
    
    beginScrollDirection = JKPhotoPickerScrollDirectionNone;
    endScrollDirection = JKPhotoPickerScrollDirectionNone;
    
    beginDraggingOffset = scrollView.contentOffset;
    lastOffsetY = scrollView.contentOffset.y;
    
    if (self.playVideoButton.isHidden) {
        return;
    }
    
    [UIView animateWithDuration:0.25 animations:^{
       
        self.playVideoButton.alpha = 0;
    }];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    [(UICollectionView *)self.superview setScrollEnabled:YES];
    
    isDragging = NO;
    
    beginScrollDirection = JKPhotoPickerScrollDirectionNone;
    endScrollDirection = JKPhotoPickerScrollDirectionNone;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    
    if (self.isZooming) { return; }
    
    if (scrollView.contentOffset.y + scrollView.contentInset.top < -dismissDistance && (beginScrollDirection == endScrollDirection)) {
        
        isGonnaDismiss = YES;
        
        [self selfDismiss];
        
    }else{
        
        CGAffineTransform transform = CGAffineTransformMakeScale(self.currentZoomScale, self.currentZoomScale);
        
        [UIView animateWithDuration:0.25 delay:0 options:(UIViewAnimationOptionAllowUserInteraction) animations:^{
            [UIView setAnimationCurve:(7)];//CGAffineTransformTranslate(self.photoImageView.transform, 0, 0);
            
            self.photoImageView.transform = transform;//CGAffineTransformTranslate(transform, 0, 0);
            self.collectionView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:1];
            
        } completion:^(BOOL finished) {
            
            scrollView.pinchGestureRecognizer.enabled = YES;
            self.collectionView.scrollEnabled = YES;
        }];
        
        if (self.playVideoButton.isHidden) {
            return;
        }
        
        [UIView animateWithDuration:0.25 animations:^{
            
            self.playVideoButton.alpha = 1;
        }];
    }
}

- (void)selfDismiss{
    
    CGRect rect = [self.photoImageView.superview convertRect:self.photoImageView.frame toView:[UIApplication sharedApplication].delegate.window];
    
    rect.origin.x += 10;
    
    self.photoImageView.frame = rect;
    
    rect.origin.x -= 10;
    
    [self.contentView addSubview:self.photoImageView];
    [self.scrollView removeFromSuperview];
    self.scrollView = nil;
    self.selectButton.hidden = YES;
    
    [UIView animateWithDuration:0.3 animations:^{
        
        self.selectIconImageView.hidden = YES;
        self.selectButton.hidden = YES;
        self.playVideoButton.hidden = YES;
        self.collectionView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    }];
    
    !self.dismissBlock ? : self.dismissBlock(self, rect);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    //NSLog(@"contentOffset --> %@", NSStringFromCGPoint(scrollView.contentOffset));
    
    if (isDragging) {
        
        currentOffsetY = scrollView.contentOffset.y;
        
        if (currentOffsetY > lastOffsetY) {
            
            if (beginScrollDirection == JKPhotoPickerScrollDirectionNone) {
                
                beginScrollDirection = JKPhotoPickerScrollDirectionUp;
            }
            
            endScrollDirection = JKPhotoPickerScrollDirectionUp;
            
            //JKLog("上滑-------")
        }
        
        if (currentOffsetY < lastOffsetY) {
            
            //JKLog("下滑-------")
            
            if (beginScrollDirection == JKPhotoPickerScrollDirectionNone) {
                
                beginScrollDirection = JKPhotoPickerScrollDirectionDown;
            }
            
            endScrollDirection = JKPhotoPickerScrollDirectionDown;
        }
        
        lastOffsetY = currentOffsetY;
    }
    
    if (scrollView.contentOffset.y + scrollView.contentInset.top >= 0) {
        return;
    }
    
    if (self.isZooming || isGonnaDismiss || self.isDoubleTap || !isDragging) {
        return;
    }
    
    CGPoint point = [scrollView.panGestureRecognizer translationInView:scrollView.panGestureRecognizer.view.superview];
    
    point.y -= (beginDraggingOffset.y + scrollView.contentInset.top);
    
    CGFloat scale = point.y / JKPhotoPickerScreenH;
    
    self.bgAlpha = 1 - scale;
    
    self.collectionView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:self.bgAlpha];
    
    if (!isDragging) { return; }
    
    scrollView.pinchGestureRecognizer.enabled = NO;
    
    self.transformScale = (self.currentZoomScale - scale);
    self.transformScale = self.transformScale < 0.2 ? 0.2 : self.transformScale;
    
    self.photoImageView.transform = CGAffineTransformMakeScale(self.transformScale, self.transformScale);
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
    [self calculateInset];
    NSLog(@"当前zoomScale ---> %.2f", scale);
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.photoImageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
    [self calculateInset];
}

- (void)calculateInset{
    
    // 计算内边距，注意只能使用frame
    CGFloat offsetX = (JKPhotoPickerScreenW - self.photoImageView.frame.size.width) * 0.5;
    CGFloat offsetY = (JKPhotoPickerScreenH - self.photoImageView.frame.size.height) * 0.5;
    
    // 当小于0的时候，放大的图片将无法滚动，因为内边距为负数时限制了它可以滚动的范围
    offsetX = (offsetX < 0) ? 0 : offsetX;
    offsetY = (offsetY < 0) ? 0 : offsetY;
    
    BOOL flag = (JKPhotoPickerIsIphoneX && self.photoImageView.frame.size.height >= (JKPhotoPickerScreenH - 44 - 44));
    
    if (flag) {
        
        offsetY = 44;
    }
    
    self.scrollView.contentInset = UIEdgeInsetsMake(offsetY, offsetX, offsetY, offsetX);
}
@end
