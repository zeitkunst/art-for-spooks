//
//  AFSCardEmitterObject.m
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
