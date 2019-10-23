//
//  JKPhotoItem.m
//  JKPhotoPicker
//
//  Created by albert on 2016/12/21.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import "JKPhotoItem.h"
#import "JKPhotoPickerEngine.h"
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>

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
            
            _dataType = JKPhotoPickerMediaDataTypeStaticImage;
            _shouldSelected = [JKPhotoItem selectDataType] == _dataType || ([JKPhotoItem selectDataType] == JKPhotoPickerMediaDataTypeImageIncludeGif);
            
            _dataTypeDescription = @"";
            
            if (@available(iOS 9.1, *)) {
                
                if (_photoAsset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
                    
                    _dataTypeDescription = @"LivePhoto";
                    
                    _dataType = JKPhotoPickerMediaDataTypePhotoLive;
                    _shouldSelected = [JKPhotoItem selectDataType] == _dataType;
                }
            }
            
            break;
            
        case PHAssetMediaTypeVideo:
            
            _dataType = JKPhotoPickerMediaDataTypeVideo;
            _shouldSelected = [JKPhotoItem selectDataType] == _dataType;
            
            _dataTypeDescription = @"Video";
            
            break;
            
        case PHAssetMediaTypeAudio:
            
            break;
            
        default:
            break;
    }
    
    _fileName = [_photoAsset valueForKey:@"filename"];
    
    if ([[[_fileName pathExtension] lowercaseString] isEqualToString:@"gif"]) {
        
        _dataTypeDescription = @"GIF";
        
        _dataType = JKPhotoPickerMediaDataTypeGif;
        
        _shouldPlayGif = ([JKPhotoItem selectDataType] == JKPhotoPickerMediaDataTypeGif || [JKPhotoItem selectDataType] == JKPhotoPickerMediaDataTypeImageIncludeGif || [JKPhotoItem selectDataType] == JKPhotoPickerMediaDataTypeAll);
        
        if ([JKPhotoItem selectDataType] == JKPhotoPickerMediaDataTypeGif) {
            
            _shouldSelected = YES;
        }
        NSLog(@"%@", _fileName);
    }
    
    if ([JKPhotoItem selectDataType] == JKPhotoPickerMediaDataTypeAll) {
        
        _shouldSelected = YES;
    }
    
    
//    PHAssetResource *resource = [PHAssetResource assetResourcesForAsset:_photoAsset].firstObject;
//
//    if ([resource.uniformTypeIdentifier isEqualToString:(NSString *)kUTTypeGIF]) {
//
//
//    }
    
    _assetLocalIdentifier = _photoAsset.localIdentifier;
}

- (UIImage *)thumImage{
    if (!_thumImage) {
        
        [[PHImageManager defaultManager] requestImageForAsset:_photoAsset targetSize:CGSizeMake(200, 200) contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            
            self->_thumImage = result;
        }];
    }
    return _thumImage;
}

- (UIImage *)originalImage{
    if (!_originalImage) {
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc]init];
        options.synchronous = YES;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
        
//        [[PHImageManager defaultManager] requestImageDataForAsset:_photoAsset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
//
//        }];
        
        [[PHImageManager defaultManager] requestImageForAsset:_photoAsset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            
            self->_originalImage = result;
        }];
    }
    return _originalImage;
}

- (NSString *)videoPath{
    if (!_videoPath) {
        _videoPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"JKPhotoPickerVideoCache"] stringByAppendingPathComponent:self.photoAsset.localIdentifier];
    }
    return _videoPath;
}

// 防止崩溃
- (void)setValue:(id)value forUndefinedKey:(NSString *)key{}


JKPhotoPickerMediaDataType type_;

+ (void)setSelectDataType:(JKPhotoPickerMediaDataType)selectDataType{
    
    type_ = selectDataType;
}

+ (JKPhotoPickerMediaDataType)selectDataType{
    
    return type_;
}
@end
