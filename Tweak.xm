//
//  SmoothCoverFlow
//  
//  
//  Copyright (c) 2011 deVbug
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//


#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AppSupport/CPLRUDictionary.h>

#include <sys/types.h>
#include <sys/sysctl.h>



#define MAX_CACHES				5


typedef NSUInteger DeviceType;
enum {
	DeviceTypeUnsupported		= 0,					// 00000000(2)
	DeviceTypeiPodTouch3G		= 1 << 0,				// 00000001(2)
	DeviceTypeiPhone3Gs			= 1 << 1,				// 00000010(2)
	DeviceTypeiPodTouch4G		= 1 << 2,				// 00000100(2)
	DeviceTypeiPhone4			= 1 << 3,				// 00001000(2)
	DeviceTypeiPad				= 1 << 4,				// 00010000(2)
	
	DeviceTypeUnknown			= 0,					// 00000000(2)
	DeviceTypeNoRetina			= 3 << 1,				// 00000011(2)
	DeviceTypeRetina			= 3 << 2,				// 00001100(2)
	//DeviceTypeNormaliPad		= 3 << 4				// 00110000(2)
};

static DeviceType this_device = DeviceTypeiPhone4;

static NSMutableArray *cachedImageKey = nil;



// http://alones.kr/1384
// Copyright 2009 삼성전자. All rights reserved.
UIImage *resizedImage(UIImage *inImage, CGSize newSize)
{
	CGSize newSize2 = CGSizeMake(newSize.width * ((this_device & DeviceTypeRetina) != 0 ? 2 : 1), newSize.height * ((this_device & DeviceTypeRetina) != 0 ? 2 : 1));
	CGSize thumbSize = newSize2;
	if (inImage.size.width > inImage.size.height)
		thumbSize = CGSizeMake(newSize2.width, newSize2.height * (inImage.size.height / inImage.size.width));
	else
		thumbSize = CGSizeMake(newSize2.width * (inImage.size.width / inImage.size.height), newSize2.height);
	
	if (inImage.size.width < thumbSize.width && inImage.size.height < thumbSize.height)
		return inImage;
	
	CGImageRef			imageRef = [inImage CGImage];
	CGImageAlphaInfo	alphaInfo = CGImageGetAlphaInfo(imageRef);
	
	// There's a wierdness with kCGImageAlphaNone and CGBitmapContextCreate
	// see Supported Pixel Formats in the Quartz 2D Programming Guide
	// Creating a Bitmap Graphics Context section
	// only RGB 8 bit images with alpha of kCGImageAlphaNoneSkipFirst, kCGImageAlphaNoneSkipLast, kCGImageAlphaPremultipliedFirst,
	// and kCGImageAlphaPremultipliedLast, with a few other oddball image kinds are supported
	// The images on input here are likely to be png or jpeg files
	if (alphaInfo == kCGImageAlphaNone)
		alphaInfo = kCGImageAlphaNoneSkipLast;
	
	// Build a bitmap context that's the size of the thumbSize
	CGFloat bytesPerRow;
	
	if( thumbSize.width > thumbSize.height ) {
		bytesPerRow = 4 * thumbSize.width;
	} else {
		bytesPerRow = 4 * thumbSize.height;
	}
	
	CGContextRef bitmap = CGBitmapContextCreate(
												NULL,
												thumbSize.width,		// width
												thumbSize.height,		// height
												8, //CGImageGetBitsPerComponent(imageRef),	// really needs to always be 8
												bytesPerRow, //4 * thumbSize.width,	// rowbytes
												CGImageGetColorSpace(imageRef),
												alphaInfo
												);
	
	CGRect thumbRect = CGRectMake(0, 0, thumbSize.width, thumbSize.height);
	// Draw into the context, this scales the image
	CGContextDrawImage(bitmap, thumbRect, imageRef);
	
	// Get an image from the context and a UIImage
	CGImageRef	ref = CGBitmapContextCreateImage(bitmap);
	UIImage*	result = [UIImage imageWithCGImage:ref];
	
	CGContextRelease(bitmap);	// ok if NULL
	CGImageRelease(ref);
	
	return result;
}



@interface MPImageCacheRequest : NSOperation
- (void)setFinalSize:(CGSize)size;
- (CGSize)finalSize;
- (UIImage *)_newBitmapImageFromImage:(UIImage *)img finalSize:(struct CGSize)size;
@end

