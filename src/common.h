// common.h - Core Definitions for SplitPlay2 (carplay-cast based)
#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <CoreLocation/CoreLocation.h>

#ifndef typeof
#define typeof __typeof__
#endif

#define PREF_PATH @"/var/jb/var/mobile/Library/Preferences/com.splitplay.preferences.plist"
#define PREF_CHANGED_NOTIFICATION @"com.splitplay.preferences.changed"
#define SPLITPLAY_LAUNCH_NOTIFICATION @"com.splitplay.launch"

#define CARPLAY_DOCK_WIDTH 48.0
#define DEFAULT_DIVIDER_WIDTH 12.0
#define TAB_BAR_HEIGHT 28.0

#define objcInvokeT(a, b, t) ((t (*)(id, SEL))objc_msgSend)(a, NSSelectorFromString(b))
#define objcInvoke(a, b) objcInvokeT(a, b, id)
#define objcInvoke_1(a, b, c) ((id (*)(id, SEL, __typeof__(c)))objc_msgSend)(a, NSSelectorFromString(b), c)
#define objcInvoke_2(a, b, c, d) ((id (*)(id, SEL, __typeof__(c), __typeof__(d)))objc_msgSend)(a, NSSelectorFromString(b), c, d)
#define objcInvoke_3(a, b, c, d, e) ((id (*)(id, SEL, __typeof__(c), __typeof__(d), __typeof__(e)))objc_msgSend)(a, NSSelectorFromString(b), c, d, e)

#define getIvar(object, ivar) [object valueForKey:ivar]
#define setIvar(object, ivar, value) [object setValue:value forKey:ivar]

typedef NS_ENUM(NSInteger, SPSplitRatio) {
    SPSplitRatio50_50 = 0,
    SPSplitRatio60_40 = 1,
    SPSplitRatio40_60 = 2,
    SPSplitRatio70_30 = 3,
    SPSplitRatio30_70 = 4,
    SPSplitRatioFullLeft = 5,
    SPSplitRatioFullRight = 6,
};

@class SP2Pane, SP2Workspace, SP2Car;

@protocol SP2PaneDelegate <NSObject>
- (void)paneWantsPicker:(SP2Pane *)pane;
- (void)paneWantsSwap:(SP2Pane *)pane;
- (void)paneWantsZoom:(SP2Pane *)pane;
- (void)paneWantsClose:(SP2Pane *)pane;
- (void)pane:(SP2Pane *)pane didSelectApp:(NSString *)bundleID;
@end

extern int (*orig_BKSDisplayServicesSetScreenBlanked)(int);

