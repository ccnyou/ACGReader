//
//  ImageCache.h
//  ACGReader
//
//  Created by ccnyou on 2018/3/1.
//  Copyright © 2018年 ccnyou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GYModelObject.h"
#import "Constant.h"

@interface ImageCache : GYModelObject
@property(nonatomic, assign) NSInteger cacheId;        // 主键
@property(nonatomic, strong) NSString *linkUrl;        // 来源网页url
@property(nonatomic, strong) NSString *imageUrl;       // 图片url, 会变
@property(nonatomic, strong) NSString *pageUrl;        // 图片网页url，用于刷新图片
@property(nonatomic, assign) NSInteger imageOrder;     // 顺序
@property(nonatomic, assign) ACGCacheState cacheState; // 缓存状态
@end
