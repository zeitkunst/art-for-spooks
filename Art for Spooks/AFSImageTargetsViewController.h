/*===============================================================================
Copyright (c) 2012-2014 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of QUALCOMM Incorporated, registered in the United States 
and other countries. Trademarks of QUALCOMM Incorporated are used with permission.
===============================================================================*/

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "SampleAppMenu.h"
#import "AFSImageTargetsEAGLView.h"
#import "SampleApplicationSession.h"
#import <QCAR/DataSet.h>

@interface AFSImageTargetsViewController : UIViewController <SampleApplicationControl>{
    CGRect viewFrame;
    AFSImageTargetsEAGLView* eaglView;
    QCAR::DataSet*  dataSetCurrent;
    QCAR::DataSet*  dataSetTarmac;
    QCAR::DataSet*  dataSetSpooks;
    UITapGestureRecognizer * tapGestureRecognizer;
    SampleApplicationSession * vapp;
    CGRect arViewRect; // the size of the AR view
    
    BOOL switchToTarmac;
    BOOL switchToSpooks;
    BOOL extendedTrackingIsOn;
    
}

@end
