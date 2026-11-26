// SP2Pane.mm - Implementation of Pane Container & Tab Bar (Part 1: SP2Tab)
#import "SP2Pane.h"

@implementation SP2Tab

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.95];
        self.layer.cornerRadius = 6.0;
        self.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
        self.clipsToBounds = YES;

        _iconView = [[UIImageView alloc] init];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.layer.cornerRadius = 4.0;
        _iconView.clipsToBounds = YES;
        [self addSubview:_iconView];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        [self addSubview:_titleLabel];

        // Three lights: Close, Swap, Zoom
        _closeBtn = [self makeLightWithColor:[UIColor colorWithRed:0.95 green:0.3 blue:0.3 alpha:1.0]
                                      action:@selector(closePressed)];
        _swapBtn  = [self makeLightWithColor:[UIColor colorWithRed:0.95 green:0.7 blue:0.2 alpha:1.0]
                                      action:@selector(swapPressed)];
        _zoomBtn  = [self makeLightWithColor:[UIColor colorWithRed:0.25 green:0.85 blue:0.4 alpha:1.0]
                                      action:@selector(zoomPressed)];

        [self addSubview:_closeBtn];
        [self addSubview:_swapBtn];
        [self addSubview:_zoomBtn];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tabPressed)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (UIButton *)makeLightWithColor:(UIColor *)color action:(SEL)sel {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = color;
    btn.layer.cornerRadius = 5.0;
    btn.clipsToBounds = YES;
    [btn addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat h = self.bounds.size.height;
    CGFloat w = self.bounds.size.width;

    _iconView.frame = CGRectMake(8, (h - 18) / 2.0, 18, 18);
    _titleLabel.frame = CGRectMake(32, 0, w - 100, h);

    CGFloat btnSize = 10.0;
    CGFloat rightPad = 8.0;
    CGFloat spacing = 6.0;

    _closeBtn.frame = CGRectMake(w - rightPad - btnSize, (h - btnSize) / 2.0, btnSize, btnSize);
    _swapBtn.frame  = CGRectMake(w - rightPad - btnSize*2 - spacing, (h - btnSize) / 2.0, btnSize, btnSize);
    _zoomBtn.frame  = CGRectMake(w - rightPad - btnSize*3 - spacing*2, (h - btnSize) / 2.0, btnSize, btnSize);
}

- (void)setTitle:(NSString *)title icon:(UIImage *)icon {
    self.titleLabel.text = title;
    self.iconView.image = icon;
}

- (void)tabPressed   { if (self.onTabTapped) self.onTabTapped(); }
- (void)closePressed { if (self.onCloseTapped) self.onCloseTapped(); }
- (void)swapPressed  { if (self.onSwapTapped) self.onSwapTapped(); }
- (void)zoomPressed  { if (self.onZoomTapped) self.onZoomTapped(); }

@end

// ─────────────────────────────────────────────
// MARK: - SP2Pane Implementation
// ─────────────────────────────────────────────

@interface SP2Pane ()
@property (nonatomic, strong) UIView *emptyPlaceholder;
@end

@implementation SP2Pane

- (instancetype)initWithFrame:(CGRect)frame slot:(NSInteger)slot {
    if (self = [super initWithFrame:frame]) {
        _slot = slot;
        self.backgroundColor = [UIColor colorWithWhite:0.06 alpha:1.0];
        self.layer.cornerRadius = 8.0;
        self.clipsToBounds = YES;

        [self setupPaneViews];
    }
    return self;
}

- (void)setupPaneViews {
    _tabBar = [[SP2Tab alloc] initWithFrame:CGRectZero];
    __weak typeof(self) weakSelf = self;
    _tabBar.onTabTapped   = ^{ [weakSelf.delegate paneWantsPicker:weakSelf]; };
    _tabBar.onSwapTapped  = ^{ [weakSelf.delegate paneWantsSwap:weakSelf]; };
    _tabBar.onZoomTapped  = ^{ [weakSelf.delegate paneWantsZoom:weakSelf]; };
    _tabBar.onCloseTapped = ^{ [weakSelf closeApp]; };
    [self addSubview:_tabBar];

    _sceneContainer = [[UIView alloc] initWithFrame:CGRectZero];
    _sceneContainer.backgroundColor = [UIColor blackColor];
    _sceneContainer.clipsToBounds = YES;
    [self addSubview:_sceneContainer];

    [self showEmptyState];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;

    _tabBar.frame = CGRectMake(0, 0, w, TAB_BAR_HEIGHT);
    _sceneContainer.frame = CGRectMake(0, TAB_BAR_HEIGHT, w, h - TAB_BAR_HEIGHT);

    if (_emptyPlaceholder) {
        _emptyPlaceholder.frame = _sceneContainer.bounds;
    }
    if (_currentSceneView && [_currentSceneView isKindOfClass:[UIView class]]) {
        ((UIView *)_currentSceneView).frame = _sceneContainer.bounds;
    }
}

- (void)showEmptyState {
    if (!_emptyPlaceholder) {
        _emptyPlaceholder = [[UIView alloc] init];
        _emptyPlaceholder.backgroundColor = [UIColor colorWithWhite:0.08 alpha:1.0];

        UIButton *plusBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [plusBtn setTitle:@"+" forState:UIControlStateNormal];
        plusBtn.titleLabel.font = [UIFont systemFontOfSize:36 weight:UIFontWeightLight];
        [plusBtn setTitleColor:[UIColor colorWithWhite:0.5 alpha:1.0] forState:UIControlStateNormal];
        plusBtn.frame = CGRectMake(0, 0, 60, 60);
        plusBtn.center = CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0);
        plusBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
                                   UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [plusBtn addTarget:self action:@selector(pickerRequested) forControlEvents:UIControlEventTouchUpInside];
        [_emptyPlaceholder addSubview:plusBtn];
    }
    [_sceneContainer addSubview:_emptyPlaceholder];
    [_tabBar setTitle:@"Chọn ứng dụng" icon:nil];
}

