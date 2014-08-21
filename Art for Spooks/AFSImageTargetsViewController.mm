/*===============================================================================
Copyright (c) 2012-2014 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of QUALCOMM Incorporated, registered in the United States 
and other countries. Trademarks of QUALCOMM Incorporated are used with permission.
===============================================================================*/

#import "AFSImageTargetsViewController.h"
#import <QCAR/QCAR.h>
#import <QCAR/TrackerManager.h>
#import <QCAR/ImageTracker.h>
#import <QCAR/Trackable.h>
#import <QCAR/DataSet.h>
#import <QCAR/CameraDevice.h>

@interface AFSImageTargetsViewController ()

@end

@implementation AFSImageTargetsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        vapp = [[SampleApplicationSession alloc] initWithDelegate:self];
        
        // Custom initialization
        self.title = @"Image Targets";
        // Create the EAGLView with the screen dimensions
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        viewFrame = screenBounds;
        
        arViewRect.size = [[UIScreen mainScreen] bounds].size;
        arViewRect.origin.x = arViewRect.origin.y = 0;
        NSLog(@"arViewRect.width: %f; arViewRect.height: %f", arViewRect.size.width, arViewRect.size.height);
        
        // If this device has a retina display, scale the view bounds that will
        // be passed to QCAR; this allows it to calculate the size and position of
        // the viewport correctly when rendering the video background
        if (YES == vapp.isRetinaDisplay) {
            viewFrame.size.width *= 2.0;
            viewFrame.size.height *= 2.0;
        }
        
        dataSetCurrent = nil;
        extendedTrackingIsOn = NO;
        
        // a single tap will trigger a single autofocus operation
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(autofocus:)];
        
        // we use the iOS notification to pause/resume the AR when the application goes (or come back from) background
        
        [[NSNotificationCenter defaultCenter]
             addObserver:self
             selector:@selector(pauseAR)
             name:UIApplicationWillResignActiveNotification
             object:nil];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(resumeAR)
         name:UIApplicationDidBecomeActiveNotification
         object:nil];
        
    }
    return self;
}

- (void) pauseAR {
    NSError * error = nil;
    if (![vapp pauseAR:&error]) {
        NSLog(@"Error pausing AR:%@", [error description]);
    }
}

- (void) resumeAR {
    NSError * error = nil;
    if(! [vapp resumeAR:&error]) {
        NSLog(@"Error resuming AR:%@", [error description]);
    }
    // on resume, we reset the flash
    QCAR::CameraDevice::getInstance().setFlashTorchMode(false);
    
    [self handleRotation:self.interfaceOrientation];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //[tapGestureRecognizer release];
    
    [vapp release];
    [eaglView release];
    
    [super dealloc];
}

- (void)loadView
{
    // Create the EAGLView
    eaglView = [[AFSImageTargetsEAGLView alloc] initWithFrame:viewFrame appSession:vapp];
    [self setView:eaglView];
    
    // show loading animation while AR is being initialized
    [self showLoadingAnimation];
    
    // initialize the AR session
    //[vapp initAR:QCAR::GL_20 ARViewBoundsSize:viewFrame.size orientation:UIInterfaceOrientationPortrait];
    [vapp initAR:QCAR::GL_20 ARViewBoundsSize:viewFrame.size orientation:self.interfaceOrientation];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

	// Do any additional setup after loading the view.
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    //[self.view addGestureRecognizer:tapGestureRecognizer];
    
    NSLog(@"self.navigationController.navigationBarHidden:%d",self.navigationController.navigationBarHidden);
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [vapp stopAR:nil];
    // Be a good OpenGL ES citizen: now that QCAR is paused and the render
    // thread is not executing, inform the root view controller that the
    // EAGLView should finish any OpenGL ES commands
    [eaglView finishOpenGLESCommands];
    [eaglView freeOpenGLESResources];
}

- (void)finishOpenGLESCommands
{
    // Called in response to applicationWillResignActive.  Inform the EAGLView
    [eaglView finishOpenGLESCommands];
}


