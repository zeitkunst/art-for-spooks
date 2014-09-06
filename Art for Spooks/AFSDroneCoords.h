//
//  AFSDroneCoords.h
//  Art for Spooks Twitter
//
//  Created by Nicholas A Knouf on 9/1/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AFSDroneCoords : NSObject
@property (nonatomic, strong) NSMutableArray *droneCoords;

- (id)initWithFilename:(NSString *)filename;
- (void)loadCoordsFrom:(NSString *)droneCoordsFile;
- (NSArray *)randomDroneCoord;
- (void)tokenizeTextFrom:(NSString *)textFilename;
@end