- (void)pickerRequested {
    [self.delegate paneWantsPicker:self];
}

- (void)hostAppWithBundleID:(NSString *)bundleID {
    if (!bundleID || bundleID.length == 0) return;
    self.currentBundleID = bundleID;

    [_emptyPlaceholder removeFromSuperview];
    _emptyPlaceholder = nil;

    id appController = objcInvoke(objc_getClass("SBApplicationController"), @"sharedInstance");
    id app = objcInvoke_1(appController, @"applicationWithBundleIdentifier:", bundleID);
    self.currentApp = app;

    if (app) {
        NSString *displayName = objcInvoke(app, @"displayName") ?: bundleID;
        [_tabBar setTitle:displayName icon:nil];

        @try {
            id sceneHandle = objcInvoke_1(objc_getClass("SBDeviceApplicationSceneHandle"),
                                          @"sceneHandleForApplication:", app);
            if (!sceneHandle) {
                sceneHandle = objcInvoke(app, @"mainSceneHandle");
            }
            if (sceneHandle) {
                id sceneView = objcInvoke_1([objc_getClass("SBDeviceApplicationSceneView") alloc],
                                            @"initWithApplicationSceneHandle:", sceneHandle);
                if (sceneView && [sceneView isKindOfClass:[UIView class]]) {
                    if (_currentSceneView && [_currentSceneView superview] == _sceneContainer) {
                        [_currentSceneView removeFromSuperview];
                    }
                    _currentSceneView = sceneView;
                    ((UIView *)sceneView).frame = _sceneContainer.bounds;
                    ((UIView *)sceneView).autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                    [_sceneContainer addSubview:(UIView *)sceneView];
                }
            }
        } @catch (NSException *e) {
            NSLog(@"[SplitPlay2] Failed to host scene for %@: %@", bundleID, e);
        }
    }
}

- (void)closeApp {
    if (_currentSceneView && [_currentSceneView superview] == _sceneContainer) {
        [_currentSceneView removeFromSuperview];
        _currentSceneView = nil;
    }
    _currentApp = nil;
    _currentBundleID = nil;
    [self showEmptyState];
}

- (void)teardown {
    [self closeApp];
}

@end

