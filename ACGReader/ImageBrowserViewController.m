//
//  ImageBrowserViewController.m
//  ImageBrowser
//
//  Created by msk on 16/9/1.
//  Copyright © 2016年 msk. All rights reserved.
//

#import <math.h>
#import "ImageBrowserViewController.h"
#import "PhotoView.h"
#import "UIImageView+WebCache.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface ImageBrowserViewController () <UIScrollViewDelegate, PhotoViewDelegate> {
    NSMutableArray *_subViewArray;//scrollView的所有子视图
}

/** 背景容器视图 */
@property(nonatomic, strong) UIScrollView *scrollView;
/** 外部操作控制器 */
@property(nonatomic, weak) UIViewController *handleVC;
/** 图片浏览方式 */
@property(nonatomic, assign) PhotoBroswerVCType type;
/** 图片数组 */
@property(nonatomic, strong) NSArray *imagesArray;
/** 初始显示的index */
@property(nonatomic, assign) NSUInteger index;
/** 圆点指示器 */
@property(nonatomic, strong) UIPageControl *pageControl;
/** 记录当前的图片显示视图 */
@property(nonatomic, strong) PhotoView *photoView;
@end

@implementation ImageBrowserViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _subViewArray = [NSMutableArray arrayWithCapacity:0];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.view.backgroundColor = [UIColor blackColor];
    //去除自动处理
    self.automaticallyAdjustsScrollViewInsets = NO;
    //设置contentSize
    self.scrollView.contentSize = CGSizeMake(SCREEN_WIDTH * self.imagesArray.count, 0);
    for (int i = 0; i < self.imagesArray.count; i++) {
        [_subViewArray addObject:[NSNull class]];
    }
    self.scrollView.contentOffset = CGPointMake(SCREEN_WIDTH * self.index, 0);//此句代码需放在[_subViewArray addObject:[NSNull class]]之后，因为其主动调用scrollView的代理方法，否则会出现数组越界

    if (self.imagesArray.count > 1 && self.imagesArray.count < 20) {
        // 图片不多才显示pageControl，不然显示不下
        [self loadPageControl];
        self.pageControl.currentPage = self.index;
    }
    
    self.title = [NSString stringWithFormat:@"%zd/%zd", self.index + 1, self.imagesArray.count];
    [self loadPhoto:self.index];//显示当前索引的图片

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideCurrentVC:)];
    [self.view addGestureRecognizer:tap]; //为当前view添加手势
}

- (void)hideCurrentVC:(UIGestureRecognizer *)tap {
    [self hideScanImageVC];
}

#pragma mark - 显示图片

- (void)loadPhoto:(NSUInteger)index {
    if (index < 0 || index >= self.imagesArray.count) {
        return;
    }
    id currentPhotoView = [_subViewArray objectAtIndex:index];
    if (![currentPhotoView isKindOfClass:[PhotoView class]]) {
        //url数组或图片数组
        CGRect frame = CGRectMake(index * _scrollView.frame.size.width, 20, self.view.frame.size.width, self.view.frame.size.height - 20);
        if ([[self.imagesArray firstObject] isKindOfClass:[UIImage class]]) {
            PhotoView *photoV = [[PhotoView alloc] initWithFrame:frame withPhotoImage:[self.imagesArray objectAtIndex:index]];
            photoV.delegate = self;
            [self.scrollView insertSubview:photoV atIndex:0];
            [_subViewArray replaceObjectAtIndex:index withObject:photoV];
            self.photoView = photoV;
        } else if ([[self.imagesArray firstObject] isKindOfClass:[NSString class]]) {
            PhotoView *photoV = [[PhotoView alloc] initWithFrame:frame withPhotoUrl:[self.imagesArray objectAtIndex:index]];
            photoV.delegate = self;
            [self.scrollView insertSubview:photoV atIndex:0];
            [_subViewArray replaceObjectAtIndex:index withObject:photoV];
            self.photoView = photoV;
        }
    } else {
        PhotoView *photoView = currentPhotoView;
        if ([[self.imagesArray firstObject] isKindOfClass:[UIImage class]]) {
            photoView.imageView.image = [self.imagesArray objectAtIndex:index];
        } else if ([[self.imagesArray firstObject] isKindOfClass:[NSString class]]) {
            NSString *url = [self.imagesArray objectAtIndex:index];
            [photoView.imageView sd_setImageWithURL:[NSURL URLWithString:url]];
        }
    }
}

#pragma mark - 生成显示窗口

