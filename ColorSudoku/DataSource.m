#import "DataSource.h"

@implementation DataSource

NSString *_str_data;
NSMutableArray *_data_array;
NSMutableArray *_puzzle_array;
NSMutableArray *ma;  // reusable variable

- (id)init{
    if (self = [super init]) {
        return self;
    }
    return nil;
}

- (NSMutableArray *)getData {
    return _data_array;
}

- (void)setData:(NSMutableArray *)new_value {
    _data_array = new_value;
}

- (void)loadBundleData {
    NSBundle *b = [NSBundle mainBundle];
    NSString *s = @"puzzles";
    NSString *p = [b pathForResource:s ofType:@"txt"];
    NSString *puzzle_data = [self loadDataFromFile:p];
    NSArray *a = [puzzle_data componentsSeparatedByString:@"\n"];
    
    // filter the array for blank lines or comment lines
    _puzzle_array = [[NSMutableArray alloc] init];
    for (NSString * line in a) {
        if ([line hasPrefix:@"#"]) { continue; }
        if ([line isEqualToString:@""]) { continue; }
        [_puzzle_array addObject:line];
    }
    [self loadPuzzleAtIndex:0];
}

- (void)loadPuzzleAtIndex:(int)i {
    NSString *demo = [_puzzle_array objectAtIndex:i];
    _str_data = demo;
    [self convertStringToDataArray:_str_data];
}


- (NSString *)loadDataFromFile:(NSString *)fn {
    NSError *e;
    NSString *str = [[NSString alloc]
                     initWithContentsOfFile:fn
                     encoding:NSUTF8StringEncoding
                     error:&e];
    if (e != nil) {
        NSLog(@"%@", [e localizedDescription]);
    }
    return str;
}

- (void)convertStringToDataArray:(NSString *)s {
    ma = [[NSMutableArray alloc] init];
    NSMutableArray *tmp;
    // filter first
    for (int i = 0; i < s.length; i++) {
        
        // is the next charcter in allowed set?
        NSRange r = NSMakeRange(i,1);
        NSString *c = [s substringWithRange:r];
        NSRange r2 = [@"123456789.0" rangeOfString:c];
        if (r2.location == NSNotFound) { continue; }
        
        // "0" and "." are synonyms, 1..9 each allowed
        if ([c isEqualToString:@"."] || [c isEqualToString:@"0"]) {
            NSMutableArray *all = [[NSMutableArray alloc] init];
            for (int i = 1; i < 10; i++) {
                [all addObject:[NSNumber numberWithInt:i ]];
            }
            tmp = all;
        }
        else {
            NSInteger n = (NSInteger)[c integerValue];
            NSNumber *num = [NSNumber numberWithInteger:n];
            tmp = [NSMutableArray arrayWithArray:@[num]];
        }
        [ma addObject:tmp];
    }
    _data_array = ma;
}

- (NSString*)description{
    if (! _data_array) { return @"no data"; }
    ma = [[NSMutableArray alloc] init];
    for (int i = 0; i < _data_array.count; i++ ) {
        if (i == 5) { break; }
        NSArray *a = [_data_array objectAtIndex:i];
        if (a.count == 1) {
            NSString *s = [[a objectAtIndex:0] stringValue];
            [ma addObject:s];
        }
        else {
            [ma addObject:@"."];
        }
    }
    return [ma componentsJoinedByString:@""];
}

// check whether proposed move is "coherent"
// (would result in an illegal/conflicting board)

- (BOOL)isLegalMoveForIndex:(int)i
               editedSquare:(NSMutableArray *)sq {
    // just a simple check:
    if (sq.count > 1) { return YES; }
    NSNumber *n = [sq objectAtIndex:0];
    
    // check squares in same row, col or box
    for (int j = 0; j < 81; j++) {
        if (([self sameRowFirstIndex:i
                         secondIndex:j]) ||
            ([self sameColFirstIndex:i
                         secondIndex:j]) ||
            ([self sameBoxFirstIndex:i
                         secondIndex:j])) {
            
            NSMutableArray *sq2 = [_data_array objectAtIndex:j];
            
            // just a simple check:
            if (sq2.count > 1) { continue; }
            if ([[sq2 objectAtIndex:0] isEqualTo:n]) {
                return NO;
            }
        }
    }
    return YES;
}

