//
//  JKPhotoPickerViewController.m
//  JKPhotoPicker
//
//  Created by albert on 2016/12/21.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import "JKPhotoPickerViewController.h"
#import "JKPhotoSelectedCollectionViewCell.h"
#import "JKPhotoItem.h"
#import "JKPhotoManager.h"
#import "JKPhotoAlbumListView.h"
#import "JKPhotoTitleButton.h"
#import "JKPhotoBrowserViewController.h"
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>

#define JKScreenW [UIScreen mainScreen].bounds.size.width
#define JKScreenH [UIScreen mainScreen].bounds.size.height
#define JKScreenBounds [UIScreen mainScreen].bounds

@interface JKPhotoPickerViewController () <UICollectionViewDataSource, UICollectionViewDelegate, CAAnimationDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
/** collectionView */
@property (nonatomic, weak) UICollectionView *collectionView;

/** 底部的collectionView */
@property (nonatomic, weak) UICollectionView *bottomCollectionView;

/** 选中数量提示按钮 */
@property (nonatomic, weak) UIButton *selectedCountButton;

/** 相册列表view */
@property (nonatomic, weak) JKPhotoAlbumListView *albumListView;

/** titleButton */
@property (nonatomic, weak) JKPhotoTitleButton *titleButton;

/** 最多选择图片数量 默认3 */
@property (nonatomic, assign) NSUInteger maxSelectCount;

/** 监听点击完成的block */
@property (nonatomic, copy) void(^completeHandler)(NSArray *photoItems) ;

/** 所有的图片数组 */
@property (nonatomic, strong) NSMutableArray *allPhotos;

/** 选中的图片数组 */
@property (nonatomic, strong) NSMutableArray *selectedPhotos;
@end

@implementation JKPhotoPickerViewController

static NSString * const reuseID = @"JKPhotoCollectionViewCell"; // 重用ID
static NSString * const reuseIDSelected = @"JKPhotoSelectedCollectionViewCell"; // 选中的照片重用ID

#pragma mark - 类方法
+ (void)showWithPresentVc:(UIViewController *)presentVc maxSelectCount:(NSUInteger)maxSelectCount seletedPhotos:(NSArray <JKPhotoItem *> *)seletedPhotos isPenCameraFirst:(BOOL)isPenCameraFirst completeHandler:(void(^)(NSArray <JKPhotoItem *> *photoItems))completeHandler{
    
    [JKPhotoManager checkPhotoAccessFinished:^(BOOL isAccessed) {
        if (!isAccessed) {
            return;
        }
        
        JKPhotoPickerViewController *vc = [[self alloc] init];
        vc.maxSelectCount = maxSelectCount;
        vc.completeHandler = completeHandler;
        [vc.selectedPhotos removeAllObjects];
        [vc.selectedPhotos addObjectsFromArray:seletedPhotos];
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        
        if (presentVc && [presentVc isKindOfClass:[UIViewController class]]) {
            [presentVc presentViewController:nav animated:YES completion:^{
                if (isPenCameraFirst) {
                    [vc updateIconWithSourType:(UIImagePickerControllerSourceTypeCamera)];
                }
            }];
            return;
        }
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:nav animated:YES completion:^{
            if (isPenCameraFirst) {
                [vc updateIconWithSourType:(UIImagePickerControllerSourceTypeCamera)];
            }
        }];
    }];
}

+ (void)initialize{
    [[UIView appearance] setExclusiveTouch:YES];
}

#pragma mark - 懒加载
- (NSMutableArray *)allPhotos{
    if (!_allPhotos) {
        _allPhotos = [NSMutableArray array];
    }
    return _allPhotos;
}

- (NSMutableArray *)selectedPhotos{
    if (!_selectedPhotos) {
        _selectedPhotos = [NSMutableArray array];
    }
    return _selectedPhotos;
}

