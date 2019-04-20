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
#import "JKPhotoResourceManager.h"

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

/** 不可选择的遮盖 */
@property (nonatomic, weak) UIView *selectCoverView;

/** 数据类型 */
@property (nonatomic, weak) UILabel *dataTypeLabel;
@end

@implementation JKPhotoCollectionViewCell

- (UIButton *)cameraIconButton{
    if (!_cameraIconButton) {
        UIButton *cameraIconButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
        cameraIconButton.hidden = YES;
        
        [cameraIconButton setBackgroundImage:[JKPhotoResourceManager jk_imageNamed:@"take_photo"] forState:(UIControlStateNormal)];
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
    
    [self.contentView bringSubviewToFront:self.selectCoverView];
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
    
    // 不允许选择时的遮盖view
    UIView *selectCoverView = [[UIView alloc] init];
    selectCoverView.userInteractionEnabled = YES;
    selectCoverView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    [self.contentView insertSubview:selectCoverView aboveSubview:photoImageView];
    self.selectCoverView = selectCoverView;
    
    // 约束
    selectCoverView.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *selectCoverViewCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[selectCoverView]-0-|" options:0 metrics:nil views:@{@"selectCoverView" : selectCoverView}];
    [self.contentView addConstraints:selectCoverViewCons1];
    
    NSArray *selectCoverViewCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[selectCoverView]-0-|" options:0 metrics:nil views:@{@"selectCoverView" : selectCoverView}];
    [self.contentView addConstraints:selectCoverViewCons2];
    
    // 数据类型
    UILabel *dataTypeLabel = [[UILabel alloc] init];
    dataTypeLabel.textColor = [UIColor whiteColor];
    dataTypeLabel.font = [UIFont systemFontOfSize:11];
    dataTypeLabel.textAlignment = NSTextAlignmentRight;
    [selectCoverView addSubview:dataTypeLabel];
    _dataTypeLabel = dataTypeLabel;
    
    dataTypeLabel.shadowColor = [UIColor blackColor];
    dataTypeLabel.shadowOffset = CGSizeMake(0, 0.5);
    
    dataTypeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *dataTypeLabelLeftCons = [NSLayoutConstraint constraintWithItem:dataTypeLabel attribute:(NSLayoutAttributeLeft) relatedBy:(NSLayoutRelationEqual) toItem:selectCoverView attribute:(NSLayoutAttributeLeft) multiplier:1 constant:0];
    [self.contentView addConstraint:dataTypeLabelLeftCons];
    
    NSLayoutConstraint *dataTypeLabelRightCons = [NSLayoutConstraint constraintWithItem:dataTypeLabel attribute:(NSLayoutAttributeRight) relatedBy:(NSLayoutRelationEqual) toItem:selectCoverView attribute:(NSLayoutAttributeRight) multiplier:1 constant:0];
    [self.contentView addConstraint:dataTypeLabelRightCons];
    
    NSLayoutConstraint *dataTypeLabelBottomCons = [NSLayoutConstraint constraintWithItem:dataTypeLabel attribute:(NSLayoutAttributeBottom) relatedBy:(NSLayoutRelationEqual) toItem:selectCoverView attribute:(NSLayoutAttributeBottom) multiplier:1 constant:0];
    [self.contentView addConstraint:dataTypeLabelBottomCons];
    
    NSLayoutConstraint *dataTypeLabelHCons = [NSLayoutConstraint constraintWithItem:dataTypeLabel attribute:(NSLayoutAttributeHeight) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:_dataTypeLabel.font.lineHeight];
    [self.contentView addConstraint:dataTypeLabelHCons];
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
    
    selectIconImageView.image = [JKPhotoResourceManager jk_imageNamed:@"deselected_icon@3x"];
    selectIconImageView.highlightedImage = [JKPhotoResourceManager jk_imageNamed:@"selected_icon@3x"];
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
    
    _dataTypeLabel.text = _photoItem.dataTypeDescription;
    
    self.selectIconImageView.highlighted = _photoItem.isSelected;
    
    if (_photoItem.isShowCameraIcon) {
        self.photoImageView.hidden = YES;
        self.selectButton.hidden = YES;
        self.selectIconImageView.hidden = YES;
        self.cameraIconButton.hidden = NO;
        self.selectCoverView.hidden = YES;
        return;
    }
    
    _cameraIconButton.hidden = YES;
    self.photoImageView.hidden = NO;
    self.selectButton.hidden = NO;
    self.selectIconImageView.hidden = NO;
    self.selectCoverView.hidden = _photoItem.shouldSelected;
    
    self.selectIconImageView.hidden = !self.selectCoverView.hidden;
    self.selectButton.hidden = !self.selectCoverView.hidden;
    
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
