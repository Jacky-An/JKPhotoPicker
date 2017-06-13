//
//  JKPhotoSelectCompleteCollectionViewCell.m
//  JKPhotoPicker
//
//  Created by albert on 2016/12/29.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import "JKPhotoSelectCompleteCollectionViewCell.h"
#import "JKPhotoItem.h"
#import <Photos/Photos.h>

@interface JKPhotoSelectCompleteCollectionViewCell ()
{
    JKPhotoItem *_photoItem;
}
@end

@implementation JKPhotoSelectCompleteCollectionViewCell

- (JKPhotoItem *)photoItem{
    
    return _photoItem;
}

- (void)setPhotoItem:(JKPhotoItem *)photoItem{
    _photoItem = photoItem;
    
    self.cameraIconButton.hidden = YES;
    self.photoImageView.hidden = NO;
    
    self.contentView.hidden = NO;
    
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    
//        PHImageRequestOptions *options = [[PHImageRequestOptions alloc]init];
//        options.synchronous = YES;
    
        [[PHImageManager defaultManager] requestImageForAsset:_photoItem.photoAsset targetSize:CGSizeMake(200, 200) contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            
//            dispatch_async(dispatch_get_main_queue(), ^{
               self.photoImageView.image = result;
//            });
        }];
//    });
}
@end
