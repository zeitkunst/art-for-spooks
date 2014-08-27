//
//  AFSCardParticle.h
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 8/26/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import <Foundation/Foundation.h>

float xRotMin = 0.5;
float xRotMax = 3.0;

float yRotMin = 0.5;
float yRotMax = 3.0;

float zRotMin = 0.5;
float zRotMax = 0.5;

float xPosMin = -20.0;
float xPosMax = 20.0;

float yPosMin = -10.0;
float yPosMax = 10.0;

float zPosMin = 0.2;
float zPosMax = 0.9;

double lifetimeMin = 4.0;
double lifetimeMax = 8.0;

float xStartPosMin = -100.0;
float xStartPosMax = 100.0;

float yStartPosMin = -50.0;
float yStartPosMax = 50.0;

float zStartPosMin = 1.0;
float zStartPosMax = 4.0;

float angleOffsetMin = 5.0;
float angleOffsetMax = 20.0;

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

@end
