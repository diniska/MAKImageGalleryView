//
//  MAKImageGalleryView.m
//  MAKImageGalleryView
//
//  Created by Denis Chaschin on 01.09.14.
//  Copyright (c) 2014 diniska. All rights reserved.
//

#import "MAKImageGalleryView.h"

static CGFloat const kPageControlHeight = 20;

static NSString *const kImageCellReusableId = @"imageCell";

@interface MAKImageGalleryViewImageCell : UICollectionViewCell
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSOperation *imageLoadingOperation;
@end

@interface MAKImageGalleryView () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) UIPageControl *pageControl;
@property (strong, nonatomic) NSTimer *imageChangingTimer;
@property (assign, nonatomic) BOOL animatingForward;
@end

@implementation MAKImageGalleryView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame collectionViewLayout:[self createLayout]];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.collectionViewLayout = [self createLayout];
        [self initialize];
    }
    return self;
}

- (void)initialize {
    UIPageControl *pageControl = [[UIPageControl alloc] init];
    pageControl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self addSubview:pageControl];
    pageControl.numberOfPages = 1;
    pageControl.currentPage = 0;
    _pageControl = pageControl;
    self.dataSource = self;
    self.delegate = self;
    self.pagingEnabled = YES;
    self.allowsSelection = NO;
    [self registerClass:[MAKImageGalleryViewImageCell class] forCellWithReuseIdentifier:kImageCellReusableId];
    self.clipsToBounds = YES;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
}

#pragma mark - Private
- (UICollectionViewLayout *)createLayout {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.minimumLineSpacing = 0;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.itemSize = self.bounds.size;
    flowLayout.sectionInset = UIEdgeInsetsZero;
    return flowLayout;
}

- (void)updatePageControlNumberOfPages {
    self.pageControl.numberOfPages = [self.imageGalleryDataSource numberOfImagesInGallery:self];
}

- (void)updatePageControlCurrentPositionAnimated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.1 animations:^{
            [self updatePageControlCurrentPositionWithoutAnimation];
        }];
    } else {
        [self updatePageControlCurrentPositionWithoutAnimation];
    }
}

- (void)updatePageControlCurrentPositionWithoutAnimation {
    self.pageControl.currentPage = (self.contentOffset.x + self.bounds.size.width / 2) / ( self.contentSize.width / self.pageControl.numberOfPages);
}

- (void)updatePageControlFrame {
    self.pageControl.frame = (CGRect){
        self.contentOffset.x,
        self.bounds.size.height - kPageControlHeight,
        self.bounds.size.width,
        kPageControlHeight
    };
}

- (void)createAndStartImageChangingTimerWithInterval:(NSTimeInterval)interval {
    if (self.imageChangingTimer != nil) {
        [self.imageChangingTimer invalidate];
    }
    self.imageChangingTimer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(imageChangingTimerDidFire) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.imageChangingTimer forMode:NSRunLoopCommonModes];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.imageGalleryDataSource numberOfImagesInGallery:self];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MAKImageGalleryViewImageCell *res = [collectionView dequeueReusableCellWithReuseIdentifier:kImageCellReusableId forIndexPath:indexPath];
    
    [res.imageLoadingOperation cancel];
    res.image = nil;
    
    res.imageLoadingOperation = [NSBlockOperation blockOperationWithBlock:^{
        UIImage *const image = [self.imageGalleryDataSource imageInGalery:self atIndex:indexPath.row];
        res.image = image;
        res.imageLoadingOperation = nil;
        
    }];
    [[NSOperationQueue mainQueue] addOperation:res.imageLoadingOperation];
    
    if ([self.imageGalleryDataSource respondsToSelector:@selector(imageGallery:contentModeForImageAtIndex:)]) {
        res.contentMode = [self.imageGalleryDataSource imageGallery:self contentModeForImageAtIndex:indexPath.row];
    }
    return res;
}

#pragma mark - UICollectionViewDelegate
#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updatePageControlCurrentPositionAnimated:YES];
    [self updatePageControlFrame];
}

#pragma mark - Overriding
- (void)reloadData {
    [super reloadData];
    [self updatePageControlNumberOfPages];
    [self updatePageControlCurrentPositionAnimated:NO];
    [self updatePageControlFrame];
}

#pragma mark - Setters
- (void)setChangeImagesAutormatically:(BOOL)changeImagesAutormatically {
    if (self.changeImagesAutormatically == changeImagesAutormatically) {
        return;
    }
    if (changeImagesAutormatically) {
        [self createAndStartImageChangingTimerWithInterval:self.imageChangingDelay];
    } else {
        [self.imageChangingTimer invalidate];
        self.imageChangingTimer = nil;
    }
}

#pragma mark - Getters
- (BOOL)changeImagesAutormatically {
    return self.imageChangingTimer != nil;
}

#pragma mark - Timer events
- (void)imageChangingTimerDidFire {
    if (self.animatingForward) {
        if (self.pageControl.currentPage + 1 < self.pageControl.numberOfPages) {
            [self moveToNextImageAnimated];
        } else {
            self.animatingForward = NO;
            [self moveToPreviousImageAnimated];
        }
    } else {
        if (self.pageControl.currentPage > 0) {
            [self moveToPreviousImageAnimated];
        } else {
            self.animatingForward = YES;
            [self moveToNextImageAnimated];
        }
    }
}

- (void)moveToNextImageAnimated {
    [self moveToPageAnimated:self.pageControl.currentPage + 1];
}

- (void)moveToPreviousImageAnimated {
    [self moveToPageAnimated:self.pageControl.currentPage - 1];
}

- (void)moveToPageAnimated:(NSInteger)pageNumber {
    [self scrollRectToVisible:(CGRect){pageNumber * self.bounds.size.width, 0, self.bounds.size} animated:YES];
}
@end

@implementation MAKImageGalleryViewImageCell {
    UIImageView *_imageView;
}
- (void)setImage:(UIImage *)image {
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_imageView];
    }
    _imageView.image = image;
}

- (UIImage *)image {
    return _imageView.image;
}
@end
