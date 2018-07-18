//
//  LRZCycleBannerView.m
//  LRZCycleBannerView
//
//  Created by 刘强 on 2018/7/18.
//  Copyright © 2018年 LightReason. All rights reserved.
//

#import "LRZCycleBannerView.h"

typedef struct {
    NSInteger index;
    NSInteger section;
}LRZIndexSection;

NS_INLINE BOOL LRZEqualIndexSection(LRZIndexSection indexSection1,LRZIndexSection indexSection2) {
    return indexSection1.index == indexSection2.index && indexSection1.section == indexSection2.section;
}

NS_INLINE LRZIndexSection LRZMakeIndexSection(NSInteger index, NSInteger section) {
    LRZIndexSection indexSection;
    indexSection.index = index;
    indexSection.section = section;
    return indexSection;
}


@interface LRZCycleBannerView () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, LRZCycleBannerTransformLayoutDelegate> {
    struct {
        unsigned int pagerViewDidScroll   :1;
        unsigned int didScrollFromIndexToNewIndex   :1;
        unsigned int initializeTransformAttributes   :1;
        unsigned int applyTransformToAttributes   :1;
    }_delegateFlags;
    struct {
        unsigned int cellForItemAtIndex   :1;
        unsigned int layoutForBannerView   :1;
    }_dataSourceFlags;
}

// UI
@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, strong) LRZCycleBannerViewLayout *bannerViewLayout;
@property (nonatomic, strong) NSTimer *timer;

// Data
@property (nonatomic, assign) NSInteger numberOfItems;

@property (nonatomic, assign) LRZIndexSection indexSection; // current index
@property (nonatomic, assign) NSInteger dequeueSection;
@property (nonatomic, assign) LRZIndexSection beginDragIndexSection;
@property (nonatomic, assign) NSInteger firstScrollIndex;

@property (nonatomic, assign) BOOL needClearLayout;
@property (nonatomic, assign) BOOL didReloadData;
@property (nonatomic, assign) BOOL didLayout;



@end

#define kPagerViewMaxSectionCount 200
#define kPagerViewMinSectionCount 18


@implementation LRZCycleBannerView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self configureProperty];
        
        [self addCollectionView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self configureProperty];
        
        [self addCollectionView];
    }
    return self;
}

- (void)configureProperty {
    _didReloadData = NO;
    _didLayout = NO;
    _autoScrollInterval = 0;
    _isInfiniteLoop = YES;
    _beginDragIndexSection.index = 0;
    _beginDragIndexSection.section = 0;
    _indexSection.index = -1;
    _indexSection.section = -1;
    _firstScrollIndex = -1;
}

- (void)addCollectionView {
    LRZCycleBannerTransformLayout *layout = [[LRZCycleBannerTransformLayout alloc]init];
    UICollectionView *collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
    layout.delegate = _delegateFlags.applyTransformToAttributes ? self : nil;;
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.pagingEnabled = NO;
    collectionView.decelerationRate = 1-0.0076;
    if ([collectionView respondsToSelector:@selector(setPrefetchingEnabled:)]) {
        collectionView.prefetchingEnabled = NO;
    }
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.showsVerticalScrollIndicator = NO;
    [self addSubview:collectionView];
    _collectionView = collectionView;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (!newSuperview) {
        [self removeTimer];
    }else {
        [self removeTimer];
        if (_autoScrollInterval > 0) {
            [self addTimer];
        }
    }
}

#pragma mark - timer

- (void)addTimer {
    if (_timer) {
        return;
    }
    _timer = [NSTimer timerWithTimeInterval:_autoScrollInterval target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)removeTimer {
    if (!_timer) {
        return;
    }
    [_timer invalidate];
    _timer = nil;
}

- (void)timerFired:(NSTimer *)timer {
    if (!self.superview || !self.window || _numberOfItems == 0 || self.tracking) {
        return;
    }
    
    [self scrollToNearlyIndexAtDirection:LRZPagerScrollDirectionRight animate:YES];
}

#pragma mark - getter

- (LRZCycleBannerViewLayout *)bannerViewLayout {
    if (!_bannerViewLayout) {
        if (_dataSourceFlags.layoutForBannerView) {
            _bannerViewLayout = [_dataSource layoutForbannerView:self];
            _bannerViewLayout.isInfiniteLoop = _isInfiniteLoop;
        }
        if (_bannerViewLayout.itemSize.width <= 0 || _bannerViewLayout.itemSize.height <= 0) {
            _bannerViewLayout = nil;
        }
    }
    return _bannerViewLayout;
}

- (NSInteger)curIndex {
    return _indexSection.index;
}

- (CGPoint)contentOffset {
    return _collectionView.contentOffset;
}

- (BOOL)tracking {
    return _collectionView.tracking;
}

- (BOOL)dragging {
    return _collectionView.dragging;
}

- (BOOL)decelerating {
    return _collectionView.decelerating;
}

- (UIView *)backgroundView {
    return _collectionView.backgroundView;
}

- (__kindof UICollectionViewCell *)curIndexCell {
    return [_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_indexSection.index inSection:_indexSection.section]];
}