- (void)freeOpenGLESResources
{
    // Called in response to applicationDidEnterBackground.  Inform the EAGLView
    [eaglView freeOpenGLESResources];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - loading animation

- (void) showLoadingAnimation {
    CGRect indicatorBounds;
    
    CGRect mainBounds = [[UIScreen mainScreen] bounds];
    if (self.interfaceOrientation ==UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        indicatorBounds = CGRectMake(mainBounds.size.width / 2 - 12,
                                     mainBounds.size.height / 2 - 12, 24, 24);
    } else {
        indicatorBounds = CGRectMake(mainBounds.size.height / 2 - 12,
                                     mainBounds.size.width / 2 - 12, 24, 24);
    }
    UIActivityIndicatorView *loadingIndicator = [[[UIActivityIndicatorView alloc]
                                                  initWithFrame:indicatorBounds]autorelease];
    
    loadingIndicator.tag  = 1;
    loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [eaglView addSubview:loadingIndicator];
    [loadingIndicator startAnimating];
}

- (void) hideLoadingAnimation {
    UIActivityIndicatorView *loadingIndicator = (UIActivityIndicatorView *)[eaglView viewWithTag:1];
    [loadingIndicator removeFromSuperview];
}


#pragma mark - SampleApplicationControl

- (bool) doInitTrackers {
    // Initialize the image or marker tracker
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    
    // Image Tracker...
    QCAR::Tracker* trackerBase = trackerManager.initTracker(QCAR::ImageTracker::getClassType());
    if (trackerBase == NULL)
    {
        NSLog(@"Failed to initialize ImageTracker.");
        return false;
    }
    NSLog(@"Successfully initialized ImageTracker.");
    return true;
}

- (bool) doLoadTrackersData {
    dataSetSpooks = [self loadImageTrackerDataSet:@"ArtForSpooks.xml"];
    dataSetTarmac = [self loadImageTrackerDataSet:@"Tarmac.xml"];
    if ((dataSetSpooks == NULL) || (dataSetTarmac == NULL)) {
        NSLog(@"Failed to load datasets");
        return NO;
    }
    if (! [self activateDataSet:dataSetSpooks]) {
        NSLog(@"Failed to activate dataset");
        return NO;
    }
    
    
    return YES;
}

- (bool) doStartTrackers {
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker* tracker = trackerManager.getTracker(QCAR::ImageTracker::getClassType());
    if(tracker == 0) {
        return NO;
    }

    tracker->start();
    return YES;
}

// callback: the AR initialization is done
- (void) onInitARDone:(NSError *)initError {
    [self hideLoadingAnimation];
    
    if (initError == nil) {
        // If you want multiple targets being detected at once,
        // you can comment out this line
        // QCAR::setHint(QCAR::HINT_MAX_SIMULTANEOUS_IMAGE_TARGETS, 2);
        
        NSError * error = nil;
        [vapp startAR:QCAR::CameraDevice::CAMERA_BACK error:&error];
        NSLog(@"in onInitARDone");
        
        // by default, we try to set the continuous auto focus mode
        QCAR::CameraDevice::getInstance().setFocusMode(QCAR::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO);
        
        //  the camera is initialized, this call will reset the screen configuration
        [self handleRotation:self.interfaceOrientation];
    } else {
        NSLog(@"Error initializing AR:%@", [initError description]);
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Support all orientations
    return YES;
}


// Not using iOS6 specific enums in order to compile on iOS5 and lower versions
-(NSUInteger)supportedInterfaceOrientations
{
    return ((1 << UIInterfaceOrientationPortrait) | (1 << UIInterfaceOrientationLandscapeLeft) | (1 << UIInterfaceOrientationLandscapeRight) | (1 << UIInterfaceOrientationPortraitUpsideDown));
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // make sure we're oriented/sized properly before reappearing/restarting
    [self handleARViewRotation:self.interfaceOrientation];
}

// This is called on iOS 4 devices (when built with SDK 5.1 or 6.0) and iOS 6
// devices (when built with SDK 5.1)
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [self handleRotation:interfaceOrientation];
}

- (void) handleRotation:(UIInterfaceOrientation)interfaceOrientation {
    // ensure overlay size and AR orientation is correct for screen orientation
    [self handleARViewRotation:self.interfaceOrientation];
    //[bookOverlayController handleViewRotation:self.interfaceOrientation];
    [vapp changeOrientation:self.interfaceOrientation];
}

- (void) handleARViewRotation:(UIInterfaceOrientation)interfaceOrientation
{
    CGPoint centre, pos;
    NSInteger rot;
    
    // Set the EAGLView's position (its centre) to be the centre of the window, based on orientation
    centre.x = arViewRect.size.width / 2;
    centre.y = arViewRect.size.height / 2;
    
    if (interfaceOrientation == UIInterfaceOrientationPortrait)
    {
        NSLog(@"ARVC: Rotating to Portrait");
        pos = centre;
        rot = 90;
        
        CGRect viewBounds;
        viewBounds.origin.x = 0;
        viewBounds.origin.y = 0;
        viewBounds.size.width = arViewRect.size.width;
        viewBounds.size.height = arViewRect.size.height;
        
        [eaglView setFrame:viewBounds];
    }
    else if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        NSLog(@"ARVC: Rotating to Upside Down");
        pos = centre;
        rot = 270;
        
        CGRect viewBounds;
        viewBounds.origin.x = 0;
        viewBounds.origin.y = 0;
        viewBounds.size.width = arViewRect.size.width;
        viewBounds.size.height = arViewRect.size.height;
        
        [eaglView setFrame:viewBounds];
    }
    else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
    {
        NSLog(@"ARVC: Rotating to Landscape Left");
        pos.x = centre.y;
        pos.y = centre.x;
        rot = 180;
        
        CGRect viewBounds;
        viewBounds.origin.x = 0;
        viewBounds.origin.y = 0;
        //viewBounds.size.width = arViewRect.size.height;
        viewBounds.size.width = 568;
        //viewBounds.size.height = arViewRect.size.width;
        viewBounds.size.height = 320;
        
        [eaglView setFrame:viewBounds];
        CGRect afterBounds = [eaglView bounds];
        NSLog(@"viewBounds.size.width: %f; viewBounds.size.height: %f", viewBounds.size.width, viewBounds.size.height);
        NSLog(@"arViewRect.size.width: %f; arViewRect.size.height: %f", arViewRect.size.width, arViewRect.size.height);
        NSLog(@"afterBounds.origin.x: %f; afterBounds.origin.y: %f", afterBounds.origin.x, afterBounds.origin.y);
        NSLog(@"afterBounds.size.width: %f; afterBounds.size.height: %f", afterBounds.size.width, afterBounds.size.height);
    }
    else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        NSLog(@"ARVC: Rotating to Landscape Right");
        pos.x = centre.y;
        pos.y = centre.x;
        rot = 0;
        
        CGRect viewBounds;
        viewBounds.origin.x = 0;
        viewBounds.origin.y = 0;
        viewBounds.size.width = arViewRect.size.height;
        viewBounds.size.height = arViewRect.size.width;
        
        [eaglView setFrame:viewBounds];
    }
}


