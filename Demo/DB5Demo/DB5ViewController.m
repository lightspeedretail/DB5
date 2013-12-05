//
//  DB5ViewController.m
//  DB5Demo
//
//  Created by Brent Simmons on 6/26/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "DB5ViewController.h"
#import "VSTheme.h"


@interface DB5ViewController ()

@property (strong, nonatomic) IBOutlet UILabel *label;
@property (getter = isLoaded) BOOL loaded;
@property CGPoint initialLabelOrigin;

@end


@implementation DB5ViewController


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil theme:(VSTheme *)theme {

	self = [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self == nil)
		return nil;

	_theme = theme;
    _loaded = NO;

	return self;
}


- (void)viewDidLoad {
    
    self.loaded = YES;
    self.initialLabelOrigin = self.label.frame.origin;
    
    [self applyTheme:self.theme];
}

- (void)applyTheme:(VSTheme *)theme {
    
    self.view.backgroundColor = [theme colorForKey:@"backgroundColor"];
	self.label.textColor = [theme colorForKey:@"labelTextColor"];
	self.label.font = [theme fontForKey:@"labelFont"];

    CGPoint themeLabelOrigin = [theme pointForKey:@"label"];
    CGPoint newLabelOrigin = CGPointEqualToPoint(self.label.frame.origin, themeLabelOrigin) ? self.initialLabelOrigin : themeLabelOrigin;
    
	[theme animateWithAnimationSpecifierKey:@"labelAnimation" animations:^{
        
		CGRect rLabel = self.label.frame;
		rLabel.origin = newLabelOrigin;
        
		self.label.frame = rLabel;
		
	} completion:^(BOOL finished) {
		NSLog(@"Ran an animation.");
	}];
}

- (void)setTheme:(VSTheme *)theme {
    
    if (self.isLoaded) {
        [self applyTheme:theme];
    }
    _theme = theme;
}

@end
