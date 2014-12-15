//
//  AFSSetupViewController.h
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 12/15/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AFSSetupViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *flickrAuthButton;
@property (weak, nonatomic) IBOutlet UILabel *flickrAuthLabel;
@property (weak, nonatomic) IBOutlet UILabel *twitterInfoLabel;
@property (weak, nonatomic) IBOutlet UILabel *twitterAccountLabel;

@end
