//
//  Constant.h
//  ACGReader
//
//  Created by ccnyou on 2018/2/28.
//  Copyright © 2018年 ccnyou. All rights reserved.
//

#ifndef CONSTANT_H
#define CONSTANT_H

static const char *kIndexUrl = "https://e-hentai.org/?f_doujinshi=0&f_manga=1&f_artistcg=0&f_gamecg=0&f_western=0&f_non-h=0&f_imageset=0&f_cosplay=0&f_asianporn=0&f_misc=0&f_search=chinese&f_apply=Apply+Filter";
static const char *kTableNodeQuery = "table.itg";
static const char *kTitleNodeQuery = "div.it5";
static const char *kImageCacheDoneNotification = "kImageCacheDoneNotification";
static const char *kImageCacheProgressUpdateNotification = "kImageCacheProgressUpdateNotification";
static const char *kImageCountUpdateNotification = "kImageCountUpdateNotification";

typedef NS_ENUM(NSInteger, ACGCacheState) {
    ACGCacheStateNone,
    ACGCacheStateRuning,
    ACGCacheStatePause,
    ACGCacheStateDone,
    ACGCacheStateError
};

#endif
