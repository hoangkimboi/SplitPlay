// SP2Dividers.mm - Resizable Split View Divider Handle Implementation
#import "SP2Dividers.h"

@interface SP2Dividers ()
@property (nonatomic, assign) CGPoint lastPanPoint;
@end

@implementation SP2Dividers

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;

        // Thin separator line
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1.0];
        [self addSubview:_lineView];

        // Center pill grabber handle
        _handleView = [[UIView alloc] init];
        _handleView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.9];
        _handleView.layer.cornerRadius = 2.5;
        _handleView.clipsToBounds = YES;
        [self addSubview:_handleView];

        // Pan gesture to resize
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];

        // Double tap to swap
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(handleDoubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTap];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;

    // Line in middle
    _lineView.frame = CGRectMake((w - 2.0) / 2.0, 0, 2.0, h);

    // Pill handle in center
    CGFloat handleW = 5.0;
    CGFloat handleH = 40.0;
    _handleView.frame = CGRectMake((w - handleW) / 2.0, (h - handleH) / 2.0, handleW, handleH);
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint currentPoint = [gesture translationInView:self.superview];

    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.lastPanPoint = currentPoint;
        [UIView animateWithDuration:0.2 animations:^{
            self.handleView.transform = CGAffineTransformMakeScale(1.3, 1.1);
            self.handleView.backgroundColor = [UIColor whiteColor];
        }];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGFloat deltaX = currentPoint.x - self.lastPanPoint.x;
        self.lastPanPoint = currentPoint;
        if (self.onPanChanged) {
            self.onPanChanged(deltaX);
        }
    } else if (gesture.state == UIGestureRecognizerStateEnded ||
               gesture.state == UIGestureRecognizerStateCancelled) {
        [UIView animateWithDuration:0.2 animations:^{
            self.handleView.transform = CGAffineTransformIdentity;
            self.handleView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.9];
        }];
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)gesture {
    if (self.onDoubleTapped) {
        self.onDoubleTapped();
    }
}

@end
