//
//  AFSDroneCoords.m
//  Art for Spooks Twitter
//
//  Created by Nicholas A Knouf on 9/1/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import "AFSDroneCoords.h"

@implementation AFSDroneCoords

- (id)initWithFilename:(NSString *)filename {
    self = [super init];
    if (self) {
        [self loadCoordsFrom:filename];
    }
    return self;
}

- (void)loadCoordsFrom:(NSString *)droneCoordsFile {
    // Basic CSV scanning from: http://stackoverflow.com/questions/5503791/objective-c-read-a-csv-file
    self.droneCoords = [[NSMutableArray alloc] init];
    NSError *readError = nil;
    NSString* path = [[NSBundle mainBundle] pathForResource:droneCoordsFile ofType:@"csv"];
    NSString *fileString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&readError];
    if (!fileString) {
        NSLog(@"Error reading drone coordinates file.");
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:fileString];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\r ,"]];

    NSString *latCoord, *longCoord;
    
    while ([scanner scanUpToString:@"," intoString:&latCoord] && [scanner scanUpToString:@"\r" intoString:&longCoord]) {
        //NSLog(@"lat: %@; long: %@", latCoord, longCoord);
        NSArray *currentCoord = [[NSArray alloc] initWithObjects:latCoord, longCoord, nil];
        [self.droneCoords addObject:currentCoord];
    }
}

- (NSArray *)randomDroneCoord {
    NSUInteger randomIndex = arc4random() % [self.droneCoords count];
    return self.droneCoords[randomIndex];
}

@end
