//
//  AFSLaunchViewController.h
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 9/6/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AFSLaunchViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIButton *flickrAuthButton;
@property (strong, nonatomic) IBOutlet UILabel *flickrAuthLabel;
@property (strong, nonatomic) IBOutlet UILabel *twitterInfoLabel;
@property (strong, nonatomic) IBOutlet UIButton *twitterstreamLaunchButton;
@property (strong, nonatomic) IBOutlet UIButton *flickrLaunchButton;
@property (strong, nonatomic) IBOutlet UIButton *launchButton;

@end
