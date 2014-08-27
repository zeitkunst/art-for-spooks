//
//  AFSCardParticle.h
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 8/26/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AFSCardParticle : NSObject
@property int cardID;
@property float xRotOffset;
@property float yRotOffset;
@property float zRotOffset;

@property float xPosOffset;
@property float yPosOffset;
@property float zPosOffset;

@property float angleOffset;

@property float xStartRot;
@property float yStartRot;
@property float zStartRot;

@property float xStartPos;
@property float yStartPos;
@property float zStartPos;

@property float xPos;
@property float yPos;
@property float zPos;

@property float xRot;
@property float yRot;
@property float zRot;

@property float angle;

@property float angleStart;

@property double lifetime;
@property double createdTime;

- (void)setupCard;
- (float)randomFloatBetweenMin:(float)min andMax:(float)max;
- (double)randomDoubleBetweenMin:(double)min andMax:(double)max;

@end
