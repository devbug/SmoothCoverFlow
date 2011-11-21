
#import <UIKit/UIKit.h>


@interface MPImageCacheRequest : NSOperation
- (void)setFinalSize:(CGSize)size;
- (CGSize)finalSize;
- (UIImage *)_newBitmapImageFromImage:(UIImage *)img finalSize:(struct CGSize)size;
@end



// TO DO: apply to lock screen's album art, too


%hook MPImageCacheRequest

// quality 0 : default size is (128, 128)
// quality 1 : default size is (256, 256)
- (void)setFinalSize:(CGSize)size {
	size.width	/= 2;
	size.height	/= 2;
	%orig;
}

- (UIImage *)copyImageFromImage:(UIImage *)img {
	if ([self finalSize].height > 100) {
		// NOTE: I think 160 is so blur and 180 is delicate a litte
		//       but it appear bad upscaling on 3Gs and normal playback screen.
		//       so changed to 256.
		// FIXME: specify only cover flow
		return [self _newBitmapImageFromImage:img finalSize:CGSizeMake(256,256)];
	} else 
		return %orig;
}

%end


