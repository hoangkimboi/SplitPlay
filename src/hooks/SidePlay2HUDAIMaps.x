// SidePlay2HUDAIMaps.x - AI Maps HUD Adapter (100% Safe, Sandbox Only)
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import <notify.h>
#import <objc/runtime.h>

#define HUD_SPEED_NOTIFICATION "com.sideplay2.hud.legacy.speed"
#define HUD_LIMIT_NOTIFICATION "com.sideplay2.hud.legacy.limit"
#define HUD_ALERT_NOTIFICATION "com.sideplay2.hud.legacy.alert.first"

static int g_speed_token = -1;
static int g_limit_token = -1;
static int g_alert_token = -1;

static int g_last_speed = -1;
static int g_last_limit = -1;
static int g_last_alert = -1;

static void post_speed(int speed) {
    if (speed < 0 || speed == g_last_speed) return;
    g_last_speed = speed;
    if (g_speed_token == -1) notify_register_check(HUD_SPEED_NOTIFICATION, &g_speed_token);
    notify_set_state(g_speed_token, (uint64_t)speed);
    notify_post(HUD_SPEED_NOTIFICATION);
}

static void post_limit(int limit) {
    if (limit < 30 || limit > 140 || limit == g_last_limit) return;
    g_last_limit = limit;
    if (g_limit_token == -1) notify_register_check(HUD_LIMIT_NOTIFICATION, &g_limit_token);
    notify_set_state(g_limit_token, (uint64_t)limit);
    notify_post(HUD_LIMIT_NOTIFICATION);
}

static void post_alert(int alertCode) {
    if (alertCode <= 0 || alertCode == g_last_alert) return;
    g_last_alert = alertCode;
    if (g_alert_token == -1) notify_register_check(HUD_ALERT_NOTIFICATION, &g_alert_token);
    notify_set_state(g_alert_token, (uint64_t)alertCode);
    notify_post(HUD_ALERT_NOTIFICATION);
}

// ─────────────────────────────────────────────
// MARK: - 1. GPS Speed & Background Location
// ─────────────────────────────────────────────

static void (*orig_didUpdateLocations)(id, SEL, CLLocationManager *, NSArray<CLLocation *> *) = NULL;

static void safe_didUpdateLocations(id self, SEL _cmd, CLLocationManager *manager, NSArray<CLLocation *> *locations) {
    @try {
        if (orig_didUpdateLocations) {
            orig_didUpdateLocations(self, _cmd, manager, locations);
        }
        if (locations && locations.count > 0) {
            CLLocation *loc = [locations lastObject];
            if (loc && loc.speed >= 0) {
                int speedKMH = (int)round(loc.speed * 3.6);
                post_speed(speedKMH);
            }
        }
    } @catch (NSException *e) {}
}

%hook CLLocationManager

- (void)setDelegate:(id<CLLocationManagerDelegate>)delegate {
    @try {
        if (delegate) {
            Class cls = [delegate class];
            static NSMutableSet *swizzledClasses = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                swizzledClasses = [[NSMutableSet alloc] init];
            });

            if (![swizzledClasses containsObject:cls]) {
                [swizzledClasses addObject:cls];
                SEL sel = @selector(locationManager:didUpdateLocations:);
                Method m = class_getInstanceMethod(cls, sel);
                if (m) {
                    orig_didUpdateLocations = (void (*)(id, SEL, CLLocationManager *, NSArray<CLLocation *> *))method_getImplementation(m);
                    method_setImplementation(m, (IMP)safe_didUpdateLocations);
                }
            }
        }
    } @catch (NSException *e) {}
    %orig(delegate);
}

- (void)startUpdatingLocation {
    @try {
        [self setAllowsBackgroundLocationUpdates:YES];
        [self setPausesLocationUpdatesAutomatically:NO];
    } @catch (NSException *e) {}
    %orig;

// ─────────────────────────────────────────────
// MARK: - 2. AI Maps Voice Announcements Parser
// ─────────────────────────────────────────────

%hook AVSpeechSynthesizer

- (void)speakUtterance:(AVSpeechUtterance *)utterance {
    @try {
        NSString *spoken = [utterance.speechString lowercaseString];
        if (spoken && spoken.length > 0) {
            static NSRegularExpression *speedRegex = nil;
            static dispatch_once_t regexToken;
            dispatch_once(&regexToken, ^{
                speedRegex = [NSRegularExpression regularExpressionWithPattern:@"(?:giới hạn|tốc độ|tối đa)[^0-9]{0,15}([3-9]0|1[0-2]0)"
                                                                       options:NSRegularExpressionCaseInsensitive error:nil];
            });

            NSTextCheckingResult *match = [speedRegex firstMatchInString:spoken options:0 range:NSMakeRange(0, spoken.length)];
            if (match && match.numberOfRanges > 1) {
                NSString *numStr = [spoken substringWithRange:[match rangeAtIndex:1]];
                int limit = [numStr intValue];
                post_limit(limit);
            }

            if ([spoken containsString:@"camera"] || [spoken containsString:@"phạt nguội"]) {
                int code = [spoken containsString:@"đèn đỏ"] ? 2 : 1;
                post_alert(code);
            }
        }
    } @catch (NSException *e) {}
    %orig(utterance);
}

%end

// ─────────────────────────────────────────────
// MARK: - 3. AI Maps Speed Limit Badge Parser
// ─────────────────────────────────────────────

%hook UILabel

- (void)setText:(NSString *)text {
    @try {
        if (text && text.length >= 2 && text.length <= 3) {
            int val = [text intValue];
            if (val == 40 || val == 50 || val == 60 || val == 70 || val == 80 || val == 90 || val == 100 || val == 120) {
                post_limit(val);
            }
        }
    } @catch (NSException *e) {}
    %orig(text);
}

%end

// ─────────────────────────────────────────────
// MARK: - Constructor
// ─────────────────────────────────────────────
%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if ([bundleID isEqualToString:@"vn.aimap.ios"]) {
            NSLog(@"[SidePlay2-AIMaps] Injected into AI Maps (vn.aimap.ios)!");
        }
    }
}

}

- (void)setAllowsBackgroundLocationUpdates:(BOOL)allow {
    %orig(YES);
}

%end
