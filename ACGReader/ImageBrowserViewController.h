//
//  ImageBrowserViewController.h
//  ImageBrowser
//
//  Created by msk on 16/9/1.
//  Copyright © 2016年 msk. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * 跳转方式
 */
typedef NS_ENUM(NSUInteger, PhotoBroswerVCType) {
    PhotoBrowserVCTypePush = 0, //modal
    PhotoBrowserVCTypeModal,    //push
    PhotoBrowserVCTypeZoom,     //zoom
};

typedef void(^ImageBrowserScrollToPageBlock)(NSInteger pageIndex);

@interface ImageBrowserViewController : UIViewController
@property (nonatomic, assign) BOOL hideOnTapImage;
@property (nonatomic, copy) ImageBrowserScrollToPageBlock scrollToPageBlock;

/**
 *  显示图片
 */
+ (instancetype)show:(UIViewController *)handleVC type:(PhotoBroswerVCType)type index:(NSUInteger)index imageUrls:(NSArray *)imageUrls;

@end
