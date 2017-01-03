//
//  JKPhotoAlbumListView.h
//  JKPhotoPicker
//
//  Created by albert on 2016/12/27.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JKPhotoItem;

@interface JKPhotoAlbumListView : UIView

/** 监听点击选中cell的block */
@property (nonatomic, copy) void(^selectRowBlock)(JKPhotoItem *photoItem);

/** 监听重新加载相册完成的block */
@property (nonatomic, copy) void(^reloadCompleteBlock)();

/** 相机胶卷的相册item */
@property (nonatomic, strong, readonly) JKPhotoItem *cameraRollItem;

/** 执行动画 */
- (void)executeAlbumListViewAnimationCompletion:(void(^)())completion;

/** 重新加载相册 */
- (void)reloadAlbum;
@end
