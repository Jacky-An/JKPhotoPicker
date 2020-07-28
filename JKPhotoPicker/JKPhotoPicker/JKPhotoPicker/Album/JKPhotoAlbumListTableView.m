//
//  JKPhotom
//  JKPhotoPicker
//
//  Created by albert on 2016/12/27.
//  Copyright © 2016年 安永博. All rights reserved.
//

#import "JKPhotoAlbumListTableView.h"
#import "JKPhotoAlbumListTableViewCell.h"
#import "JKPhotoPickerEngine.h"
#import "JKPhotoAlbumItem.h"
#import "JKPhotoUtility.h"

@interface JKPhotoAlbumListTableView () <UITableViewDataSource, UITableViewDelegate>

/** tableView */
@property (nonatomic, weak) UITableView *tableView;

/** contentView */
@property (nonatomic, weak) UIView *contentView;

/** 整个背景按钮 */
@property (nonatomic, weak) UIButton *dismissButton;

/** 相册列表view是否正在执行动画 */
@property (nonatomic, assign) BOOL isAnimating;

/** 相册数组 */
@property (nonatomic, strong) NSMutableArray *albumListArray;

/** 当前选中的索引 */
@property (nonatomic, strong) NSIndexPath *currentSelectedIndex;

/** albumCache */
@property (nonatomic, strong) NSCache *albumCache;
@end

static NSString * const JKPhotoAlbumListTableViewCellReuseID = @"JKPhotoAlbumListTableViewCell";
static CGFloat const JKPhotoAlbumListTableViewRowHeight = 60;

@implementation JKPhotoAlbumListTableView

#pragma mark
#pragma mark - Public Methods

/// 展示动画
- (void)executeShowAlbumListAnimation {
    
    if (self.isAnimating) return;
    
    self.isAnimating = YES;
    
    if (self.hidden) { // 显示动画
        
        self.contentView.frame = CGRectMake(0, -[UIScreen mainScreen].bounds.size.height * 0.5 - 15, self.frame.size.width, self.contentView.frame.size.height);
        
        self.hidden = NO;
        
        !self.albumListDidShowHandler ? : self.albumListDidShowHandler();
        
        [UIView animateWithDuration:0.25 animations:^{
            
            self.contentView.frame = CGRectMake(0, 15, self.frame.size.width, self.contentView.frame.size.height);
             
            self.backgroundView.backgroundColor = JKPhotoAdaptColor([[UIColor blackColor] colorWithAlphaComponent:0.4], [[UIColor whiteColor] colorWithAlphaComponent:0.3]);
            
        } completion:^(BOOL finished) {
            
            [UIView animateWithDuration:0.25 animations:^{
                
                self.contentView.frame = CGRectMake(0, 0, self.frame.size.width, self.contentView.frame.size.height);
                
            } completion:^(BOOL finished) {
                
                self.isAnimating = NO;
            }];
        }];
        
        return;
    }
}

/// 隐藏动画
- (void)executeDismissAlbumListAnimation {
    
    if (self.isAnimating) return;
    
    self.isAnimating = YES;
    
    // 隐藏动画
    [UIView animateWithDuration:0.25 animations:^{
        
        self.contentView.frame = CGRectMake(self.frame.origin.x, 15, self.frame.size.width, self.contentView.frame.size.height);
        
    } completion:^(BOOL finished) {
        
        !self.albumListDidDismissHandler ? : self.albumListDidDismissHandler();
        
        [UIView animateWithDuration:0.25 animations:^{
            
            self.contentView.frame = CGRectMake(self.frame.origin.x, -[UIScreen mainScreen].bounds.size.height * 0.5 - 15, self.frame.size.width, self.contentView.frame.size.height);
            
            self.backgroundView.backgroundColor = JKPhotoAdaptColor([[UIColor blackColor] colorWithAlphaComponent:0], [[UIColor whiteColor] colorWithAlphaComponent:0]);
            
        } completion:^(BOOL finished) {
            
            self.hidden = YES;
            
            self.isAnimating = NO;
        }];
    }];
}

