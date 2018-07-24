//
//  JKPhotoItem.m
//  JKPhotoPicker
//
//  Created by albert on 2016/12/21.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import "JKPhotoItem.h"
#import "JKPhotoManager.h"

@interface JKPhotoItem ()
{
    /** 缩略图 */
    UIImage *_thumImage;
    
    /** 原图 */
    UIImage *_originalImage;
    
    /** 相册缩略图 */
    UIImage *_albumThumImage;
    
//    BOOL _shouldSelected;
    
    NSString *_videoPath;
}
@end

@implementation JKPhotoItem

- (instancetype)init{
    
    if (self = [super init]) {
        
        _shouldSelected = YES;
    }
    
    return self;
}

//- (BOOL)shouldSelected{
//
//    _shouldSelected = self.photoAsset.mediaType == PHAssetMediaTypeImage;
//
//    return _shouldSelected;
//}

- (void)setPhotoAsset:(PHAsset *)photoAsset{
    _photoAsset = photoAsset;
    
    switch (_photoAsset.mediaType) {
            
        case PHAssetMediaTypeUnknown:
            
            break;
            
        case PHAssetMediaTypeImage:
            
            _dataType = JKPhotoPickerMediaDataTypeNormalImage;
            
            if (_photoAsset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
                
                _dataType = JKPhotoPickerMediaDataTypePhotoLive;
            }
            
            break;
            
        case PHAssetMediaTypeVideo:
            
            _dataType = JKPhotoPickerMediaDataTypeVideo;
            
            break;
            
        case PHAssetMediaTypeAudio:
            
            break;
            
        default:
            break;
    }
    
    _shouldSelected = _dataType == JKPhotoPickerMediaDataTypeNormalImage;
    
    _assetLocalIdentifier = _photoAsset.localIdentifier;
}

- (UIImage *)thumImage{
    if (!_thumImage) {
        
        [[PHImageManager defaultManager] requestImageForAsset:_photoAsset targetSize:CGSizeMake(200, 200) contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            
            _thumImage = result;
        }];
    }
    return _thumImage;
}

- (UIImage *)originalImage{
    if (!_originalImage) {
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc]init];
        options.synchronous = YES;
        
//        [[PHImageManager defaultManager] requestImageDataForAsset:_photoAsset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
//
//        }];
        
        [[PHImageManager defaultManager] requestImageForAsset:_photoAsset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            
            _originalImage = result;
        }];
    }
    return _originalImage;
}

- (void)setAlbumAssetCollection:(PHAssetCollection *)albumAssetCollection{
    _albumAssetCollection = albumAssetCollection;
    
    _albumLocalIdentifier = _albumAssetCollection.localIdentifier;
    
    _albumTitle = _albumAssetCollection.localizedTitle;
    if ([_albumTitle isEqualToString:@"Favorites"]) {
        _albumTitle = @"个人收藏";
    }else if ([_albumTitle isEqualToString:@"Recently Added"]) {
        _albumTitle = @"最近添加";
    }else if ([_albumTitle isEqualToString:@"Screenshots"]) {
        _albumTitle = @"屏幕快照";
    }else if ([_albumTitle isEqualToString:@"Camera Roll"]) {
        _albumTitle = @"相机胶卷";
    }else if ([_albumTitle isEqualToString:@"All Photos"]) {
        _albumTitle = @"所有照片";
    }
    
    NSLog(@"localizedTitle == %@ \nlocalizedLocationNames == %@ \nlocalIdentifier == %@", _albumAssetCollection.localizedTitle, _albumAssetCollection.localizedLocationNames, _albumAssetCollection.localIdentifier);
}

- (UIImage *)albumThumImage{
    if (!_albumThumImage) {
        
        [[PHImageManager defaultManager] requestImageForAsset:_albumThumAsset targetSize:CGSizeMake(200, 200) contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            
            _albumThumImage = result;
        }];
    }
    
    return _albumThumImage;
}

- (NSString *)videoPath{
    if (!_videoPath) {
        _videoPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"JKPhotoPickerVideoCache"];
    }
    return _videoPath;
}

// 防止崩溃
- (void)setValue:(id)value forUndefinedKey:(NSString *)key{}
@end
