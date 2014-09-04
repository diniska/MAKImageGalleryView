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
@property (assign, nonatomic) UIViewContentMode imageContentMode;
@property (strong, nonatomic) NSOperation *imageLoadingOperation;
@property (assign, nonatomic) NSUInteger blockLoadingId;
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

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [(UICollectionViewFlowLayout *)self.collectionViewLayout setItemSize:self.bounds.size];
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
    if (self.pageControl.numberOfPages != 0) {
        const CGFloat onePageWidth = self.bounds.size.width;
        const CGFloat currentPageCenterOffset = (self.contentOffset.x + self.bounds.size.width / 2);
        self.pageControl.currentPage = currentPageCenterOffset / onePageWidth;
    }
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

- (void)loadImageForRow:(NSInteger)row withOperationToCell:(MAKImageGalleryViewImageCell *)cell {
    cell.imageLoadingOperation = [NSBlockOperation blockOperationWithBlock:^{
        UIImage *const image = [self.imageGalleryDataSource imageInGalery:self atIndex:row];
        cell.image = image;
        cell.imageLoadingOperation = nil;
    }];
    [[NSOperationQueue mainQueue] addOperation:cell.imageLoadingOperation];
}

- (void)loadImageForRow:(NSInteger)row withBlockToCell:(MAKImageGalleryViewImageCell *)cell {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSUInteger key = random();
        cell.blockLoadingId = key;
        [self.imageGalleryDataSource loadImageInGallery:self atIndex:row callback:^(UIImage *image) {
            if (cell.blockLoadingId == key) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (cell.blockLoadingId == key) { //if still not reused
                        cell.image = image;
                    }
                });
            }
        }];
    });
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.imageGalleryDataSource numberOfImagesInGallery:self];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MAKImageGalleryViewImageCell *res = [collectionView dequeueReusableCellWithReuseIdentifier:kImageCellReusableId forIndexPath:indexPath];
    
    if ([self.imageGalleryDataSource respondsToSelector:@selector(imageInGalery:atIndex:)]) {
        [self loadImageForRow:indexPath.row withOperationToCell:res];
    } else if ([self.imageGalleryDataSource respondsToSelector:@selector(loadImageInGallery:atIndex:callback:)]) {
        [self loadImageForRow:indexPath.row withBlockToCell:res];
    }
    
    
    if ([self.imageGalleryDataSource respondsToSelector:@selector(imageGallery:contentModeForImageAtIndex:)]) {
        res.imageContentMode = [self.imageGalleryDataSource imageGallery:self contentModeForImageAtIndex:indexPath.row];
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

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    [self setSelectedIndex:selectedIndex animated:NO];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated {
    if (self.selectedIndex != selectedIndex) {
        [self moveToPageAnimated:selectedIndex animated:animated];
    }
}

#pragma mark - Getters
- (BOOL)changeImagesAutormatically {
    return self.imageChangingTimer != nil;
}

- (NSInteger)selectedIndex {
    return self.pageControl.currentPage;
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
    [self moveToPageAnimated:self.pageControl.currentPage + 1 animated:YES];
}

- (void)moveToPreviousImageAnimated {
    [self moveToPageAnimated:self.pageControl.currentPage - 1 animated:YES];
}

- (void)moveToPageAnimated:(NSInteger)pageNumber animated:(BOOL)animated {
    [self scrollRectToVisible:(CGRect){pageNumber * self.bounds.size.width, 0, self.bounds.size} animated:animated];
}

@end

@implementation MAKImageGalleryViewImageCell {
    UIImageView *_imageView;
    UIViewContentMode _imageContentMode;
}
- (void)setImage:(UIImage *)image {
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _imageView.contentMode = self.imageContentMode;
        [self addSubview:_imageView];
    }
    _imageView.image = image;
}

- (UIImage *)image {
    return _imageView.image;
}

- (void)prepareForReuse {
    [_imageLoadingOperation cancel];
    _imageView.image = nil;
    _imageLoadingOperation = nil;
    _blockLoadingId = 0;
    _imageContentMode = UIViewContentModeScaleToFill;
    _imageView.contentMode = _imageContentMode;
}

- (void)setImageContentMode:(UIViewContentMode)imageContentMode {
    _imageContentMode = imageContentMode;
    _imageView.contentMode = imageContentMode;
}
@end