#pragma mark
#pragma mark - Override

- (void)dealloc {
    
    NSLog(@"[ClassName: %@], %d, %s", NSStringFromClass([self class]), __LINE__, __func__);
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialization];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialization];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    
    frame = [UIScreen mainScreen].bounds;
    
    [super setFrame:frame];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat Y = self.hidden ? -[UIScreen mainScreen].bounds.size.height * 0.5 - 15 : 0;
    
    self.contentView.frame = CGRectMake(0, Y, self.frame.size.width, (JKPhotoAlbumListTableViewRowHeight * self.albumListArray.count + JKPhotoUtility.navigationBarHeight > [UIScreen mainScreen].bounds.size.height * 0.5) ? [UIScreen mainScreen].bounds.size.height * 0.5 : JKPhotoAlbumListTableViewRowHeight * self.albumListArray.count + JKPhotoUtility.navigationBarHeight);
    
    self.tableView.frame = CGRectMake(0, JKPhotoUtility.navigationBarHeight, self.contentView.frame.size.width, self.contentView.frame.size.height - JKPhotoUtility.navigationBarHeight);
}

#pragma mark
#pragma mark - Private Methods

- (void)reloadAlbumList {
    
    [self loadAlbumListData];
}

- (void)loadAlbumListData {
    
    [JKPhotoPickerEngine fetchAllAlbumItemIncludeHiddenAlbum:NO complete:^(NSArray<PHAssetCollection *> * _Nonnull albumCollectionList, NSArray<JKPhotoAlbumItem *> * _Nonnull albumItemList, NSCache * _Nonnull albumItemCache) {
        
        [self.albumListArray removeAllObjects];
        [self.albumListArray addObjectsFromArray:albumItemList];
        
        [self setNeedsLayout];
        
        self.albumCache = albumItemCache;
        
        self->_cameraRollAlbumItem = self.albumListArray.firstObject;
        
        if (!self.currentAlbumItem.localIdentifier) {
            
            !self.didselectAlbumHandler ? : self.didselectAlbumHandler(self.cameraRollAlbumItem, NO);
            
            // 默认选中第一个
            self.currentSelectedIndex = [NSIndexPath indexPathForRow:0 inSection:0];
            
            [self.tableView reloadData];
            
            [self.tableView selectRowAtIndexPath:self.currentSelectedIndex animated:NO scrollPosition:UITableViewScrollPositionNone];
            
            return;
        }
        
        JKPhotoAlbumItem *currentAlbumItem = [self.albumCache objectForKey:self.currentAlbumItem.localIdentifier];
        
        NSInteger index = 0;
        
        if (currentAlbumItem) {
            
            if ([self.albumListArray containsObject:currentAlbumItem]) {
                
                index = [self.albumListArray indexOfObject:currentAlbumItem];
            }
            
            self.currentSelectedIndex = [NSIndexPath indexPathForRow:index inSection:0];
            
            self->_currentAlbumItem = currentAlbumItem;
            
        } else { // 当前浏览的相册已被删除
            
            self.currentSelectedIndex = [NSIndexPath indexPathForRow:index inSection:0];
            
            self->_currentAlbumItem = self.cameraRollAlbumItem;
            
            !self.didselectAlbumHandler ? : self.didselectAlbumHandler(self.currentAlbumItem, YES);
        }
        
        [self.tableView reloadData];
        
        [self.tableView selectRowAtIndexPath:self.currentSelectedIndex animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }];
}

#pragma mark
#pragma mark - Private Selector

- (void)dismissButtonClick:(UIButton *)button {
    
    [self executeDismissAlbumListAnimation];
}

#pragma mark
#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.albumListArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    JKPhotoAlbumListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:JKPhotoAlbumListTableViewCellReuseID];
    
    JKPhotoAlbumItem *albumItem = nil;
    
    if (self.albumListArray.count > indexPath.row) {
        
        albumItem = self.albumListArray[indexPath.row];
    }
    
    cell.albumItem = albumItem;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self executeDismissAlbumListAnimation];
    
    if ((self.currentSelectedIndex.section == indexPath.section) &&
        (self.currentSelectedIndex.row == indexPath.row)) { return; }
    
    self.currentSelectedIndex = indexPath;
    
    self->_currentAlbumItem = self.albumListArray[indexPath.row];
    
    !self.didselectAlbumHandler ? : self.didselectAlbumHandler(self.currentAlbumItem, NO);
}