- (void) onQCARUpdate: (QCAR::State *) state {
    if (switchToTarmac) {
        [self activateDataSet:dataSetTarmac];
        switchToTarmac = NO;
    }
    if (switchToSpooks) {
        [self activateDataSet:dataSetSpooks];
        switchToSpooks = NO;
    }
}

// Load the image tracker data set
- (QCAR::DataSet *)loadImageTrackerDataSet:(NSString*)dataFile
{
    NSLog(@"loadImageTrackerDataSet (%@)", dataFile);
    QCAR::DataSet * dataSet = NULL;
    
    // Get the QCAR tracker manager image tracker
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ImageTracker* imageTracker = static_cast<QCAR::ImageTracker*>(trackerManager.getTracker(QCAR::ImageTracker::getClassType()));
    
    if (NULL == imageTracker) {
        NSLog(@"ERROR: failed to get the ImageTracker from the tracker manager");
        return NULL;
    } else {
        dataSet = imageTracker->createDataSet();
        
        if (NULL != dataSet) {
            NSLog(@"INFO: successfully loaded data set");
            
            // Load the data set from the app's resources location
            if (!dataSet->load([dataFile cStringUsingEncoding:NSASCIIStringEncoding], QCAR::STORAGE_APPRESOURCE)) {
                NSLog(@"ERROR: failed to load data set");
                imageTracker->destroyDataSet(dataSet);
                dataSet = NULL;
            }
        }
        else {
            NSLog(@"ERROR: failed to create data set");
        }
    }
    
    return dataSet;
}


