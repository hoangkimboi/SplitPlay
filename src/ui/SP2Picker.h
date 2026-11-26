// SP2Picker.h - In-Car App Chooser Overlay
#pragma once
#import "../common.h"

@interface SP2Picker : UIView

@property (nonatomic, assign) NSInteger targetSlot;
@property (nonatomic, copy) void (^onAppPicked)(NSString *bundleID, NSInteger targetSlot);

- (void)showForSlot:(NSInteger)slot inView:(UIView *)parentView;
- (void)dismiss;

@end
