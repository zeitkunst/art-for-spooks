//
//  AFSMarkovChain.h
//  Art for Spooks Twitter
//
//  Created by Nicholas A Knouf on 9/1/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AFSMarkovChain : NSObject
@property (nonatomic, strong) NSMutableArray *tokensArray;
@property (nonatomic, strong) NSMutableArray *wordsArray;
@property (nonatomic, strong) NSMutableDictionary *markovChain;
@property (nonatomic) int order;
@property (nonatomic) int textLength;

- (void)loadModelWithMaxChars:(int)maxChars;
- (void)loadModel;
- (void)tokenizeTextFrom:(NSString *)corpusFile;
- (void)generateModelWithOrder:(int)order;
- (NSMutableString *)generateTextWith:(int)words limitToMaxChars:(BOOL) limitToMaxChars;
@end
