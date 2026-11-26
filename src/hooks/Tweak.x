// Tweak.x - Core Hooks for SpringBoard, CarPlay, and User Applications
#import "../common.h"
#import "../core/SP2Car.h"

// ─────────────────────────────────────────────
// MARK: - SpringBoard Hooks
// ─────────────────────────────────────────────
%group SPRINGBOARD

%hook SBSuspendedUnderLockManager

// Prevent apps hosted in SplitPlay from being suspended when iPhone locks
- (BOOL)_shouldBeBackgroundUnderLockForScene:(id)scene withSettings:(id)settings {
    BOOL shouldBackground = %orig;
    if (shouldBackground && [[SP2Car sharedInstance] isCarPlayConnected]) {
        return NO;
    }
    return shouldBackground;
}

%end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    NSLog(@"[SplitPlay2] SpringBoard Did Finish Launching");

    // Initialize SP2Car singleton
    [SP2Car sharedInstance];

    // Listen to CarPlay launch requests
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
        selector:@selector(handleSplitPlayLaunchNotification:)
        name:SPLITPLAY_LAUNCH_NOTIFICATION object:nil];
}

%new
- (void)handleSplitPlayLaunchNotification:(NSNotification *)note {
    NSString *bundleID = [note userInfo][@"identifier"];
    NSInteger slot = [[note userInfo][@"slot"] ?: @0 integerValue];
    [[SP2Car sharedInstance] launchAppOnCarPlay:bundleID slot:slot];
}

%end

%end // SPRINGBOARD

// ─────────────────────────────────────────────
// MARK: - CarPlay App Library Hooks
// ─────────────────────────────────────────────
%group CARPLAY

static void addCarPlayDeclarations(id appLibrary) {
    for (id appInfo in objcInvoke(appLibrary, @"allInstalledApplications")) {
        if (getIvar(appInfo, @"_carPlayDeclaration") == nil) {
            NSString *bid = objcInvoke(appInfo, @"bundleIdentifier");
            if ([bid containsString:@"com.apple."] && ![bid containsString:@"Maps"] && ![bid containsString:@"Music"]) {
                continue;
            }

            id declaration = [[objc_getClass("CRCarPlayAppDeclaration") alloc] init];
            objcInvoke_1(declaration, @"setSupportsTemplates:", 0);
            objcInvoke_1(declaration, @"setSupportsMaps:", 1);
            objcInvoke_1(declaration, @"setBundleIdentifier:", bid);
            objcInvoke_1(declaration, @"setBundlePath:", objcInvoke(appInfo, @"bundleURL"));
            setIvar(appInfo, @"_carPlayDeclaration", declaration);
        }
    }
}

%hook CARApplication

+ (id)_newApplicationLibrary {
    id allAppsConfig = [[objc_getClass("FBSApplicationLibraryConfiguration") alloc] init];
    objcInvoke_1(allAppsConfig, @"setApplicationInfoClass:", objc_getClass("CARApplicationInfo"));
    objcInvoke_1(allAppsConfig, @"setApplicationPlaceholderClass:", objc_getClass("FBSApplicationPlaceholder"));
    objcInvoke_1(allAppsConfig, @"setAllowConcurrentLoading:", 1);

    id allAppsLibrary = objcInvoke_1([objc_getClass("FBSApplicationLibrary") alloc],
                                     @"initWithConfiguration:", allAppsConfig);
    addCarPlayDeclarations(allAppsLibrary);
    return allAppsLibrary;
}

%end

%end // CARPLAY

// ─────────────────────────────────────────────
// MARK: - User Applications (Orientation Lock)
// ─────────────────────────────────────────────
%group APPS

%hook UIWindow

- (void)_setRotatableViewOrientation:(int)orientation duration:(float)duration force:(int)force {
    // When running in a CarPlay hosted pane, force landscape orientation
    %orig(3, duration, force); // 3 = Landscape
}

%end

%end // APPS

// ─────────────────────────────────────────────
// MARK: - Constructor
// ─────────────────────────────────────────────
%ctor {
    @autoreleasepool {
        NSString *proc = [NSProcessInfo processInfo].processName;
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];

        if ([proc isEqualToString:@"SpringBoard"]) {
            NSLog(@"[SplitPlay2] Initializing SpringBoard hooks");
            %init(SPRINGBOARD);
        } else if ([proc isEqualToString:@"CarPlay"] || [bundleID isEqualToString:@"com.apple.CarPlay"]) {
            NSLog(@"[SplitPlay2] Initializing CarPlay hooks");
            %init(CARPLAY);
        } else if ([bundleID hasPrefix:@"com."] && ![bundleID containsString:@"com.apple."]) {
            %init(APPS);
        }
    }
}
