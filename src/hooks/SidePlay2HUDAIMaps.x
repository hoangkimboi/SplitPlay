// SidePlay2HUDAIMaps.x - AI Maps Integration + Lifetime Unlock for SidePlay2
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import <notify.h>
#import <objc/runtime.h>

#define HUD_SPEED_NOTIFICATION "com.sideplay2.hud.legacy.speed"
#define HUD_LIMIT_NOTIFICATION "com.sideplay2.hud.legacy.limit"
#define HUD_ALERT_NOTIFICATION "com.sideplay2.hud.legacy.alert.first"

// ─────────────────────────────────────────────
// MARK: - 1. AI MAPS HOOKS (Bundle: vn.aimap.ios)
// ─────────────────────────────────────────────
%group AIMAPS

// Keep AI Maps location running in background
%hook CLLocationManager

- (void)startUpdatingLocation {
    @try {
        [self setAllowsBackgroundLocationUpdates:YES];
        [self setPausesLocationUpdatesAutomatically:NO];
    } @catch (NSException *e) {}
    %orig;
}

- (void)setAllowsBackgroundLocationUpdates:(BOOL)allow {
    %orig(YES);
}

%end

// Hook location updates on any delegate to capture real-time GPS speed
%hook NSObject

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    %orig;
    CLLocation *loc = [locations lastObject];
    if (loc && loc.speed >= 0) {
        int speedKMH = (int)round(loc.speed * 3.6);
        int token;
        notify_register_check(HUD_SPEED_NOTIFICATION, &token);
        notify_set_state(token, (uint64_t)speedKMH);
        notify_post(HUD_SPEED_NOTIFICATION);
    }
}

%end

// Hook Voice Announcements from AI Maps (Speed limits, Cameras, Hazards)
%hook AVSpeechSynthesizer

- (void)speakUtterance:(AVSpeechUtterance *)utterance {
    %orig;
    NSString *spoken = [utterance.speechString lowercaseString];
    if (!spoken || spoken.length == 0) return;

    // Detect Speed Limit numbers (e.g. "tốc độ giới hạn 60", "giới hạn 80", "50 km/h")
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(?:giới hạn|tốc độ|chạy tối đa)[^0-9]{0,15}([3-9]0|1[0-2]0)"
                                                                           options:NSRegularExpressionCaseInsensitive error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:spoken options:0 range:NSMakeRange(0, spoken.length)];
    if (match && match.numberOfRanges > 1) {
        NSString *numStr = [spoken substringWithRange:[match rangeAtIndex:1]];
        int limit = [numStr intValue];
        if (limit >= 30 && limit <= 120) {
            int token;
            notify_register_check(HUD_LIMIT_NOTIFICATION, &token);
            notify_set_state(token, (uint64_t)limit);
            notify_post(HUD_LIMIT_NOTIFICATION);
        }
    }

    // Detect Camera alerts
    if ([spoken containsString:@"camera"] || [spoken containsString:@"phạt nguội"] || [spoken containsString:@"giám sát"]) {
        int alertCode = 1; // Speed / penalty camera
        if ([spoken containsString:@"vượt đèn đỏ"] || [spoken containsString:@"đèn đỏ"]) {
            alertCode = 2; // Red light camera
        }
        int token;
        notify_register_check(HUD_ALERT_NOTIFICATION, &token);
        notify_set_state(token, (uint64_t)alertCode);
        notify_post(HUD_ALERT_NOTIFICATION);
    }
}

%end

// Hook UI Labels in AI Maps displaying the speed limit badge
%hook UILabel

- (void)setText:(NSString *)text {
    %orig(text);
    if (!text || text.length < 2 || text.length > 3) return;

    // Standard road speed limits in Vietnam: 40, 50, 60, 70, 80, 90, 100, 120
    int val = [text intValue];
    if (val == 40 || val == 50 || val == 60 || val == 70 || val == 80 || val == 90 || val == 100 || val == 120) {
        int token;
        notify_register_check(HUD_LIMIT_NOTIFICATION, &token);
        notify_set_state(token, (uint64_t)val);
        notify_post(HUD_LIMIT_NOTIFICATION);
    }
}

%end

%end // AIMAPS

// ─────────────────────────────────────────────
// MARK: - 2. SIDEPLAY2 APP UNLOCK HOOKS (Bundle: com.sideplay2.app)
// ─────────────────────────────────────────────
%group SIDEPLAY_APP

// Unlock Lifetime SidePro status in SidePlay2 app
%hook SP2Status

- (BOOL)active {
    return YES;
}

- (BOOL)pro {
    return YES;
}

- (BOOL)isPro {
    return YES;
}

- (NSInteger)state {
    return 1; // Active
}

- (NSInteger)toDays {
    return 99999; // Forever
}

- (NSString *)plan {
    return @"SidePro";
}

- (void)checkServer {
    // Prevent server from overriding with trial expiration
}

- (void)checkServerQuietly:(id)arg1 {
    // No-op
}

%end

%hook SP2AccountController

- (void)viewDidLoad {
    %orig;
    // Hide or update Buy Pro row
}

%end

%end // SIDEPLAY_APP

// ─────────────────────────────────────────────
// MARK: - 3. SPRINGBOARD HOOKS (Process: SpringBoard)
// ─────────────────────────────────────────────
%group SPRINGBOARD

// Ensure SidePlay2 CarPlay tweak never disables itself due to seat / license check
%hook SP2Car

- (BOOL)isLicensed {
    return YES;
}

- (BOOL)vipTrial {
    return YES;
}

- (NSInteger)daysGrace {
    return 99999;
}

%end

%end // SPRINGBOARD

// ─────────────────────────────────────────────
// MARK: - Constructor
// ─────────────────────────────────────────────
%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        NSString *proc = [NSProcessInfo processInfo].processName;

        if ([bundleID isEqualToString:@"vn.aimap.ios"]) {
            NSLog(@"[SidePlay2-AIMaps] Injected into AI Maps! Capturing speed and limits...");
            %init(AIMAPS);
        } else if ([bundleID isEqualToString:@"com.sideplay2.app"]) {
            NSLog(@"[SidePlay2-AIMaps] Injected into SidePlay2 App! Unlocking Lifetime Pro...");
            %init(SIDEPLAY_APP);
        } else if ([proc isEqualToString:@"SpringBoard"]) {
            NSLog(@"[SidePlay2-AIMaps] Injected into SpringBoard! Keeping SidePlay2 active...");
            %init(SPRINGBOARD);
        }
    }
}