@interface MPMediaItemArtwork (Private)
- (UIImage *)coverFlowImageWithSize:(struct CGSize)size;
- (NSData *)imageDataWithSize:(struct CGSize)size atPlaybackTime:(double)time;
- (UIImage *)imageWithSize:(struct CGSize)size atPlaybackTime:(double)time;
- (UIImage *)imageWithSize:(struct CGSize)size;
- (NSData *)albumImageDataWithSize:(struct CGSize)size;
- (UIImage *)albumImageWithSize:(struct CGSize)size;
@end

@interface MPConcreteMediaItemArtwork : MPMediaItemArtwork {
	unsigned long long _itemPersistentID;
}
- (struct CGRect)bounds;
- (UIImage *)coverFlowImageWithSize:(struct CGSize)size;
- (NSData *)imageDataWithSize:(struct CGSize)size atPlaybackTime:(double)time;
- (UIImage *)imageWithSize:(struct CGSize)size atPlaybackTime:(double)time;
- (NSData *)albumImageDataWithSize:(struct CGSize)size;
- (UIImage *)albumImageWithSize:(struct CGSize)size;
- (void)_fixupBoundsForImage:(id)image;
@end

@interface MPImageCache : NSObject {
	CPLRUDictionary *_cachedImages;
}
+ (id)sharedImageCache;
- (UIImage *)_cachedImageForKey:(NSString *)key;
- (void)_cacheImage:(UIImage *)image forKey:(NSString *)key;
- (void)loadImageForRequest:(id)arg1 asynchronously:(BOOL)arg2 completionHandler:(id)arg3;
@end

@interface UIApplication (Private)
- (BOOL)_isActivated;
@end

@interface IUMediaQueryNowPlayingItem : NSObject // MPAVItem
- (MPMediaItem *)mediaItem;
- (id)initWithMediaItem:(MPMediaItem *)mediaItem;
@end
@interface IUNowPlayingObserver : NSObject
- (IUMediaQueryNowPlayingItem *)_currentItem;
@end
@interface IUPlaybackViewController : UIViewController
- (void)_reloadForTransitionFromItem:(id)arg1 toItem:(id)arg2 animated:(BOOL)arg3;
@end
@interface IUMixedPlaybackViewController : IUPlaybackViewController
- (void)setItem:(id)arg1 animated:(BOOL)arg2;
@end
@interface MediaApplication : NSObject {
	IUNowPlayingObserver *_nowPlayingObserver;
}
- (UIViewController *)IUTopViewController;
@end

@interface MPPlaybackTitlesView : UIView
@end



%hook MPImageCacheRequest

// Album view 
// low quality	: (55, 55)
// high quality	: (88, 88)
//
// Coverflow and Playback view
// low quality (0)	: default size is (128, 128)
// high quality (1)	: default size is (256, 256)
- (void)setFinalSize:(CGSize)size {
	if (![[UIApplication sharedApplication] _isActivated]) {
		if (size.width > 90 || size.height > 90) {
			%orig(CGSizeMake(64,64));
			return;
		}
	}
	
	if ([NSStringFromClass([self class]) isEqualToString:@"IUMediaItemCoverFlowImageRequest"]) {
		if (size.width > 90 || size.height > 90) {
			size.width	/= 2;
			size.height	/= 2;
		}
	}
	%orig;
}

- (UIImage *)copyImageFromImage:(UIImage *)img {
	if (![[UIApplication sharedApplication] _isActivated])
		return %orig;
	
	if ([self finalSize].height > 90) {						// high quality
		if ([NSStringFromClass([self class]) isEqualToString:@"IUMediaItemCoverFlowImageRequest"]) {
			if ((this_device & DeviceTypeNoRetina) != 0) {		// no retina
				if (img.size.width > 256 || img.size.height > 256) {
					return [self _newBitmapImageFromImage:img finalSize:CGSizeMake(256,256)];
				}
			}
			else if ((this_device & DeviceTypeRetina) != 0) {	// retina
				if (img.size.width > 170 || img.size.height > 170) {
					return [self _newBitmapImageFromImage:img finalSize:CGSizeMake(170,170)];
				}
			}
		} else {	// NSStringFromClass([self class]) == @"MPMediaItemImageRequest"
			if ((this_device & (DeviceTypeNoRetina | DeviceTypeRetina)) != 0) {
				if (img.size.width > 320 || img.size.height > 320) {
					return [self _newBitmapImageFromImage:img finalSize:CGSizeMake(320,320)];
				}
			}
		}
	}
	
	return %orig;
}

