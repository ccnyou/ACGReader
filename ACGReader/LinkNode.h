//
//  LinkNode.h
//  ACGReader
//
//  Created by ccnyou on 2018/2/28.
//  Copyright © 2018年 ccnyou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GYModelObject.h"
#import "ImageCache.h"
#import "Constant.h"


typedef NSMutableDictionary<NSString *, ImageCache *> ImageCacheMap;


@interface LinkNode : GYModelObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *previewImageUrl;
@property (nonatomic, assign) ACGCacheState cacheState;
@property (nonatomic, assign) NSInteger imageCount;
@property (nonatomic, assign) NSInteger cachedCount;
@property (nonatomic, assign) NSInteger readingIndex;
@property (nonatomic, strong) NSDate *lastReadDate;
@property (nonatomic, strong) ImageCacheMap *imageCacheMaps;

- (BOOL)isCacheExists;

- (void)cacheAcgImages;
@end