- (NSArray<__kindof UICollectionViewCell *> *)visibleCells {
    return _collectionView.visibleCells;
}

- (NSArray *)visibleIndexs {
    NSMutableArray *indexs = [NSMutableArray array];
    for (NSIndexPath *indexPath in _collectionView.indexPathsForVisibleItems) {
        [indexs addObject:@(indexPath.item)];
    }
    return [indexs copy];
}

#pragma mark - setter

- (void)setBackgroundView:(UIView *)backgroundView {
    [_collectionView setBackgroundView:backgroundView];
}

- (void)setAutoScrollInterval:(CGFloat)autoScrollInterval {
    _autoScrollInterval = autoScrollInterval;
    [self removeTimer];
    if (autoScrollInterval > 0 && self.superview) {
        [self addTimer];
    }
}

- (void)setDelegate:(id<LRZCycleBannerViewDelegate>)delegate {
    _delegate = delegate;
    _delegateFlags.pagerViewDidScroll = [delegate respondsToSelector:@selector(bannerViewDidScroll:)];
    _delegateFlags.didScrollFromIndexToNewIndex = [delegate respondsToSelector:@selector(bannerView:didScrollFromIndex:toIndex:)];
    _delegateFlags.initializeTransformAttributes = [delegate respondsToSelector:@selector(bannerView:initializeTransformAttributes:)];
    _delegateFlags.applyTransformToAttributes = [delegate respondsToSelector:@selector(bannerView:applyTransformToAttributes:)];
    if (self.collectionView && self.collectionView.collectionViewLayout) {
        ((LRZCycleBannerTransformLayout *)self.collectionView.collectionViewLayout).delegate = _delegateFlags.applyTransformToAttributes ? self : nil;
    }
}

- (void)setDataSource:(id<LRZCycleBannerViewDataSource>)dataSource {
    _dataSource = dataSource;
    _dataSourceFlags.cellForItemAtIndex = [dataSource respondsToSelector:@selector(bannerView:cellForItemAtIndex:)];
    _dataSourceFlags.layoutForBannerView = [dataSource respondsToSelector:@selector(layoutForbannerView:)];
}

#pragma mark - public

- (void)reloadData {
    _didReloadData = YES;
    [self setNeedClearLayout];
    [self clearLayout];
    [self updateData];
}

// not clear layout
- (void)updateData {
    [self updateLayout];
    _numberOfItems = [_dataSource numberOfItemsInBannerView:self];
    [_collectionView reloadData];
    if (!_didLayout && !CGRectIsEmpty(self.frame) && _indexSection.index < 0) {
        _didLayout = YES;
    }
    [self resetPagerViewAtIndex:_indexSection.index < 0 && !CGRectIsEmpty(self.frame) ? 0 :_indexSection.index];
}

- (void)scrollToNearlyIndexAtDirection:(LRZPagerScrollDirection)direction animate:(BOOL)animate {
    LRZIndexSection indexSection = [self nearlyIndexPathAtDirection:direction];
    [self scrollToItemAtIndexSection:indexSection animate:animate];
}

- (void)scrollToItemAtIndex:(NSInteger)index animate:(BOOL)animate {
    if (!_didLayout && _didReloadData) {
        _firstScrollIndex = index;
    }else {
        _firstScrollIndex = -1;
    }
    if (!_isInfiniteLoop) {
        [self scrollToItemAtIndexSection:LRZMakeIndexSection(index, 0) animate:animate];
        return;
    }
    
    [self scrollToItemAtIndexSection:LRZMakeIndexSection(index, index >= self.curIndex ? _indexSection.section : _indexSection.section+1) animate:animate];
}

