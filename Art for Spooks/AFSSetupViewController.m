//
//  AFSSetupViewController.m
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 12/15/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import "FlickrKit.h"
#import "AFSSetupViewController.h"

@interface AFSSetupViewController ()
@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, retain) FKDUNetworkOperation *completeAuthOp;
@property (nonatomic, retain) FKDUNetworkOperation *checkAuthOp;
@property (nonatomic, retain) FKImageUploadNetworkOperation *uploadOp;
@property (nonatomic, retain) NSString *userID;
@property BOOL justLoggedOut;
@end

@implementation AFSSetupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
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
    self.twitterAccountLabel.font = sourceSansProRegular;
    
    // Check on twitter accounts
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) // check Twitter is configured in Settings or not
    {
        self.accountStore = [[ACAccountStore alloc] init]; // you have to retain ACAccountStore
        
        ACAccountType *twitterAcc = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        
        [self.accountStore requestAccessToAccountsWithType:twitterAcc options:nil completion:^(BOOL granted, NSError *error)
         {
             if (granted)
             {
                 ACAccount *twitterAccount = [[self.accountStore accountsWithAccountType:twitterAcc] lastObject];
                 [self.twitterAccountLabel setText:[NSString stringWithFormat:@"Twitter account: %@", twitterAccount.username]];
                 NSLog(@"Twitter UserName: %@, FullName: %@", twitterAccount.username, twitterAccount.userFullName);
             }
             else
             {
                 if (error == nil) {
                     NSLog(@"User Has disabled your app from settings...");
                 }
                 else
                 {
                     NSLog(@"Error in Login: %@", error);
                 }
             }
         }];
    }
    else
    {
        [self.twitterAccountLabel setText:@"No Twitter account specified in Settings; please add one manually."];
        NSLog(@"Twitter account not Configured in Settings......"); // show user an alert view that Twitter is not configured in settings.
    }
    [self.twitterAccountLabel setNeedsDisplay];
    
    // Check on stored Flickr token
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [self.completeAuthOp cancel];
    [self.checkAuthOp cancel];
    [self.uploadOp cancel];
    [super viewWillDisappear:animated];
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
    [self.flickrAuthButton setTitle:@"Flickr Logout" forState:UIControlStateNormal];
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
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
