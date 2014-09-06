//
//  AFSInfoOverlayView.m
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 9/6/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "AFSDroneCoords.h"
#import "AFSMarkovChain.h"
#import "AFSInfoOverlayView.h"

@interface AFSInfoOverlayView ()
@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) AFSDroneCoords *droneCoords;
@property (nonatomic, strong) AFSMarkovChain *markovChain;
@end

@implementation AFSInfoOverlayView

// More info: http://stackoverflow.com/questions/11708597/loadnibnamed-vs-initwithframe-dilemma-for-setting-frames-height-and-width
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self = [[[NSBundle mainBundle] loadNibNamed:@"AFSInfoOverlayView" owner:nil options:nil] objectAtIndex:0];
        [self setFrame:frame];
        self.infoOverlayWebViewHidden = NO;
        [self.infoWebView setHidden:self.infoOverlayWebViewHidden];
        
        // Setup drone coords and markov chain
        self.droneCoords = [[AFSDroneCoords alloc] initWithFilename:@"drone_coords"];
        self.markovChain = [[AFSMarkovChain alloc] init];
        [self.markovChain loadModelWithMaxChars:90];
        
    }
    //[self.infoWebView setHidden:YES];
    return self;
}

- (void)setOverlayInfoWebView:(NSString *)infoHTMLFilename {
    //  Load html from a local file for the about screen
    NSString *aboutFilePath = [[NSBundle mainBundle] pathForResource:infoHTMLFilename
                                                              ofType:@"html"];
    
    NSString* htmlString = [NSString stringWithContentsOfFile:aboutFilePath
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
    
    NSString *aPath = [[NSBundle mainBundle] bundlePath];
    NSURL *anURL = [NSURL fileURLWithPath:aPath];
    [self.infoWebView loadHTMLString:htmlString baseURL:anURL];
}

- (IBAction)overlayQuestionMarkTapped:(id)sender {
    self.infoOverlayWebViewHidden = !self.infoOverlayWebViewHidden;
    [self.infoWebView setHidden:self.infoOverlayWebViewHidden];
}

- (IBAction)overlayShareTapped:(id)sender {
    //NSMutableString *generatedText = [self.markovChain generateTextWith:50 limitToMaxChars:NO];
    //NSLog(@"Generated text: %@", generatedText);
    
    // Get some coords
    NSArray *chosenCoord = [self.droneCoords randomDroneCoord];
    NSMutableString *status = [self.markovChain generateTextWith:50 limitToMaxChars:YES];
    [self tweetWithStatus:status andCoords:chosenCoord];
}

- (void)tweetWithStatus:(NSString *)status andCoords:(NSArray *) chosenCoord {
    self.accountStore = [[ACAccountStore alloc] init];
    //NSArray *chosenCoord = [self.droneCoords randomDroneCoord];
    NSLog(@"lat: %@; long: %@", chosenCoord[0], chosenCoord[1]);
    
    ACAccountType *twitterType =
    [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    SLRequestHandler requestHandler =
    ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (responseData) {
            NSInteger statusCode = urlResponse.statusCode;
            NSDictionary *postResponseData =
            [NSJSONSerialization JSONObjectWithData:responseData
                                            options:NSJSONReadingMutableContainers
                                              error:NULL];
            if (statusCode >= 200 && statusCode < 300) {
                
                NSLog(@"[SUCCESS!] Created Tweet with ID: %@; postResponseData: %@", postResponseData[@"id_str"], postResponseData);
            }
            else {
                NSLog(@"[ERROR] Server responded: status code %d %@, responseData %@", statusCode,
                      [NSHTTPURLResponse localizedStringForStatusCode:statusCode], postResponseData);
            }
        }
        else {
            NSLog(@"[ERROR] An error occurred while posting: %@", [error localizedDescription]);
        }
    };
    
    ACAccountStoreRequestAccessCompletionHandler accountStoreHandler =
    ^(BOOL granted, NSError *error) {
        if (granted) {
            NSArray *accounts = [self.accountStore accountsWithAccountType:twitterType];
            NSURL *url = [NSURL URLWithString:@"https://api.twitter.com"
                          @"/1.1/statuses/update.json"];
            NSDictionary *params = @{
                                     @"status" : status,
                                     @"lat": chosenCoord[0],
                                     @"long": chosenCoord[1]};
            SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                    requestMethod:SLRequestMethodPOST
                                                              URL:url
                                                       parameters:params];
            [request setAccount:[accounts lastObject]];
            [request performRequestWithHandler:requestHandler];
        }
        else {
            NSLog(@"[ERROR] An error occurred while asking for user authorization: %@",
                  [error localizedDescription]);
        }
    };
    
    [self.accountStore requestAccessToAccountsWithType:twitterType
                                               options:NULL
                                            completion:accountStoreHandler];
    //self.tweetLabel.text = @"Tweeting...";
    
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