%end


%hook MPConcreteMediaItemArtwork

- (id)imageDataWithSize:(struct CGSize)size atPlaybackTime:(double)time {
	if ([[UIApplication sharedApplication] _isActivated])
		return %orig;
	
	if (self.bounds.size.width > size.width || self.bounds.size.height > size.height) {
		unsigned long long itemPersistentID = MSHookIvar<unsigned long long>(self, "_itemPersistentID");
		MPImageCache *cache = [objc_getClass("MPImageCache") sharedImageCache];
		NSString *key = [NSString stringWithFormat:@"%llu", itemPersistentID];
		UIImage *image = [cache _cachedImageForKey:key];
		
		if (cache == nil || image == nil) {
			image = [self imageWithSize:size];
			image = resizedImage(image, size);
			
			if (cache && image) {
				if (cachedImageKey.count >= MAX_CACHES) {
					CPLRUDictionary *cachedImages = MSHookIvar<CPLRUDictionary *>(cache, "_cachedImages");
					NSString *tmpKey = [cachedImageKey objectAtIndex:0];
					[cachedImages removeObjectForKey:tmpKey];
					[cachedImageKey removeObjectAtIndex:0];
				}
				[cache _cacheImage:image forKey:key];
				[cachedImageKey addObject:key];
			}
		}
		
		if (image) {
			//NSLog(@"%@", NSStringFromCGSize([image size]));
			MPMediaItemArtwork *temp = [[MPMediaItemArtwork alloc] initWithImage:image];
			NSData *data = [temp imageDataWithSize:image.size atPlaybackTime:time];
			[temp release];
			return data;
		}
		
		return nil;
	}
	
	return %orig;
}

%end


%hook IUNowPlayingAlbumFrontViewController

- (id)copyOverlayViewForTransitionToItem:(IUMediaQueryNowPlayingItem *)nowPlayingItem {
	if (nowPlayingItem == nil) {
		MediaApplication *appDelegate = [[UIApplication sharedApplication] delegate];
		if ([appDelegate respondsToSelector:@selector(IUTopViewController)]) {
			IUNowPlayingObserver *nowplaying = MSHookIvar<IUNowPlayingObserver *>(appDelegate, "_nowPlayingObserver");
			return %orig(nowplaying._currentItem);
		}
	}
	return %orig;
}

%end


%hook MediaApplication

- (void)applicationDidBecomeActive:(UIApplication *)application {
	%orig;
	
	if ([self.IUTopViewController respondsToSelector:@selector(_reloadForTransitionFromItem:toItem:animated:)]) {
		IUNowPlayingObserver *nowplaying = MSHookIvar<IUNowPlayingObserver *>(self, "_nowPlayingObserver");
		[(IUPlaybackViewController *)(self.IUTopViewController) _reloadForTransitionFromItem:nowplaying._currentItem toItem:nil animated:NO];
		[(IUPlaybackViewController *)(self.IUTopViewController) _reloadForTransitionFromItem:nil toItem:nowplaying._currentItem animated:NO];
	}
}

%end


%hook MPPlaybackTitlesView

- (void)layoutSubviews {
	self.frame = CGRectMake(55, 2, 210, 40);
	%orig;
}

%end


%ctor
{
	size_t size;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);
	char *name = (char *)malloc(size);
	sysctlbyname("hw.machine", name, &size, NULL, 0);
	
	if (strstr(name, "iPhone2"))
		this_device = DeviceTypeiPhone3Gs;
	else if (strstr(name, "iPod3"))
		this_device = DeviceTypeiPodTouch3G;
	else if (strstr(name, "iPad"))
		this_device = DeviceTypeiPad;
	else if (strstr(name, "iPhone1"))
		this_device = DeviceTypeUnsupported;
	else if (strstr(name, "iPod1") || strstr(name, "iPod2"))
		this_device = DeviceTypeUnsupported;
	else if (strstr(name, "iPod"))			// above iPodTouch 4G
		this_device = DeviceTypeiPodTouch4G;
	else if (strstr(name, "iPhone"))		// above iPhone 4
		this_device = DeviceTypeiPhone4;
	else
		this_device = DeviceTypeUnsupported;
	
	free(name);
	
	cachedImageKey = [[NSMutableArray alloc] init];
	
	%init;
}


