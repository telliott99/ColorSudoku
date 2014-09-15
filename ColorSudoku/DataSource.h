//
//  DataSource.h
//  Test
//
//  Created by Tom Elliott on 9/14/14.
//  Copyright (c) 2014 Tom Elliott. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataSource : NSObject


- (void)loadBundleData;
- (NSString *)loadDataFromFile:(NSString *)fn;

- (void)loadPuzzleAtIndex:(int)i;
- (void)convertStringToDataArray:(NSString *)s;

- (NSMutableArray *)getData;
- (void)setData:(NSMutableArray *)new_value;

- (BOOL)sameRowFirstIndex:(int)i secondIndex:(int)j;
- (BOOL)sameColFirstIndex:(int)i secondIndex:(int)j;
- (BOOL)value:(int)v isInArray:(int [])a;
- (BOOL)sameBoxFirstIndex:(int)i secondIndex:(int)j;
- (void)makeDataCoherentFirstIndex:(int) i secondIndex:(int) j;

- (BOOL)isLegalMoveForIndex:(int)i
               editedSquare:(NSMutableArray *)sq;

- (void)cleanRows;
- (void)cleanCols;
- (void)cleanBoxes;

@end
