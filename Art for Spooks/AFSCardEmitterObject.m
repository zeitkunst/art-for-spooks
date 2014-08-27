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
        //self.cardEmitter.eCards[i].cardID = i;
        AFSCardParticle *newCard = [[AFSCardParticle alloc] init];
        NSLog(@"newCard yPos: %f", newCard.yPos);
        [self.cardEmitter addObject:newCard];
    }
    AFSCardParticle *testingCard;
    testingCard = [self.cardEmitter objectAtIndex:7];
    NSLog(@"testingCard at index 7 yPos: %f", testingCard.yPos);
}

- (void)updateLifeCycle {
    for (int i = 0; i < NUM_CARDS; i++) {
        //NSLog(@"CACurrentMediaTime: %f", CACurrentMediaTime());
        //NSLog(@"createdTime: %f", self.cardEmitter.eCards[i].createdTime);
        //NSLog(@"lifetime: %f", self.cardEmitter.eCards[i].lifetime);
        AFSCardParticle *currentCard = [[AFSCardParticle alloc] init];
        currentCard = [self.cardEmitter objectAtIndex:i];
        
        if ((CACurrentMediaTime() - currentCard.createdTime) > (currentCard.lifetime)) {
            NSLog(@"RESETTING CARD %d", i);
            [currentCard setupCard];
            [self.cardEmitter replaceObjectAtIndex:i withObject:currentCard];
        } else {
            //self.cardEmitter.eCards[i].xPos += self.cardEmitter.eCards[i].xPosOffset;
            //self.cardEmitter.eCards[i].yPos += self.cardEmitter.eCards[i].yPosOffset;
            //self.cardEmitter.eCards[i].zPos += self.cardEmitter.eCards[i].zPosOffset;
            
            //self.cardEmitter.eCards[i].xRot += self.cardEmitter.eCards[i].xRotOffset;
            //self.cardEmitter.eCards[i].yRot += self.cardEmitter.eCards[i].yRotOffset;
            //self.cardEmitter.eCards[i].zRot += self.cardEmitter.eCards[i].zRotOffset;
            
            //self.cardEmitter.eCards[i].angle += self.cardEmitter.eCards[i].angleOffset;
            currentCard.angle += currentCard.angleOffset;
            currentCard.zPos += 3*currentCard.zPosOffset;
            [self.cardEmitter replaceObjectAtIndex:i withObject:currentCard];
            NSLog(@"currentCard angle: %f", currentCard.angle);
            //NSLog(@"angle: %f", [self.cardEmitter objectAtIndex:i]);
            //NSLog(@"angleOffset: %f", self.cardEmitter.eCards[i].angleOffset);
        }
    }
}

@end
