//
//  AFSCardEmitterObject.h
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 8/26/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NUM_CARDS 8

@interface AFSCardEmitterObject : NSObject
@property (strong, nonatomic) NSMutableArray* cardEmitter;
- (void)updateLifeCycle;
- (void)setupCardEmitter;

@end
