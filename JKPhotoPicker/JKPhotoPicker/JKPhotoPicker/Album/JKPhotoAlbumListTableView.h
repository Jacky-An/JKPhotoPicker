//
//  JKPhotoAlbumListTableView.h
//  JKPhotoPicker
//
//  Created by albert on 2016/12/27.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JKPhotoAlbumItem;

@protocol JKPhotoAlbumListTableViewDelegate;

@interface JKPhotoAlbumListTableView : UIView

/** delegate */
@property (nonatomic, weak) id<JKPhotoAlbumListTableViewDelegate> delegate;

/** 监听点击选中cell的block */
@property (nonatomic, copy) void(^selectRowBlock)(JKPhotoAlbumItem *albumItem, BOOL isReload);

/** 监听重新加载相册完成的block */
@property (nonatomic, copy) void(^reloadCompleteBlock)(void);

/** 相机胶卷的相册item */
@property (nonatomic, strong, readonly) JKPhotoAlbumItem *cameraRollAlbumItem;

/** 当前选择的相册item */
@property (nonatomic, strong, readonly) JKPhotoAlbumItem *currentAlbumItem;

/** navigationController */
@property (nonatomic, weak) UINavigationController *navigationController;

/** 执行动画 */
- (void)executeAlbumListTableViewAnimationCompletion:(void(^)(void))completion;

/** 重新加载相册 */
- (void)reloadAlbum;
@end


@protocol JKPhotoAlbumListTableViewDelegate <NSObject>

@optional

- (void)albumListTableView:(JKPhotoAlbumListTableView *)albumListTableView didSelectAlbumItem:(JKPhotoAlbumItem *)albumItem isReload:(BOOL)isReload;
@end
