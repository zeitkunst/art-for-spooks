//
//  AFSCardParticle.h
//  Art for Spooks
//
//  Created by Nicholas A Knouf on 8/26/14.
//  Copyright (c) 2014 Nicholas A. Knouf
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

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
