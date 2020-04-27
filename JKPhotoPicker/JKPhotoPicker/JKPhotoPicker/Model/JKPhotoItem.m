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
