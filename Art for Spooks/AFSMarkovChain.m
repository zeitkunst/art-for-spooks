//
//  AFSMarkovChain.m
//  Art for Spooks Twitter
//
//  Created by Nicholas A Knouf on 9/1/14.
//  Copyright (c) 2014 zeitkunst. All rights reserved.
//

#import "AFSMarkovChain.h"

@implementation AFSMarkovChain

#pragma mark - Initialization

- (id)init {
    self = [super init];
    if (self) {
        // Do some other initialization here
    }
    return self;
}


- (void)loadModelWithMaxChars:(int)maxChars {
    //[self tokenizeTextFrom:filename];
    [self loadMarkovModelFrom:@"art_for_spooks_model"];
    [self loadWordsFrom:@"art_for_spooks_words"];
    // TODO: BRITTLE: load this from some sort of config in the model json file
    self.order = 2;
    // TODO: get this from the Twitter guidelines; for now, setting to safe default of 90 characters
    self.textLength = maxChars;
}

- (void)loadModel {
    // A sensible default
    [self loadModelWithMaxChars:90];
}

#pragma mark - JSON loading methods

- (void)loadMarkovModelFrom:(NSString *)jsonFile {
    NSString *path = [[NSBundle mainBundle] pathForResource:jsonFile ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfFile:path];
    
    NSError *error = nil;
    
    id object = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    
    if ([object isKindOfClass:[NSDictionary class]] && error == nil) {
        self.markovChain = [[NSMutableDictionary alloc] initWithDictionary:object];
        //NSLog(@"%@", object);
    }
}

- (void)loadWordsFrom:(NSString *)jsonFile {
    NSString *path = [[NSBundle mainBundle] pathForResource:jsonFile ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfFile:path];
    
    NSError *error = nil;
    
    id object = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    
    if ([object isKindOfClass:[NSArray class]] && error == nil) {
        self.wordsArray = [[NSMutableArray alloc] initWithArray:object];
        //NSLog(@"%@", self.wordsArray);
    }
}

#pragma mark - Text generation methods

- (NSMutableString *)generateTextWith:(int)words limitToMaxChars:(BOOL) limitToMaxChars {
    NSUInteger randomWordIndex = arc4random() % [self.wordsArray count];
    NSString *randomWord = self.wordsArray[randomWordIndex];
    
    NSMutableArray *possibleStarts = [[NSMutableArray alloc] init];
    for (id key in self.markovChain) {
        if (!([key rangeOfString:randomWord].location == NSNotFound)) {
            [possibleStarts addObject:key];
        }
    }
    NSUInteger possibleStartsIndex = arc4random() % [possibleStarts count];
    NSMutableString *current = possibleStarts[possibleStartsIndex];
    //NSLog(@"current: %@", current);
    
    NSArray *currentComponents = [current componentsSeparatedByString:@" "];
    
    NSMutableArray *outputArray = [[NSMutableArray alloc] init];
    for (id item in currentComponents) {
        [outputArray addObject:item];
    }
    //NSLog(@"outputArray: %@", outputArray);
    
    //NSMutableString *outputString = [[NSMutableString alloc] initWithString:current];
    
    for (int i = 0; i < words; i++) {
        //NSLog(@"ON LOOP %d", i);
        NSArray *possibleNext = [[NSArray alloc] initWithArray:self.markovChain[current]];
        //NSLog(@"possibleNext: %@", possibleNext);
        NSUInteger possibleNextIndex = arc4random() % [possibleNext count];
        //NSLog(@"possibleNextIndex: %d", possibleNextIndex);
        NSString *nextNgram = [[NSString alloc] initWithString:possibleNext[possibleNextIndex]];
        [outputArray addObject:nextNgram];
        
        NSMutableString *currentNgrams = [[NSMutableString alloc] init];
        NSArray *fragment = [outputArray subarrayWithRange:NSMakeRange([outputArray count] - self.order, self.order)];
        for (id gram in fragment) {
            currentNgrams = [NSMutableString stringWithFormat:@"%@ %@", currentNgrams, gram];
        }
        current = [NSMutableString stringWithString:currentNgrams];
        current = (NSMutableString *)[current stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //NSLog(@"current: %@", current);
    }
    
    // Now go through the tagger so that we can format and decide on the length of the string
    NSLinguisticTaggerOptions options = NSLinguisticTaggerOmitWhitespace | NSLinguisticTaggerJoinNames;
    NSLinguisticTagger *tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:[NSLinguisticTagger availableTagSchemesForLanguage:@"en"] options:options];
    NSMutableString *outputStringTemp = [[NSMutableString alloc] initWithString:[outputArray componentsJoinedByString:@" "]];
    NSMutableString *outputString = [[NSMutableString alloc] initWithString:@""];
    
    // Create our string to tag from the output array
    tagger.string = outputStringTemp;

    // Was the previous tag punctuation?
    __block BOOL previousTagPunctuation = NO;
    
    // Run our tagger
    [tagger enumerateTagsInRange:NSMakeRange(0, [outputStringTemp length]) scheme:NSLinguisticTagSchemeTokenType options:options usingBlock:^(NSString *tag, NSRange tokenRange, NSRange sentenceRange, BOOL *stop) {
        NSString *currentToken = [outputStringTemp substringWithRange:tokenRange];
        
        if (limitToMaxChars) {
            if (([outputString length] + [currentToken length] + 1) > self.textLength) {
                *stop = YES;
            }
        }
        
        if ([tag isEqualToString:@"Word"]) {
            if (previousTagPunctuation) {
                [outputString appendFormat:@"%@", currentToken];
            } else {
                [outputString appendFormat:@" %@", currentToken];
            }
            previousTagPunctuation = NO;
        } else if ([tag isEqualToString:@"Punctuation"]) {
            if ([currentToken isEqualToString:@"'"]) {
                [outputString appendFormat:@"%@", currentToken];
            } else {
                [outputString appendFormat:@"%@ ", currentToken];
            }
            previousTagPunctuation = YES;
        }
        
        //NSArray *currentToken = [[NSArray alloc] initWithObjects:[outputStringTemp substringWithRange:tokenRange], tag, nil];
        //[self.tokensArray addObject:currentToken];
        //[self.tokensArray addObject:[outputString substringWithRange:tokenRange]];
        //NSLog(@"token tag: %@", tag);
        //NSLog(@"token: %@", [fileString substringWithRange:tokenRange]);
    }];
    
    return outputString;
}

