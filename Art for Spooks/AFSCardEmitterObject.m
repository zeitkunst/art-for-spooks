//
//  AFSCardEmitterObject.m
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 8/26/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import "AFSCardEmitterObject.h"

@interface AFSCardEmitterObject ()

@end

@implementation AFSCardEmitterObject

- (id)init {
    if (self = [super init]) {
        [self setupCardEmitter];
    }
    return self;
}

- (void)setupCardEmitter {
    CardEmitter newEmitter = {0.0f};
    
    for (int i = 0; i < NUM_CARDS; i++) {
        //self.cardEmitter.eCards[i].cardID = i;
        newEmitter.eCards[i] = [self createNewCardParticle];
    }
    self.cardEmitter = newEmitter;
}

- (void)updateLifeCycle {
    for (int i = 0; i < NUM_CARDS; i++) {
        //NSLog(@"CACurrentMediaTime: %f", CACurrentMediaTime());
        //NSLog(@"createdTime: %f", self.cardEmitter.eCards[i].createdTime);
        //NSLog(@"lifetime: %f", self.cardEmitter.eCards[i].lifetime);
        
        if ((CACurrentMediaTime() - self.cardEmitter.eCards[i].createdTime) > (self.cardEmitter.eCards[i].lifetime)) {
            NSLog(@"REMOVING CARD %d", i);
            self.cardEmitter.eCards[i] = [self createNewCardParticle];
        } else {
            //self.cardEmitter.eCards[i].xPos += self.cardEmitter.eCards[i].xPosOffset;
            //self.cardEmitter.eCards[i].yPos += self.cardEmitter.eCards[i].yPosOffset;
            //self.cardEmitter.eCards[i].zPos += self.cardEmitter.eCards[i].zPosOffset;
            
            //self.cardEmitter.eCards[i].xRot += self.cardEmitter.eCards[i].xRotOffset;
            //self.cardEmitter.eCards[i].yRot += self.cardEmitter.eCards[i].yRotOffset;
            //self.cardEmitter.eCards[i].zRot += self.cardEmitter.eCards[i].zRotOffset;
            
            //self.cardEmitter.eCards[i].angle += self.cardEmitter.eCards[i].angleOffset;
            Card currentCard = self.cardEmitter.eCards[i];
            currentCard.angle += currentCard.angleOffset;
            self.cardEmitter.eCards[i] = currentCard;
            //self.cardEmitter.eCards[i].angle += self.cardEmitter.eCards[i].angleOffset;
            NSLog(@"currentCard angle: %f", currentCard.angle);
            NSLog(@"angle: %f", self.cardEmitter.eCards[i].angle);
            NSLog(@"angleOffset: %f", self.cardEmitter.eCards[i].angleOffset);
        }
    }
}

@end