- (JKPhotoAlbumListView *)albumListView{
    if (!_albumListView) {
        JKPhotoAlbumListView *albumListView = [[JKPhotoAlbumListView alloc] init];
        albumListView.hidden = YES;
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            [self loadPhotoWithPhotoItem:albumListView.cameraRollItem];
        });
        
        __weak typeof(self) weakSelf = self;
#pragma mark - 选中相册
        [albumListView setSelectRowBlock:^(JKPhotoItem *photoItem) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.titleButton setTitle:[photoItem.albumTitle stringByAppendingString:@"  "] forState:(UIControlStateNormal)];
                weakSelf.titleButton.selected = NO;
            });
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                [weakSelf loadPhotoWithPhotoItem:photoItem];
                
            });
        }];
        
        [self.view addSubview:albumListView];
        
        _albumListView = albumListView;
    }
    return _albumListView;
}

#pragma mark - 初始化
- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (self.maxSelectCount <= 0) {
        self.maxSelectCount = 3;
    }
    
    [self setupNav];
    
    [self setupCollectionView];
    
    [self albumListView];
}

- (void)setupNav{
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:(UIBarButtonItemStylePlain) target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItems = @[leftItem];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:(UIBarButtonItemStylePlain) target:self action:@selector(done)];
    self.navigationItem.rightBarButtonItems = @[rightItem];
    
    JKPhotoTitleButton *titleButton = [JKPhotoTitleButton buttonWithType:(UIButtonTypeCustom)];
    titleButton.frame = CGRectMake(0, 0, 200, 40);
    [titleButton setTitleColor:[UIColor blackColor] forState:(UIControlStateNormal)];
    [titleButton setTitle:@"相机胶卷  " forState:(UIControlStateNormal)];
    [titleButton setImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"JKPhotoPickerResource.bundle/images/arrow_down@2x.png"]] forState:(UIControlStateNormal)];
    [titleButton setImage:[UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"JKPhotoPickerResource.bundle/images/arrow_up@2x.png"]] forState:(UIControlStateSelected)];
    
    [titleButton addTarget:self action:@selector(titleViewClick:) forControlEvents:(UIControlEventTouchUpInside)];
    
    self.navigationItem.titleView = titleButton;
    self.titleButton = titleButton;
}

- (void)titleViewClick:(UIButton *)button{
    
    __weak typeof(self) weakSelf = self;
    
    [self.albumListView executeAlbumListViewAnimationCompletion:^{
        weakSelf.titleButton.selected = !weakSelf.albumListView.hidden;
    }];
}

- (void)done{
    !self.completeHandler ? : self.completeHandler(self.selectedPhotos);
    [self dismiss];
}

