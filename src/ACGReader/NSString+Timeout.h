//
//  NSString+Timeout.h
//  ACGReader
//
//  Created by ervinchen on 2018/3/30.
//  Copyright © 2018年 ccnyou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Timeout)

+ (instancetype)acg_stringWithContentsOfURL:(NSURL *)url
                                   encoding:(NSStringEncoding)enc
                                      error:(NSError **)error
                            timeoutInterval:(NSTimeInterval)timeoutInterval;

@end
