//
//  JKTestViewController.m
//  JKPhotoPicker
//
//  Created by albert on 2016/12/29.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import "JKTestViewController.h"

#import "JKPhotoPicker.h"

@interface JKTestViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
/** 已选择的照片容器view */
@property (nonatomic, weak) JKPhotoSelectCompleteView *selectCompleteView;
@property (weak, nonatomic) IBOutlet UIScrollView *uploadScrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicatorView;
@property (weak, nonatomic) UIImageView *imageView;
@end

@implementation JKTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.selectCompleteView = [JKPhotoSelectCompleteView completeViewWithSuperView:self.view viewController:self frame:CGRectMake(0, (JKPhotoPickerIsIphoneX ? 88 : 64), self.view.frame.size.width, 130) itemSize:CGSizeMake((self.view.frame.size.width - 3) / 4, (self.view.frame.size.width - 3) / 4 + 10) scrollDirection:UICollectionViewScrollDirectionHorizontal];
    
    self.selectCompleteView.backgroundColor = [UIColor cyanColor];
}

- (IBAction)photoAction:(UIButton *)sender {
    
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:(UIAlertControllerStyleActionSheet)];
    
    [alertVc addAction:[UIAlertAction actionWithTitle:@"拍照" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        
//        [self updateIconWithSourType:(UIImagePickerControllerSourceTypeCamera)];
        [JKPhotoPickerViewController showWithPresentVc:self maxSelectCount:7 seletedItems:self.selectCompleteView.photoItems shouldPreview:NO shouldSelectAll:YES dataType:JKPhotoPickerMediaDataTypeImageIncludeGif completeHandler:^(NSArray <JKPhotoItem *> *photoItems, NSArray<PHAsset *> *selectedAssetArray) {
            [self.imageView removeFromSuperview];
            self.imageView = nil;
            self.selectCompleteView.photoItems = photoItems;
            self.selectCompleteView.assets = selectedAssetArray;
        }];
    }]];
    
    [alertVc addAction:[UIAlertAction actionWithTitle:@"从相册选择" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        [JKPhotoPickerViewController showWithPresentVc:self maxSelectCount:0 seletedItems:self.selectCompleteView.photoItems shouldPreview:NO shouldSelectAll:YES dataType:JKPhotoPickerMediaDataTypeAll completeHandler:^(NSArray <JKPhotoItem *> *photoItems, NSArray<PHAsset *> *selectedAssetArray) {
            [self.imageView removeFromSuperview];
            self.imageView = nil;
            self.selectCompleteView.photoItems = photoItems;
            self.selectCompleteView.assets = selectedAssetArray;
        }];
    }]];
    
    [alertVc addAction:[UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:nil]];
    
    [self presentViewController:alertVc animated:YES completion:nil];
}

- (void)updateIconWithSourType:(UIImagePickerControllerSourceType)sourceType{
    
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) return;
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = sourceType;
    imagePicker.allowsEditing = YES;
    
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

#pragma mark - <UIImagePickerControllerDelegate>
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
    UIImage *image = info[UIImagePickerControllerEditedImage];
    
    [self.imageView removeFromSuperview];
    self.imageView = nil;
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake(0, 0, self.selectCompleteView.frame.size.height, self.selectCompleteView.frame.size.height);
    [self.selectCompleteView addSubview:imageView];
    self.imageView = imageView;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)uploadClick:(UIButton *)sender {
    
    sender.selected = !sender.selected;
    
    if (!sender.selected) {
        
        [self.uploadScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        return;
    }
    
    if (self.selectCompleteView.photoItems.count <= 0) { return; }
    
    [self.indicatorView startAnimating];
    
#pragma mark - 获取原图
    
    [JKPhotoSelectCompleteView getOriginalImagesWithItems:self.selectCompleteView.photoItems complete:^(NSArray<UIImage *> *originalImages) {
       
        [self uploadImages:originalImages];
    }];
}

- (void)uploadImages:(NSArray<UIImage *> *)images{
    
    NSInteger count = images.count;
    
    self.uploadScrollView.contentSize = CGSizeMake(10 + (self.view.frame.size.width / 4 + 10) * count, 0);
    self.uploadScrollView.showsHorizontalScrollIndicator = NO;
    
    for (NSInteger i = 0; i < count; i++) {
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        
        imageView.frame = CGRectMake(5 + (self.view.frame.size.width / 4 + 10) * i, (self.uploadScrollView.frame.size.height - (self.view.frame.size.width * 0.25)) * 0.5, (self.view.frame.size.width - 3) / 4, (self.view.frame.size.width * 0.25));
        
        imageView.image = images[i];
        [self.uploadScrollView addSubview:imageView];
        
        if (i == count - 1) {
            
            [self.indicatorView stopAnimating];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    NSLog(@"%d, %s",__LINE__, __func__);
}
@end
