//
//  JKPhotoCollectionViewCell.h
//  JKPhotoPicker
//
//  Created by albert on 2016/12/21.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JKPhotoItem;

@interface JKPhotoCollectionViewCell : UICollectionViewCell
/** 照片模型 */
@property (nonatomic, strong) JKPhotoItem *photoItem;

/** 照片 */
@property (nonatomic, weak) UIImageView *photoImageView;

/** 相机按钮 */
@property (nonatomic, weak, readonly) UIButton *cameraIconButton;

/** 监听点击选中照片的block */
@property (nonatomic, copy) BOOL(^selectBlock)(BOOL selected, JKPhotoCollectionViewCell *currentCell);

/** 监听点击相机按钮的block */
@property (nonatomic, copy) void(^cameraButtonClickBlock)(void);

/** 监听点击删除按钮的block */
@property (nonatomic, copy) void(^deleteButtonClickBlock)(JKPhotoCollectionViewCell *currentCell);
@end
