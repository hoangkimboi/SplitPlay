// SP2Pane.h - App Container with Custom Tab Bar and Scene Hosting
#pragma once
#import "../common.h"

@interface SP2Tab : UIView
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UIButton *closeBtn;
@property (nonatomic, strong) UIButton *swapBtn;
@property (nonatomic, strong) UIButton *zoomBtn;
@property (nonatomic, copy) void (^onTabTapped)(void);
@property (nonatomic, copy) void (^onCloseTapped)(void);
@property (nonatomic, copy) void (^onSwapTapped)(void);
@property (nonatomic, copy) void (^onZoomTapped)(void);
- (void)setTitle:(NSString *)title icon:(UIImage *)icon;
@end

@interface SP2Pane : UIView

@property (nonatomic, weak) id<SP2PaneDelegate> delegate;
@property (nonatomic, assign) NSInteger slot;
@property (nonatomic, strong) NSString *currentBundleID;
@property (nonatomic, strong) SP2Tab *tabBar;
@property (nonatomic, strong) UIView *sceneContainer;
@property (nonatomic, strong) id currentSceneView;
@property (nonatomic, strong) id currentApp;

- (instancetype)initWithFrame:(CGRect)frame slot:(NSInteger)slot;
- (void)hostAppWithBundleID:(NSString *)bundleID;
- (void)closeApp;
- (void)teardown;

@end
