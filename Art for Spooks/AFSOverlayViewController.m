//
//  AFSOverlayViewController.m
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 9/2/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import "AFSOverlayViewController.h"
#import "AFSOverlayView.h"


@interface AFSOverlayViewController ()

@end

@implementation AFSOverlayViewController

- (id)initWithDelegate:(id) delegate {
    self = [super init];
    if (self) {
        NSLog(@"in AFSOverlayViewController init");
        afsDelegate = delegate;
        //self.infoOverlayView = [[[NSBundle mainBundle] loadNibNamed:@"AFSInfoOverlayView" owner:nil options:nil] objectAtIndex:0];
        self.infoOverlayView = [[AFSInfoOverlayView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [self.infoOverlayView setBackgroundColor:[UIColor clearColor]];
        [self.infoOverlayView setOverlayInfoWebView:@"overlayInfo"];
        [self.view addSubview:self.infoOverlayView];
    }
    return self;
}

- (void)loadView {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    //[self.view setBounds:screenBounds];
    overlayView = [[AFSOverlayView alloc] initWithFrame: screenBounds];
    self.view = overlayView;
    
    //CGRect screenBounds = [[UIScreen mainScreen] bounds];

    // We don't need to do this...let this VC handle all interactions
    // We're going to let the parent VC handle all interactions so disable any UI
    // Further on, we'll also implement a touch pass-through
    //self.view.userInteractionEnabled = NO;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
