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
#import "JKPhotoConst.h"

@interface JKPhotoAlbumListTableView () <UITableViewDataSource, UITableViewDelegate>

/** tableView */
@property (nonatomic, weak) UITableView *tableView;

/** contentView */
@property (nonatomic, weak) UIView *contentView;

/** 整个背景按钮 */
@property (nonatomic, weak) UIButton *backgroundButton;

/** 相册列表view是否正在执行动画 */
@property (nonatomic, assign) BOOL isAnimating;

/** 相册数组 */
@property (nonatomic, strong) NSMutableArray *albumListArray;

/** 监听动画完成 */
@property (nonatomic, copy) void(^completion)(void);

/** 当前选中的索引 */
@property (nonatomic, strong) NSIndexPath *currentSelectedIndex;

/** albumCache */
@property (nonatomic, strong) NSCache *albumCache;
@end

static NSString * const JKPhotoAlbumListTableViewCellReuseID = @"JKPhotoAlbumListTableViewCell";
static CGFloat const JKPhotoAlbumListTableViewRowHeight = 60;

@implementation JKPhotoAlbumListTableView

#pragma mark
#pragma mark - 生命周期

- (void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSLog(@"[ClassName: %@], %d, %s", NSStringFromClass([self class]), __LINE__, __func__);
}

#pragma mark
#pragma mark - 初始化

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self initialization];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
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
    
    UIButton *backgroundButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [self insertSubview:backgroundButton atIndex:0];
    _backgroundButton = backgroundButton;
    
    [backgroundButton addTarget:self action:@selector(executeAnimation) forControlEvents:(UIControlEventTouchUpInside)];
    
    // backgroundButton约束
    backgroundButton.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *backgroundButtonCons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[backgroundButton]-0-|" options:0 metrics:nil views:@{@"backgroundButton" : backgroundButton}];
    [self addConstraints:backgroundButtonCons1];
    
    NSArray *backgroundButtonCons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[backgroundButton]-0-|" options:0 metrics:nil views:@{@"backgroundButton" : backgroundButton}];
    [self addConstraints:backgroundButtonCons2];
    
    [self tableView];
    
    [self loadData];
}

/** 布局UI 交给子类重写 super自动调用该方法 */
- (void)layoutUI{
    
}

/** 初始化UI数据 交给子类重写 super自动调用该方法 */
- (void)initializeUIData{
    
    self.backgroundColor = [UIColor clearColor];
}

#pragma mark
#pragma mark - Override

- (void)setFrame:(CGRect)frame{
    
    frame = [UIScreen mainScreen].bounds;
    
    [super setFrame:frame];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    CGFloat Y = self.hidden ? -[UIScreen mainScreen].bounds.size.height * 0.5 - 15 : 0;
    
    self.contentView.frame = CGRectMake(0, Y, self.frame.size.width, (JKPhotoAlbumListTableViewRowHeight * self.albumListArray.count + JKPhotoNavigationBarHeight() > [UIScreen mainScreen].bounds.size.height * 0.5) ? [UIScreen mainScreen].bounds.size.height * 0.5 : JKPhotoAlbumListTableViewRowHeight * self.albumListArray.count + JKPhotoNavigationBarHeight());
    
    self.tableView.frame = CGRectMake(0, JKPhotoNavigationBarHeight(), self.contentView.frame.size.width, self.contentView.frame.size.height - JKPhotoNavigationBarHeight());
}

#pragma mark
#pragma mark - 点击事件

- (void)executeAnimation{
    
    [self executeAlbumListTableViewAnimationCompletion:self.completion];
}

