//
//  AFSInfoOverlayView.h
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 9/6/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AFSInfoOverlayView : UIView {
    // Timer to hide status label
    NSTimer* statusLabelTimer;
}
@property (weak, nonatomic) IBOutlet UIWebView *infoWebView;
@property (weak, nonatomic) IBOutlet UIButton *overlayQuestionMarkButton;
@property (weak, nonatomic) IBOutlet UIButton *overlayShareButton;

@property (nonatomic) BOOL infoOverlayWebViewHidden;
@property (weak, nonatomic) IBOutlet UILabel *overlayStatusLabel;


- (void)setOverlayInfoWebView:(NSString *)infoHTMLFilename;
- (void)tweetWithStatus:(NSString *)status andCoords:(NSArray *) chosenCoord;
@end
