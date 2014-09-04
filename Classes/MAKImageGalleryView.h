//
//  MAKImageGalleryView.h
//  MAKImageGalleryView
//
//  Created by Denis Chaschin on 01.09.14.
//  Copyright (c) 2014 diniska. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MAKImageGalleryView;

@protocol MAKImageGalleryViewDataSource <NSObject>
- (NSInteger)numberOfImagesInGallery:(MAKImageGalleryView *)galleryView;
@optional
- (UIViewContentMode)imageGallery:(MAKImageGalleryView *)galleryView contentModeForImageAtIndex:(NSInteger)index;
/**
 * This method have to return image. Method called asynchronously
 */
- (UIImage *)imageInGalery:(MAKImageGalleryView *)galleryView atIndex:(NSInteger)index;
/**
 * You have to implement this method or -imageInGalery:atIndex: 
 * Priority of method -imageInGalery:atIndex: is bigger
 */
- (void)loadImageInGallery:(MAKImageGalleryView *)galleryView atIndex:(NSInteger)index callback:(void(^)(UIImage *))callback;
@end


@interface MAKImageGalleryView : UICollectionView
@property (weak, nonatomic) id<MAKImageGalleryViewDataSource> imageGalleryDataSource;
@property (assign, nonatomic) BOOL changeImagesAutormatically;
/**
 * Image will be shown during this time
 * 1 second by default
 * Used when changeImagesAutormatically = YES
 */
@property (assign, nonatomic) NSTimeInterval imageChangingDelay;
@property (assign, nonatomic) NSInteger selectedIndex;
- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated;
@end
