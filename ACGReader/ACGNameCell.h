//
//  ACGNameCell.h
//  ACGReader
//
//  Created by ccnyou on 2018/2/28.
//  Copyright © 2018年 ccnyou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LinkNode.h"

@interface ACGNameCell : UITableViewCell
@property (strong, nonatomic) UITextView *titleTextView;
@property (strong, nonatomic) UILabel *countLabel;
@property (strong, nonatomic) UILabel *dateLabel;
@property (strong, nonatomic) UIButton *button;
@property (strong, nonatomic) UIImageView *previewImageView;
@property (strong, nonatomic) LinkNode *linkNode;

+ (instancetype)cell;
+ (NSString *)reuseIdentifier;

@end
