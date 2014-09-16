//
//  AFSDroneCoords.m
//  Art for Spooks Twitter
//
//  Created by Nicholas A Knouf on 9/1/14.
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

    NSString *latCoord, *longCoord, *location, *date, *numCivilians;
    
    while ([scanner scanUpToString:@"," intoString:&latCoord] && [scanner scanUpToString:@"," intoString:&longCoord] && [scanner scanUpToString:@"," intoString:&location] && [scanner scanUpToString:@"," intoString:&date] && [scanner scanUpToString:@"\r" intoString:&numCivilians]) {
        //NSLog(@"lat: %@; long: %@", latCoord, longCoord);
        NSArray *currentCoord = [[NSArray alloc] initWithObjects:latCoord, longCoord, location, date, numCivilians, nil];
        [self.droneCoords addObject:currentCoord];
    }
}

- (NSArray *)randomDroneCoord {
    NSUInteger randomIndex = arc4random() % [self.droneCoords count];
    return self.droneCoords[randomIndex];
}

@end
