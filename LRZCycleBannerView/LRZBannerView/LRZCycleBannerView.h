//
//  LRZCycleBannerView.h
//  LRZCycleBannerView
//
//  Created by 刘强 on 2018/7/18.
//  Copyright © 2018年 LightReason. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LRZCycleBannerTransformLayout.h"

NS_ASSUME_NONNULL_BEGIN

//bannerView scrolling direction
typedef NS_ENUM(NSUInteger, LRZPagerScrollDirection) {
    LRZPagerScrollDirectionLeft,
    LRZPagerScrollDirectionRight,
};

@class LRZCycleBannerView;
@protocol LRZCycleBannerViewDataSource <NSObject>
@required
- (NSInteger)numberOfItemsInBannerView:(LRZCycleBannerView *)bannerView;
- (__kindof UICollectionViewCell *)bannerView:(LRZCycleBannerView *)bannerView cellForItemAtIndex:(NSInteger )index;
/**
 return bannerView layout,and cache layout
 */
- (LRZCycleBannerViewLayout *)layoutForbannerView:(LRZCycleBannerView *)bannerView;
@end

@protocol LRZCycleBannerViewDelegate <NSObject>
@optional
/**
 bannerView did scroll to new index page
 */
- (void)bannerView:(LRZCycleBannerView *)bannerView didScrollFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
/**
 bannerView did selected item cell
 */
- (void)bannerView:(LRZCycleBannerView *)bannerView didSelectedItemCell:(__kindof UICollectionViewCell *)cell atIndex:(NSInteger)index;

// custom layout
- (void)bannerView:(LRZCycleBannerView *)bannerView initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes;

- (void)bannerView:(LRZCycleBannerView *)bannerView applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes;


// scrollViewDelegate
- (void)bannerViewDidScroll:(LRZCycleBannerView *)bannerView;

- (void)bannerViewWillBeginDragging:(LRZCycleBannerView *)bannerView;

- (void)bannerViewDidEndDragging:(LRZCycleBannerView *)bannerView willDecelerate:(BOOL)decelerate;

- (void)bannerViewWillBeginDecelerating:(LRZCycleBannerView *)bannerView;

- (void)bannerViewDidEndDecelerating:(LRZCycleBannerView *)bannerView;

- (void)bannerViewWillBeginScrollingAnimation:(LRZCycleBannerView *)bannerView;

- (void)bannerViewDidEndScrollingAnimation:(LRZCycleBannerView *)bannerView;
@end

@interface LRZCycleBannerView : UIView
// will be automatically resized to track the size of the bannerView
@property (nonatomic, strong, nullable) UIView *backgroundView;

@property (nonatomic, weak, nullable) id<LRZCycleBannerViewDataSource> dataSource;
@property (nonatomic, weak, nullable) id<LRZCycleBannerViewDelegate> delegate;

// banner view, don't set dataSource and delegate
@property (nonatomic, weak, readonly) UICollectionView *collectionView;
// banner view layout
@property (nonatomic, strong, readonly) LRZCycleBannerTransformLayout *layout;
/**
 is infinite cycle bannerView
 是否开启无限循环
 */
@property (nonatomic, assign) BOOL isInfiniteLoop;

/**
 bannerView automatic scroll time interval, default 0,disable automatic
 */
@property (nonatomic, assign) CGFloat autoScrollInterval;

/**
 current page index
 */
@property (nonatomic, assign, readonly) NSInteger curIndex;

// scrollView property
@property (nonatomic, assign, readonly) CGPoint contentOffset;
@property (nonatomic, assign, readonly) BOOL tracking;
@property (nonatomic, assign, readonly) BOOL dragging;
@property (nonatomic, assign, readonly) BOOL decelerating;


/**
 reload data, !!important!!: will clear layout and call delegate layoutForPagerView
 */
- (void)reloadData;

/**
 update data is reload data, but not clear layuot
 */
- (void)updateData;

/**
 if you only want update layout
 */
- (void)setNeedUpdateLayout;

/**
 will set layout nil and call delegate->layoutForBannerView
 */
- (void)setNeedClearLayout;

/**
 current index cell in bannerView
 */
- (__kindof UICollectionViewCell * _Nullable)curIndexCell;

/**
 visible cells in bannerView
 */
- (NSArray<__kindof UICollectionViewCell *> *_Nullable)visibleCells;


/**
 visible bannerView indexs, maybe repeat index
 */
- (NSArray *)visibleIndexs;

/**
 scroll to item at index
 */
- (void)scrollToItemAtIndex:(NSInteger)index animate:(BOOL)animate;

/**
 scroll to next or pre item
 */
- (void)scrollToNearlyIndexAtDirection:(LRZPagerScrollDirection)direction animate:(BOOL)animate;

/**
 register banner view cell with class
 */
- (void)registerClass:(Class)Class forCellWithReuseIdentifier:(NSString *)identifier;

/**
 register banner view cell with nib
 */
- (void)registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier;

/**
 dequeue reusable cell for bannerView
 */
- (__kindof UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index;
@end

NS_ASSUME_NONNULL_END
