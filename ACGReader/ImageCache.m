//
//  ImageCache.m
//  ACGReader
//
//  Created by ccnyou on 2018/3/1.
//  Copyright © 2018年 ccnyou. All rights reserved.
//

#import "ImageCache.h"

@implementation ImageCache

+ (NSString *)dbName {
    return @"ACGReader";
}

+ (NSString *)tableName {
    return @"ImageCache";
}

+ (NSString *)primaryKey {
    return @"cacheId";
}

+ (NSArray *)persistentProperties {
    static NSArray *properties = nil;
    if (!properties) {
        properties = @[
                       @"cacheId",
                       @"linkUrl",
                       @"imageUrl",
                       @"pageUrl",
                       @"imageOrder",
                       @"cacheState"
                       ];
    };
    return properties;
}

+ (NSArray *)indices {
    return @[ @[@"linkUrl", @"imageOrder"] ];
}

- (void)save {
    if (self.cacheId == 0) {
        NSArray *objects = [ImageCache objectsWhere:@"where linkUrl=? and imageOrder=?"
                                          arguments:@[self.linkUrl, @(self.imageOrder)]];
        ImageCache *existsCache = [objects firstObject];
        if (existsCache) {
            NSLog(@"%s %d exists cache, id=%zd", __FUNCTION__, __LINE__, existsCache.cacheId);
            self.cacheId = existsCache.cacheId;
        }
    }
    
    [super save];
}

@end
