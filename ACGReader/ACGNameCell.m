//
//  ACGNameCell.m
//  ACGReader
//
//  Created by ccnyou on 2018/2/28.
//  Copyright © 2018年 ccnyou. All rights reserved.
//

#import "ACGNameCell.h"
#import "NSDate+ACG.h"
#import "UIImageView+WebCache.h"
#import "UIImage+GIF.h"
#import "Masonry.h"

@implementation ACGNameCell

+ (instancetype)cell {
    return [[ACGNameCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ACGNameCell"];
}

+ (NSString *)reuseIdentifier {
    return @"ACGNameCell";
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self _loadSubviews];
        [self _registerNotifications];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_loadSubviews {
    [self _loadImageView];
    [self _loadTitleTextView];
    [self _loadCountLabel];
    [self _loadDateLabel];
    [self _loadCacheButton];
}

- (void)_loadCacheButton {
    self.button = [UIButton buttonWithType:UIButtonTypeSystem];
    self.button.backgroundColor = [UIColor clearColor];
    self.button.titleLabel.font = [UIFont systemFontOfSize:14.0f];
    self.button.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
    [self.button setTitle:@"缓存" forState:UIControlStateNormal];
    [self.button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.button addTarget:self action:@selector(onCacheTouched:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.button];
    [self.button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleTextView.mas_bottom);
        make.width.mas_equalTo(88);
        make.height.mas_equalTo(40);
        make.bottom.mas_equalTo(self.previewImageView.mas_bottom);
        make.right.mas_equalTo(self.titleTextView.mas_right);
    }];
}

- (void)_loadDateLabel {
    self.dateLabel = [[UILabel alloc] init];
    self.dateLabel.font = [UIFont systemFontOfSize:14.0f];
    self.dateLabel.backgroundColor = [UIColor clearColor];
    self.dateLabel.textColor = [UIColor whiteColor];
    [self.contentView addSubview:self.dateLabel];
    [self.dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.countLabel.mas_right).offset(10);
        make.bottom.mas_equalTo(self.previewImageView.mas_bottom);
    }];
}

- (void)_loadCountLabel {
    self.countLabel = [[UILabel alloc] init];
    self.countLabel.font = [UIFont systemFontOfSize:14.0f];
    self.countLabel.backgroundColor = [UIColor clearColor];
    self.countLabel.textColor = [UIColor whiteColor];
    [self.contentView addSubview:self.countLabel];
    [self.countLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.previewImageView.mas_right).offset(10);
        make.bottom.mas_equalTo(self.previewImageView.mas_bottom);
    }];
}

- (void)_loadTitleTextView {
    self.titleTextView = [[UITextView alloc] init];
    self.titleTextView.editable = NO;
    self.titleTextView.scrollEnabled = NO;
    self.titleTextView.selectable = NO;
    self.titleTextView.userInteractionEnabled = NO;
    self.titleTextView.textContainerInset = UIEdgeInsetsZero;
    self.titleTextView.textColor = [UIColor whiteColor];
    self.titleTextView.backgroundColor = [UIColor clearColor];
    self.titleTextView.font = [UIFont systemFontOfSize:16.0f];
    [self.contentView addSubview:self.titleTextView];
    [self.titleTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.previewImageView.mas_right).offset(10);
        make.top.mas_equalTo(self.previewImageView.mas_top);
        make.right.mas_equalTo(-10);
    }];
}

- (void)_loadImageView {
    self.previewImageView = [[UIImageView alloc] init];
    self.previewImageView.backgroundColor = [UIColor whiteColor];
    self.previewImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.previewImageView];
    [self.previewImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(10);
        make.top.mas_equalTo(5);
        make.bottom.mas_equalTo(-5);
        make.height.mas_equalTo(self.previewImageView.mas_width).multipliedBy(286.0f / 200.0f);
    }];
}

- (void)_registerNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(onImageCacheDone:)
                               name:@(kImageCacheDoneNotification)
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(onImageCountUpdate:)
                               name:@(kImageCountUpdateNotification)
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(onImageCacheProgressUpdate:)
                               name:@(kImageCacheProgressUpdateNotification)
                             object:nil];
}

- (IBAction)onCacheTouched:(id)sender {
    self.linkNode.cacheState = ACGCacheStateRuning;
    [self.linkNode cacheAcgImages];
    [self _refreshWithNode:self.linkNode];
}

- (void)onImageCacheDone:(NSNotification *)notification {
    if (notification.object == self.linkNode) {
        [self _refreshButton:self.linkNode];
        [self _refreshCount:self.linkNode];
    }
}

- (void)onImageCountUpdate:(NSNotification *)notification {
    if (notification.object == self.linkNode) {
        [self _refreshCount:self.linkNode];
    }
}

- (void)onImageCacheProgressUpdate:(NSNotification *)notification {
    if (notification.object == self.linkNode) {
        [self _refreshCount:self.linkNode];
    }
}

- (void)setLinkNode:(LinkNode *)linkNode {
    _linkNode = linkNode;
    [self _refreshWithNode:linkNode];
}

- (void)_refreshWithNode:(LinkNode *)linkNode {
    [self _refreshImage:linkNode];
    [self _refreshTitle:linkNode];
    [self _refreshCount:linkNode];
    [self _refreshDate:linkNode];
    [self _refreshButton:linkNode];
}

- (void)_refreshImage:(LinkNode *)node {
    if (node.previewImageUrl.length > 0) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"loading_gif" ofType:@"gif"];
        NSData *data = [NSData dataWithContentsOfFile:path];
        UIImage *image = [UIImage sd_animatedGIFWithData:data];
        [self.previewImageView sd_setImageWithURL:[NSURL URLWithString:node.previewImageUrl]
                                 placeholderImage:image
                                        completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL)
        {
            NSLog(@"%s %d size = %@", __FUNCTION__, __LINE__, NSStringFromCGSize(image.size));
        }];
    }
}

- (void)_refreshDate:(LinkNode *)node {
    if (node.lastReadDate) {
        self.dateLabel.hidden = NO;
        self.dateLabel.text = [node.lastReadDate acg_passTimeString];
    } else {
        self.dateLabel.hidden = YES;
    }
}

- (void)_refreshButton:(LinkNode *)linkNode {
    NSString *text = nil;
    switch (linkNode.cacheState) {
        case ACGCacheStateNone:
            text = @"缓存";
            self.button.enabled = YES;
            break;

        case ACGCacheStateDone:
            text = @"已缓存";
            self.button.enabled = NO;
            break;

        case ACGCacheStateRuning:
            text = @"缓存中";
            self.button.enabled = NO;
            break;

        case ACGCacheStatePause:
            text = @"继续缓存";
            self.button.enabled = YES;
            break;

        case ACGCacheStateError:
            text = @"重试缓存";
            self.button.enabled = YES;
            break;

        default:
            break;
    }

    [self.button setTitle:text forState:UIControlStateNormal];
}

- (void)_refreshCount:(LinkNode *)linkNode {
    self.countLabel.text = [NSString stringWithFormat:@"%zd/%zd", linkNode.cachedCount, linkNode.imageCount];
}

- (void)_refreshTitle:(LinkNode *)linkNode {
    NSString *text = [linkNode.title stringByReplacingOccurrencesOfString:@"[Chinese]" withString:@""];
    text = [text stringByReplacingOccurrencesOfString:@"中文" withString:@""];
    text = [text stringByReplacingOccurrencesOfString:@"[]" withString:@""];
    self.titleTextView.text = text;
}

@end
