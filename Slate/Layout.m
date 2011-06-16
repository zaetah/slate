//
//  Layout.m
//  Slate
//
//  Created by Jigish Patel on 6/13/11.
//  Copyright 2011 Jigish Patel. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see http://www.gnu.org/licenses

#import "ApplicationOptions.h"
#import "Constants.h"
#import "Layout.h"
#import "Operation.h"
#import "OperationFactory.h"
#import "StringTokenizer.h"


@implementation Layout

@synthesize name;
@synthesize appStates;
@synthesize appOptions;

- (id)init {
  self = [super init];
  if (self) {
    appStates = [[NSMutableDictionary alloc] init];
    appOptions = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (id)initWithString:(NSString *)layout {
  self = [self init];
  if (self) {
    [self addWithString:layout];
  }
  return self;
}

- (void)addWithString:(NSString *)layout {
  // layout <name> <app name> <op+params> (| <op+params>)*
  NSMutableArray *tokens = [[NSMutableArray alloc] initWithCapacity:10];
  [StringTokenizer tokenize:layout into:tokens maxTokens:4 quoteChars:[NSCharacterSet characterSetWithCharactersInString:QUOTES]];
  if ([tokens count] <=3) {
    @throw([NSException exceptionWithName:@"Unrecognized Layout" reason:layout userInfo:nil]);
  }

  [self setName:[tokens objectAtIndex:1]];

  NSArray *appNameAndOptions = [[tokens objectAtIndex:2] componentsSeparatedByString:COLON];
  NSString *appName = [appNameAndOptions objectAtIndex:0];
  if ([appNameAndOptions count] > 1) {
    NSString *options = [appNameAndOptions objectAtIndex:1];
    ApplicationOptions *appOpts = [[ApplicationOptions alloc] init];
    NSArray *optArr = [options componentsSeparatedByString:COMMA];
    for (NSInteger i = 0; i < [optArr count]; i++) {
      NSString *option = [optArr objectAtIndex:i];
      if ([option isEqualToString:IGNORE_FAIL]) {
        [appOpts setIgnoreFail:YES];
      } else if ([option isEqualToString:REPEAT]) {
        [appOpts setRepeat:YES];
      } else if ([option isEqualToString:MAIN_FIRST]) {
        [appOpts setMainFirst:YES];
      } else if ([option isEqualToString:MAIN_LAST]) {
        [appOpts setMainLast:YES];
      } else if ([option isEqualToString:SORT_ALPHA]) {
        [appOpts setAlphabetical:YES];
      }
    }
    [appOptions setObject:appOpts forKey:appName];
    [appOpts release];
  } else {
    [appOptions setObject:[[[ApplicationOptions alloc] init] autorelease] forKey:appName];
  }
  NSString *opsString = [tokens objectAtIndex:3];
  NSArray *ops = [opsString componentsSeparatedByString:PIPE];
  NSMutableArray *opArray = [[NSMutableArray alloc] initWithCapacity:10];
  for (NSInteger i = 0; i < [ops count]; i++) {
    Operation *op = [OperationFactory createOperationFromString:[ops objectAtIndex:i]];
    if (op != nil) {
      [opArray addObject:op];
    } else {
      NSLog(@"ERROR: Invalid Operation in Chain: '%@'", [ops objectAtIndex:i]);
      @throw([NSException exceptionWithName:@"Invalid Operation in Chain" reason:[NSString stringWithFormat:@"Invalid operation '%@' in chain.", [ops objectAtIndex:i]] userInfo:nil]);
    }
  }

  [[self appStates] setObject:opArray forKey:appName];
  [opArray release];
  [tokens release];
}

@end