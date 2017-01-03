//
//  JKPhotoCollectionViewCell.m
//  JKPhotoPicker
//
//  Created by albert on 2016/12/21.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import "JKPhotoCollectionViewCell.h"
#import "JKPhotoItem.h"
#import <Photos/Photos.h>

// 随机色
#define JKRandomColor [UIColor colorWithRed:arc4random_uniform(100)/100.0 green:arc4random_uniform(100)/100.0 blue:arc4random_uniform(100)/100.0 alpha:1]

@interface JKPhotoCollectionViewCell ()
{
    __weak UIButton *_cameraIconButton;
}
/** 照片选中按钮 */
@property (nonatomic, weak) UIButton *selectButton;

/** 选中和未选中的标识 */
@property (nonatomic, weak) UIImageView *selectIconImageView;
@end

@implementation JKPhotoCollectionViewCell

- (UIButton *)cameraIconButton{
    if (!_cameraIconButton) {
        UIButton *cameraIconButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
        cameraIconButton.hidden = YES;
        [cameraIconButton setBackgroundImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"resource.bundle/images/take_photo.png"]] forState:(UIControlStateNormal)];
        [self.contentView addSubview:cameraIconButton];
        _cameraIconButton = cameraIconButton;
        
        [cameraIconButton addTarget:self action:@selector(cameraButtonClick) forControlEvents:(UIControlEventTouchUpInside)];
        
        // 相机按钮约束
        cameraIconButton.translatesAutoresizingMaskIntoConstraints = NO;
        NSArray *cameraIconButtonCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[cameraIconButton]-0-|" options:0 metrics:nil views:@{@"cameraIconButton" : cameraIconButton}];
        [self.contentView addConstraints:cameraIconButtonCons1];
        
        NSArray *cameraIconButtonCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[cameraIconButton]-0-|" options:0 metrics:nil views:@{@"cameraIconButton" : cameraIconButton}];
        [self.contentView addConstraints:cameraIconButtonCons2];
    }
    return _cameraIconButton;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self initialization];
    }
    return self;
}

- (void)initialization{
    
    [self setupPhotoImageView];
    
    [self setupSelectedIcon];
}

- (void)setupPhotoImageView{
    // 照片
    UIImageView *photoImageView = [[UIImageView alloc] init];
    photoImageView.contentMode = UIViewContentModeScaleAspectFill;
    photoImageView.clipsToBounds = YES;
//    photoImageView.backgroundColor = JKRandomColor;
    [self.contentView insertSubview:photoImageView atIndex:0];
    self.photoImageView = photoImageView;
    
    // 照片约束
    photoImageView.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *photoImageViewCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[photoImageView]-0-|" options:0 metrics:nil views:@{@"photoImageView" : photoImageView}];
    [self.contentView addConstraints:photoImageViewCons1];
    
    NSArray *photoImageViewCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[photoImageView]-0-|" options:0 metrics:nil views:@{@"photoImageView" : photoImageView}];
    [self.contentView addConstraints:photoImageViewCons2];
}

- (void)setupSelectedIcon{
    // 照片选中按钮
    UIButton *selectButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [selectButton addTarget:self action:@selector(selectImageClick) forControlEvents:(UIControlEventTouchUpInside)];
    [self.contentView addSubview:selectButton];
    self.selectButton = selectButton;
    
    // 照片选中按钮约束
    selectButton.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *selectButtonCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[selectButton(40)]-0-|" options:0 metrics:nil views:@{@"selectButton" : selectButton}];
    [self.contentView addConstraints:selectButtonCons1];
    
    NSArray *selectButtonCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[selectButton(40)]-0-|" options:0 metrics:nil views:@{@"selectButton" : selectButton}];
    [self.contentView addConstraints:selectButtonCons2];
    
    // 照片选中标识
    UIImageView *selectIconImageView = [[UIImageView alloc] init];
    selectIconImageView.image = [UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"resource.bundle/images/deselected_icon.png"]];
    selectIconImageView.highlightedImage = [UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"resource.bundle/images/selected_icon.png"]];
    [self.contentView addSubview:selectIconImageView];
    self.selectIconImageView = selectIconImageView;
    
    // 照片选中标识约束
    selectIconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *selectIconImageViewCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[selectIconImageView(25)]-3-|" options:0 metrics:nil views:@{@"selectIconImageView" : selectIconImageView}];
    [self.contentView addConstraints:selectIconImageViewCons1];
    
    NSArray *selectIconImageViewCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[selectIconImageView(25)]-3-|" options:0 metrics:nil views:@{@"selectIconImageView" : selectIconImageView}];
    [self.contentView addConstraints:selectIconImageViewCons2];
}

- (void)setHighlighted:(BOOL)highlighted{}

- (void)setSelected:(BOOL)selected{
    [super setSelected:selected];
    
//    self.selectIconImageView.highlighted = self.selectIconImageView.highlighted;
}

- (void)setPhotoItem:(JKPhotoItem *)photoItem{
    _photoItem = photoItem;
    
    self.selectIconImageView.highlighted = _photoItem.isSelected;
    
    if (_photoItem.isShowCameraIcon) {
        self.photoImageView.hidden = YES;
        self.selectButton.hidden = YES;
        self.selectIconImageView.hidden = YES;
        self.cameraIconButton.hidden = NO;
        return;
    }
    _cameraIconButton.hidden = YES;
    self.photoImageView.hidden = NO;
    self.selectButton.hidden = NO;
    self.selectIconImageView.hidden = NO;
    
    [[PHImageManager defaultManager] requestImageForAsset:_photoItem.photoAsset targetSize:CGSizeMake(200, 200) contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        self.photoImageView.image = result;
    }];
    
    // 这样会很卡，而且内存警告直接崩，还不清晰
//    self.photoImageView.image = _photoItem.thumImage;
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

// 点击相机拍照
- (void)cameraButtonClick{
    !self.cameraButtonClickBlock ? : self.cameraButtonClickBlock();
}

- (void)dealloc{
//    NSLog(@"%d, %s",__LINE__, __func__);
}
@end
