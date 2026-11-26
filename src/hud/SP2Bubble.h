// SP2Bubble.h - Floating Speed HUD Bubble
#pragma once
#import "../common.h"

@interface SP2Bubble : UIView <CLLocationManagerDelegate>

@property (nonatomic, strong) UILabel *speedLabel;
@property (nonatomic, strong) UILabel *unitLabel;
@property (nonatomic, strong) UIView *limitCircle;
@property (nonatomic, strong) UILabel *limitLabel;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) NSInteger currentSpeed;
@property (nonatomic, assign) NSInteger speedLimit;

- (void)start;
- (void)stop;
- (void)setSpeedLimit:(NSInteger)limit;

@end
