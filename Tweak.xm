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

#include <sys/types.h>
#include <sys/sysctl.h>



typedef NSUInteger DeviceType;
enum {
	DeviceTypeUnsupported		= 0,					// 00000000(2)
	DeviceTypeiPodTouch3G		= 1,					// 00000001(2)
	DeviceTypeiPhone3Gs			= (1 << 1) + 1,			// 00000011(2)
	DeviceTypeiPodTouch4G		= 1 << 2,				// 00000100(2)
	DeviceTypeiPhone4			= (1 << 3) + (1 << 2),	// 00001100(2)
	DeviceTypeiPad				= 1 << 4				// 00010000(2)
};

static DeviceType this_device = DeviceTypeiPhone4;


@interface MPImageCacheRequest : NSOperation
- (void)setFinalSize:(CGSize)size;
- (CGSize)finalSize;
- (UIImage *)_newBitmapImageFromImage:(UIImage *)img finalSize:(struct CGSize)size;
@end



%hook MPImageCacheRequest

// quality 0 : default size is (128, 128)
// quality 1 : default size is (256, 256)
- (void)setFinalSize:(CGSize)size {
	size.width	/= 2;
	size.height	/= 2;
	%orig;
}

- (UIImage *)copyImageFromImage:(UIImage *)img {
	if ([self finalSize].height > 100) {					// high quality
		if ([NSStringFromClass([self class]) isEqualToString:@"IUMediaItemCoverFlowImageRequest"]) {
			if ((this_device & DeviceTypeiPhone3Gs) != 0)		// no retina
				return [self _newBitmapImageFromImage:img finalSize:CGSizeMake(256,256)];
			else if ((this_device & DeviceTypeiPhone4) != 0)	// retina
				return [self _newBitmapImageFromImage:img finalSize:CGSizeMake(170,170)];
		} else {	// NSStringFromClass([self class]) == @"MPMediaItemImageRequest"
			if ((this_device & (DeviceTypeiPhone3Gs | DeviceTypeiPhone4)) != 0)
				return [self _newBitmapImageFromImage:img finalSize:CGSizeMake(320,320)];
		}
	}
	
	return %orig;
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
	
	%init;
}


