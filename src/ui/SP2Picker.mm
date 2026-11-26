// SP2Picker.mm - In-Car App Chooser Overlay Implementation
#import "SP2Picker.h"

@interface SP2PickerCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) NSString *bundleID;
@end

@implementation SP2PickerCell
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithWhite:0.18 alpha:0.7];
        self.layer.cornerRadius = 10.0;
        self.clipsToBounds = YES;

        _iconView = [[UIImageView alloc] init];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.layer.cornerRadius = 6.0;
        _iconView.clipsToBounds = YES;
        [self.contentView addSubview:_iconView];

        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = [UIColor whiteColor];
        _nameLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_nameLabel];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.contentView.bounds.size.width, h = self.contentView.bounds.size.height;
    _iconView.frame = CGRectMake((w - 36)/2.0, 8, 36, 36);
    _nameLabel.frame = CGRectMake(2, h - 20, w - 4, 14);
}
@end

@interface SP2Picker () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *installedApps;
@property (nonatomic, strong) UIButton *closeBtn;
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation SP2Picker

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.alpha = 0;
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        _blurView.frame = self.bounds;
        _blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_blurView];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"Chọn ứng dụng cho khung hình";
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
        [self addSubview:_titleLabel];

        _closeBtn = [UIButton buttonWithType:UIButtonTypeClose];
        [_closeBtn addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_closeBtn];

        UICollectionViewFlowLayout *fl = [[UICollectionViewFlowLayout alloc] init];
        fl.itemSize = CGSizeMake(68, 70);
        fl.minimumInteritemSpacing = 12;
        fl.minimumLineSpacing = 12;
        fl.sectionInset = UIEdgeInsetsMake(12, 12, 12, 12);

        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:fl];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [_collectionView registerClass:[SP2PickerCell class] forCellWithReuseIdentifier:@"AppCell"];
        [self addSubview:_collectionView];

        [self loadInstalledApps];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width, h = self.bounds.size.height;
    _titleLabel.frame = CGRectMake(16, 10, w - 70, 22);
    _closeBtn.frame = CGRectMake(w - 40, 8, 28, 28);
    _collectionView.frame = CGRectMake(0, 38, w, h - 38);
}

- (void)loadInstalledApps {
    NSMutableArray *apps = [NSMutableArray array];
    id appController = objcInvoke(objc_getClass("SBApplicationController"), @"sharedInstance");
    NSArray *allApps = objcInvoke(appController, @"allApplications");
    for (id app in allApps) {
        NSString *bid = objcInvoke(app, @"bundleIdentifier");
        NSString *name = objcInvoke(app, @"displayName");
        if (bid && name && ![bid containsString:@"com.apple.springboard"]) {
            [apps addObject:@{ @"bid": bid, @"name": name }];
        }
    }
    [apps sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
    }];
    self.installedApps = apps;
    [self.collectionView reloadData];
}

- (void)showForSlot:(NSInteger)slot inView:(UIView *)parentView {
    self.targetSlot = slot;
    self.frame = parentView.bounds;
    self.titleLabel.text = (slot == 0) ? @"Chọn ứng dụng - Khung Trái" : @"Chọn ứng dụng - Khung Phải";
    [parentView bringSubviewToFront:self];
    [UIView animateWithDuration:0.25 animations:^{ self.alpha = 1.0; }];
}

- (void)dismiss {
    [UIView animateWithDuration:0.2 animations:^{ self.alpha = 0; }];
}

- (NSInteger)collectionView:(UICollectionView *)cv numberOfItemsInSection:(NSInteger)s {
    return self.installedApps.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)ip {
    SP2PickerCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"AppCell" forIndexPath:ip];
    NSDictionary *item = self.installedApps[ip.item];
    cell.nameLabel.text = item[@"name"];
    cell.bundleID = item[@"bid"];
    cell.iconView.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    return cell;
}

- (void)collectionView:(UICollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)ip {
    NSDictionary *item = self.installedApps[ip.item];
    if (self.onAppPicked) self.onAppPicked(item[@"bid"], self.targetSlot);
}

@end
