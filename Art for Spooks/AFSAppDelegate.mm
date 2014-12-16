//
//  AFSAppDelegate.m
//  Art for Spooks
//
//  Portions of this file are based on Qualcomm Vuforia sample code.
//
//  Created by Nicholas A Knouf on 8/17/14.
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

#import "AFSAppDelegate.h"
#import "AFSImageTargetsViewController.h"
#import "AFSLaunchViewController.h"
#import "FlickrKit.h"

@implementation AFSAppDelegate

- (BOOL) application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSString *scheme = [url scheme];
	if([@"artforspooks" isEqualToString:scheme]) {
        // TODO: figure out how to make this a singleton like described below
		// I don't recommend doing it like this, it's just a demo... I use an authentication
		// controller singleton object in my projects
		[[NSNotificationCenter defaultCenter] postNotificationName:@"UserAuthCallbackNotification" object:url userInfo:nil];
    }
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    //UIViewController *vc = [[[AFSLaunchViewController alloc] init] autorelease];
    //self.window.rootViewController = vc;
    //[self.window makeKeyAndVisible];
    
    NSDictionary *flickrCredentials;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"flickrCredentials" ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfFile:path];
    
    NSError *error = nil;
    
    id object = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    
    if ([object isKindOfClass:[NSDictionary class]] && error == nil) {
        flickrCredentials = [[NSDictionary alloc] initWithDictionary:object];
        //NSLog(@"%@", object);
    }
    
    NSString *apiKey = flickrCredentials[@"apiKey"];
	NSString *secret = flickrCredentials[@"secret"];
    if (!apiKey) {
        NSLog(@"\n----------------------------------\nYou need to enter your own 'apiKey' and 'secret' in FKAppDelegate for the demo to run. \n\nYou can get these from your Flickr account settings.\n----------------------------------\n");
        exit(0);
    }
    [[FlickrKit sharedFlickrKit] initializeWithAPIKey:apiKey sharedSecret:secret];
    
    // Navigation bar style
    UIFont* sourceSansProRegular  = [UIFont fontWithName:@"SourceSansPro-Regular" size:20];
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowOffset = CGSizeMake(0.0, 1.0);
    shadow.shadowColor = [UIColor whiteColor];
    
    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil]
     setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor redColor],
       NSShadowAttributeName:shadow,
       NSFontAttributeName:sourceSansProRegular
       }
     forState:UIControlStateNormal];
    
    /*
    NSLog(@"Available fonts: %@", [UIFont familyNames]);
    NSArray *familyNames = [UIFont familyNames];
    NSMutableString *name;
    for (name in familyNames) {
        NSArray *fontNames = [UIFont fontNamesForFamilyName:name];
        NSMutableString *fontName;
        for (fontName in fontNames) {
            NSLog(@"Family Name: %@; Font Name: %@", name, fontName);
        }
    }
     */
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
