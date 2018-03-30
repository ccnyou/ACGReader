//
// Created by ccnyou on 2018/3/1.
// Copyright (c) 2018 ccnyou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController
@property(nonatomic, strong) UIWebView *webView;
@property(nonatomic, strong) NSString *url;
@end