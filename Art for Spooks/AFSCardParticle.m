//
//  AFSCardParticle.m
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 8/26/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import "AFSCardParticle.h"

float xRotMin = 0.0;
float xRotMax = 0.5;

float yRotMin = 0.0;
float yRotMax = 0.5;

float zRotMin = 0.0;
float zRotMax = 0.5;

float xPosMin = -20.0;
float xPosMax = 20.0;

float yPosMin = -10.0;
float yPosMax = 10.0;

float zPosMin = 2.0;
float zPosMax = 9.0;

double lifetimeMin = 1.5;
double lifetimeMax = 3.5;

float xStartPosMin = -100.0;
float xStartPosMax = 100.0;

float yStartPosMin = -50.0;
float yStartPosMax = 50.0;

float zStartPosMin = 1.0;
float zStartPosMax = 4.0;

float angleOffsetMin = 10.0;
float angleOffsetMax = 20.0;

@implementation AFSCardParticle
- (id)init {
    self = [super init];
    if (self) {
        [self setupCard];
    }
    return self;
}

- (void)setupCard {
    self.xStartRot = 0.0;
    self.yStartRot = 0.0;
    self.zStartRot = 0.0;
    
    self.xStartPos = 0.0;
    self.yStartPos = 0.0;
    self.zStartPos = 0.0;
    
    self.angleStart = 0.0;
    
    self.xRotOffset = [self randomFloatBetweenMin:xRotMin andMax:xRotMax];
    self.yRotOffset = [self randomFloatBetweenMin:yRotMin andMax:yRotMax];
    self.zRotOffset = [self randomFloatBetweenMin:zRotMin andMax:zRotMax];
    
    self.xPosOffset = [self randomFloatBetweenMin:xPosMin andMax:xPosMax];
    self.yPosOffset = [self randomFloatBetweenMin:yPosMin andMax:yPosMax];
    self.zPosOffset = [self randomFloatBetweenMin:zPosMin andMax:zPosMax];
    
    self.xStartPos = [self randomFloatBetweenMin:xStartPosMin andMax:xStartPosMax];
    self.yStartPos = [self randomFloatBetweenMin:yStartPosMin andMax:yStartPosMax];
    self.zStartPos = [self randomFloatBetweenMin:zStartPosMin andMax:zStartPosMax];
    
    self.angleOffset = [self randomFloatBetweenMin:angleOffsetMin andMax:angleOffsetMax];
    
    self.xPos = self.xStartPos;
    self.yPos = self.yStartPos;
    NSLog(@"Creating card, yPos: %f", self.yPos);
    self.zPos = self.zStartPos;
    
    self.xRot = self.xRotOffset;
    self.yRot = self.yRotOffset;
    self.zRot = self.zRotOffset;
    
    self.angle = self.angleStart;
    
    self.lifetime = [self randomDoubleBetweenMin:lifetimeMin andMax:lifetimeMax];
    
    self.createdTime = CACurrentMediaTime();

}

- (float)randomFloatBetweenMin:(float)min andMax:(float)max
{
    float range = max - min;
    return (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * range) + min;
}

- (double)randomDoubleBetweenMin:(double)min andMax:(double)max
{
    double range = max - min;
    return (((double) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * range) + min;
}
@end
