//
//  JKPhotoAlbumItem.m
//  JKPhotoPicker
//
//  Created by albert on 2019/10/22.
//  Copyright © 2019 安永博. All rights reserved.
//

#import "JKPhotoAlbumItem.h"
#import <Photos/Photos.h>

@interface JKPhotoAlbumItem ()

@end

@implementation JKPhotoAlbumItem


- (void)setAssetCollection:(PHAssetCollection *)albumAssetCollection{
    _assetCollection = albumAssetCollection;
    
    _localIdentifier = _assetCollection.localIdentifier;
    
    _albumTitle = _assetCollection.localizedTitle;
    
    if ([_albumTitle isEqualToString:@"Favorites"]) {
        
        _albumTitle = @"个人收藏";
        
    } else if ([_albumTitle isEqualToString:@"Recently Added"]) {
        
        _albumTitle = @"最近添加";
        
    } else if ([_albumTitle isEqualToString:@"Screenshots"]) {
        
        _albumTitle = @"屏幕快照";
        
    } else if ([_albumTitle isEqualToString:@"Camera Roll"]) {
        
        _albumTitle = @"相机胶卷";
        
    } else if ([_albumTitle isEqualToString:@"All Photos"]) {
        
        _albumTitle = @"所有照片";
    }
    
    NSLog(@" \n\n<----------------------------------\nlocalizedTitle == %@ \nlocalizedLocationNames == %@ \nlocalIdentifier == %@\n---------------------------------->\n ", _assetCollection.localizedTitle, _assetCollection.localizedLocationNames, _assetCollection.localIdentifier);
}
@end