#pragma mark - Markov model generation methods (likely unneeded)
- (void)tokenizeTextFrom:(NSString *)corpusFile {
    self.tokensArray = [[NSMutableArray alloc] init];
    self.markovChain = [[NSMutableDictionary alloc] init];
    
    NSError *readError = nil;
    NSString* path = [[NSBundle mainBundle] pathForResource:corpusFile ofType:@"txt"];
    NSString *fileString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&readError];
    if (readError) {
        NSLog(@"Error reading file: %@", [readError localizedDescription]);
    } else {
        //NSLog(@"Corpus string: %@", fileString);
        
        NSLinguisticTaggerOptions options = NSLinguisticTaggerOmitWhitespace | NSLinguisticTaggerJoinNames;
        NSLinguisticTagger *tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:[NSLinguisticTagger availableTagSchemesForLanguage:@"en"] options:options];
        tagger.string = fileString;
        
        [tagger enumerateTagsInRange:NSMakeRange(0, [fileString length]) scheme:NSLinguisticTagSchemeTokenType options:options usingBlock:^(NSString *tag, NSRange tokenRange, NSRange sentenceRange, BOOL *stop) {
            NSArray *currentToken = [[NSArray alloc] initWithObjects:[fileString substringWithRange:tokenRange], tag, nil];
            //[self.tokensArray addObject:currentToken];
            [self.tokensArray addObject:[fileString substringWithRange:tokenRange]];
            //NSLog(@"token tag: %@", tag);
            //NSLog(@"token: %@", [fileString substringWithRange:tokenRange]);
        }];
        
        //NSLog(@"total tokens: %d", [self.tokensArray count]);
        [self generateModelWithOrder:4];
    }
}

- (void)generateModelWithOrder:(int)order {
    for (int i = 0; i < ([self.tokensArray count] - order); i++) {
        NSArray *fragment = [self.tokensArray subarrayWithRange:NSMakeRange(i, order)];
        NSArray *nextWord = self.tokensArray[i + order];
        NSArray *keys = [self.markovChain allKeys];
        
        // If our keys don't already contain the fragment, create an empty dictionary
        if (![keys containsObject:fragment]) {
            [self.markovChain setObject:[[NSMutableDictionary alloc] init] forKey:fragment];
        }
        
        //NSMutableDictionary *fragmentDict = [self.markovChain objectForKey:fragment];
        
        
    }
}
@end
