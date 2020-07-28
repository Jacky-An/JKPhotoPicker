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
#import "JKPhotoResourceManager.h"
#import "JKPhotoBrowserViewController.h"

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
    
    BOOL beginDraggingZoom;
    CGPoint beginDraggingZoomTranslation;
    CGFloat draggingZoomDeltaX;
    
    CGFloat draggingZoomTranlationScaleY;
    
    JKPhotoPickerScrollDirection beginScrollDirection;
    JKPhotoPickerScrollDirection endScrollDirection;
    
    CGFloat initialX;
    CGFloat calculateX;
    CGFloat calculateDistanceX;
    CGFloat calculateDistanceY;
    
    BOOL shouldResetCalculate;
}
/** imageContainerView */
@property (nonatomic, weak) UIView *imageContainerView;

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

/** defaultZoomScale */
@property (nonatomic, assign) CGFloat defaultZoomScale;
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
    
    _defaultZoomScale = 1.001;
    
    self.currentZoomScale = 1;
    
    // 当前屏幕宽高比
    _screenAspectRatio = JKPhotoScreenWidth / JKPhotoScreenHeight;
    
    [self setupPhotoImageView];
    
    [self setupSelectedIcon];
    
    UIActivityIndicatorViewStyle style = UIActivityIndicatorViewStyleWhiteLarge;
    if (@available(iOS 13.0, *)) {
        style = UIActivityIndicatorViewStyleLarge;
    }
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] init];
    indicatorView.activityIndicatorViewStyle = style;
    [self.contentView addSubview:indicatorView];
    self.indicatorView = indicatorView;
    
    indicatorView.center = CGPointMake(self.browserContentView.frame.size.width * 0.5 + 10, self.browserContentView.frame.size.width * 0.5);
}

