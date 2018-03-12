//
//  NSDate+ACG.m
//  ACGReader
//
//  Created by ccnyou on 15/8/18.
//  Copyright (c) 2015年 ccnyou. All rights reserved.
//

#import "NSDate+ACG.h"

@implementation NSDate (ACG)

- (NSDate *)acg_tomorrowDate {
    return [self yoyo_dateByAddingDay:1];
}

- (NSDate *)yoyo_dateByAddingDay:(NSInteger)day {
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setDay:day];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *date = [calendar dateByAddingComponents:dateComponents toDate:self options:0];

    return date;
}

- (BOOL)acg_isToday {
    NSDateComponents *otherDay = [[NSCalendar currentCalendar] components:NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self];
    NSDateComponents *today = [[NSCalendar currentCalendar] components:NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:[NSDate date]];
    if ([today day] == [otherDay day] &&
            [today month] == [otherDay month] &&
            [today year] == [otherDay year] &&
            [today era] == [otherDay era]) {
        return YES;
    }

    return NO;
}

- (NSString *)acg_passTimeString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSString *timeString = @"";

    if ([self acg_isToday]) {
        [formatter setDateFormat:@"HH:mm"];
        timeString = [formatter stringFromDate:self];
    } else if (self.acg_tomorrowDate.acg_isToday) {
        [formatter setDateFormat:@"HH:mm"];
        NSString *tmpString = [formatter stringFromDate:self];
        timeString = [timeString stringByAppendingFormat:@"昨天 %@", tmpString];
    } else if (self.acg_tomorrowDate.acg_tomorrowDate.acg_isToday) {
        [formatter setDateFormat:@"HH:mm"];
        NSString *tmpString = [formatter stringFromDate:self];
        timeString = [timeString stringByAppendingFormat:@"前天 %@", tmpString];
    } else {
        [formatter setDateFormat:@"MM-dd HH:mm"];
        timeString = [formatter stringFromDate:self];
    }

    return timeString;
}

@end
