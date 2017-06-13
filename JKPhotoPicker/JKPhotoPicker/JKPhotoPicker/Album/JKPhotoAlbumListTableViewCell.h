//
//  JKPhotoAlbumListTableViewCell.h
//  JKPhotoPicker
//
//  Created by albert on 2016/12/27.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PHAssetCollection, JKPhotoItem;

@interface JKPhotoAlbumListTableViewCell : UITableViewCell
/** 模型 */
@property (nonatomic, strong) JKPhotoItem *photoItem;

/** 模型 */
//@property (nonatomic, strong) PHAssetCollection *assetCollection;
@end