- (bool) doStopTrackers {
    // Stop the tracker
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker* tracker = trackerManager.getTracker(QCAR::ImageTracker::getClassType());
    
    if (NULL != tracker) {
        tracker->stop();
        NSLog(@"INFO: successfully stopped tracker");
        return YES;
    }
    else {
        NSLog(@"ERROR: failed to get the tracker from the tracker manager");
        return NO;
    }
}

- (bool) doUnloadTrackersData {
    [self deactivateDataSet: dataSetCurrent];
    dataSetCurrent = nil;
    
    // Get the image tracker:
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ImageTracker* imageTracker = static_cast<QCAR::ImageTracker*>(trackerManager.getTracker(QCAR::ImageTracker::getClassType()));
    
    // Destroy the data sets:
    if (!imageTracker->destroyDataSet(dataSetTarmac))
    {
        NSLog(@"Failed to destroy data set Tarmac.");
    }
    if (!imageTracker->destroyDataSet(dataSetSpooks))
    {
        NSLog(@"Failed to destroy data set Spooks.");
    }
    
    NSLog(@"datasets destroyed");
    return YES;
}

- (BOOL)activateDataSet:(QCAR::DataSet *)theDataSet
{
    // if we've previously recorded an activation, deactivate it
    if (dataSetCurrent != nil)
    {
        [self deactivateDataSet:dataSetCurrent];
    }
    BOOL success = NO;
    
    // Get the image tracker:
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ImageTracker* imageTracker = static_cast<QCAR::ImageTracker*>(trackerManager.getTracker(QCAR::ImageTracker::getClassType()));
    
    if (imageTracker == NULL) {
        NSLog(@"Failed to load tracking data set because the ImageTracker has not been initialized.");
    }
    else
    {
        // Activate the data set:
        if (!imageTracker->activateDataSet(theDataSet))
        {
            NSLog(@"Failed to activate data set.");
        }
        else
        {
            NSLog(@"Successfully activated data set.");
            dataSetCurrent = theDataSet;
            success = YES;
        }
    }
    
    // we set the off target tracking mode to the current state
    if (success) {
        [self setExtendedTrackingForDataSet:dataSetCurrent start:extendedTrackingIsOn];
    }
    
    return success;
}

- (BOOL)deactivateDataSet:(QCAR::DataSet *)theDataSet
{
    if ((dataSetCurrent == nil) || (theDataSet != dataSetCurrent))
    {
        NSLog(@"Invalid request to deactivate data set.");
        return NO;
    }
    
    BOOL success = NO;
    
    // we deactivate the enhanced tracking
    [self setExtendedTrackingForDataSet:theDataSet start:NO];
    
    // Get the image tracker:
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ImageTracker* imageTracker = static_cast<QCAR::ImageTracker*>(trackerManager.getTracker(QCAR::ImageTracker::getClassType()));
    
    if (imageTracker == NULL)
    {
        NSLog(@"Failed to unload tracking data set because the ImageTracker has not been initialized.");
    }
    else
    {
        // Activate the data set:
        if (!imageTracker->deactivateDataSet(theDataSet))
        {
            NSLog(@"Failed to deactivate data set.");
        }
        else
        {
            success = YES;
        }
    }
    
    dataSetCurrent = nil;
    
    return success;
}

- (BOOL) setExtendedTrackingForDataSet:(QCAR::DataSet *)theDataSet start:(BOOL) start {
    BOOL result = YES;
    for (int tIdx = 0; tIdx < theDataSet->getNumTrackables(); tIdx++) {
        QCAR::Trackable* trackable = theDataSet->getTrackable(tIdx);
        if (start) {
            if (!trackable->startExtendedTracking())
            {
                NSLog(@"Failed to start extended tracking on: %s", trackable->getName());
                result = false;
            }
        } else {
            if (!trackable->stopExtendedTracking())
            {
                NSLog(@"Failed to stop extended tracking on: %s", trackable->getName());
                result = false;
            }
        }
    }
    return result;
}

- (bool) doDeinitTrackers {
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    trackerManager.deinitTracker(QCAR::ImageTracker::getClassType());
    return YES;
}

- (void)autofocus:(UITapGestureRecognizer *)sender
{
    [self performSelector:@selector(cameraPerformAutoFocus) withObject:nil afterDelay:.4];
}

- (void)cameraPerformAutoFocus
{
    QCAR::CameraDevice::getInstance().setFocusMode(QCAR::CameraDevice::FOCUS_MODE_TRIGGERAUTO);
}

@end