- (void)executeAlbumListTableViewAnimationCompletion:(void(^)(void))completion{
    
    if (self.isAnimating) return;
    
    self.completion = completion;
    
    self.isAnimating = YES;
    
    if (self.hidden) { // 显示动画
        
        self.contentView.frame = CGRectMake(0, -[UIScreen mainScreen].bounds.size.height * 0.5 - 15, self.frame.size.width, self.contentView.frame.size.height);
        
        self.hidden = NO;
        
        !self.completion ? : self.completion();
        
        [UIView animateWithDuration:0.25 animations:^{
            
            self.contentView.frame = CGRectMake(0, 15, self.frame.size.width, self.contentView.frame.size.height);
            self.backgroundButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
            
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
        
        self.backgroundButton.backgroundColor = [UIColor clearColor];
        
    } completion:^(BOOL finished) {
        
        !self.completion ? : self.completion();
        
        [UIView animateWithDuration:0.25 animations:^{
            
            self.contentView.frame = CGRectMake(self.frame.origin.x, -[UIScreen mainScreen].bounds.size.height * 0.5 - 15, self.frame.size.width, self.contentView.frame.size.height);
            
        } completion:^(BOOL finished) {
            
            self.hidden = YES;
            
            self.isAnimating = NO;
        }];
    }];
}

#pragma mark
#pragma mark - 发送请求

- (void)loadData{
    
    [self loadAlbumData];
}

- (void)loadAlbumData{
    
    [JKPhotoPickerEngine fetchAllAlbumItemIncludeHiddenAlbum:NO complete:^(NSArray<PHAssetCollection *> * _Nonnull albumCollectionList, NSArray<JKPhotoAlbumItem *> * _Nonnull albumItemList, NSCache * _Nonnull albumItemCache) {
        
        [self.albumListArray removeAllObjects];
        [self.albumListArray addObjectsFromArray:albumItemList];
        
        [self setNeedsLayout];
        
        self.albumCache = albumItemCache;
        
        self->_cameraRollAlbumItem = self.albumListArray.firstObject;
        
        if (!self.currentAlbumItem.localIdentifier) {
            
            !self.selectRowBlock ? : self.selectRowBlock(self.cameraRollAlbumItem, NO);
            
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
            
            // TODO: JKTODO 处理正在浏览图片
            
            self.currentSelectedIndex = [NSIndexPath indexPathForRow:index inSection:0];
            
            self->_currentAlbumItem = self.cameraRollAlbumItem;
            
            !self.selectRowBlock ? : self.selectRowBlock(self.currentAlbumItem, YES);
        }
        
        [self.tableView reloadData];
        
        [self.tableView selectRowAtIndexPath:self.currentSelectedIndex animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }];
}

- (void)reloadAlbum{
    
    [self loadAlbumData];
}

#pragma mark
#pragma mark - 处理数据


#pragma mark
#pragma mark - 赋值


#pragma mark
#pragma mark - tableView数据源及代理

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.albumListArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    JKPhotoAlbumListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:JKPhotoAlbumListTableViewCellReuseID];
    
    cell.albumItem = self.albumListArray[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    __weak typeof(self) weakSelf = self;
    
    [self executeAlbumListTableViewAnimationCompletion:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if ((weakSelf.currentSelectedIndex.section == indexPath.section) &&
            (weakSelf.currentSelectedIndex.row == indexPath.row)) { return; }
        
        weakSelf.currentSelectedIndex = indexPath;
        
        strongSelf->_currentAlbumItem = weakSelf.albumListArray[indexPath.row];
        
        !weakSelf.selectRowBlock ? : weakSelf.selectRowBlock(weakSelf.currentAlbumItem, NO);
    }];
}

#pragma mark
#pragma mark - Property

- (NSMutableArray *)albumListArray{
    if (!_albumListArray) {
        _albumListArray = [NSMutableArray array];
    }
    return _albumListArray;
}

- (UIView *)contentView{
    if (!_contentView) {
        UIView *contentView = [[UIView alloc] init];
        contentView.backgroundColor = JKPhotoAdaptColor([UIColor colorWithRed:239.0 / 255.0 green:239.0 / 255.0 blue:239.0 / 255.0 alpha:1], [UIColor colorWithRed:16.0 / 255.0 green:16.0 / 255.0 blue:16.0 / 255.0 alpha:1]);
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
