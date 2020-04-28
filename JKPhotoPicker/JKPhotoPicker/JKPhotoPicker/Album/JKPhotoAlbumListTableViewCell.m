//
//  JKPhotoAlbumListTableViewCell.m
//  JKPhotoPicker
//
//  Created by albert on 2016/12/27.
//  Copyright © 2016年 安永博. All rights reserved.
//  相册cell

#import "JKPhotoAlbumListTableViewCell.h"
#import "JKPhotoAlbumItem.h"
#import "JKPhotoConst.h"
#import <Photos/Photos.h>

@interface JKPhotoAlbumListTableViewCell ()

/** 缩略图 */
@property (nonatomic, weak) UIImageView *thumImageView;

/** 相册名称label */
@property (nonatomic, weak) UILabel *albumTitleLabel;

/** 相册中照片数量label */
@property (nonatomic, weak) UILabel *albumPhotoCountLabel;

/** requestID */
@property (nonatomic, assign) PHImageRequestID thumbImageRequestID;
@end

@implementation JKPhotoAlbumListTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

#pragma mark
#pragma mark - 初始化

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        [self initialization];
    }
    return self;
}

/** 初始化自身属性 交给子类重写 super自动调用该方法 */
- (void)initializeProperty{
    
}

/** 构造函数初始化时调用 注意调用super */
- (void)initialization{
    
    [self initializeProperty];
    [self createUI];
    [self layoutUI];
    [self initializeUIData];
}

/** 创建UI 交给子类重写 super自动调用该方法 */
- (void)createUI{
    
    UIImageView *thumImageView = [[UIImageView alloc] init];
    thumImageView.layer.cornerRadius = 5;
    thumImageView.contentMode = UIViewContentModeScaleAspectFill;
    thumImageView.clipsToBounds = YES;
    [self.contentView addSubview:thumImageView];
    _thumImageView = thumImageView;
    
    UILabel *albumTitleLabel = [[UILabel alloc] init];
    albumTitleLabel.font = [UIFont systemFontOfSize:16];
    albumTitleLabel.textColor = JKPhotoAdaptColor([UIColor blackColor], [UIColor whiteColor]);
    [self.contentView addSubview:albumTitleLabel];
    _albumTitleLabel = albumTitleLabel;
    
    UILabel *albumPhotoCountLabel = [[UILabel alloc] init];
    albumPhotoCountLabel.font = [UIFont systemFontOfSize:13];
    albumPhotoCountLabel.textColor = JKPhotoAdaptColor([[UIColor blackColor] colorWithAlphaComponent:0.6], [[UIColor whiteColor] colorWithAlphaComponent:0.6]);
    [self.contentView addSubview:albumPhotoCountLabel];
    _albumPhotoCountLabel = albumPhotoCountLabel;
}

/** 布局UI 交给子类重写 super自动调用该方法 */
- (void)layoutUI{
    
}

/** 初始化UI数据 交给子类重写 super自动调用该方法 */
- (void)initializeUIData{
    
}

#pragma mark
#pragma mark - Override

- (void)layoutSubviews{
    [super layoutSubviews];
    
    self.thumImageView.frame = CGRectMake(15, (self.bounds.size.height - 50) * 0.5, 50, 50);
    
    self.albumTitleLabel.frame = CGRectMake(CGRectGetMaxX(self.thumImageView.frame) + 15, 10, self.bounds.size.width - CGRectGetMaxX(self.imageView.frame) - 15 * 2, self.bounds.size.height * 0.5 - 10);
    
    self.albumPhotoCountLabel.frame = CGRectMake(self.albumTitleLabel.frame.origin.x, self.bounds.size.height * 0.5, self.bounds.size.width - CGRectGetMaxX(self.imageView.frame) - 15 * 2, self.bounds.size.height * 0.5 - 10);
}


#pragma mark
#pragma mark - 点击事件


#pragma mark
#pragma mark - 赋值

- (void)setAlbumItem:(JKPhotoAlbumItem *)albumItem{
    _albumItem = albumItem;
    
    self.albumTitleLabel.text = _albumItem.albumTitle;
    
    self.albumPhotoCountLabel.text = @(_albumItem.imagesCount).stringValue;
    
    if (!_albumItem.thumbAsset) {
        
        self.thumImageView.image = nil;
        
        self.thumImageView.backgroundColor = JKPhotoAdaptColor([UIColor blackColor], [UIColor whiteColor]);
        
        return;
    }
    
    self.thumImageView.backgroundColor = nil;
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    
    self.thumbImageRequestID = [[PHImageManager defaultManager] requestImageForAsset:_albumItem.thumbAsset targetSize:JKPhotoThumbSize() contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        
        PHImageRequestID ID = [[info objectForKey:PHImageResultRequestIDKey] intValue];
        
        if (ID != self.thumbImageRequestID) { return; }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.thumImageView.image = result;
        });
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
}

- (void)setHighlighted:(BOOL)highlighted{
    [super setHighlighted:highlighted];
    
}


#pragma mark
#pragma mark - Property




@end
