//
//  AFSAppDelegate.m
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 8/17/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

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
    //TODO: Generate new key and secret once we launch
    NSString *apiKey = @"9a4a6ad4ddd2398e02b45c193f385d8f";
	NSString *secret = @"2e006ab52ffa280f";
    if (!apiKey) {
        NSLog(@"\n----------------------------------\nYou need to enter your own 'apiKey' and 'secret' in FKAppDelegate for the demo to run. \n\nYou can get these from your Flickr account settings.\n----------------------------------\n");
        exit(0);
    }
    [[FlickrKit sharedFlickrKit] initializeWithAPIKey:apiKey sharedSecret:secret];
    
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
