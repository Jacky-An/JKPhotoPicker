//
//  JKPhotom
//  JKPhotoPicker
//
//  Created by albert on 2016/12/27.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import "JKPhotoAlbumListView.h"
#import "JKPhotoAlbumListTableViewCell.h"
#import "JKPhotoManager.h"
#import "JKPhotoItem.h"

@interface JKPhotoAlbumListView () <UITableViewDataSource, UITableViewDelegate>
/** tableView */
@property (nonatomic, weak) UITableView *tableView;

/** contentView */
@property (nonatomic, weak) UIView *contentView;

/** 导航条上加的按钮 */
@property (nonatomic, weak) UIButton *navBgButton;

/** 整个背景按钮 */
@property (nonatomic, weak) UIButton *bgButton;

/** 相册列表view是否正在执行动画 */
@property (nonatomic, assign) BOOL isAnimating;

/** 相册数组 */
@property (nonatomic, strong) NSMutableArray *albums;

/** 监听动画完成 */
@property (nonatomic, copy) void(^completion)(void);

/** 当前选中的索引 */
@property (nonatomic, strong) NSIndexPath *currentSelectedIndex;
@end

static NSString * const reuseID = @"JKPhotoAlbumListTableViewCell";
static CGFloat const rowHeight = 70;

@implementation JKPhotoAlbumListView

#pragma mark - 懒加载
- (NSMutableArray *)albums{
    if (!_albums) {
        _albums = [NSMutableArray array];
    }
    return _albums;
}

- (UIView *)contentView{
    if (!_contentView) {
        UIView *contentView = [[UIView alloc] init];
        contentView.backgroundColor = [UIColor colorWithRed:239.0 / 255.0 green:239.0 / 255.0 blue:239.0 / 255.0 alpha:1];
        [self addSubview:contentView];
        _contentView = contentView;
    }
    return _contentView;
}

- (UITableView *)tableView{
    if (!_tableView) {
        
        UITableView *tableView = [[UITableView alloc] init];
        [self.contentView addSubview:tableView];
        _tableView = tableView;
        
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.alwaysBounceVertical = YES;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.backgroundColor = nil;
        
        tableView.rowHeight = rowHeight;
        tableView.sectionFooterHeight = 0;
        tableView.sectionHeaderHeight = 0;
        
        tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, CGFLOAT_MIN)];
        tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, CGFLOAT_MIN)];
        
        SEL selector = NSSelectorFromString(@"setContentInsetAdjustmentBehavior:");
        
        if ([tableView respondsToSelector:selector]) {
            
            IMP imp = [tableView methodForSelector:selector];
            void (*func)(id, SEL, NSInteger) = (void *)imp;
            func(tableView, selector, 2);
            
            // [tbView performSelector:@selector(setContentInsetAdjustmentBehavior:) withObject:@(2)];
        }
        
        // 注册cell
        [tableView registerClass:[JKPhotoAlbumListTableViewCell class] forCellReuseIdentifier:reuseID];
    }
    return _tableView;
}

#pragma mark - 初始化
- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        [self initialization];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self initialization];
    }
    return self;
}

- (void)setFrame:(CGRect)frame{
    
    frame = [UIScreen mainScreen].bounds;
    [super setFrame:frame];
}

- (void)initialization{
    self.backgroundColor = [UIColor clearColor];
    
    UIButton *bgButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [self insertSubview:bgButton atIndex:0];
    self.bgButton = bgButton;
    
    [bgButton addTarget:self action:@selector(executeAnimation) forControlEvents:(UIControlEventTouchUpInside)];
    
    // bgButton约束
    bgButton.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *bgButtonCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[bgButton]-0-|" options:0 metrics:nil views:@{@"bgButton" : bgButton}];
    [self addConstraints:bgButtonCons1];
    
    NSArray *bgButtonCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[bgButton]-0-|" options:0 metrics:nil views:@{@"bgButton" : bgButton}];
    [self addConstraints:bgButtonCons2];
    
    [self tableView];
    [self loadData];
    
    UIButton *navBgButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    navBgButton.hidden = YES;
    navBgButton.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, JKPhotoCurrentNavigationBarHeight);
    [[UIApplication sharedApplication].delegate.window addSubview:navBgButton];
    self.navBgButton = navBgButton;
    
    [navBgButton addTarget:self action:@selector(executeAnimation) forControlEvents:(UIControlEventTouchUpInside)];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidTakeScreenshot) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

//- (void)userDidTakeScreenshot{
//    
//    [self performSelector:@selector(reloadAlbum) withObject:nil afterDelay:0.8];
//}

//- (void)applicationDidBecomeActive{
//    [self reloadAlbum];
//}

- (void)reloadAlbum{
    
    [self loadAlbumData];
    
    !self.selectRowBlock ? : self.selectRowBlock(self.albums[self.currentSelectedIndex.row], YES);
    
    [self.tableView selectRowAtIndexPath:self.currentSelectedIndex animated:NO scrollPosition:UITableViewScrollPositionNone];
}

