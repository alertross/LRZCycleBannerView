//
//  LRZCycleBannerTransformLayout.h
//  LRZCycleBannerView
//
//  Created by 刘强 on 2018/7/18.
//  Copyright © 2018年 LightReason. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger,LRZCycleBannerTransformLayoutType) {
    LRZCycleBannerTransformLayoutNormal,
    LRZCycleBannerTransformLayoutLinear,
    LRZCycleBannerTransformLayoutCoverflow,
};

@class LRZCycleBannerTransformLayout;

@protocol LRZCycleBannerTransformLayoutDelegate<NSObject>
@required
// initialize layout attributes
- (void)bannerViewTransformLayout:(LRZCycleBannerTransformLayout *)bannerViewTransformLayout initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes;

// apply layout attributes
- (void)bannerViewTransformLayout:(LRZCycleBannerTransformLayout *)bannerViewTransformLayout applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes;
@end

//////////////////////////////////////////LRZCycleBannerViewLayout////////////////////////////////////////////

@interface LRZCycleBannerViewLayout : NSObject

@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) CGFloat itemSpacing;
@property (nonatomic, assign) UIEdgeInsets sectionInset;

@property (nonatomic, assign) LRZCycleBannerTransformLayoutType layoutType;

@property (nonatomic, assign) CGFloat minimumScale; // sacle default 0.8
@property (nonatomic, assign) CGFloat minimumAlpha; // alpha default 1.0
@property (nonatomic, assign) CGFloat maximumAngle; // angle is % default 0.2

@property (nonatomic, assign) BOOL isInfiniteLoop;  // infinte scroll
@property (nonatomic, assign) CGFloat rateOfChange; // scale and angle change rate
@property (nonatomic, assign) BOOL adjustSpacingWhenScroling;

/**
 bannerView cell item vertical centering
 */
@property (nonatomic, assign) BOOL itemVerticalCenter;

/**
 first and last item horizontalc enter, when isInfiniteLoop is NO
 */
@property (nonatomic, assign) BOOL itemHorizontalCenter;

// sectionInset
@property (nonatomic, assign, readonly) UIEdgeInsets onlyOneSectionInset;
@property (nonatomic, assign, readonly) UIEdgeInsets firstSectionInset;
@property (nonatomic, assign, readonly) UIEdgeInsets lastSectionInset;
@property (nonatomic, assign, readonly) UIEdgeInsets middleSectionInset;
@end



//////////////////////////////////////////LRZCycleBannerTransformLayout////////////////////////////////////////////

@interface LRZCycleBannerTransformLayout : UICollectionViewFlowLayout

@property (nonatomic, strong) LRZCycleBannerViewLayout *layout;

@property (nonatomic, weak, nullable) id<LRZCycleBannerTransformLayoutDelegate> delegate;

@end
NS_ASSUME_NONNULL_END
