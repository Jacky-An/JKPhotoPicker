//
//  JKPhotoSelectCompleteView.h
//  JKPhotoPicker
//
//  Created by albert on 2016/12/29.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JKPhotoSelectCompleteView : UIView

/** 选中的图片模型数组 */
@property (nonatomic, strong) NSArray *photoItems;

/** 选中的图片数组 */
@property (nonatomic, strong, readonly) NSArray *selectedImages;

/** 流水布局 */
@property (nonatomic, strong, readonly) UICollectionViewFlowLayout *flowLayout;

/**
 * 类方法
 * superView : 父控件
 * viewController : 父控件所在的控制器，不传则无法预览已选择好的图片
 * frame : 设置frame
 * itemSize : cell的尺寸，注意高度要比宽度多10，图片才会是正方形
 */
+ (instancetype)completeViewWithSuperView:(UIView *)superView viewController:(UIViewController *)viewController frame:(CGRect)frame itemSize:(CGSize)itemSize scrollDirection:(UICollectionViewScrollDirection)scrollDirection;
@end
