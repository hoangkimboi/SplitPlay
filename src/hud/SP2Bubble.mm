// SP2Bubble.mm - Floating Speed HUD Bubble Implementation
#import "SP2Bubble.h"

@interface SP2Bubble ()
@property (nonatomic, assign) CGPoint panOffset;
@end

@implementation SP2Bubble

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.92];
        self.layer.cornerRadius = frame.size.width / 2.0;
        self.layer.borderColor = [UIColor colorWithWhite:0.35 alpha:0.8].CGColor;
        self.layer.borderWidth = 1.5;
        self.clipsToBounds = YES;

        _speedLabel = [[UILabel alloc] init];
        _speedLabel.text = @"0";
        _speedLabel.textColor = [UIColor whiteColor];
        _speedLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
        _speedLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_speedLabel];

        _unitLabel = [[UILabel alloc] init];
        _unitLabel.text = @"km/h";
        _unitLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
        _unitLabel.font = [UIFont systemFontOfSize:9 weight:UIFontWeightRegular];
        _unitLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_unitLabel];

        // Speed limit circle indicator
        _limitCircle = [[UIView alloc] init];
        _limitCircle.backgroundColor = [UIColor whiteColor];
        _limitCircle.layer.borderColor = [UIColor colorWithRed:0.9 green:0.1 blue:0.1 alpha:1.0].CGColor;
        _limitCircle.layer.borderWidth = 2.5;
        _limitCircle.layer.cornerRadius = 10.0;
        _limitCircle.clipsToBounds = YES;
        _limitCircle.hidden = YES;

        _limitLabel = [[UILabel alloc] init];
        _limitLabel.textColor = [UIColor blackColor];
        _limitLabel.font = [UIFont systemFontOfSize:9 weight:UIFontWeightBlack];
        _limitLabel.textAlignment = NSTextAlignmentCenter;
        [_limitCircle addSubview:_limitLabel];
        [self addSubview:_limitCircle];

        // Drag gesture
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleBubblePan:)];
        [self addGestureRecognizer:pan];

        [self start];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    self.layer.cornerRadius = w / 2.0;

    _speedLabel.frame = CGRectMake(0, 10, w, 28);
    _unitLabel.frame  = CGRectMake(0, 36, w, 14);

    CGFloat limS = 20.0;
    _limitCircle.frame = CGRectMake(w - limS - 4, 4, limS, limS);
    _limitLabel.frame  = _limitCircle.bounds;
}

- (void)handleBubblePan:(UIPanGestureRecognizer *)gesture {
    CGPoint loc = [gesture locationInView:self.superview];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.panOffset = CGPointMake(loc.x - self.center.x, loc.y - self.center.y);
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        self.center = CGPointMake(loc.x - self.panOffset.x, loc.y - self.panOffset.y);
    }
}

- (void)start {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        _locationManager.distanceFilter = kCLDistanceFilterNone;
    }
    [_locationManager startUpdatingLocation];
}

- (void)stop {
    [_locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *loc = [locations lastObject];
    if (!loc) return;

    double speedMPS = loc.speed; // meters per second
    NSInteger speedKMH = 0;
    if (speedMPS > 0) {
        speedKMH = (NSInteger)round(speedMPS * 3.6);
    }
    self.currentSpeed = speedKMH;
    self.speedLabel.text = [NSString stringWithFormat:@"%ld", (long)speedKMH];

    // Check overspeed
    if (self.speedLimit > 0 && speedKMH > self.speedLimit) {
        self.speedLabel.textColor = [UIColor colorWithRed:1.0 green:0.25 blue:0.2 alpha:1.0];
        self.layer.borderColor = [UIColor colorWithRed:1.0 green:0.25 blue:0.2 alpha:1.0].CGColor;
    } else {
        self.speedLabel.textColor = [UIColor whiteColor];
        self.layer.borderColor = [UIColor colorWithWhite:0.35 alpha:0.8].CGColor;
    }
}

- (void)setSpeedLimit:(NSInteger)limit {
    _speedLimit = limit;
    if (limit > 0) {
        self.limitCircle.hidden = NO;
        self.limitLabel.text = [NSString stringWithFormat:@"%ld", (long)limit];
    } else {
        self.limitCircle.hidden = YES;
    }
}

@end
