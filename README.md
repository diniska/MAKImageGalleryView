MAKImageGalleryView
===================

Image gallery for iOS apps, that allows to show images animated or user interacted

## Installation
The easiest way is to use [CocoaPods](http://cocoapods.org). It takes care of all required frameworks and third party dependencies:
```ruby
pod 'MAKImageGalleryView', '~> 0.0'
```

## Usage example

```objective-c
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
```
The result is:

![image alt][1]

[1]: https://raw.githubusercontent.com/diniska/MAKImageGalleryView/master/Screens/screen1.png
