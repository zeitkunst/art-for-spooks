//
//  AFSCardEmitterObject.m
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 8/26/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import "AFSCardEmitterObject.h"
#import "AFSCardParticle.h"

@interface AFSCardEmitterObject ()

@end

@implementation AFSCardEmitterObject

- (id)init {
    self = [super init];
    if (self) {
        self.cardEmitter = [[NSMutableArray alloc] init];
        [self setupCardEmitter];
    }
    return self;
}

- (void)setupCardEmitter {
    
    for (int i = 0; i < NUM_CARDS; i++) {
        AFSCardParticle *newCard = [[AFSCardParticle alloc] init];
        [self.cardEmitter addObject:newCard];
    }
    AFSCardParticle *testingCard;
}

- (void)updateLifeCycle {
    for (int i = 0; i < NUM_CARDS; i++) {
        AFSCardParticle *currentCard = [[AFSCardParticle alloc] init];
        currentCard = [self.cardEmitter objectAtIndex:i];
        
        if ((CACurrentMediaTime() - currentCard.createdTime) > (currentCard.lifetime)) {
            [currentCard setupCard];
            [self.cardEmitter replaceObjectAtIndex:i withObject:currentCard];
        } else {
            currentCard.angle += currentCard.angleOffset;
            currentCard.zPos += currentCard.zPosOffset;
            [self.cardEmitter replaceObjectAtIndex:i withObject:currentCard];
        }
    }
}

@end
