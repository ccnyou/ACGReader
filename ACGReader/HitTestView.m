//
//  HitTestView.m
//  ACGReader
//
//  Created by 聪宁陈 on 2018/3/3.
//  Copyright © 2018年 ccnyou. All rights reserved.
//

#import "HitTestView.h"

@implementation HitTestView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView* aView = [super hitTest:point withEvent:event];
    if (aView != self) {
        return aView;
    }
    
    CGPoint p = [self.backgroundView convertPoint:point fromView:self];
    aView = [self.backgroundView hitTest:p withEvent:event];
    
    return aView;
}

@end
