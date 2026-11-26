// SP2Workspace.mm - Implementation of Split-Screen Workspace
#import "SP2Workspace.h"
#import "SP2Pane.h"
#import "SP2Dividers.h"
#import "SP2Picker.h"

@implementation SP2Workspace

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor blackColor];
        self.clipsToBounds = YES;
        _dividerPosition = 0.5; // default 50/50
        _splitRatio = SPSplitRatio50_50;

        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews {
    self.leftPane = [[SP2Pane alloc] initWithFrame:CGRectZero slot:0];
    self.leftPane.delegate = self;
    [self addSubview:self.leftPane];

    self.rightPane = [[SP2Pane alloc] initWithFrame:CGRectZero slot:1];
    self.rightPane.delegate = self;
    [self addSubview:self.rightPane];

    self.divider = [[SP2Dividers alloc] initWithFrame:CGRectZero];
    __weak __typeof__(self) weakSelf = self;
    self.divider.onPanChanged = ^(CGFloat deltaX) {
        [weakSelf handleDividerDragged:deltaX];
    };
    self.divider.onDoubleTapped = ^{
        [weakSelf swapPanes];
    };

    [self addSubview:self.divider];

    [self relayoutPanesAnimated:NO];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self relayoutPanesAnimated:NO];
}

- (void)handleDividerDragged:(CGFloat)deltaX {
    CGFloat totalW = self.bounds.size.width;
    if (totalW <= 0) return;

    CGFloat newPos = self.dividerPosition + (deltaX / totalW);
    // Clamp between 20% and 80%
    newPos = MAX(0.20, MIN(0.80, newPos));
    self.dividerPosition = newPos;

    [self relayoutPanesAnimated:NO];
}

- (void)relayoutPanesAnimated:(BOOL)animated {
    CGRect b = self.bounds;
    CGFloat divW = DEFAULT_DIVIDER_WIDTH;

    if (self.splitRatio == SPSplitRatioFullLeft) {
        self.leftPane.frame = b;
        self.rightPane.frame = CGRectZero;
        self.divider.hidden = YES;
        return;
    } else if (self.splitRatio == SPSplitRatioFullRight) {
        self.leftPane.frame = CGRectZero;
        self.rightPane.frame = b;
        self.divider.hidden = YES;
        return;
    }

    self.divider.hidden = NO;
    CGFloat leftW = floorf((b.size.width - divW) * self.dividerPosition);
    CGFloat rightW = b.size.width - divW - leftW;

    CGRect leftF = CGRectMake(0, 0, leftW, b.size.height);
    CGRect divF  = CGRectMake(leftW, 0, divW, b.size.height);
    CGRect rightF = CGRectMake(leftW + divW, 0, rightW, b.size.height);

    void (^applyBlock)(void) = ^{
        self.leftPane.frame = leftF;
        self.divider.frame  = divF;
        self.rightPane.frame = rightF;
    };

    if (animated) {
        [UIView animateWithDuration:0.35 delay:0
             usingSpringWithDamping:0.85 initialSpringVelocity:0.4
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:applyBlock completion:nil];
    } else {
        applyBlock();
    }
}

- (void)setSplitRatio:(SPSplitRatio)ratio animated:(BOOL)animated {
    _splitRatio = ratio;
    switch (ratio) {
        case SPSplitRatio50_50: _dividerPosition = 0.50; break;
        case SPSplitRatio60_40: _dividerPosition = 0.60; break;
        case SPSplitRatio40_60: _dividerPosition = 0.40; break;
        case SPSplitRatio70_30: _dividerPosition = 0.70; break;
        case SPSplitRatio30_70: _dividerPosition = 0.30; break;
        default: break;
    }
    [self relayoutPanesAnimated:animated];
}

- (void)hostApp:(NSString *)bundleID inSlot:(NSInteger)slot {
    if (slot == 0) {
        [self.leftPane hostAppWithBundleID:bundleID];
    } else {
        [self.rightPane hostAppWithBundleID:bundleID];
    }
}

- (void)swapPanes {
    NSString *lApp = self.leftPane.currentBundleID;
    NSString *rApp = self.rightPane.currentBundleID;

    [UIView transitionWithView:self duration:0.35
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        [self.leftPane hostAppWithBundleID:rApp];
        [self.rightPane hostAppWithBundleID:lApp];
    } completion:nil];
}

#pragma mark - SP2PaneDelegate

- (void)paneWantsPicker:(SP2Pane *)pane {
    if (!self.appPicker) {
        self.appPicker = [[SP2Picker alloc] initWithFrame:self.bounds];
        __weak __typeof__(self) weakSelf = self;
        self.appPicker.onAppPicked = ^(NSString *bid, NSInteger targetSlot) {
            [weakSelf hostApp:bid inSlot:targetSlot];
            [weakSelf.appPicker dismiss];
        };
        [self addSubview:self.appPicker];
    }

    [self.appPicker showForSlot:pane.slot inView:self];
}

- (void)paneWantsSwap:(SP2Pane *)pane {
    [self swapPanes];
}

- (void)paneWantsZoom:(SP2Pane *)pane {
    if (self.splitRatio == SPSplitRatioFullLeft || self.splitRatio == SPSplitRatioFullRight) {
        // Restore to 50/50
        [self setSplitRatio:SPSplitRatio50_50 animated:YES];
    } else {
        // Maximize tapped pane
        [self setSplitRatio:(pane.slot == 0 ? SPSplitRatioFullLeft : SPSplitRatioFullRight) animated:YES];
    }
}

- (void)paneWantsClose:(SP2Pane *)pane {
    [pane closeApp];
}

- (void)pane:(SP2Pane *)pane didSelectApp:(NSString *)bundleID {
    [pane hostAppWithBundleID:bundleID];
}

- (void)teardown {
    [self.leftPane teardown];
    [self.rightPane teardown];
}

@end
