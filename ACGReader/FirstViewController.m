//
//  FirstViewController.m
//  ACGReader
//
//  Created by ccnyou on 2018/2/28.
//  Copyright © 2018年 ccnyou. All rights reserved.
//

#import "FirstViewController.h"
#import "OCGumbo+Query.h"
#import "LinkNode.h"
#import "ACGNameCell.h"
#import "WebViewController.h"
#import "ImageBrowserViewController.h"
#import "MJRefresh.h"
#import "HitTestView.h"
#import "SDImageCache.h"

@interface FirstViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *nodes;
@property (nonatomic, strong) NSMutableDictionary *existsNodes;
@property (nonatomic, strong) NSString *nextPageUrl;
@property (nonatomic, strong) HitTestView *hitTestView;
@property (nonatomic, assign) BOOL needReladOnAppear;
@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self _commonInit];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[SDImageCache sharedImageCache] clearMemory];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    self.hitTestView.backgroundView = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.hitTestView.backgroundView = self.view;
    if (self.needReladOnAppear) {
        [self _refreshTableView];
    }
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.nodes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"kListCellId";
    ACGNameCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [ACGNameCell cell];
    }

    NSUInteger index = (NSUInteger) indexPath.row;
    LinkNode *node = [self.nodes objectAtIndex:index];
    cell.linkNode = node;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger index = (NSUInteger) indexPath.row;
    LinkNode *node = [self.nodes objectAtIndex:index];
    if ([node isCacheExists]) {
        [self _showLocalImageBrowser:node];
    } else {
        [self _showWebBrowser:node];
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100.0f;
}

#pragma mark - Event

- (void)_refreshTableView {
    NSArray *sortedNodes = [self _sortedNodes:self.nodes];
    self.nodes = [sortedNodes mutableCopy];
    [self.tableView reloadData];
}

- (void)onImageCacheDone:(NSNotification *)notification {
    [self _refreshTableView];
}

#pragma mark - Private

- (void)_commonInit {
    [self _initAppearance];
    [self _loadHitTestView];
    [self _loadCachedNodes];
    [self _setupPullRefresh];
    [self _registerNotifications];
    [self _refreshNodes];
}

- (void)_initAppearance {
    UIImage *image = [self _imageWithColor:[UIColor clearColor]];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
}

- (void)_refreshNodes {
    if (self.nodes.count <= 0) {
        // 本地没有缓存，刷新一次
        [self _asyncFetchAcgList];
    }
}

- (void)_registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onImageCacheDone:)
                                                 name:@(kImageCacheDoneNotification)
                                               object:nil];
}

- (void)_loadHitTestView {
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    HitTestView *htView = [[HitTestView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 44)];
    htView.backgroundView = self.view;
    self.hitTestView = htView;
    [self.navigationController.navigationBar addSubview:htView];
}

- (UIImage *)_imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

- (void)_setupPullRefresh {
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [self _asyncFetchAcgList];
    }];

    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        if (self.nextPageUrl) {
            [self _parseAcgListByUrl:self.nextPageUrl];
        } else {
            [self _asyncFetchAcgList];
        }
    }];
}

- (NSArray *)_sortedNodes:(NSArray *)nodes {
    nodes = [nodes sortedArrayUsingComparator:^NSComparisonResult(LinkNode *node1, LinkNode *node2) {
        if (node1.lastReadDate != nil && node2.lastReadDate != nil) {
            return [node2.lastReadDate compare:node1.lastReadDate];
        }
        
        if (node1.cacheState != node2.cacheState) {
            return (NSComparisonResult)(node2.cacheState - node1.cacheState);
        }
        return [node1.title compare:node2.title];
    }];
    
    return nodes;
}

- (void)_loadCachedNodes {
    self.existsNodes = [[NSMutableDictionary alloc] init];
    self.nodes = [[NSMutableArray alloc] init];
    NSArray *nodes = [LinkNode objectsWhere:@"" arguments:nil];
    nodes = [self _sortedNodes:nodes];
    for (LinkNode *node in nodes) {
        if (node.cacheState == ACGCacheStateRuning) {
            // 恢复出来发现上次任务进行中
            node.cacheState = ACGCacheStatePause;
            [node save];
        }
        [self.existsNodes setObject:node forKey:node.url];
    }

    if (nodes.count > 0) {
        [self.nodes addObjectsFromArray:nodes];
    }
}

- (void)_asyncFetchAcgList {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *url = @(kIndexUrl);
        [self _parseAcgListByUrl:url];
    });
}

