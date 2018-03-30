//
//  NSString+Timeout.m
//  ACGReader
//
//  Created by ervinchen on 2018/3/30.
//  Copyright © 2018年 ccnyou. All rights reserved.
//

#import "NSString+Timeout.h"

@implementation NSString (Timeout)

+ (instancetype)acg_stringWithContentsOfURL:(NSURL *)url
                                   encoding:(NSStringEncoding)enc
                                      error:(NSError **)error
                            timeoutInterval:(NSTimeInterval)timeoutInterval
{
    NSURLRequest* request = [NSURLRequest requestWithURL:url cachePolicy:0 timeoutInterval:timeoutInterval];
    NSURLResponse* response = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];
    NSString* result = [[NSString alloc] initWithData:data encoding:enc];
    return result;
}

@end