// check whether two squares are same row or column

- (BOOL)sameRowFirstIndex:(int)i secondIndex:(int)j {
    if ((i / 9) == (j / 9)) { return YES; }
    return NO;
}

- (BOOL)sameColFirstIndex:(int)i secondIndex:(int)j {
    if ((i % 9) == (j % 9)) { return YES; }
    return NO;
}

/*
most of the rest of the code checks to see whether
two squares are in the same 3 x 3 "box"

*/

// know the size is 9
- (BOOL)value:(int)v isInArray:(int [])a {
    for (int j = 0; j < 9; j++) {
        if (a[j] == v) { return YES; }
    }
    return NO;
}

- (BOOL)sameBoxFirstIndex:(int)i secondIndex:(int)j {
    int a[9] = {0,1,2,9,10,11,18,19,20};
    if ([self value:i isInArray:a]) {
        if ([self value:j isInArray:a]) {
            return YES;
        }
    }
    int b[9] = {3,4,5,12,13,14,21,22,23};
    if ([self value:i isInArray:b]) {
        if ([self value:j isInArray:b]) {
            return YES;
        }
    }
    int c[9] = {6,7,8,15,16,17,24,25,26};
    if ([self value:i isInArray:c]) {
        if ([self value:j isInArray:c]) {
            return YES;
        }
    }
    int d[9] = {27,28,29,36,37,38,45,46,47};
    if ([self value:i isInArray:d]) {
        if ([self value:j isInArray:d]) {
            return YES;
        }
    }
    int e[9] = {30,31,32,39,40,41,48,49,50};
    if ([self value:i isInArray:e]) {
        if ([self value:j isInArray:e]) {
            return YES;
        }
    }
    int f[9] = {33,34,35,42,43,44,51,52,53};
    if ([self value:i isInArray:f]) {
        if ([self value:j isInArray:f]) {
            return YES;
        }
    }
    int g[9] = {54,55,56,63,64,65,72,73,74};
    if ([self value:i isInArray:g]) {
        if ([self value:j isInArray:g]) {
            return YES;
        }
    }
    int h[9] = {57,58,59,66,67,68,75,76,77};
    if ([self value:i isInArray:h]) {
        if ([self value:j isInArray:h]) {
            return YES;
        }
    }
    int aa[9] = {60,61,62,69,70,71,78,79,80};
    if ([self value:i isInArray:aa]) {
        if ([self value:j isInArray:aa]) {
            return YES;
        }
    }
    return NO;
}

// if there is only one choice for square at index
// i *or* j, eliminate that choice for the other one

- (void)makeDataCoherentFirstIndex:(int) i secondIndex:(int) j {
    NSMutableArray *a = _data_array[i];
    NSMutableArray *b = _data_array[j];
    if(!(a.count == 1 && b.count == 1)) {
        // fails, why?
        // assert ([a objectAtIndex:0] != [b objectAtIndex:0]);
    }
    if (a.count > 1 && b.count == 1) {
        NSNumber *n = [b objectAtIndex:0];
        [a removeObject:n];
        _data_array[i] = a;
    }
    if (b.count > 1 && a.count == 1) {
        NSNumber *n = [a objectAtIndex:0];
        [b removeObject:n];
        _data_array[j] = b;
    }
}

// triggered from buttons in the window

- (void)cleanRows {
    for (int i = 0; i < 80; i++) {
        for (int j = i+1; j < 81; j++) {
            if ([self sameRowFirstIndex:i secondIndex:j]) {
                [self makeDataCoherentFirstIndex:i secondIndex:j];
            }
        }
    }
}

- (void)cleanCols {
    for (int i = 0; i < 80; i++) {
        for (int j = i+1; j < 81; j++) {
            if ([self sameColFirstIndex:i secondIndex:j]) {
                [self makeDataCoherentFirstIndex:i secondIndex:j];
            }
        }
    }
}

- (void)cleanBoxes {
    for (int i = 0; i < 80; i++) {
        for (int j = i+1; j < 81; j++) {
            if ([self sameBoxFirstIndex:i secondIndex:j]) {
                [self makeDataCoherentFirstIndex:i secondIndex:j];
            }
        }
    }
}

@end
