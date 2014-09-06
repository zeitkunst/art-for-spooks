/*===============================================================================
Copyright (c) 2012-2014 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of QUALCOMM Incorporated, registered in the United States 
and other countries. Trademarks of QUALCOMM Incorporated are used with permission.
===============================================================================*/

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "SampleAppMenu.h"
#import "AFSImageTargetsEAGLView.h"
#import "AFSOverlayViewController.h"
#import "SampleApplicationSession.h"
#import <QCAR/DataSet.h>

@interface AFSImageTargetsViewController : UIViewController <SampleApplicationControl>{
    CGRect viewFrame;
    AFSImageTargetsEAGLView* eaglView;
    QCAR::DataSet*  dataSetCurrent;
    QCAR::DataSet*  dataSetSpooks;
    UITapGestureRecognizer * tapGestureRecognizer;
    SampleApplicationSession * vapp;
    CGRect arViewRect; // the size of the AR view
    
    BOOL switchToSpooks;
    BOOL extendedTrackingIsOn;
    
    BOOL fullScreenPlayerPlaying;
    UINavigationController * navController;
    AFSOverlayViewController* overlayViewController;
    
}

- (void) pauseAR;
- (void) setNavigationController:(UINavigationController *) navController;
@end
