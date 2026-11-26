TARGET := iphone:clang:16.5:14.0
ARCHS = arm64 arm64e

THEOS_PACKAGE_SCHEME ?= rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SidePlay2HUDAIMaps

SidePlay2HUDAIMaps_FILES = src/hooks/SidePlay2HUDAIMaps.x
SidePlay2HUDAIMaps_CFLAGS = -fobjc-arc -Wno-unused-variable
SidePlay2HUDAIMaps_FRAMEWORKS = UIKit CoreLocation AVFoundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"





