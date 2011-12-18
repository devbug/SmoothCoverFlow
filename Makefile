SDKVERSION=5.0

include theos/makefiles/common.mk

TWEAK_NAME = SmoothCoverFlow
SmoothCoverFlow_FILES = Tweak.xm
SmoothCoverFlow_FRAMEWORKS = Foundation CoreFoundation UIKit MediaPlayer CoreGraphics
SmoothCoverFlow_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk
