//
//  AFSInfoOverlayView.h
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 9/6/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AFSInfoOverlayView : UIView
@property (weak, nonatomic) IBOutlet UIWebView *infoWebView;
@property (weak, nonatomic) IBOutlet UIButton *overlayQuestionMarkButton;
@property (weak, nonatomic) IBOutlet UIButton *overlayShareButton;

@property (nonatomic) BOOL infoOverlayWebViewHidden;

- (void)setOverlayInfoWebView:(NSString *)infoHTMLFilename;

@end
