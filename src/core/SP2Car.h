// SP2Car.h - CarPlay Session & Display Management
#pragma once
#import "../common.h"

@class SP2Workspace, SP2Bubble;

@interface SP2Car : NSObject

@property (nonatomic, strong) UIWindow *rootWindow;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) SP2Workspace *workspace;
@property (nonatomic, strong) SP2Bubble *bubble;
@property (nonatomic, assign) BOOL isCarPlayConnected;
@property (nonatomic, assign) BOOL hideDock;
@property (nonatomic, assign) CGFloat screenZoom;

+ (instancetype)sharedInstance;

- (void)carPlayDidConnect;
- (void)carPlayDidDisconnect;
- (void)launchAppOnCarPlay:(NSString *)bundleID slot:(NSInteger)slot;
- (void)reloadPreferences;
- (id)getCarPlayCADisplay;

@end