- (void)setupPhotoImageView{
    
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.frame = CGRectMake(10, 0, JKPhotoScreenWidth, JKPhotoScreenHeight);
    scrollView.delegate = self;
    scrollView.minimumZoomScale = 1;
    scrollView.maximumZoomScale = 3;
    scrollView.alwaysBounceVertical = YES;
    //scrollView.alwaysBounceHorizontal = NO;
    
    [self.contentView insertSubview:scrollView atIndex:0];
    _scrollView = scrollView;
    
    if (@available(iOS 11.0, *)) {
        
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    if (@available(iOS 13.0, *)) {
        
        scrollView.automaticallyAdjustsScrollIndicatorInsets = NO;
    }
    
    UIView *imageContainerView = [[UIView alloc] init];
    [self.scrollView insertSubview:imageContainerView atIndex:0];
    _imageContainerView = imageContainerView;
    
    // 照片
    UIImageView *photoImageView = [[UIImageView alloc] init];
    photoImageView.backgroundColor = [UIColor blackColor];
    photoImageView.userInteractionEnabled = YES;
    photoImageView.contentMode = UIViewContentModeScaleAspectFit;
    photoImageView.clipsToBounds = YES;
    [self.imageContainerView insertSubview:photoImageView atIndex:0];
    _photoImageView = photoImageView;
    
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
    
    [playVideoButton setBackgroundImage:[JKPhotoResourceManager jk_imageNamed:@"video-play@3x"] forState:(UIControlStateNormal)];
    
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
    gifWebView.scrollView.scrollEnabled = NO;
    
    if (@available(iOS 11.0, *)) {
        
        gifWebView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    if (@available(iOS 13.0, *)) {
        
        gifWebView.scrollView.automaticallyAdjustsScrollIndicatorInsets = NO;
    }
    
    gifWebView.userInteractionEnabled = NO;
    //    gifWebView.scalesPageToFit = YES;
    gifWebView.backgroundColor = nil;
    gifWebView.opaque = NO;
    gifWebView.hidden = YES;
    [self.photoImageView addSubview:gifWebView];
    self.gifWebView = gifWebView;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    self.scrollView.frame = CGRectMake(10, 0, self.frame.size.width - 20, self.frame.size.height);
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
    
    if (tap.state == UIGestureRecognizerStateEnded) {
        
        [self selfDismiss];
    }
}

- (void)doubleTap:(UITapGestureRecognizer *)tap{
    self.isDoubleTap = YES;
    
    CGPoint touchPoint = [tap locationInView:self.contentView];
    
    CGPoint point = [self.imageContainerView convertPoint:touchPoint fromView:self.contentView];
    
    if (![self.imageContainerView pointInside:point withEvent:nil]) {
        return;
    }
    
    // 双击缩小
    if (self.scrollView.zoomScale > 1.1) {
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
    
    NSArray *selectButtonCons2 = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[selectButton(70)]-%.0f-|", JKPhotoUtility.currentHomeIndicatorHeight] options:0 metrics:nil views:@{@"selectButton" : selectButton}];
    [self.contentView addConstraints:selectButtonCons2];
    
    // 照片选中标识
    UIImageView *selectIconImageView = [[UIImageView alloc] init];
    selectIconImageView.contentMode = PHImageContentModeAspectFit;
    
    selectIconImageView.image = [JKPhotoResourceManager jk_imageNamed:@"deselected_icon@3x"];
    selectIconImageView.highlightedImage = [JKPhotoResourceManager jk_imageNamed:@"selected_icon@3x"];
    [self.contentView addSubview:selectIconImageView];
    self.selectIconImageView = selectIconImageView;
    
    // 照片选中标识约束
    selectIconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *selectIconImageViewCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[selectIconImageView(25)]-10-|" options:0 metrics:nil views:@{@"selectIconImageView" : selectIconImageView}];
    [self.contentView addConstraints:selectIconImageViewCons1];
    
    NSArray *selectIconImageViewCons2 = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[selectIconImageView(25)]-%.0f-|", JKPhotoUtility.currentHomeIndicatorHeight + 10] options:0 metrics:nil views:@{@"selectIconImageView" : selectIconImageView}];
    [self.contentView addConstraints:selectIconImageViewCons2];
}

- (void)setHighlighted:(BOOL)highlighted{}

- (void)setSelected:(BOOL)selected{
    [super setSelected:selected];
    
    //    self.selectIconImageView.highlighted = self.selectIconImageView.highlighted;
}

- (void)setController:(JKPhotoBrowserViewController *)controller{
    
    __weak typeof(self) weakSelf = self;
    
    [controller setDraggingBlock:^(BOOL isDragging) {
        
        weakSelf.scrollView.scrollEnabled = !isDragging;
    }];
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
    
    CGSize targetSize = CGSizeMake(MIN(JKPhotoScreenWidth, JKPhotoScreenHeight) * JKPhotoScreenScale, MAX(JKPhotoScreenWidth, JKPhotoScreenHeight) * JKPhotoScreenScale);
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.networkAccessAllowed = YES;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;

        // 使用requestImageDataForAsset
        self.imageRequestID = [[PHImageManager defaultManager] requestImageForAsset:self->_photoItem.photoAsset targetSize:targetSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            
            PHImageRequestID ID = [[info objectForKey:PHImageResultRequestIDKey] intValue];
            
            if (ID != self.imageRequestID) { return; }
            
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
                options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
                
                self.livePhotoRequestID = [[PHImageManager defaultManager] requestLivePhotoForAsset:self->_photoItem.photoAsset targetSize:targetSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
                    
                    //PHImageRequestID ID = [[info objectForKey:PHImageResultRequestIDKey] intValue];
                    
                    //if (ID != self.livePhotoRequestID) { return; }
                    
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
            
            self.gifRequestID = [[PHImageManager defaultManager] requestImageDataForAsset:self->_photoItem.photoAsset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                
                PHImageRequestID ID = [[info objectForKey:PHImageResultRequestIDKey] intValue];
                
                if (ID != self.gifRequestID) { return; }
                
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
    CGFloat pictureW = self.browserContentView.frame.size.width;
    CGFloat pictureH = pictureW * image.size.height / image.size.width;
    
    if (JKPhotoUtility.isDeviceiPad || JKPhotoUtility.isLandscape) {
        
        if (pictureH > self.browserContentView.frame.size.height) {
            
            pictureH = self.browserContentView.frame.size.height;
            pictureW = pictureH * image.size.width / image.size.height;
        }
    }
    
    self.imageContainerView.frame = CGRectMake(0, 0, pictureW, pictureH);
    self.photoImageView.frame = CGRectMake(0, 0, pictureW, pictureH);
    
    if (pictureW < self.browserContentView.frame.size.width) {
        
        self.scrollView.maximumZoomScale = self.browserContentView.frame.size.width / pictureW;
    }
    
    if (self.photoItem.shouldPlayGif) {
        
        self.gifWebView.transform = CGAffineTransformIdentity;
        self.gifWebView.frame = self.photoImageView.bounds;
        
        if (image.size.width < self.browserContentView.frame.size.width) {
            
            self.gifWebView.frame = CGRectMake((pictureW - image.size.width) * 0.5, (pictureH - image.size.height) * 0.5, image.size.width, image.size.height);
            self.gifWebView.transform = CGAffineTransformMakeScale(pictureW / image.size.width, pictureH / image.size.height);
        }
    }
    
    self.scrollView.contentSize = CGSizeMake(0, pictureH);
    
    [self calculateInset];
    
    originalHeight = pictureH;
    
    [self.scrollView setContentOffset:CGPointMake(-self.scrollView.contentInset.left, -self.scrollView.contentInset.top) animated:NO];
    
    self.defaultZoomScale = (pictureW + 0.5) / pictureW;
    
    //self.scrollView.alwaysBounceHorizontal = self.imageContainerView.frame.size.width >= self.scrollView.frame.size.width;
}

- (void)resetView{
    
    self.currentZoomScale = 1;
    
    self.scrollView.scrollEnabled = YES;
    self.scrollView.contentOffset = CGPointZero;
    self.scrollView.contentInset = UIEdgeInsetsZero;
    self.scrollView.contentSize = CGSizeZero;
    
    // 放大图片实质就是transform形变
    self.imageContainerView.transform = CGAffineTransformIdentity;
    self.imageContainerView.frame = JKPhotoScreenBounds;
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
    
    initialX = self.photoImageView.frame.origin.x;
    
    //self.collectionView.scrollEnabled = NO;
    
    beginDraggingZoomTranslation = [scrollView.panGestureRecognizer translationInView:scrollView.panGestureRecognizer.view.superview];
    
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
    
    self.collectionView.scrollEnabled = YES;
    
    isDragging = NO;
    
    beginScrollDirection = JKPhotoPickerScrollDirectionNone;
    endScrollDirection = JKPhotoPickerScrollDirectionNone;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    
    beginDraggingZoom = NO;
    
    if (self.isZooming) { return; }
    
    if (scrollView.contentOffset.y + scrollView.contentInset.top < -dismissDistance &&
        (endScrollDirection == JKPhotoPickerScrollDirectionDown)) {
        
        isGonnaDismiss = YES;
        
        [self selfDismiss];
        
    } else {
        
        if (self.currentZoomScale == self.defaultZoomScale) {
            
            self.currentZoomScale = 1;
            
            [self.scrollView setZoomScale:1 animated:YES];
        }
        
        [UIView animateWithDuration:0.25 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:15.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            
            self.photoImageView.transform = CGAffineTransformIdentity;
            self.controllerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:1];
            self.photoImageView.frame = CGRectMake(self->initialX, 0, self.photoImageView.frame.size.width, self.photoImageView.frame.size.height);
            
        } completion:^(BOOL finished) {
            
            scrollView.pinchGestureRecognizer.enabled = YES;
            
            self.collectionView.scrollEnabled = YES;
        }];
        
        if (self.playVideoButton.isHidden) { return; }
        
        [UIView animateWithDuration:0.25 animations:^{
            
            self.playVideoButton.alpha = 1;
        }];
    }
}

- (void)selfDismiss{
    
    CGRect rect = [self.photoImageView.superview convertRect:self.photoImageView.frame toView:JKPhotoUtility.keyWindow];
    
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
        self.controllerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
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
    
    if (scrollView.pinchGestureRecognizer.state == UIGestureRecognizerStateBegan ||
        scrollView.pinchGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        
        return;
    }
    
    CGPoint location = [self.scrollView.panGestureRecognizer locationInView:self.scrollView];
    
    if (scrollView.contentOffset.y + scrollView.contentInset.top >= 0) {
        
        if (shouldResetCalculate) {
            
            calculateDistanceY = location.y - self.photoImageView.frame.origin.y;
            calculateDistanceX = location.x - self.photoImageView.frame.origin.x;
            calculateX = self.photoImageView.frame.origin.x;
            
            //self.scrollView.alwaysBounceHorizontal = NO;
            
            shouldResetCalculate = NO;
        }
        
        return;
    }
    
    if (!shouldResetCalculate) {
        
        shouldResetCalculate = YES;
        
        beginDraggingZoom = NO;
    }
    
    if (self.isZooming || isGonnaDismiss || self.isDoubleTap || !isDragging) {
        return;
    }
    
    CGPoint point = [scrollView.panGestureRecognizer translationInView:scrollView.panGestureRecognizer.view.superview];
    
    if (!beginDraggingZoom) {
        
        beginDraggingZoom = YES;
        
        draggingZoomDeltaX = point.x - beginDraggingZoomTranslation.x;
        
        scrollView.pinchGestureRecognizer.enabled = NO;
        
        draggingZoomTranlationScaleY = self.photoImageView.frame.size.height / MAX(JKPhotoScreenHeight, JKPhotoScreenWidth);
        
        //self.scrollView.alwaysBounceHorizontal = YES;
        
        calculateDistanceY = location.y - self.photoImageView.frame.origin.y;
        calculateDistanceX = location.x - self.photoImageView.frame.origin.x;
        calculateX = self.photoImageView.frame.origin.x;
        
        if (self.currentZoomScale == 1) {
            
            self.currentZoomScale = self.defaultZoomScale;
            [self.scrollView setZoomScale:self.defaultZoomScale animated:NO];
        }
    }
    
    point.x -=draggingZoomDeltaX;//-(scrollView.contentOffset.x + scrollView.contentInset.left);// -= draggingZoomDeltaX;
    
    point.y -= (beginDraggingOffset.y + scrollView.contentInset.top);
    
    CGFloat scale = MAX(0, point.y) / JKPhotoScreenHeight;
    
    self.bgAlpha = 1 - scale;
    
    if (self.bgAlpha > 0.2) {
        
        self.collectionView.scrollEnabled = NO;
    }
    
    self.controllerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:self.bgAlpha];
    
    if (!isDragging) { return; }
    
    if (draggingZoomTranlationScaleY > 3) {
        
        scale = (-scrollView.contentOffset.y - scrollView.contentInset.top) / JKPhotoScreenHeight / draggingZoomTranlationScaleY;
        
        self.transformScale = (1 - scale);
        self.transformScale = self.transformScale < 0.2 ? 0.2 : self.transformScale;
        
        self.photoImageView.transform = CGAffineTransformMakeScale(self.transformScale, self.transformScale);
        
        return;
    }
    
    self.transformScale = (1 - scale);
    self.transformScale = self.transformScale < 0.2 ? 0.2 : self.transformScale;
    
    self.photoImageView.transform = CGAffineTransformMakeScale(self.transformScale, self.transformScale);
    
    CGFloat currentDistanceX = calculateDistanceX * self.transformScale;
    CGFloat currentDistanceY = calculateDistanceY * self.transformScale;
    
    CGRect frame = self.photoImageView.frame;
    
    frame.origin.x = (location.x - currentDistanceX) / self.currentZoomScale;
    frame.origin.y = (location.y - currentDistanceY) / self.currentZoomScale;
    self.photoImageView.frame = frame;
    
    //NSLog(@"location --> %@", NSStringFromCGPoint(location));
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    self.collectionView.scrollEnabled = YES;
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
    return self.imageContainerView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
    [self calculateInset];
}

- (void)calculateInset{
    
    // 计算内边距，注意只能使用frame
    CGFloat offsetX = (self.browserContentView.frame.size.width - self.imageContainerView.frame.size.width) * 0.5;
    CGFloat offsetY = (self.browserContentView.frame.size.height - self.imageContainerView.frame.size.height) * 0.5;
    
    // 当小于0的时候，放大的图片将无法滚动，因为内边距为负数时限制了它可以滚动的范围
    offsetX = (offsetX < 0) ? 0 : offsetX;
    offsetY = (offsetY < 0) ? 0 : offsetY;
    
    [self.scrollView setContentInset:UIEdgeInsetsMake(offsetY, offsetX, offsetY, offsetX)];
}
@end
