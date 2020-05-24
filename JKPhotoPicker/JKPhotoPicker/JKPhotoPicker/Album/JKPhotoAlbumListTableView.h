//
//  JKPhotoAlbumListTableView.h
//  JKPhotoPicker
//
//  Created by albert on 2016/12/27.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JKPhotoAlbumItem;

@interface JKPhotoAlbumListTableView : UIView

/** 监听点击选中cell的block */
@property (nonatomic, copy) void(^didselectAlbumHandler)(JKPhotoAlbumItem *albumItem, BOOL isReload);

/** 监听重新加载相册完成的block */
@property (nonatomic, copy) void(^reloadCompleteBlock)(void);

/** albumListDidShowHandler */
@property (nonatomic, copy) void (^albumListDidShowHandler)(void);

/** albumListDidDismissHandler */
@property (nonatomic, copy) void (^albumListDidDismissHandler)(void);

/** 相机胶卷的相册item */
@property (nonatomic, strong, readonly) JKPhotoAlbumItem *cameraRollAlbumItem;

/** 当前选择的相册item */
@property (nonatomic, strong, readonly) JKPhotoAlbumItem *currentAlbumItem;

/** navigationController */
@property (nonatomic, weak) UINavigationController *navigationController;

/// 展示动画
- (void)executeShowAlbumListAnimation;

/// 隐藏动画
- (void)executeDismissAlbumListAnimation;

/** 重新加载相册 */
- (void)reloadAlbumList;

#pragma mark
#pragma mark - Private

/** backgroundView */
@property (nonatomic, weak, readonly) UIView *backgroundView;

/** contentView */
@property (nonatomic, weak, readonly) UIView *contentView;

/** 初始化自身属性 交给子类重写 super自动调用该方法 */
- (void)initializeProperty NS_REQUIRES_SUPER;

/** 构造函数初始化时调用 注意调用super */
- (void)initialization NS_REQUIRES_SUPER;

/** 创建UI 交给子类重写 super自动调用该方法 */
- (void)createUI NS_REQUIRES_SUPER;

/** 布局UI 交给子类重写 super自动调用该方法 */
- (void)layoutUI NS_REQUIRES_SUPER;

/** 初始化数据 交给子类重写 super自动调用该方法 */
- (void)initializeUIData NS_REQUIRES_SUPER;
@end
