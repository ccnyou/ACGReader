//
//  LinkNode.m
//  ACGReader
//
//  Created by ccnyou on 2018/2/28.
//  Copyright © 2018年 ccnyou. All rights reserved.
//

#import "LinkNode.h"
#import "OCGumbo.h"
#import "OCGumbo+Query.h"
#import "SDWebImageManager.h"

@implementation LinkNode

+ (NSString *)dbName {
    return @"ACGReader";
}

+ (NSString *)tableName {
    return @"LinkNode";
}

+ (NSString *)primaryKey {
    return @"url";
}

+ (NSArray *)persistentProperties {
    static NSArray *properties = nil;
    if (!properties) {
        properties = @[
                @"title",
                @"url",
                @"previewImageUrl",
                @"cacheState",
                @"imageCount",
                @"cachedCount",
                @"readingIndex",
                @"lastReadDate"
        ];
    };
    return properties;
}

- (ImageCacheMap *)imageCacheMaps {
    if (!_imageCacheMaps) {
        _imageCacheMaps = [self _loadImageCacheMaps];
    }
    return _imageCacheMaps;
}

- (BOOL)isCacheExists {
    if (self.cacheState == ACGCacheStateDone) {
        return YES;
    }
    return NO;
}

- (NSUInteger)hash {
    return self.url.hash;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[LinkNode class]]) {
        return NO;
    }

    LinkNode *node = object;
    if (![node.url isEqualToString:self.url]) {
        return NO;
    }

    return YES;
}

- (void)cacheAcgImages {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSInteger beginOrder = 0;
        NSString *pageUrl = self.url;
        BOOL parseImageCount = YES;
        while (YES) {
            NSDictionary *result = [self _parseImageListPage:pageUrl beginOrder:beginOrder parseImageCount:parseImageCount];
            if (!result) {
                break;
            }
            
            NSInteger nextOrder = [[result objectForKey:@"nextOrder"] integerValue];
            NSString *nextUrl = [result objectForKey:@"nextUrl"];
            if (nextOrder == beginOrder || nextUrl.length <= 0) {
                break;
            }

            beginOrder = nextOrder;
            pageUrl = nextUrl;
            parseImageCount = NO;
        }
    });
}

- (NSDictionary *)_parseImageListPage:(NSString *)pageUrl beginOrder:(NSInteger)beginOrder parseImageCount:(BOOL)parseImageCount {
    NSString *htmlString = [self _loadHtmlByUrl:pageUrl];
    OCGumboDocument *document = [[OCGumboDocument alloc] initWithHTMLString:htmlString];
    OCGumboElement *root = document.rootElement;
    if (parseImageCount) {
        [self _parseImageCount:root];
    }

    NSArray *divNodes = root.Query(@"div.gdtm");
    if (divNodes.count <= 0) {
        return nil;
    }

    NSInteger order = beginOrder;
    for (OCGumboElement *divNode in divNodes) {
        order++;
        [self _handleImageListDivNode:divNode order:order];
    }

    NSString *nextPageUrl = [self _parseNextPageUrl:root];
    if (!nextPageUrl) {
        return nil;
    }
    
    NSDictionary *result = @{
            @"nextOrder": @(order),
            @"nextUrl": nextPageUrl
    };

    return result;
}

- (NSString *)_parseNextPageUrl:(OCGumboElement *)root {
    OCGumboNode *tableNode = root.Query(@"table.ptt").first();
    if (!tableNode) {
        return @"";
    }
    
    OCGumboNode *tdNode = tableNode.Query(@"td").last();
    if (!tdNode) {
        return @"";
    }
    
    OCGumboNode *aNode = tdNode.Query(@"a").first();
    if (!aNode) {
        return @"";
    }
    
    NSString *text = aNode.text();
    NSString *url = aNode.attr(@"href");
    if (![text isEqualToString:@">"]) {
        return @"";
    }
    if (url.length <= 0) {
        url = @"";
    }

    return url;
}

- (void)_parseImageCount:(OCGumboElement *)root {
    OCGumboNode *pNode = root.Query(@"p.gpc").first();
    NSString *text = pNode.text();
    NSArray *components = [text componentsSeparatedByString:@" "];
    if (components.count <= 0) {
        return;
    }

    NSUInteger count = components.count;
    if (count <= 2) {
        return;
    }

    NSString *imageCountText = [components objectAtIndex:count - 2];
    self.imageCount = [imageCountText integerValue];
    [self save];

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@(kImageCountUpdateNotification) object:self];
    });
}