+ (instancetype)show:(UIViewController *)handleVC
        type:(PhotoBroswerVCType)type
       index:(NSUInteger)index
   imageUrls:(NSArray *)imageUrls
{
    NSArray *photoModels = imageUrls;//取出相册数组
    if (photoModels == nil || photoModels.count == 0) {
        return nil;
    }

    if (index >= photoModels.count) {
        return nil;
    }
    
    ImageBrowserViewController *imgBrowserVC = [[self alloc] init];
    imgBrowserVC.index = index;
    imgBrowserVC.imagesArray = photoModels;
    imgBrowserVC.type = type;
    imgBrowserVC.handleVC = handleVC;
    [imgBrowserVC show]; //展示
    return imgBrowserVC;
}

/** 真正展示 */
- (void)show {
    switch (_type) {
        case PhotoBrowserVCTypePush://push
            [self pushPhotoVC];
            break;
        case PhotoBrowserVCTypeModal://modal
            [self modalPhotoVC];
            break;
        case PhotoBrowserVCTypeZoom://zoom
            [self zoomPhotoVC];
            break;
        default:
            break;
    }
}

/** push */
- (void)pushPhotoVC {
    [_handleVC.navigationController pushViewController:self animated:YES];
}

/** modal */
- (void)modalPhotoVC {
    [_handleVC presentViewController:self animated:YES completion:nil];
}

/** zoom */
- (void)zoomPhotoVC {
    //拿到window
    UIWindow *window = _handleVC.view.window;
    if (window == nil) {
        NSLog(@"错误：窗口为空！");
        return;
    }

    self.view.frame = [UIScreen mainScreen].bounds;
    [window addSubview:self.view]; //添加视图
    [_handleVC addChildViewController:self]; //添加子控制器
}

#pragma mark - 隐藏当前显示窗口

- (void)hideScanImageVC {
    switch (_type) {
        case PhotoBrowserVCTypePush://push
            [self.navigationController popViewControllerAnimated:YES];
            break;
        case PhotoBrowserVCTypeModal://modal
            [self dismissViewControllerAnimated:YES completion:NULL];
            break;
        case PhotoBrowserVCTypeZoom://zoom
            [self.view removeFromSuperview];
            [self removeFromParentViewController];
            break;
        default:
            break;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    NSUInteger page = (NSUInteger)(floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1);

    if (page < 0 || page >= self.imagesArray.count) {
        return;
    }
    
    self.pageControl.currentPage = page;
    self.title = [NSString stringWithFormat:@"%zd/%zd", page + 1, self.imagesArray.count];
    if (self.scrollToPageBlock) {
        self.scrollToPageBlock(page);
    }
    
    for (UIView *view in scrollView.subviews) {
        if ([view isKindOfClass:[PhotoView class]]) {
            id photoV = (PhotoView *)[_subViewArray objectAtIndex:page];
            if (photoV != self.photoView) {
                [self.photoView.scrollView setZoomScale:1.0 animated:YES];
                self.photoView = photoV;
            }
            
            if (view != self.photoView) {
                PhotoView *photoView = (PhotoView *)view;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (1.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    // 延迟1.5s释放，避免出现短暂黑屏
                    photoView.imageView.image = nil;
                });
            }
        }
    }

    [self loadPhoto:page];
}

#pragma mark - PhotoViewDelegate

- (void)tapHiddenPhotoView {
    if (self.hideOnTapImage) {
        [self hideScanImageVC];//隐藏当前显示窗口
    } else {
        if (self.navigationController.navigationBarHidden) {
            [self.navigationController setNavigationBarHidden:NO animated:YES];
        } else {
            [self.navigationController setNavigationBarHidden:YES animated:YES];
        }
    }
}

#pragma mark - 懒加载

- (UIScrollView *)scrollView {
    if (_scrollView == nil) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _scrollView.delegate = self;
        _scrollView.pagingEnabled = YES;
        _scrollView.contentOffset = CGPointZero;
        //设置最大伸缩比例
        _scrollView.maximumZoomScale = 3;
        //设置最小伸缩比例
        _scrollView.minimumZoomScale = 1;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;

        [self.view addSubview:_scrollView];
    }
    return _scrollView;
}

- (void)loadPageControl {
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - 40, SCREEN_WIDTH, 30)];
    bottomView.backgroundColor = [UIColor clearColor];
    _pageControl = [[UIPageControl alloc] initWithFrame:bottomView.bounds];
    _pageControl.currentPage = self.index;
    _pageControl.numberOfPages = self.imagesArray.count;
    _pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:153 green:153 blue:153 alpha:1];
    _pageControl.pageIndicatorTintColor = [UIColor colorWithRed:235 green:235 blue:235 alpha:0.6];
    [bottomView addSubview:_pageControl];
    [self.view addSubview:bottomView];
}

@end
