//
//  AFSOverlayViewController.h
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 9/2/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFSInfoOverlayView.h"

@interface AFSOverlayViewController : UIViewController {
    id afsDelegate;
    UIView *overlayView;
}
@property (nonatomic, retain) IBOutlet AFSInfoOverlayView *infoOverlayView;
- (id)initWithDelegate:(id) delegate;
@end
