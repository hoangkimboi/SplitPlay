// SP2Workspace.h - Split-Screen Layout & Panes Coordinator
#pragma once
#import "../common.h"

@class SP2Pane, SP2Dividers, SP2Picker;

@interface SP2Workspace : UIView <SP2PaneDelegate>

@property (nonatomic, strong) SP2Pane *leftPane;
@property (nonatomic, strong) SP2Pane *rightPane;
@property (nonatomic, strong) SP2Dividers *divider;
@property (nonatomic, strong) SP2Picker *appPicker;
@property (nonatomic, assign) SPSplitRatio splitRatio;
@property (nonatomic, assign) CGFloat dividerPosition; // fraction 0.0 - 1.0

- (void)hostApp:(NSString *)bundleID inSlot:(NSInteger)slot;
- (void)swapPanes;
- (void)setSplitRatio:(SPSplitRatio)ratio animated:(BOOL)animated;
- (void)teardown;

@end
