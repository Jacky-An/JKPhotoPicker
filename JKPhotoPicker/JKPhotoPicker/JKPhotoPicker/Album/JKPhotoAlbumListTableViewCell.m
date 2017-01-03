//
//  JKPhotoAlbumListTableViewCell.m
//  JKPhotoPicker
//
//  Created by albert on 2016/12/27.
//  Copyright © 2016年 安永博. All rights reserved.
//  相册cell

#import "JKPhotoAlbumListTableViewCell.h"
#import "JKPhotoItem.h"
#import <Photos/Photos.h>

@interface JKPhotoAlbumListTableViewCell ()
/** 缩略图 */
@property (nonatomic, weak) UIImageView *thumImageView;

/** 相册名称label */
@property (nonatomic, weak) UILabel *albumTitleLabel;

/** 相册中照片数量label */
@property (nonatomic, weak) UILabel *albumPhotoCountLabel;
@end

@implementation JKPhotoAlbumListTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self initialization];
    }
    return self;
}

- (void)initialization{
    
    UIImageView *thumImageView = [[UIImageView alloc] init];
    thumImageView.contentMode = UIViewContentModeScaleAspectFill;
    thumImageView.clipsToBounds = YES;
    [self.contentView addSubview:thumImageView];
    self.thumImageView = thumImageView;
    
    UILabel *albumTitleLabel = [[UILabel alloc] init];
    albumTitleLabel.font = [UIFont systemFontOfSize:16];
    albumTitleLabel.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.9];
    [self.contentView addSubview:albumTitleLabel];
    self.albumTitleLabel = albumTitleLabel;
    
    UILabel *albumPhotoCountLabel = [[UILabel alloc] init];
    albumPhotoCountLabel.font = [UIFont systemFontOfSize:13];
    albumPhotoCountLabel.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    [self.contentView addSubview:albumPhotoCountLabel];
    self.albumPhotoCountLabel = albumPhotoCountLabel;
}

- (void)setPhotoItem:(JKPhotoItem *)photoItem{
    _photoItem = photoItem;
    
    self.albumTitleLabel.text = _photoItem.albumTitle;
    
    self.albumPhotoCountLabel.text = @(_photoItem.albumImagesCount).stringValue;
    
    [[PHImageManager defaultManager] requestImageForAsset:_photoItem.albumThumAsset targetSize:CGSizeMake(200, 200) contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        self.thumImageView.image = result;
    }];
    
    // 这样会很卡，而且内存警告直接崩，还不清晰
//    self.thumImageView.image = _photoItem.albumThumImage;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.thumImageView.frame = CGRectMake(15, (self.bounds.size.height - 60) * 0.5, 60, 60);
    
    self.albumTitleLabel.frame = CGRectMake(CGRectGetMaxX(self.thumImageView.frame) + 15, 10, self.bounds.size.width - CGRectGetMaxX(self.imageView.frame) - 15 * 2, self.bounds.size.height * 0.5 - 10);
    
    self.albumPhotoCountLabel.frame = CGRectMake(self.albumTitleLabel.frame.origin.x, self.bounds.size.height * 0.5, self.bounds.size.width - CGRectGetMaxX(self.imageView.frame) - 15 * 2, self.bounds.size.height * 0.5 - 10);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setHighlighted:(BOOL)highlighted{
    [super setHighlighted:highlighted];
}
@end
