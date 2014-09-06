//
//  AFSInfoOverlayView.m
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 9/6/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import "AFSInfoOverlayView.h"

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
    NSLog(@"? being tapped");
    self.infoOverlayWebViewHidden = !self.infoOverlayWebViewHidden;
    [self.infoWebView setHidden:self.infoOverlayWebViewHidden];
}

- (IBAction)overlayShareTapped:(id)sender {
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