- (void)scrollToItemAtIndexSection:(LRZIndexSection)indexSection animate:(BOOL)animate {
    if (_numberOfItems <= 0 || ![self isValidIndexSection:indexSection]) {
        //NSLog(@"scrollToItemAtIndex: item indexSection is invalid!");
        return;
    }
    
    if (animate && [_delegate respondsToSelector:@selector(bannerViewWillBeginScrollingAnimation:)]) {
        [_delegate bannerViewWillBeginScrollingAnimation:self];
    }
    CGFloat offset = [self caculateOffsetXAtIndexSection:indexSection];
    [_collectionView setContentOffset:CGPointMake(offset, _collectionView.contentOffset.y) animated:animate];
}

- (void)registerClass:(Class)Class forCellWithReuseIdentifier:(NSString *)identifier {
    [_collectionView registerClass:Class forCellWithReuseIdentifier:identifier];
}

- (void)registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier {
    [_collectionView registerNib:nib forCellWithReuseIdentifier:identifier];
}

- (__kindof UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index {
    UICollectionViewCell *cell = [_collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:[NSIndexPath indexPathForItem:index inSection:_dequeueSection]];
    return cell;
}

#pragma mark - configure layout

- (void)updateLayout {
    if (!self.layout) {
        return;
    }
    self.bannerViewLayout.isInfiniteLoop = _isInfiniteLoop;
    ((LRZCycleBannerTransformLayout *)_collectionView.collectionViewLayout).layout = self.bannerViewLayout;
}

- (void)clearLayout {
    if (_needClearLayout) {
        _bannerViewLayout = nil;
        _needClearLayout = NO;
    }
}

- (void)setNeedClearLayout {
    _needClearLayout = YES;
}

- (void)setNeedUpdateLayout {
    if (!self.layout) {
        return;
    }
    [self clearLayout];
    [self updateLayout];
    [_collectionView.collectionViewLayout invalidateLayout];
    [self resetPagerViewAtIndex:_indexSection.index < 0 ? 0 :_indexSection.index];
}

#pragma mark - pager index

- (BOOL)isValidIndexSection:(LRZIndexSection)indexSection {
    return indexSection.index >= 0 && indexSection.index < _numberOfItems && indexSection.section >= 0 && indexSection.section < kPagerViewMaxSectionCount;
}

- (LRZIndexSection)nearlyIndexPathAtDirection:(LRZPagerScrollDirection)direction{
    return [self nearlyIndexPathForIndexSection:_indexSection direction:direction];
}

- (LRZIndexSection)nearlyIndexPathForIndexSection:(LRZIndexSection)indexSection direction:(LRZPagerScrollDirection)direction {
    if (indexSection.index < 0 || indexSection.index >= _numberOfItems) {
        return indexSection;
    }
    
    if (!_isInfiniteLoop) {
        if (direction == LRZPagerScrollDirectionRight && indexSection.index == _numberOfItems - 1) {
            return _autoScrollInterval > 0 ? LRZMakeIndexSection(0, 0) : indexSection;
        } else if (direction == LRZPagerScrollDirectionRight) {
            return LRZMakeIndexSection(indexSection.index+1, 0);
        }
        
        if (indexSection.index == 0) {
            return _autoScrollInterval > 0 ? LRZMakeIndexSection(_numberOfItems - 1, 0) : indexSection;
        }
        return LRZMakeIndexSection(indexSection.index-1, 0);
    }
    
    if (direction == LRZPagerScrollDirectionRight) {
        if (indexSection.index < _numberOfItems-1) {
            return LRZMakeIndexSection(indexSection.index+1, indexSection.section);
        }
        if (indexSection.section >= kPagerViewMaxSectionCount-1) {
            return LRZMakeIndexSection(indexSection.index, kPagerViewMaxSectionCount-1);
        }
        return LRZMakeIndexSection(0, indexSection.section+1);
    }
    
    if (indexSection.index > 0) {
        return LRZMakeIndexSection(indexSection.index-1, indexSection.section);
    }
    if (indexSection.section <= 0) {
        return LRZMakeIndexSection(indexSection.index, 0);
    }
    return LRZMakeIndexSection(_numberOfItems-1, indexSection.section-1);
}

- (LRZIndexSection)caculateIndexSectionWithOffsetX:(CGFloat)offsetX {
    if (_numberOfItems <= 0) {
        return LRZMakeIndexSection(0, 0);
    }
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    CGFloat leftEdge = _isInfiniteLoop ? _bannerViewLayout.sectionInset.left : _bannerViewLayout.onlyOneSectionInset.left;
    CGFloat width = CGRectGetWidth(_collectionView.frame);
    CGFloat middleOffset = offsetX + width/2;
    CGFloat itemWidth = layout.itemSize.width + layout.minimumInteritemSpacing;
    NSInteger curIndex = 0;
    NSInteger curSection = 0;
    if (middleOffset - leftEdge >= 0) {
        NSInteger itemIndex = (middleOffset - leftEdge+layout.minimumInteritemSpacing/2)/itemWidth;
        if (itemIndex < 0) {
            itemIndex = 0;
        }else if (itemIndex >= _numberOfItems*kPagerViewMaxSectionCount) {
            itemIndex = _numberOfItems*kPagerViewMaxSectionCount-1;
        }
        curIndex = itemIndex%_numberOfItems;
        curSection = itemIndex/_numberOfItems;
    }
    return LRZMakeIndexSection(curIndex, curSection);
}

- (CGFloat)caculateOffsetXAtIndexSection:(LRZIndexSection)indexSection{
    if (_numberOfItems == 0) {
        return 0;
    }
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    UIEdgeInsets edge = _isInfiniteLoop ? _bannerViewLayout.sectionInset : _bannerViewLayout.onlyOneSectionInset;
    CGFloat leftEdge = edge.left;
    CGFloat rightEdge = edge.right;
    CGFloat width = CGRectGetWidth(_collectionView.frame);
    CGFloat itemWidth = layout.itemSize.width + layout.minimumInteritemSpacing;
    CGFloat offsetX = 0;
    if (!_isInfiniteLoop && !_bannerViewLayout.itemHorizontalCenter && indexSection.index == _numberOfItems - 1) {
        offsetX = leftEdge + itemWidth*(indexSection.index + indexSection.section*_numberOfItems) - (width - itemWidth) -  layout.minimumInteritemSpacing + rightEdge;
    }else {
        offsetX = leftEdge + itemWidth*(indexSection.index + indexSection.section*_numberOfItems) - layout.minimumInteritemSpacing/2 - (width - itemWidth)/2;
    }
    return MAX(offsetX, 0);
}

- (void)resetPagerViewAtIndex:(NSInteger)index {
    if (_didLayout && _firstScrollIndex >= 0) {
        index = _firstScrollIndex;
        _firstScrollIndex = -1;
    }
    if (index < 0) {
        return;
    }
    if (index >= _numberOfItems) {
        index = 0;
    }
    [self scrollToItemAtIndexSection:LRZMakeIndexSection(index, _isInfiniteLoop ? kPagerViewMaxSectionCount/3 : 0) animate:NO];
    if (!_isInfiniteLoop && _indexSection.index < 0) {
        [self scrollViewDidScroll:_collectionView];
    }
}

- (void)recyclePagerViewIfNeed {
    if (!_isInfiniteLoop) {
        return;
    }
    if (_indexSection.section > kPagerViewMaxSectionCount - kPagerViewMinSectionCount || _indexSection.section < kPagerViewMinSectionCount) {
        [self resetPagerViewAtIndex:_indexSection.index];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _isInfiniteLoop ? kPagerViewMaxSectionCount : 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    _numberOfItems = [_dataSource numberOfItemsInBannerView:self];
    return _numberOfItems;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    _dequeueSection = indexPath.section;
    if (_dataSourceFlags.cellForItemAtIndex) {
        return [_dataSource bannerView:self cellForItemAtIndex:indexPath.row];
    }
    NSAssert(NO, @"pagerView cellForItemAtIndex: is nil!");
    return nil;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if (!_isInfiniteLoop) {
        return _bannerViewLayout.onlyOneSectionInset;
    }
    if (section == 0 ) {
        return _bannerViewLayout.firstSectionInset;
    }else if (section == kPagerViewMaxSectionCount -1) {
        return _bannerViewLayout.lastSectionInset;
    }
    return _bannerViewLayout.middleSectionInset;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if ([_delegate respondsToSelector:@selector(bannerView:didSelectedItemCell:atIndex:)]) {
        [_delegate bannerView:self didSelectedItemCell:cell atIndex:indexPath.item];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!_didLayout) {
        return;
    }
    LRZIndexSection newIndexSection =  [self caculateIndexSectionWithOffsetX:scrollView.contentOffset.x];
    if (_numberOfItems <= 0 || ![self isValidIndexSection:newIndexSection]) {
        NSLog(@"inVlaidIndexSection:(%ld,%ld)!",(long)newIndexSection.index,(long)newIndexSection.section);
        return;
    }
    LRZIndexSection indexSection = _indexSection;
    _indexSection = newIndexSection;
    
    if (_delegateFlags.pagerViewDidScroll) {
        [_delegate bannerViewDidScroll:self];
    }
    
    if (_delegateFlags.didScrollFromIndexToNewIndex && !LRZEqualIndexSection(_indexSection, indexSection)) {
        //NSLog(@"curIndex %ld",(long)_indexSection.index);
        [_delegate bannerView:self didScrollFromIndex:MAX(indexSection.index, 0) toIndex:_indexSection.index];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (_autoScrollInterval > 0) {
        [self removeTimer];
    }
    _beginDragIndexSection = [self caculateIndexSectionWithOffsetX:scrollView.contentOffset.x];
    if ([_delegate respondsToSelector:@selector(bannerViewWillBeginDragging:)]) {
        [_delegate bannerViewWillBeginDragging:self];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (fabs(velocity.x) < 0.35 || !LRZEqualIndexSection(_beginDragIndexSection, _indexSection)) {
        targetContentOffset->x = [self caculateOffsetXAtIndexSection:_indexSection];
        return;
    }
    LRZPagerScrollDirection direction = LRZPagerScrollDirectionRight;
    if ((scrollView.contentOffset.x < 0 && targetContentOffset->x <= 0) || (targetContentOffset->x < scrollView.contentOffset.x && scrollView.contentOffset.x < scrollView.contentSize.width - scrollView.frame.size.width)) {
        direction = LRZPagerScrollDirectionLeft;
    }
    LRZIndexSection indexSection = [self nearlyIndexPathForIndexSection:_indexSection direction:direction];
    targetContentOffset->x = [self caculateOffsetXAtIndexSection:indexSection];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (_autoScrollInterval > 0) {
        [self addTimer];
    }
    if ([_delegate respondsToSelector:@selector(bannerViewDidEndDragging:willDecelerate:)]) {
        [_delegate bannerViewDidEndDragging:self willDecelerate:decelerate];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(bannerViewWillBeginDecelerating:)]) {
        [_delegate bannerViewWillBeginDecelerating:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self recyclePagerViewIfNeed];
    if ([_delegate respondsToSelector:@selector(bannerViewDidEndDecelerating:)]) {
        [_delegate bannerViewDidEndDecelerating:self];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self recyclePagerViewIfNeed];
    if ([_delegate respondsToSelector:@selector(bannerViewDidEndScrollingAnimation:)]) {
        [_delegate bannerViewDidEndScrollingAnimation:self];
    }
}

#pragma mark - TYCyclePagerTransformLayoutDelegate

- (void)bannerViewTransformLayout:(LRZCycleBannerTransformLayout *)bannerViewTransformLayout initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes {
    if (_delegateFlags.initializeTransformAttributes) {
        [_delegate bannerView:self initializeTransformAttributes:attributes];
    }
}

- (void)bannerViewTransformLayout:(LRZCycleBannerTransformLayout *)bannerViewTransformLayout applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes {
    if (_delegateFlags.applyTransformToAttributes) {
        [_delegate bannerView:self applyTransformToAttributes:attributes];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL needUpdateLayout = !CGRectEqualToRect(_collectionView.frame, self.bounds);
    _collectionView.frame = self.bounds;
    if ((_indexSection.section < 0 || needUpdateLayout) && (_numberOfItems > 0 || _didReloadData)) {
        _didLayout = YES;
        [self setNeedUpdateLayout];
    }
}

- (void)dealloc {
    ((LRZCycleBannerTransformLayout *)_collectionView.collectionViewLayout).delegate = nil;
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
}


@end
