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
- (UIImage *)imageInGalery:(MAKImageGalleryView *)galleryView atIndex:(NSInteger)index;
@optional
- (UIViewContentMode)imageGallery:(MAKImageGalleryView *)galleryView contentModeForImageAtIndex:(NSInteger)index;
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
@end
