TARGET := iphone:clang:16.5:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SplitPlay2

SplitPlay2_FILES = \
	src/hooks/Tweak.x \
	src/core/SP2Car.mm \
	src/ui/SP2Workspace.mm \
	src/ui/SP2Pane.mm \
	src/ui/SP2Dividers.mm \
	src/ui/SP2Picker.mm \
	src/hud/SP2Bubble.mm

SplitPlay2_CFLAGS = -fobjc-arc -Wno-unused-variable -Wno-unused-property-ivar
SplitPlay2_CCFLAGS = -std=c++17 -fobjc-arc
SplitPlay2_FRAMEWORKS = UIKit CoreGraphics QuartzCore CoreLocation
SplitPlay2_PRIVATE_FRAMEWORKS = SpringBoard SpringBoardServices FrontBoardServices BackBoardServices
SplitPlay2_LIBRARIES = substrate

# Preferences Bundle
BUNDLE_NAME = SplitPlay2Prefs
SplitPlay2Prefs_FILES = prefs/SplitPlayPrefsListController.mm
SplitPlay2Prefs_INSTALL_PATH = /var/jb/Library/PreferenceBundles
SplitPlay2Prefs_FRAMEWORKS = UIKit
SplitPlay2Prefs_PRIVATE_FRAMEWORKS = Preferences
SplitPlay2Prefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
