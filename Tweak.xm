#import "Tweak.h"


static SBMainSwitcherViewController *mainSwitcher = nil;

%hook SBMainSwitcherViewController
- (void)viewWillAppear:(BOOL)arg1 {
    %orig;
    mainSwitcher = self; // 'self' is ALWAYS the current, live instance
}
%end

// Add close button to switcher
%hook SBAppSwitcherScrollView
%property (nonatomic, strong) UIButton *closeAllButton;
%property (nonatomic, strong) _UIBackdropViewSettings *blurViewSettings;
%property (nonatomic, strong) _UIBackdropView *blurView;
-(void)didMoveToWindow {
    %orig;
    if (!self.closeAllButton) [self addButton];
}

%new
- (void)addButton {
    //if (!mainSwitcher) mainSwitcher = [%c(SBMainSwitcherViewController) sharedInstance];

    if (self.superview) {
        self.closeAllButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.closeAllButton.titleEdgeInsets = UIEdgeInsetsMake(-2,-2,-2,-2);
        [self.closeAllButton setContentMode:UIViewContentModeCenter];

        //button touch down, up, click events for appearance & close
        [self.closeAllButton addTarget:self action:@selector(buttonHighlight) forControlEvents:UIControlEventTouchDown];
        [self.closeAllButton addTarget:self action:@selector(buttonNormal) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
        [self.closeAllButton addTarget:self action:@selector(closeAll)
                      forControlEvents:UIControlEventTouchUpInside];

        self.closeAllButton.frame = CGRectMake(0,0,55,25);
        self.closeAllButton.layer.masksToBounds = YES;
        self.closeAllButton.layer.cornerRadius = self.closeAllButton.frame.size.height/3;
        [self.closeAllButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.closeAllButton.backgroundColor = [UIColor clearColor];
        [self.closeAllButton setTitle:@"Close" forState:UIControlStateNormal];
        self.closeAllButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        if (self.closeAllButton) [self addBlurToButton];
        [self.superview insertSubview:self.closeAllButton atIndex:12];
        self.closeAllButton.translatesAutoresizingMaskIntoConstraints = false;
        [self.closeAllButton.widthAnchor constraintEqualToConstant:55].active = true;
        [self.closeAllButton.heightAnchor constraintEqualToConstant:25].active = true;
        [self.closeAllButton.rightAnchor constraintEqualToAnchor:self.superview.rightAnchor constant:-30].active = true;
        [self.closeAllButton.topAnchor constraintEqualToAnchor:self.superview.topAnchor constant:8].active = true;
        
        self.closeAllButton.alpha = 0;
        self.blurView.alpha = 0;

        self.closeAllButton.exclusiveTouch = YES;

        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^ {
            self.closeAllButton.alpha = 1;
            self.blurView.alpha = 1;
        } completion:nil];
    }
}

// Make sure the button is only visible when the switcher is visible
-(void)setScrollEnabled:(BOOL)arg1 {
    %orig;
    if (arg1 == false) {
        [UIView animateWithDuration:0.3 animations:^ {
            self.closeAllButton.alpha = 0;
            self.blurView.alpha = 0;
        }];
    } else if (mainSwitcher && [[mainSwitcher recentAppLayouts] count] > 0) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^ {
            self.closeAllButton.alpha = 1;
            self.blurView.alpha = 1;
        } completion:nil];
    }
}

// Add a blur behind the close button
%new
- (void)addBlurToButton {
    if (self.superview && self.closeAllButton) {
        self.blurViewSettings = [_UIBackdropViewSettings settingsForStyle:4005];
        self.blurView = [[_UIBackdropView alloc] initWithSettings:self.blurViewSettings];
        self.blurView.frame = self.closeAllButton.bounds;
        self.blurView.layer.masksToBounds = YES;
        self.blurView.layer.cornerRadius = self.closeAllButton.frame.size.height/3;
        [self.superview insertSubview:self.blurView atIndex:11];
        self.blurView.translatesAutoresizingMaskIntoConstraints = false;
        [self.blurView.widthAnchor constraintEqualToConstant:55].active = true;
        [self.blurView.heightAnchor constraintEqualToConstant:25].active = true;
        [self.blurView.rightAnchor constraintEqualToAnchor:self.superview.rightAnchor constant:-30].active = true;
        [self.blurView.topAnchor constraintEqualToAnchor:self.superview.topAnchor constant:8].active = true;
    }
}


//button appearance on events
%new
- (void)buttonHighlight {
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.2 options:0 animations:^{
        self.closeAllButton.backgroundColor = [UIColor whiteColor];
        [self.closeAllButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    } completion:nil];
}

%new
- (void)buttonNormal {
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.2 options:0 animations:^{
            self.closeAllButton.backgroundColor = [UIColor clearColor];
            [self.closeAllButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } completion:nil];
}
// Close all apps
%new
- (void)closeAll {
    CloseAllManager *cm = [[CloseAllManager alloc] init];
    
    if (@available(iOS 16.0, *)) {
        SBMainSwitcherControllerCoordinator *mainSwitcher16 = [%c(SBMainSwitcherControllerCoordinator) sharedInstance];
        NSArray *items16 = mainSwitcher16.recentAppLayouts;
        for (SBAppLayout *item16 in items16) {
            //AudioServicesPlaySystemSound(1519);
            [cm clearApp:item16 switcher:mainSwitcher16 /*excludeList:keyArray*/];
        }
    } else {
        NSArray *items = mainSwitcher.recentAppLayouts;
        for (SBAppLayout *item in items) {
            //AudioServicesPlaySystemSound(1519);
            [cm clearApp:item switcher:mainSwitcher /*excludeList:keyArray*/];
        }
    }
}

%end