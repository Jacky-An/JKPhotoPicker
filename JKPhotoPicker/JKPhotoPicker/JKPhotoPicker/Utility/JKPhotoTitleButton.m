//
//  JKPhotoTitleButton.m
//  JKPhotoPicker
//
//  Created by albert on 2016/12/27.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import "JKPhotoTitleButton.h"

@implementation JKPhotoTitleButton

//可以通过下面这两个方法实现按钮图片和文字的排布位置
//    override func titleRectForContentRect(contentRect: CGRect) -> CGRect {
//
//    }
//
//    override func imageRectForContentRect(contentRect: CGRect) -> CGRect {
//
//    }

- (void)layoutSubviews{
    [super layoutSubviews];
    
    self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x - self.imageView.frame.size.width, self.titleLabel.frame.origin.y, self.titleLabel.frame.size.width, self.titleLabel.frame.size.height);
    
    self.imageView.frame = CGRectMake(CGRectGetMaxX(self.titleLabel.frame), self.imageView.frame.origin.y, self.imageView.frame.size.width, self.imageView.frame.size.height);
}

- (void)setHighlighted:(BOOL)highlighted{
    [super setHighlighted:highlighted];
    
    self.alpha = highlighted ? 0.5 : 1.0;
}
@end
