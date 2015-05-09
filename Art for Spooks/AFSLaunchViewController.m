//
//  AFSLaunchViewController.m
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 9/6/14.
//  Copyright (c) 2014 Nicholas A. Knouf
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

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
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userAuthenticateCallback:) name:@"UserAuthCallbackNotification" object:nil];
    
    // Setup my fonts
    UIFont* sourceSansProBlack  = [UIFont fontWithName:@"SourceSansPro-Black" size:30];
    UIFont* sourceSansProRegular  = [UIFont fontWithName:@"SourceSansPro-Regular" size:24];
    self.flickrAuthButton.titleLabel.font = sourceSansProBlack;
    self.flickrAuthLabel.font = sourceSansProRegular;
    self.twitterInfoLabel.font = sourceSansProRegular;
    [self.twitterInfoLabel setNumberOfLines:2];
    self.launchButton.titleLabel.font = sourceSansProBlack;
    self.setupButton.titleLabel.font = sourceSansProBlack;
    self.aboutButton.titleLabel.font = sourceSansProBlack;
    self.downloadButton.titleLabel.font = sourceSansProBlack;
    
    // Navigation bar
    UINavigationBar *bar = self.navigationController.navigationBar;
    bar.tintColor = [UIColor redColor];
    bar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor redColor], NSForegroundColorAttributeName, [UIFont fontWithName:@"SourceSansPro-Regular" size:20], NSFontAttributeName, nil];
    
    /* check for iOS 6 or 7 */
    if ([[self navigationController].navigationBar respondsToSelector:@selector(setBarTintColor:)]) {
        [[self navigationController].navigationBar setBarTintColor:[UIColor whiteColor]];
        
    } else {
        /* Set background and foreground */
        [[self navigationController].navigationBar setTintColor:[UIColor whiteColor]];
        //[self navigationController].navigationBar.titleTextAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[UIColor blackColor],UITextAttributeTextColor,nil];
    }
    
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

-(NSUInteger)supportedInterfaceOrientations
{
    return (1 << UIInterfaceOrientationLandscapeRight);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    
	[self.checkAuthOp cancel];
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
- (IBAction)downloadButtonPressed:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://art-for-spooks.org/pdf/art-for-spooks.pdf"]];
}

#pragma mark - Authentication

- (void) userLoggedIn:(NSString *)username userID:(NSString *)userID {
	self.userID = userID;
	[self.flickrAuthButton setTitle:@"Logout" forState:UIControlStateNormal];
	self.flickrAuthLabel.text = [NSString stringWithFormat:@"You are logged in as %@", username];
}

- (void) userLoggedOut {
	[self.flickrAuthButton setTitle:@"Login to Flickr" forState:UIControlStateNormal];
	self.flickrAuthLabel.text = @"Not logged in";
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
