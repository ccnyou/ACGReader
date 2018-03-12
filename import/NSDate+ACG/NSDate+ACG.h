//
//  NSDate+ACG.h
//  ACGReader
//
//  Created by ccnyou on 15/8/18.
//  Copyright (c) 2015年 ccnyou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (ACG)

- (NSDate *)acg_tomorrowDate;

- (NSDate *)yoyo_dateByAddingDay:(NSInteger)day;

- (BOOL)acg_isToday;

- (NSString *)acg_passTimeString;

@end
