// SP2Dividers.h - Resizable Split View Divider Handle
#pragma once
#import "../common.h"

@interface SP2Dividers : UIView

@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UIView *handleView;
@property (nonatomic, copy) void (^onPanChanged)(CGFloat deltaX);
@property (nonatomic, copy) void (^onDoubleTapped)(void);

@end