- (void)_parseAcgListByUrl:(NSString *)url {
    NSError *error = nil;
    NSString *htmlString = [NSString stringWithContentsOfURL:[NSURL URLWithString:url] encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"%s %d error = %@", __FUNCTION__, __LINE__, error);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView.mj_header endRefreshing];
            [self.tableView.mj_footer endRefreshing];
        });
        return;
    }

    OCGumboDocument *document = [[OCGumboDocument alloc] initWithHTMLString:htmlString];
    OCGumboElement *root = document.rootElement;
    OCGumboNode *tableNode = root.Query(@(kTableNodeQuery)).first();
    self.nextPageUrl = [self _parseNextPageUrl:root];

    NSArray *titleNodes = tableNode.Query(@(kTitleNodeQuery));
    for (OCGumboElement *titleNode in titleNodes) {
        [self _handleTitleNode:titleNode rootNode:root];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.nextPageUrl.length <= 0) {
            [self.tableView.mj_header endRefreshing];
            [self.tableView.mj_footer endRefreshingWithNoMoreData];
        } else {
            [self.tableView.mj_header endRefreshing];
            [self.tableView.mj_footer endRefreshing];
        }

        [self.tableView reloadData];
    });
}

- (void)_handleTitleNode:(OCGumboElement *)titleNode rootNode:(OCGumboElement *)rootNode {
    OCGumboNode *aNode = titleNode.Query(@"a").first();
    NSString *nodeUrl = aNode.attr(@"href");
    NSString *previewUrl = [self _parsePreviewImageUrl:rootNode aNode:aNode];
    id existsObject = [self.existsNodes objectForKey:nodeUrl];
    if (!existsObject) {
        LinkNode *linkNode = [[LinkNode alloc] init];
        linkNode.title = aNode.text();
        linkNode.url = nodeUrl;
        linkNode.previewImageUrl = previewUrl;
        [linkNode save];
        [self.nodes addObject:linkNode];
        [self.existsNodes setObject:linkNode forKey:nodeUrl];
    }
}

- (NSString *)_parsePreviewImageUrl:(OCGumboElement *)rootNode aNode:(OCGumboNode *)aNode {
    NSString *result = nil;
    NSString *mouseOver = aNode.attr(@"onmouseover");
    NSInteger beginPos = [mouseOver rangeOfString:@"("].location;
    NSInteger endPos = [mouseOver rangeOfString:@")"].location;
    NSRange numberRange = NSMakeRange(beginPos + 1, endPos - beginPos - 1);
    NSString *substring = [mouseOver substringWithRange:numberRange];
    NSString *elementQuery = [NSString stringWithFormat:@"#i%@", substring];
    OCGumboNode *divNode = rootNode.Query(elementQuery).first();
    if (!divNode) {
        return nil;
    }
    
    NSString *text = divNode.html();
    NSArray *components = [text componentsSeparatedByString:@"~"];
    if (components.count >= 4) {
        // 需要自行处理图片地址
        if ([components.firstObject isEqualToString:@"init"]) {
            result = [NSString stringWithFormat:@"http://%@/%@", components[1], components[2]];
        } else {
            result = [NSString stringWithFormat:@"https://%@/%@", components[1], components[2]];
        }
    } else {
        // 尝试直接解析成imgNode
        OCGumboNode *imgNode = divNode.Query(@"img").first();
        if (imgNode) {
            result = imgNode.attr(@"src");
        }
    }
    
    return result;
}

- (void)_showWebBrowser:(LinkNode *)node {
    WebViewController *controller = [[WebViewController alloc] init];
    controller.url = node.url;
    controller.title = node.title;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)_showLocalImageBrowser:(LinkNode *)node {
    NSArray *cacheImages = [node.imageCacheMaps allValues];
    cacheImages = [cacheImages sortedArrayUsingComparator:^NSComparisonResult(ImageCache *obj1, ImageCache *obj2) {
        return (NSComparisonResult) (obj1.imageOrder - obj2.imageOrder);
    }];
    NSMutableArray *imageUrls = [[NSMutableArray alloc] init];
    for (ImageCache *cache in cacheImages) {
        [imageUrls addObject:cache.imageUrl];
    }

    __weak typeof(self) wself = self;
    ImageBrowserViewController *vc = [ImageBrowserViewController show:self type:PhotoBrowserVCTypePush index:node.readingIndex imageUrls:imageUrls];
    vc.scrollToPageBlock = ^(NSInteger pageIndex) {
        if (pageIndex != node.readingIndex) {
            node.lastReadDate = [NSDate date];
            node.readingIndex = pageIndex;
            [node save];
            
            __strong typeof(wself) sself = wself;
            sself.needReladOnAppear = YES;
        }
    };
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

@end