- (void)dismiss{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setupCollectionView{
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake((JKScreenW - 3) / 4, (JKScreenW - 3) / 4);
    flowLayout.minimumLineSpacing = 1;
    flowLayout.minimumInteritemSpacing = 1;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 70 - (JKIsIphoneX ? JKBottomSafeAreaHeight : 0)) collectionViewLayout:flowLayout];
    collectionView.contentInset = UIEdgeInsetsMake(JKNavBarHeight, 0, 0, 0);
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.alwaysBounceVertical = YES;
    collectionView.dataSource = self;
    collectionView.delegate = self;
    [self.view insertSubview:collectionView atIndex:0];
    self.collectionView = collectionView;
    
    SEL selector = NSSelectorFromString(@"setContentInsetAdjustmentBehavior:");
    
    if ([collectionView respondsToSelector:selector]) {
        
        IMP imp = [collectionView methodForSelector:selector];
        void (*func)(id, SEL, NSInteger) = (void *)imp;
        func(collectionView, selector, 2);
        
        // [tbView performSelector:@selector(setContentInsetAdjustmentBehavior:) withObject:@(2)];
    }
    
    // 注册cell
    [collectionView registerClass:[JKPhotoCollectionViewCell class] forCellWithReuseIdentifier:reuseID];
    
    
    
    UIView *bottomContentView = [[UIView alloc] init];
    bottomContentView.frame = CGRectMake(0, CGRectGetMaxY(collectionView.frame), self.view.frame.size.width, 70 + (JKIsIphoneX ? JKBottomSafeAreaHeight : 0));
    bottomContentView.backgroundColor = [UIColor colorWithRed:250.0 / 255.0 green:250.0 / 255.0 blue:250.0 / 255.0 alpha:1];
    [self.view addSubview:bottomContentView];
    
    // 底部的collectionView
    UICollectionViewFlowLayout *flowLayout2 = [[UICollectionViewFlowLayout alloc] init];
    flowLayout2.itemSize = CGSizeMake(60, 70);
    flowLayout2.minimumLineSpacing = 1;
    flowLayout2.minimumInteritemSpacing = 1;
    flowLayout2.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    UICollectionView *bottomCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 70, 70) collectionViewLayout:flowLayout2];
    bottomCollectionView.backgroundColor = [UIColor clearColor];
    bottomCollectionView.alwaysBounceHorizontal = YES;
    bottomCollectionView.showsHorizontalScrollIndicator = NO;
    bottomCollectionView.dataSource = self;
    bottomCollectionView.delegate = self;
    bottomCollectionView.contentInset = UIEdgeInsetsMake(0, 5, 0, 0);
    [bottomContentView addSubview:bottomCollectionView];
    self.bottomCollectionView = bottomCollectionView;
    
    // 注册cell
    [bottomCollectionView registerClass:[JKPhotoSelectedCollectionViewCell class] forCellWithReuseIdentifier:reuseIDSelected];
    
    UIButton *selectedCountButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
    selectedCountButton.frame = CGRectMake(CGRectGetMaxX(bottomCollectionView.frame) + 10, 10, 50, 50);
    selectedCountButton.backgroundColor = [UIColor redColor];
    selectedCountButton.layer.cornerRadius = 25;
    selectedCountButton.layer.masksToBounds = YES;
    [selectedCountButton setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
    [bottomContentView addSubview:selectedCountButton];
    self.selectedCountButton = selectedCountButton;
    
    [selectedCountButton addTarget:self action:@selector(done) forControlEvents:(UIControlEventTouchUpInside)];
    
    [self changeSelectedCount];
}

#pragma mark - 加载数据
- (void)loadPhotoWithPhotoItem:(JKPhotoItem *)photoItem{
    
    NSMutableArray *photoItems = [JKPhotoManager getPhotoAssetsWithFetchResult:photoItem.albumFetchResult];
    
    if ([photoItems.firstObject isShowCameraIcon] == NO) {
        JKPhotoItem *item1 = [[JKPhotoItem alloc] init];
        item1.isShowCameraIcon = YES;
        [photoItems insertObject:item1 atIndex:0];
    }
    
    self.allPhotos = photoItems;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
        [self.collectionView setContentOffset:CGPointMake(0, -self.collectionView.contentInset.top) animated:YES];
        !self.albumListView.reloadCompleteBlock ? : self.albumListView.reloadCompleteBlock();
        self.albumListView.reloadCompleteBlock = nil;
    });
}

#pragma mark - collectionView数据源
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return (collectionView == self.bottomCollectionView) ? self.selectedPhotos.count : self.allPhotos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    JKPhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:(collectionView == self.bottomCollectionView) ? reuseIDSelected : reuseID forIndexPath:indexPath];
    
    JKPhotoItem *item = (collectionView == self.bottomCollectionView) ? self.selectedPhotos[indexPath.row] : self.allPhotos[indexPath.item];
    
    item.isSelected = NO;
    for (JKPhotoItem *it in self.selectedPhotos) {
        if (![it.assetLocalIdentifier isEqualToString:item.assetLocalIdentifier]) continue;
        
        item.isSelected = YES;
    }
    
    cell.photoItem = item;
    
    [self solveSelectBlockWithCell:cell];
    
    return cell;
}

