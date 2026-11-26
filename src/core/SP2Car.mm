// SP2Car.mm - Implementation of CarPlay Display Management
#import "SP2Car.h"
#import "../ui/SP2Workspace.h"
#import "../hud/SP2Bubble.h"

int (*orig_BKSDisplayServicesSetScreenBlanked)(int) = NULL;

@implementation SP2Car

+ (instancetype)sharedInstance {
    static SP2Car *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SP2Car alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _hideDock = NO;
        _screenZoom = 1.0;
        [self reloadPreferences];
        [self setupNotificationObservers];
    }
    return self;
}

- (void)reloadPreferences {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH] ?: @{};
    self.hideDock = [prefs[@"carDock"] ?: @NO boolValue];
    NSNumber *zoomNum = prefs[@"carZoom"];
    if (zoomNum) {
        self.screenZoom = [zoomNum floatValue] / 100.0f;
        if (self.screenZoom <= 0.2f) self.screenZoom = 1.0f;
    }
}

- (void)setupNotificationObservers {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(carPlayIsConnectedChanged:)
               name:@"CarPlayIsConnectedDidChange" object:nil];
    [nc addObserver:self selector:@selector(handlePrefsChanged)
               name:PREF_CHANGED_NOTIFICATION object:nil];
}

- (void)handlePrefsChanged {
    [self reloadPreferences];
    if (self.workspace) {
        [self.workspace setNeedsLayout];
    }
}

- (id)getCarPlayCADisplay {
    id carplayAV = objcInvoke(objc_getClass("AVExternalDevice"), @"currentCarPlayExternalDevice");
    if (!carplayAV) return nil;

    NSArray *screenIDs = objcInvoke(carplayAV, @"screenIDs");
    if (!screenIDs || screenIDs.count == 0) return nil;
    NSString *uid = screenIDs[0];

    for (id display in objcInvoke(objc_getClass("CADisplay"), @"displays")) {
        if ([uid isEqualToString:objcInvoke(display, @"uniqueId")]) {
            return display;
        }
    }
    return nil;
}

- (void)carPlayIsConnectedChanged:(NSNotification *)note {
    BOOL connected = [[note userInfo][@"connected"] boolValue];
    if (connected) {
        [self carPlayDidConnect];
    } else {
        [self carPlayDidDisconnect];
    }
}

- (void)carPlayDidConnect {
    if (self.isCarPlayConnected) return;
    NSLog(@"[SplitPlay2] CarPlay Did Connect");

    id display = [self getCarPlayCADisplay];
    if (!display) {
        NSLog(@"[SplitPlay2] CADisplay for CarPlay not found yet, retrying in 1s");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self carPlayDidConnect];
        });
        return;
    }

    self.isCarPlayConnected = YES;

    // Create UIRootSceneWindow on CarPlay Display using carplay-cast architecture
    id dispConfig = objcInvoke_2([objc_getClass("FBSDisplayConfiguration") alloc],
                                 @"initWithCADisplay:isMainDisplay:", display, 0);

    self.rootWindow = objcInvoke_1([objc_getClass("UIRootSceneWindow") alloc],
                                   @"initWithDisplayConfiguration:", dispConfig);

    CGRect bounds = [self.rootWindow bounds];
    [self.rootWindow.layer setCornerRadius:12.0f];
    [self.rootWindow.layer setMasksToBounds:YES];

    // Main workspace holding left and right split panes
    CGFloat dockOffset = self.hideDock ? 0.0 : CARPLAY_DOCK_WIDTH;
    CGRect workFrame = CGRectMake(dockOffset, 0, bounds.size.width - dockOffset, bounds.size.height);

    self.workspace = [[SP2Workspace alloc] initWithFrame:workFrame];
    [self.rootWindow addSubview:self.workspace];

    // Speed HUD Bubble
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH] ?: @{};
    BOOL hudEnabled = [prefs[@"hud"] ?: @YES boolValue];
    if (hudEnabled) {
        self.bubble = [[SP2Bubble alloc] initWithFrame:CGRectMake(workFrame.origin.x + 20, 20, 68, 68)];
        [self.rootWindow addSubview:self.bubble];
        [self.rootWindow bringSubviewToFront:self.bubble];
    }

    [self.rootWindow setAlpha:0];
    [self.rootWindow setHidden:NO];

    // Keep screen awake/active when locked (BKSDisplayServicesSetScreenBlanked)
    void *bks = dlopen("/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices", RTLD_NOW);
    if (bks) {
        orig_BKSDisplayServicesSetScreenBlanked = (int (*)(int))dlsym(bks, "BKSDisplayServicesSetScreenBlanked");
        if (orig_BKSDisplayServicesSetScreenBlanked) {
            orig_BKSDisplayServicesSetScreenBlanked(0);
        }
    }

    [UIView animateWithDuration:0.4 animations:^{
        [self.rootWindow setAlpha:1.0];
    }];

    // Auto-open last layout or default apps
    BOOL autoOpen = [prefs[@"autoOpen"] ?: @YES boolValue];
    if (autoOpen) {
        NSString *leftApp = prefs[@"leftApp"] ?: @"com.google.Maps";
        NSString *rightApp = prefs[@"rightApp"] ?: @"com.google.ios.youtube";
        [self.workspace hostApp:leftApp inSlot:0];
        [self.workspace hostApp:rightApp inSlot:1];
    }
}

- (void)carPlayDidDisconnect {
    if (!self.isCarPlayConnected) return;
    NSLog(@"[SplitPlay2] CarPlay Did Disconnect");
    self.isCarPlayConnected = NO;

    if (self.workspace) {
        [self.workspace teardown];
        [self.workspace removeFromSuperview];
        self.workspace = nil;
    }
    if (self.bubble) {
        [self.bubble stop];
        [self.bubble removeFromSuperview];
        self.bubble = nil;
    }
    if (self.rootWindow) {
        [self.rootWindow setHidden:YES];
        self.rootWindow = nil;
    }
}

- (void)launchAppOnCarPlay:(NSString *)bundleID slot:(NSInteger)slot {
    if (!self.isCarPlayConnected || !self.workspace) return;
    [self.workspace hostApp:bundleID inSlot:slot];
}

@end
