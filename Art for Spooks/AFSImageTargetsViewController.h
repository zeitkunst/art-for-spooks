//
//  Portions of this file are based on Qualcomm Vuforia sample code.
//
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


#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "SampleAppMenu.h"
#import "AFSImageTargetsEAGLView.h"
#import "AFSOverlayViewController.h"
#import "SampleApplicationSession.h"
#import <QCAR/DataSet.h>

@interface AFSImageTargetsViewController : UIViewController <SampleApplicationControl, UIGestureRecognizerDelegate>{
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