- (void)solveSelectBlockWithCell:(JKPhotoCollectionViewCell *)cell{
    
    __weak typeof(self) weakSelf = self;
    
#pragma mark - 点击拍照
    if (!cell.cameraButtonClickBlock) {
        
        [cell setCameraButtonClickBlock:^{
            
            NSLog(@"点击拍照");
            
            [weakSelf updateIconWithSourType:(UIImagePickerControllerSourceTypeCamera)];
        }];
    }
    
#pragma mark - 照片选中
    
    if (!cell.selectBlock) {
        
        [cell setSelectBlock:^BOOL(BOOL selected, JKPhotoCollectionViewCell *currentCell) {
            
            if (selected) {
                
                currentCell.photoItem.isSelected = NO;
                
                NSIndexPath *indexPath = nil;
                
                for (JKPhotoItem *it in weakSelf.selectedPhotos) {
                    
                    if ([it.assetLocalIdentifier isEqualToString:currentCell.photoItem.assetLocalIdentifier]) {
                        
                        indexPath = [NSIndexPath indexPathForItem:[weakSelf.selectedPhotos indexOfObject:it] inSection:0];
                        
                        [weakSelf.selectedPhotos removeObject:it];
                        
                        break;
                    }
                }
                
                if (indexPath != nil) {
                    
                    [weakSelf.bottomCollectionView deleteItemsAtIndexPaths:@[indexPath]];
                }
                
//                [weakSelf.bottomCollectionView reloadData];
                
                [weakSelf changeSelectedCount];
                NSLog(@"取消选中,当前选中了%ld个", (unsigned long)weakSelf.selectedPhotos.count);
                
                return !selected;
            }
            
            if (weakSelf.selectedPhotos.count < weakSelf.maxSelectCount) {
                
                currentCell.photoItem.isSelected = YES;
                
                [weakSelf.selectedPhotos addObject:currentCell.photoItem];
                
                [weakSelf.bottomCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:weakSelf.selectedPhotos.count - 1 inSection:0]]];
//                [weakSelf.bottomCollectionView reloadData];
                
                [weakSelf.bottomCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:weakSelf.selectedPhotos.count - 1 inSection:0] atScrollPosition:(UICollectionViewScrollPositionCenteredHorizontally) animated:YES];
                
                [weakSelf changeSelectedCount];
                NSLog(@"选中了%ld个", (unsigned long)weakSelf.selectedPhotos.count);
                
                return !selected;
            }
            
            UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:[NSString stringWithFormat:@"最多选择%ld张图片哦~~", (unsigned long)weakSelf.maxSelectCount] preferredStyle:(UIAlertControllerStyleAlert)];
            
            [alertVc addAction:[UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:nil]];
            
            [weakSelf presentViewController:alertVc animated:YES completion:nil];
            
            return NO;
        }];
    }
    
#pragma mark - 删除选中的照片
    if (!cell.deleteButtonClickBlock) {
        
        [cell setDeleteButtonClickBlock:^(JKPhotoCollectionViewCell *currentCell) {
            
            currentCell.photoItem.isSelected = NO;
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[weakSelf.selectedPhotos indexOfObject:currentCell.photoItem] inSection:0];
            [weakSelf.selectedPhotos removeObject:currentCell.photoItem];
            
            [weakSelf.bottomCollectionView deleteItemsAtIndexPaths:@[indexPath]];
//            [weakSelf.bottomCollectionView reloadData];
            
            
            [weakSelf.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self.allPhotos indexOfObject:currentCell.photoItem] inSection:0]]];
            
            [weakSelf changeSelectedCount];
        }];
    }
}

- (void)changeSelectedCount{
    
    // 旋转动画
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
//    CAKeyframeAnimation *rotationAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.y"];
    rotationAnimation.toValue = @(M_PI * 2);
    rotationAnimation.repeatCount = 1;
    rotationAnimation.duration = 0.5;
    rotationAnimation.delegate = self;
    
    [self.selectedCountButton.layer addAnimation:rotationAnimation forKey:nil];
    
    [self.selectedCountButton setTitle:[NSString stringWithFormat:@"%ld/%ld", (unsigned long)self.selectedPhotos.count, (unsigned long)self.maxSelectCount] forState:(UIControlStateNormal)];
}

