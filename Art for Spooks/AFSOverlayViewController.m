//
//  AFSOverlayViewController.m
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 9/2/14.
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

#import "AFSOverlayViewController.h"
#import "AFSOverlayView.h"


@interface AFSOverlayViewController ()

@end

@implementation AFSOverlayViewController

- (id)initWithDelegate:(id) delegate {
    self = [super init];
    if (self) {
        //NSLog(@"in AFSOverlayViewController init");
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
    self.view.userInteractionEnabled = YES;
    
}

- (void) handleViewRotation:(UIInterfaceOrientation)interfaceOrientation
{
    // adjust the size according to the rotation
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGRect overlayRect = screenRect;
    
    if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        overlayRect.size.width = screenRect.size.height;
        overlayRect.size.height = screenRect.size.width;
    }
    
    self.view.frame = overlayRect;
    self.view.userInteractionEnabled = YES;
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
