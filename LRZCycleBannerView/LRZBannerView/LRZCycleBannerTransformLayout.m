//
//  LRZCycleBannerTransformLayout.m
//  LRZCycleBannerView
//
//  Created by 刘强 on 2018/7/18.
//  Copyright © 2018年 LightReason. All rights reserved.
//

#import "LRZCycleBannerTransformLayout.h"

typedef NS_ENUM(NSUInteger, LRZTransformLayoutItemDirection) {
    LRZTransformLayoutItemLeft,
    LRZTransformLayoutItemCenter,
    LRZTransformLayoutItemRight,
};


@interface LRZCycleBannerTransformLayout () {
    struct {
        unsigned int applyTransformToAttributes      :1;
        unsigned int initializeTransformAttributes   :1;
    }_delegateFlags;
}
@property (nonatomic, assign) BOOL applyTransformToAttributesDelegate;

@end

@interface LRZCycleBannerViewLayout ()

@property (nonatomic, weak) UIView *bannerView;

@end

@implementation LRZCycleBannerTransformLayout
- (instancetype)init {
    if (self = [super init]) {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return self;
}

#pragma mark - getter setter
- (void)setDelegate:(id<LRZCycleBannerTransformLayoutDelegate>)delegate {
    _delegate = delegate;
    _delegateFlags.initializeTransformAttributes = [delegate respondsToSelector:@selector(bannerViewTransformLayout:initializeTransformAttributes:)];
    _delegateFlags.applyTransformToAttributes = [delegate respondsToSelector:@selector(bannerViewTransformLayout:applyTransformToAttributes:)];
}

- (void)setLayout:(LRZCycleBannerViewLayout *)layout {
    _layout = layout;
    _layout.bannerView = self.collectionView;
    self.itemSize = _layout.itemSize;
    self.minimumInteritemSpacing = _layout.itemSpacing;
    self.minimumLineSpacing = _layout.itemSpacing;
}

- (CGSize)itemSize {
    if (!_layout) {
        return [super itemSize];
    }
    return _layout.itemSize;
}

- (CGFloat)minimumLineSpacing {
    if (!_layout) {
        return [super minimumLineSpacing];
    }
    return _layout.itemSpacing;
}

- (CGFloat)minimumInteritemSpacing {
    if (!_layout) {
        return [super minimumInteritemSpacing];
    }
    return _layout.itemSpacing;
}

- (LRZTransformLayoutItemDirection)directionWithCenterX:(CGFloat)centerX {
    LRZTransformLayoutItemDirection direction= LRZTransformLayoutItemRight;
    CGFloat contentCenterX = self.collectionView.contentOffset.x + CGRectGetWidth(self.collectionView.frame)/2;
    if (ABS(centerX - contentCenterX) < 0.5) {
        direction = LRZTransformLayoutItemCenter;
    }else if (centerX - contentCenterX < 0) {
        direction = LRZTransformLayoutItemLeft;
    }
    return direction;
}

#pragma mark - layout

-(BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return _layout.layoutType == LRZCycleBannerTransformLayoutNormal ? [super shouldInvalidateLayoutForBoundsChange:newBounds] : YES;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    if (_delegateFlags.applyTransformToAttributes || _layout.layoutType != LRZCycleBannerTransformLayoutNormal) {
        NSArray *attributesArray = [[NSArray alloc] initWithArray:[super layoutAttributesForElementsInRect:rect] copyItems:YES];
        CGRect visibleRect = {self.collectionView.contentOffset,self.collectionView.bounds.size};
        for (UICollectionViewLayoutAttributes *attributes in attributesArray) {
            if (!CGRectIntersectsRect(visibleRect, attributes.frame)) {
                continue;
            }
            if (_delegateFlags.applyTransformToAttributes) {
                [_delegate bannerViewTransformLayout:self applyTransformToAttributes:attributes];
            }else {
                [self applyTransformToAttributes:attributes layoutType:_layout.layoutType];
            }
        }
        return attributesArray;
    }
    return [super layoutAttributesForElementsInRect:rect];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    if (_delegateFlags.initializeTransformAttributes) {
        [_delegate bannerViewTransformLayout:self initializeTransformAttributes:attributes];
    }else if(_layout.layoutType != LRZCycleBannerTransformLayoutNormal){
        [self initializeTransformAttributes:attributes layoutType:_layout.layoutType];
    }
    return attributes;
}


#pragma mark - transform

- (void)initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes layoutType:(LRZCycleBannerTransformLayoutType)layoutType {
    switch (layoutType) {
        case LRZCycleBannerTransformLayoutLinear:
            [self applyLinearTransformToAttributes:attributes scale:_layout.minimumScale alpha:_layout.minimumAlpha];
            break;
        case LRZCycleBannerTransformLayoutCoverflow:
        {
            [self applyCoverflowTransformToAttributes:attributes angle:_layout.maximumAngle alpha:_layout.minimumAlpha];
            break;
        }
        default:
            break;
    }
}

- (void)applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes layoutType:(LRZCycleBannerTransformLayoutType)layoutType {
    switch (layoutType) {
        case LRZCycleBannerTransformLayoutLinear:
            [self applyLinearTransformToAttributes:attributes];
            break;
        case LRZCycleBannerTransformLayoutCoverflow:
            [self applyCoverflowTransformToAttributes:attributes];
            break;
        default:
            break;
    }
}

#pragma mark - LinearTransform

- (void)applyLinearTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes {
    CGFloat collectionViewWidth = self.collectionView.frame.size.width;
    if (collectionViewWidth <= 0) {
        return;
    }
    CGFloat centetX = self.collectionView.contentOffset.x + collectionViewWidth/2;
    CGFloat delta = ABS(attributes.center.x - centetX);
    CGFloat scale = MAX(1 - delta/collectionViewWidth*_layout.rateOfChange, _layout.minimumScale);
    CGFloat alpha = MAX(1 - delta/collectionViewWidth, _layout.minimumAlpha);
    [self applyLinearTransformToAttributes:attributes scale:scale alpha:alpha];
}

- (void)applyLinearTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes scale:(CGFloat)scale alpha:(CGFloat)alpha {
    CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
    if (_layout.adjustSpacingWhenScroling) {
        LRZTransformLayoutItemDirection direction = [self directionWithCenterX:attributes.center.x];
        CGFloat translate = 0;
        switch (direction) {
            case LRZTransformLayoutItemLeft:
                translate = 1.15 * attributes.size.width*(1-scale)/2;
                break;
            case LRZTransformLayoutItemRight:
                translate = -1.15 * attributes.size.width*(1-scale)/2;
                break;
            default:
                // center
                scale = 1.0;
                alpha = 1.0;
                break;
        }
        transform = CGAffineTransformTranslate(transform,translate, 0);
    }
    attributes.transform = transform;
    attributes.alpha = alpha;
}

#pragma mark - CoverflowTransform

- (void)applyCoverflowTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes{
    CGFloat collectionViewWidth = self.collectionView.frame.size.width;
    if (collectionViewWidth <= 0) {
        return;
    }
    CGFloat centetX = self.collectionView.contentOffset.x + collectionViewWidth/2;
    CGFloat delta = ABS(attributes.center.x - centetX);
    CGFloat angle = MIN(delta/collectionViewWidth*(1-_layout.rateOfChange), _layout.maximumAngle);
    CGFloat alpha = MAX(1 - delta/collectionViewWidth, _layout.minimumAlpha);
    [self applyCoverflowTransformToAttributes:attributes angle:angle alpha:alpha];
}

- (void)applyCoverflowTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes angle:(CGFloat)angle alpha:(CGFloat)alpha {
    LRZTransformLayoutItemDirection direction = [self directionWithCenterX:attributes.center.x];
    CATransform3D transform3D = CATransform3DIdentity;
    transform3D.m34 = -0.002;
    CGFloat translate = 0;
    switch (direction) {
        case LRZTransformLayoutItemLeft:
            translate = (1-cos(angle*1.2*M_PI))*attributes.size.width;
            break;
        case LRZTransformLayoutItemRight:
            translate = -(1-cos(angle*1.2*M_PI))*attributes.size.width;
            angle = -angle;
            break;
        default:
            // center
            angle = 0;
            alpha = 1;
            break;
    }
    
    transform3D = CATransform3DRotate(transform3D, M_PI*angle, 0, 1, 0);
    if (_layout.adjustSpacingWhenScroling) {
        transform3D = CATransform3DTranslate(transform3D, translate, 0, 0);
    }
    attributes.transform3D = transform3D;
    attributes.alpha = alpha;
}

@end


@implementation LRZCycleBannerViewLayout

- (instancetype)init {
    if (self = [super init]) {
        _itemVerticalCenter = YES;
        _minimumScale = 0.8;
        _minimumAlpha = 1.0;
        _maximumAngle = 0.2;
        _rateOfChange = 0.4;
        _adjustSpacingWhenScroling = YES;
    }
    return self;
}

#pragma mark - getter

- (UIEdgeInsets)onlyOneSectionInset {
    CGFloat leftSpace = _bannerView && !_isInfiniteLoop && _itemHorizontalCenter ? (CGRectGetWidth(_bannerView.frame) - _itemSize.width)/2 : _sectionInset.left;
    CGFloat rightSpace = _bannerView && !_isInfiniteLoop && _itemHorizontalCenter ? (CGRectGetWidth(_bannerView.frame) - _itemSize.width)/2 : _sectionInset.right;
    if (_itemVerticalCenter) {
        CGFloat verticalSpace = (CGRectGetHeight(_bannerView.frame) - _itemSize.height)/2;
        return UIEdgeInsetsMake(verticalSpace, leftSpace, verticalSpace, rightSpace);
    }
    return UIEdgeInsetsMake(_sectionInset.top, leftSpace, _sectionInset.bottom, rightSpace);
}

- (UIEdgeInsets)firstSectionInset {
    if (_itemVerticalCenter) {
        CGFloat verticalSpace = (CGRectGetHeight(_bannerView.frame) - _itemSize.height)/2;
        return UIEdgeInsetsMake(verticalSpace, _sectionInset.left, verticalSpace, _itemSpacing);
    }
    return UIEdgeInsetsMake(_sectionInset.top, _sectionInset.left, _sectionInset.bottom, _itemSpacing);
}

- (UIEdgeInsets)lastSectionInset {
    if (_itemVerticalCenter) {
        CGFloat verticalSpace = (CGRectGetHeight(_bannerView.frame) - _itemSize.height)/2;
        return UIEdgeInsetsMake(verticalSpace, 0, verticalSpace, _sectionInset.right);
    }
    return UIEdgeInsetsMake(_sectionInset.top, 0, _sectionInset.bottom, _sectionInset.right);
}

- (UIEdgeInsets)middleSectionInset {
    if (_itemVerticalCenter) {
        CGFloat verticalSpace = (CGRectGetHeight(_bannerView.frame) - _itemSize.height)/2;
        return UIEdgeInsetsMake(verticalSpace, 0, verticalSpace, _itemSpacing);
    }
    return _sectionInset;
}

@end
