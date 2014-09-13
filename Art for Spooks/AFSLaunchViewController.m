//
//  AFSLaunchViewController.m
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 9/6/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import "AFSLaunchViewController.h"
//#import "AFSImageTargetsViewController.h"
#import "FlickrKit.h"

@class AFSImageTargetsViewController;

@interface AFSLaunchViewController ()
@property (nonatomic, retain) FKDUNetworkOperation *completeAuthOp;
@property (nonatomic, retain) FKDUNetworkOperation *checkAuthOp;
@property (nonatomic, retain) FKImageUploadNetworkOperation *uploadOp;
@property (nonatomic, retain) NSString *userID;
@property BOOL justLoggedOut;

@end

@implementation AFSLaunchViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Setup callback for authentication callback
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userAuthenticateCallback:) name:@"UserAuthCallbackNotification" object:nil];
    
    // Setup my fonts
    UIFont* sourceSansProBlack  = [UIFont fontWithName:@"SourceSansPro-Black" size:30];
    UIFont* sourceSansProRegular  = [UIFont fontWithName:@"SourceSansPro-Regular" size:24];
    self.flickrAuthButton.titleLabel.font = sourceSansProBlack;
    self.flickrAuthLabel.font = sourceSansProRegular;
    self.twitterInfoLabel.font = sourceSansProRegular;
    [self.twitterInfoLabel setNumberOfLines:2];
    self.twitterstreamLaunchButton.titleLabel.font = sourceSansProBlack;
    self.flickrLaunchButton.titleLabel.font = sourceSansProBlack;
    self.launchButton.titleLabel.font = sourceSansProBlack;
    
    // Check if there is a stored token
	// You should do this once on app launch
	self.checkAuthOp = [[FlickrKit sharedFlickrKit] checkAuthorizationOnCompletion:^(NSString *userName, NSString *userId, NSString *fullName, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (!error) {
				[self userLoggedIn:userName userID:userId];
                //NSLog(@"userID: %@", userId);
			} else {
				[self userLoggedOut];
			}
        });
	}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    
	[self.completeAuthOp cancel];
	[self.checkAuthOp cancel];
    [self.uploadOp cancel];
    [super viewWillDisappear:animated];
}

#pragma mark - Launch
- (IBAction)launchButtonPressed:(id)sender {
    
    //UIViewController *vc = [[[AFSLaunchViewController alloc] init] autorelease];
    //self.window.rootViewController = vc;
    //[self.window makeKeyAndVisible];
    UIViewController *vc = [[[AFSImageTargetsViewController alloc]  init] autorelease];
    
    [self.navigationController pushViewController:vc animated:NO];
}

- (IBAction)openTwitterStream:(id)sender {
    NSURL *url = [NSURL URLWithString:@"https://twitter.com/artforspooks"];
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)openFlickrPhotostream:(id)sender {
    NSURL *url = [NSURL URLWithString:@"https://www.flickr.com/photos/126630681@N03/"];
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - Authentication

- (void) userAuthenticateCallback:(NSNotification *)notification {
	NSURL *callbackURL = notification.object;
    self.completeAuthOp = [[FlickrKit sharedFlickrKit] completeAuthWithURL:callbackURL completion:^(NSString *userName, NSString *userId, NSString *fullName, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (!error) {
				[self userLoggedIn:userName userID:userId];
			} else {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
				[alert show];
			}
			[self.navigationController popToRootViewControllerAnimated:YES];
		});
	}];
}
- (IBAction)flickrAuthButtonPressed:(id)sender {
    NSLog(@"Auth button pressed");
    if ([FlickrKit sharedFlickrKit].isAuthorized) {
		[[FlickrKit sharedFlickrKit] logout];
		[self userLoggedOut];
        self.justLoggedOut = YES;
	}
}

- (void) userLoggedIn:(NSString *)username userID:(NSString *)userID {
	self.userID = userID;
	[self.flickrAuthButton setTitle:@"Logout" forState:UIControlStateNormal];
	self.flickrAuthLabel.text = [NSString stringWithFormat:@"You are logged in as %@", username];
}

- (void) userLoggedOut {
	[self.flickrAuthButton setTitle:@"Login to Flickr" forState:UIControlStateNormal];
	self.flickrAuthLabel.text = @"Not logged in";
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    NSLog(@"In shouldPerformSequeWithIdentifier");
    NSLog(@"Identifier: %@", identifier);
    if ([identifier isEqualToString:@"FlickrAuthSegue"]) {
        if (self.justLoggedOut) {
            NSLog(@"Shouldn't perform segue");
            self.justLoggedOut = NO;
            return NO;
        } else {
            return YES;
        }
    }
    
    return YES;
    
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
