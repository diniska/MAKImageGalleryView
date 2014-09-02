//
//  MAKViewController.m
//  MAKImageGalleryView
//
//  Created by Denis Chaschin on 01.09.14.
//  Copyright (c) 2014 diniska. All rights reserved.
//

#import "MAKViewController.h"
#import "MAKImageGalleryView.h"

@interface MAKViewController () <MAKImageGalleryViewDataSource>
@property (weak, nonatomic) IBOutlet MAKImageGalleryView *imageGalleryView;
@property (weak, nonatomic) IBOutlet MAKImageGalleryView *animatedImageGalleryView;
@end

@implementation MAKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageGalleryView.imageGalleryDataSource = self;
    
    self.animatedImageGalleryView.imageGalleryDataSource = self;
    self.animatedImageGalleryView.imageChangingDelay = 3;
    self.animatedImageGalleryView.changeImagesAutormatically = YES;
}

#pragma mark - MAKImageGalleryViewDataSource
- (NSInteger)numberOfImagesInGallery:(MAKImageGalleryView *)galleryView {
    return 4;
}

- (UIImage *)imageInGalery:(MAKImageGalleryView *)galleryView atIndex:(NSInteger)index {
    NSString *const imageName = [NSString stringWithFormat:@"image%i.jpg", index];
    return [UIImage imageNamed:imageName];
}

- (UIViewContentMode)imageGallery:(MAKImageGalleryView *)galleryView contentModeForImageAtIndex:(NSInteger)index {
    return UIViewContentModeScaleAspectFill;
}
@end