- (ImageCacheMap *)_loadImageCacheMaps {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    BOOL containsInvalidImage = NO;
    BOOL cachedCount = 0;
    NSArray *imageCaches = [ImageCache objectsWhere:@"where linkUrl = ?" arguments:@[self.url]];
    for (ImageCache *imageCache in imageCaches) {
        if ([imageCache.imageUrl containsString:@"509.gif"]) {
            // 非法图片url，这里做一下修正
            // https://ehgt.org/g/509.gif
            [imageCache deleteObject];
            containsInvalidImage = YES;
            continue;
        }

        NSLog(@"%s %d load image url = %@", __FUNCTION__, __LINE__, imageCache.imageUrl);
        cachedCount++; // 统计成功缓存的个数
        [self _saveMemoryImageCache:imageCache imageCacheMaps:result];
    }

    if (containsInvalidImage) {
        self.cachedCount = cachedCount;
        self.cacheState = ACGCacheStateError;
        [self save];
    }

    return result;
}

- (NSString *)_loadHtmlByUrl:(NSString *)urlString {
    NSError *error = nil;
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *htmlString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"%s %d error = %@", __FUNCTION__, __LINE__, error);
    }

    return htmlString;
}

- (void)_handleImageListDivNode:(OCGumboElement *)divNode order:(NSInteger)order {
    OCGumboNode *aNode = divNode.Query(@"a").first();
    NSString *linkUrl = aNode.attr(@"href");
    [self _cacheImage:linkUrl imageOrder:order];
}

- (void)_cacheImage:(NSString *)pageUrl imageOrder:(NSInteger)imageOrder {
    NSString *htmlString = [self _loadHtmlByUrl:pageUrl];
    if (htmlString.length <= 0) {
        // html 加载失败
        return;
    }

    OCGumboDocument *document = [[OCGumboDocument alloc] initWithHTMLString:htmlString];
    OCGumboElement *root = document.rootElement;
    OCGumboNode *imgNode = root.Query(@"img#img").first();
    NSString *imageUrl = imgNode.attr(@"src");
    if (imageUrl.length <= 0) {
        // url 非法
        return;
    }

    ImageCache *cache = [self _findMemoryImageCache:imageOrder];
    if (cache.cacheState == ACGCacheStateDone) {
        // 这个已经缓存过了
        return;
    }

    // 记录下载缓存
    [self _saveImageCacheState:imageOrder imageUrl:imageUrl pageUrl:pageUrl];
    [self _downloadImageByUrl:imageUrl imageOrder:imageOrder];
}

- (ImageCache *)_findMemoryImageCache:(NSInteger)imageOrder {
    ImageCache *cache = nil;
    NSString *key = [NSString stringWithFormat:@"%zd", imageOrder];
    @synchronized (self.imageCacheMaps) {
        cache = [self.imageCacheMaps objectForKey:key];
    }
    return cache;
}

- (void)_saveMemoryImageCache:(ImageCache *)cache imageCacheMaps:(NSMutableDictionary *)imageCacheMaps {
    NSString *key = [NSString stringWithFormat:@"%zd", cache.imageOrder];
    @synchronized (imageCacheMaps) {
        [imageCacheMaps setObject:cache forKey:key];
    }
}

- (void)_saveImageCacheState:(NSInteger)imageOrder imageUrl:(NSString *)imageUrl pageUrl:(NSString *)pageUrl {
    ImageCache *cache = [[ImageCache alloc] init];
    cache.linkUrl = self.url;
    cache.imageUrl = imageUrl;
    cache.pageUrl = pageUrl;
    cache.imageOrder = imageOrder;
    cache.cacheState = ACGCacheStateRuning;
    [cache save];
    [self _saveMemoryImageCache:cache imageCacheMaps:self.imageCacheMaps];
}

- (void)_downloadImageByUrl:(NSString *)url imageOrder:(NSInteger)imageOrder {
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager loadImageWithURL:[NSURL URLWithString:url]
                      options:SDWebImageHighPriority
                     progress:nil
                    completed:^(UIImage *image, NSData *data, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                        if (finished) {
                            NSLog(@"%s %d image download success, url = %@", __FUNCTION__, __LINE__, imageURL);
                            [self _markImageCacheDone:imageOrder];
                            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                                [self _updateCacheStatusProgress];
                            });
                        } else {
                            NSLog(@"%s %d image download fail, url = %@", __FUNCTION__, __LINE__, imageURL);
                        }
                    }];
}

- (void)_updateCacheStatusProgress {
    NSInteger cacheDoneCount = 0;
    NSArray *cacheObjects = [self.imageCacheMaps allValues];
    for (ImageCache *cache in cacheObjects) {
        if (cache.cacheState == ACGCacheStateDone) {
            // 包含还在下载的任务
            cacheDoneCount++;
        }
    }

    self.cachedCount = cacheDoneCount;
    if (cacheDoneCount == self.imageCount && self.imageCount != 0) {
        // 全部完成了，发通知
        self.cacheState = ACGCacheStateDone;
        [self save];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@(kImageCacheDoneNotification)
                                                                object:self];
        });
    } else {
        [self save];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@(kImageCacheProgressUpdateNotification)
                                                                object:self];
        });
    }
}

- (void)_markImageCacheDone:(NSInteger)imageOrder {
    ImageCache *cache = [self _findMemoryImageCache:imageOrder];
    cache.cacheState = ACGCacheStateDone;
    [cache save];
}

@end