- (void)executeAnimation{
    
    [self executeAlbumListViewAnimationCompletion:self.completion];
}

- (void)executeAlbumListViewAnimationCompletion:(void(^)(void))completion{
    if (self.isAnimating) return;
    
    self.completion = completion;
    
    self.isAnimating = YES;
    
    if (self.hidden) { // 显示动画
        
        self.contentView.frame = CGRectMake(0, -[UIScreen mainScreen].bounds.size.height * 0.5 - 15, self.frame.size.width, self.contentView.frame.size.height);
        self.hidden = NO;
        self.navBgButton.hidden = NO;
        !self.completion ? : self.completion();
        
        [UIView animateWithDuration:0.25 animations:^{
            
            self.contentView.frame = CGRectMake(0, 15, self.frame.size.width, self.contentView.frame.size.height);
            self.bgButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
            
        } completion:^(BOOL finished) {
            
            [UIView animateWithDuration:0.25 animations:^{
                
                self.contentView.frame = CGRectMake(0, 0, self.frame.size.width, self.contentView.frame.size.height);
                
            } completion:^(BOOL finished) {
                
                self.isAnimating = NO;
            }];
        }];
        return;
    }
    
    // 隐藏动画
    [UIView animateWithDuration:0.25 animations:^{
        
        self.contentView.frame = CGRectMake(self.frame.origin.x, 15, self.frame.size.width, self.contentView.frame.size.height);
        
        self.bgButton.backgroundColor = [UIColor clearColor];
        
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.25 animations:^{
            
            self.contentView.frame = CGRectMake(self.frame.origin.x, -[UIScreen mainScreen].bounds.size.height * 0.5 - 15, self.frame.size.width, self.contentView.frame.size.height);
            
        } completion:^(BOOL finished) {
            
            self.hidden = YES;
            
            self.isAnimating = NO;
            self.navBgButton.hidden = YES;
            !self.completion ? : self.completion();
        }];
    }];
}

- (void)loadData{
    
    [self loadAlbumData];
    
    // 默认选中第一个
    self.currentSelectedIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    
    [self.tableView selectRowAtIndexPath:self.currentSelectedIndex animated:NO scrollPosition:(UITableViewScrollPositionNone)];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    CGFloat Y = self.hidden ? -[UIScreen mainScreen].bounds.size.height * 0.5 - 15 : 0;
    
    self.contentView.frame = CGRectMake(0, Y, self.frame.size.width, (rowHeight * self.albums.count + JKPhotoCurrentNavigationBarHeight > [UIScreen mainScreen].bounds.size.height * 0.5) ? [UIScreen mainScreen].bounds.size.height * 0.5 : rowHeight * self.albums.count + JKPhotoCurrentNavigationBarHeight);
    
    self.tableView.frame = CGRectMake(0, JKPhotoCurrentNavigationBarHeight, self.contentView.frame.size.width, self.contentView.frame.size.height - JKPhotoCurrentNavigationBarHeight);
}

- (void)loadAlbumData{
    
    NSMutableArray *arr = [JKPhotoManager getAlbumList];
    
    [self.albums removeAllObjects];
    
    NSInteger index = 0;
    
    for (PHAssetCollection *assetCollection in arr) {
        
        PHFetchResult *result = [JKPhotoManager getFetchResultWithAssetCollection:assetCollection];
        
        if (index > 0 && result.count <= 0) continue;
        
        JKPhotoItem *item = [[JKPhotoItem alloc] init];
        item.albumAssetCollection = assetCollection;
        item.albumFetchResult = result;
        item.albumImagesCount = result.count;
        item.albumThumAsset = result.lastObject;
        [self.albums addObject:item];
        
        index++;
    }
    
    _cameraRollItem = self.albums.firstObject;
    [self.tableView reloadData];
}

#pragma mark - tableView数据源
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.albums.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    JKPhotoAlbumListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseID];
    
    cell.photoItem = self.albums[indexPath.row];
    
    return cell;
}

#pragma mark - tableView代理
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    __weak typeof(self) weakSelf = self;
    
    [self executeAlbumListViewAnimationCompletion:^{
        if ((weakSelf.currentSelectedIndex.section == indexPath.section) && (weakSelf.currentSelectedIndex.row == indexPath.row)) return;
        
        weakSelf.currentSelectedIndex = indexPath;
        
        JKPhotoItem *item = weakSelf.albums[indexPath.row];
        
        !weakSelf.selectRowBlock ? : weakSelf.selectRowBlock(item, NO);
    }];
}

- (void)dealloc{
    [self.navBgButton removeFromSuperview];
    self.navBgButton = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSLog(@"%d, %s",__LINE__, __func__);
}
@end