#pragma mark - CAAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    
}

#pragma mark - collectionView代理
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    NSLog(@"hehheehhehe");
    
    JKPhotoCollectionViewCell *cell = (JKPhotoCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"allPhotos"] = (collectionView == self.collectionView) ? self.allPhotos : nil;
    dict[@"selectedItems"] = self.selectedPhotos;
    dict[@"maxSelectCount"] = @(self.maxSelectCount);
    dict[@"imageView"] = cell.photoImageView;
    dict[@"collectionView"] = collectionView;
    dict[@"indexPath"] = (collectionView == self.collectionView) ? [NSIndexPath indexPathForItem:indexPath.item - 1 inSection:indexPath.section] : indexPath;
    dict[@"isSelectedCell"] = @([cell isMemberOfClass:[JKPhotoSelectedCollectionViewCell class]]);
    
    [JKPhotoBrowserViewController showWithViewController:self dataDict:dict completion:^(NSArray *seletedPhotos) {
        
        NSMutableArray *indexArr = [NSMutableArray array];
        
        for (JKPhotoItem *itm in self.selectedPhotos) {
            
            if (itm.isSelected) { continue; }
            
            [indexArr addObject:[NSIndexPath indexPathForItem:[self.allPhotos indexOfObject:itm] inSection:0]];
        }
        
        [self.selectedPhotos removeAllObjects];
        
        for (JKPhotoItem *itm in seletedPhotos) {
            
            [self.selectedPhotos addObject:itm];
            
            [indexArr addObject:[NSIndexPath indexPathForItem:[self.allPhotos indexOfObject:itm] inSection:0]];
        }
        
        [self.collectionView reloadItemsAtIndexPaths:indexArr];
        [self.bottomCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        
        [self.bottomCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedPhotos.count - 1 inSection:0] atScrollPosition:(UICollectionViewScrollPositionCenteredHorizontally) animated:YES];
        
        [self changeSelectedCount];
    }];
}

- (void)updateIconWithSourType:(UIImagePickerControllerSourceType)sourceType{
    
    
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (videoAuthStatus == AVAuthorizationStatusNotDetermined) {// 未询问用户是否授权
        
    }else if(videoAuthStatus == AVAuthorizationStatusRestricted || videoAuthStatus == AVAuthorizationStatusDenied) {// 未授权
        
    }else{// 已授权
        
    }
    
    if (videoAuthStatus == AVAuthorizationStatusDenied) {
        UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:@"当前程序未获得相机权限，是否打开？由于iOS系统原因，设置相机权限会导致app崩溃，请知晓。" preferredStyle:(UIAlertControllerStyleAlert)];
        
        [alertVc addAction:[UIAlertAction actionWithTitle:@"不用了" style:(UIAlertActionStyleDefault) handler:nil]];
        [alertVc addAction:[UIAlertAction actionWithTitle:@"去打开" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            // 打开本程序对应的权限设置
            [[UIApplication sharedApplication]openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }]];
        
        [self presentViewController:alertVc animated:YES completion:nil];
        
        return;
    }
    
//    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
//        
//        if (granted){// 用户同意授权
//            
//        }else {// 用户拒绝授权
//            
//        }
//        
//    }];
    
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        
        return;
    }
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = sourceType;
    
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

#pragma mark - <UIImagePickerControllerDelegate>
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Adds a photo to the saved photos album.  The optional completionSelector should have the form:
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (error) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    [self.albumListView setReloadCompleteBlock:^{
        
        if (weakSelf.selectedPhotos.count >= weakSelf.maxSelectCount) {
            return;
        }
        [weakSelf.selectedPhotos addObject:weakSelf.allPhotos[1]];
        [weakSelf.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:1 inSection:0]]];
        [weakSelf.bottomCollectionView reloadData];
        [weakSelf changeSelectedCount];
    }];
    
    [self.albumListView reloadAlbum];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    NSLog(@"%d, %s",__LINE__, __func__);
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
