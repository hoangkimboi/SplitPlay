// SplitPlayPrefsListController.mm - Preferences Controllers
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <spawn.h>

@interface SplitPlayPrefsListController : PSListController
@end

@implementation SplitPlayPrefsListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)respring {
    pid_t pid;
    const char *args[] = {"killall", "-9", "SpringBoard", NULL};
    posix_spawn(&pid, "/var/jb/usr/bin/killall", NULL, NULL, (char *const *)args, NULL);
}

@end

@interface SP2DriveListController : PSListController
@end
@implementation SP2DriveListController
- (NSArray *)specifiers {
    if (!_specifiers) _specifiers = [self loadSpecifiersFromPlistName:@"Drive" target:self];
    return _specifiers;
}
@end

@interface SP2CarListController : PSListController
@end
@implementation SP2CarListController
- (NSArray *)specifiers {
    if (!_specifiers) _specifiers = [self loadSpecifiersFromPlistName:@"Car" target:self];
    return _specifiers;
}
@end

@interface SP2SpeedListController : PSListController
@end
@implementation SP2SpeedListController
- (NSArray *)specifiers {
    if (!_specifiers) _specifiers = [self loadSpecifiersFromPlistName:@"Speed" target:self];
    return _specifiers;
}
@end