#pragma mark
#pragma mark - Initialization & Build UI

/** 初始化自身属性 交给子类重写 super自动调用该方法 */
- (void)initializeProperty {
    
}

/** 构造函数初始化时调用 注意调用super */
- (void)initialization {
    
    [self initializeProperty];
    [self createUI];
    [self layoutUI];
    [self initializeUIData];
    
    [self loadAlbumListData];
}

/** 创建UI 交给子类重写 super自动调用该方法 */
- (void)createUI {
    
    UIView *backgroundView = [[UIView alloc] init];
    [self addSubview:backgroundView];
    _backgroundView = backgroundView;
    
    UIButton *dismissButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [self addSubview:dismissButton];
    _dismissButton = dismissButton;
    
    [dismissButton addTarget:self action:@selector(dismissButtonClick:) forControlEvents:(UIControlEventTouchUpInside)];
    
    UIView *contentView = [[UIView alloc] init];
    contentView.backgroundColor = JKPhotoAdaptColor([UIColor colorWithRed:239.0 / 255.0 green:239.0 / 255.0 blue:239.0 / 255.0 alpha:1], [UIColor colorWithRed:16.0 / 255.0 green:16.0 / 255.0 blue:16.0 / 255.0 alpha:1]);
    [self addSubview:contentView];
    _contentView = contentView;
    
    [self tableView];
}

/** 布局UI 交给子类重写 super自动调用该方法 */
- (void)layoutUI {
    
    // dismissButton约束
    self.backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *cons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[view]-0-|" options:0 metrics:nil views:@{@"view" : self.backgroundView}];
    [self addConstraints:cons1];
    
    NSArray *cons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]-0-|" options:0 metrics:nil views:@{@"view" : self.backgroundView}];
    [self addConstraints:cons2];
    
    // dismissButton约束
    self.dismissButton.translatesAutoresizingMaskIntoConstraints = NO;
    cons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[view]-0-|" options:0 metrics:nil views:@{@"view" : self.dismissButton}];
    [self addConstraints:cons1];
    
    cons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]-0-|" options:0 metrics:nil views:@{@"view" : self.dismissButton}];
    [self addConstraints:cons2];
}

/** 初始化UI数据 交给子类重写 super自动调用该方法 */
- (void)initializeUIData {
    
    self.backgroundColor = nil;
    
    self.backgroundView.backgroundColor = JKPhotoAdaptColor([[UIColor blackColor] colorWithAlphaComponent:0], [[UIColor whiteColor] colorWithAlphaComponent:0]);
}

#pragma mark
#pragma mark - Private Property

- (NSMutableArray *)albumListArray {
    if (!_albumListArray) {
        _albumListArray = [NSMutableArray array];
    }
    return _albumListArray;
}

- (UITableView *)tableView {
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:(UITableViewStylePlain)];
        [self.contentView addSubview:tableView];
        _tableView = tableView;
        
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.alwaysBounceVertical = YES;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.backgroundColor = nil;
        
        tableView.rowHeight = JKPhotoAlbumListTableViewRowHeight;
        tableView.sectionFooterHeight = 0;
        tableView.sectionHeaderHeight = 0;
        
        tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, CGFLOAT_MIN)];
        tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, CGFLOAT_MIN)];
        
        if (@available(iOS 11.0, *)) {
            
            tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        if (@available(iOS 13.0, *)) {
            
            tableView.automaticallyAdjustsScrollIndicatorInsets = NO;
        }
        
        // 注册cell
        [tableView registerClass:[JKPhotoAlbumListTableViewCell class] forCellReuseIdentifier:JKPhotoAlbumListTableViewCellReuseID];
    }
    return _tableView;
}
@end
