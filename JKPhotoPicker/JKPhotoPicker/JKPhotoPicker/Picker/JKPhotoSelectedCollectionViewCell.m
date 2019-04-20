//
//  JKPhotoSelectedCollectionViewCell.m
//  JKPhotoPicker
//
//  Created by albert on 2016/12/28.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import "JKPhotoSelectedCollectionViewCell.h"
#import "JKPhotoResourceManager.h"

@interface JKPhotoSelectedCollectionViewCell ()
/** 照片 */
//@property (nonatomic, weak) UIImageView *photoImageView;

/** 删除按钮 */
@property (nonatomic, weak) UIButton *deleteButton;
@end

@implementation JKPhotoSelectedCollectionViewCell

- (UIButton *)deleteButton{
    if (!_deleteButton) {
        // 删除按钮
        UIButton *deleteButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [self.contentView addSubview:deleteButton];
        
        [deleteButton setBackgroundImage:[JKPhotoResourceManager jk_imageNamed:@"delete_icon@3x"] forState:(UIControlStateNormal)];
        _deleteButton = deleteButton;
        
        [deleteButton addTarget:self action:@selector(deleteButtonClick) forControlEvents:(UIControlEventTouchUpInside)];
        
        deleteButton.translatesAutoresizingMaskIntoConstraints = NO;
        NSArray *deleteButtonCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[deleteButton(16)]-(0)-|" options:0 metrics:nil views:@{@"deleteButton" : deleteButton}];
        [self.contentView addConstraints:deleteButtonCons1];
        
        NSArray *deleteButtonCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(2)-[deleteButton(16)]" options:0 metrics:nil views:@{@"deleteButton" : deleteButton}];
        [self.contentView addConstraints:deleteButtonCons2];
    }
    return _deleteButton;
}

// 覆盖基类方法
- (void)setupPhotoImageView{
    // 照片
    UIImageView *photoImageView = [[UIImageView alloc] init];
    photoImageView.contentMode = UIViewContentModeScaleAspectFill;
    photoImageView.clipsToBounds = YES;
    [self.contentView insertSubview:photoImageView atIndex:0];
    self.photoImageView = photoImageView;
    
    // 照片约束
    photoImageView.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *photoImageViewCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[photoImageView]-5-|" options:0 metrics:nil views:@{@"photoImageView" : photoImageView}];
    [self.contentView addConstraints:photoImageViewCons1];
    
    NSArray *photoImageViewCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[photoImageView]-10-|" options:0 metrics:nil views:@{@"photoImageView" : photoImageView}];
    [self.contentView addConstraints:photoImageViewCons2];
    
    [self deleteButton];
}

// 覆盖基类方法
- (void)setupSelectedIcon{}

- (void)setPhotoItem:(JKPhotoItem *)photoItem{
    [super setPhotoItem:photoItem];
    self.cameraIconButton.hidden = YES;
    self.photoImageView.hidden = NO;
    
    self.contentView.hidden = NO;
}

// 删除选中的照片
- (void)deleteButtonClick{
    
    [UIView animateWithDuration:0.25 animations:^{
        self.contentView.transform = CGAffineTransformMakeScale(0.001, 0.001);
        self.contentView.alpha = 0;
        
    } completion:^(BOOL finished) {
        self.contentView.hidden = YES;
        self.contentView.alpha = 1;
        self.contentView.transform = CGAffineTransformIdentity;
        
        !self.deleteButtonClickBlock ? : self.deleteButtonClickBlock(self);
    }];
}
@end
