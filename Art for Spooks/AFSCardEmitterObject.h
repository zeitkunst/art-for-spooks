//
//  AFSCardEmitterObject.h
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 8/26/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NUM_CARDS 8

typedef struct Card {
    int cardID;
    float xRotOffset;
    float yRotOffset;
    float zRotOffset;
    float xPosOffset;
    float yPosOffset;
    float zPosOffset;
    float angleOffset;
    
    float xStartRot;
    float yStartRot;
    float zStartRot;
    
    float xStartPos;
    float yStartPos;
    float zStartPos;
    
    float xPos;
    float yPos;
    float zPos;
    
    float xRot;
    float yRot;
    float zRot;
    
    float angle;
    
    float angleStart;
    
    double lifetime;
    double createdTime;
} Card;

typedef struct CardEmitter {
    Card eCards[NUM_CARDS];
} CardEmitter;

Card testingCard;

@interface AFSCardEmitterObject : NSObject
@property CardEmitter cardEmitter;
- (void)updateLifeCycle;
- (void)setupCardEmitter;
- (Card)createNewCardParticle;
- (float)randomFloatBetweenMin:(float)min andMax:(float)max;
- (Card)getCardFor:(int) cardID;
- (float *)getPosFor:(int) cardID;

@end
