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

/** requestID */
@property (nonatomic, assign) PHImageRequestID requestID;
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
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    
    self.requestID = [[PHImageManager defaultManager] requestImageForAsset:_photoItem.photoAsset targetSize:JKPhotoThumbSize() contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        
        PHImageRequestID requestID = [[info objectForKey:PHImageResultRequestIDKey] intValue];
        
        if (requestID != self.requestID) { return; }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.photoImageView.image = result;
        });
    }];
}
@end
