//
//  ContentViewController.m
//  36Ke
//
//  Created by lmj  on 16/3/9.
//  Copyright (c) 2016年 lmj . All rights reserved.
//

#import "ContentViewController.h"
#import "ContentListJsonHandler.h"
#import "Common.h"
#import "CommentListJsonHandler.h"
#import "NSDate+Extension.h"
#import "ContentTopCell.h"
#import "CommentCell.h"
#import "LMCommentViewController.h"
#import "AllCommentView.h"
//#import "CommentViewController.h"
#import "KeTVViewController.h"
#import "NewCommentCell.h"
#import "LMNavigationController.h"
#import "UIBarButtonItem+Badge.h"
#define kToolBarHeight 44
#define kTopHeight 44
#define kNavigationBarHeigh 44.0f

static CGFloat const kButtonWidth = 43.0f;
static CGFloat const kButtonHeight = 43.0f;

@interface ContentViewController () <UITableViewDelegate,UITableViewDataSource,UIWebViewDelegate,ContentListJsonHandlerDelegate,CommentListJsonHandlerDelegate>
{
    
    UIActivityIndicatorView *actView;
    UILabel *loadingLabel;
    NSString *htmTemp;
//    UIButton *commentBtn;
    UIView *loadingView;
    UIToolbar *toolBar;
    UIButton *favBtn;
    BOOL isFav;
    BOOL isFirstLoad;//解决web黑色
    
    ContentListJsonHandler *contentHandler;
    CommentListJsonHandler *commentHandler;
    
}
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong, readwrite) NSArray *commentArray;
@property (nonatomic, strong) ContentData *contentModel;
@property (nonatomic, strong) NSMutableArray *userArray;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, assign) BOOL isComment;
@end

@implementation ContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    _numberLabel = [[UILabel alloc] init];
    
//    if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)]) {
//        self.automaticallyAdjustsScrollViewInsets=NO;
//    }
    contentHandler = [[ContentListJsonHandler alloc] init];
    contentHandler.delegate = self;
    commentHandler = [[CommentListJsonHandler alloc] init];
    commentHandler.delegate = self;
    
    
    
    isFirstLoad=YES;
//    if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)]) {
        self.automaticallyAdjustsScrollViewInsets=NO;
//    }
    [self.view setBackgroundColor:[UIColor whiteColor]];
//
    //webview
    float webViewHeith = self.view.bounds.size.height - kToolBarHeight - kTopHeight;
    if (![Common isIOS7]) {
//        webViewHeith-=kNavigationBarHeigh;
        //        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav_detail_bg.png"] forBarMetrics:UIBarMetricsDefault];
    }
//    float webViewY = kTopHeight;
//    if (![Common isIOS7]) {
//        webViewHeith-=k_navigationBarHeigh;
//        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav_detail_bg.png"] forBarMetrics:UIBarMetricsDefault];
//    }
    self.webView=[[UIWebView alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width,webViewHeith) ];
    _webView.scrollView.scrollEnabled = NO;
//    _webView.scrollView.bounces= NO;
    
//    _webView.ve = NO;
//    _webView.showsVerticalScrollIndicator = NO;
    if ([Common isIOS7]) {
//        self.webView.scrollView.contentInset=UIEdgeInsetsMake(20+kNavigationBarHeigh, 0, 0, 0);
//        self.webView.scrollView.scrollIndicatorInsets=UIEdgeInsetsMake(20+kNavigationBarHeigh   , 0, 0, 0);
    }
    else
    {
        // remove shadow view when drag web view
        for (UIView *subView in [self.webView subviews]) {
            if ([subView isKindOfClass:[UIScrollView class]]) {
                for (UIView *shadowView in [subView subviews]) {
                    if ([shadowView isKindOfClass:[UIImageView class]]) {
                        shadowView.hidden = YES;
                    }
                }
            }
        }
    }
    [self.webView setBackgroundColor:[UIColor whiteColor]];
    self.webView.delegate=self;
//
    //获取htmltemp
    htmTemp=[Common readLocalString:[[NSBundle mainBundle] pathForResource:@"content_template" ofType:@"html"]];
    //toolbar
    float toolBarY = self.view.bounds.size.height - kToolBarHeight;
    toolBar=[[UIToolbar alloc] initWithFrame:CGRectMake(0, toolBarY, self.view.bounds.size.width, kToolBarHeight)];
    [toolBar setBackgroundImage:[UIImage imageNamed:@"toolbar_bg.png"] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [toolBar setTintColor:[UIColor darkGrayColor]];
//    [self setTabBarItems];
    [self setupUI];
    [self.view addSubview:toolBar];
    
    
//    [self setTabBarItems];
    
    [self loadDisplayView];
    
}

- (void)setupUI {
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height - 60)];
//    self.tableView.contentOffset = CGPointMake(0, 0);
    self.tableView.bounces= NO;
    //    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height - 64) style:UITableViewStyleGrouped];
    
    self.tableView.backgroundColor = self.view.backgroundColor;
//    _tableView.delegate = self;
//    _tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    //    self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    [self.view addSubview:_tableView];
}


- (BOOL)prefersStatusBarHidden {
    return  YES;
}


-(void)setTabBarItems
{
   
    //是否已收藏
//    isFav=[[DBManager share] postIsInFavorites:[self.postObj.ID stringValue]];
    NSString *favBtnBg=isFav?@"news_toolbar_icon_favorite_blue":@"news_toolbar_icon_favorite";
    favBtn=[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [favBtn setBackgroundImage:[UIImage imageNamed:favBtnBg] forState:UIControlStateNormal];
    [favBtn addTarget:self action:@selector(handleFav) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *favItem=[[UIBarButtonItem alloc] initWithCustomView:favBtn];
    
    
    //分享
    UIButton *shareBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    [shareBtn setFrame:CGRectMake(0, 0, 30, 30)];
    [shareBtn setBackgroundImage:[UIImage imageNamed:@"news_toolbar_icon_share"] forState:UIControlStateNormal];
    [shareBtn addTarget:self action:@selector(sharePost) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *shareItem=[[UIBarButtonItem alloc] initWithCustomView:shareBtn];
    //博客
    UIButton *authorBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    [authorBtn setFrame:CGRectMake(0, 0, 30, 30)];
    [authorBtn setBackgroundImage:[UIImage imageNamed:@"icon_author.png"] forState:UIControlStateNormal];
    [authorBtn addTarget:self action:@selector(authorHome) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *authorItem=[[UIBarButtonItem alloc] initWithCustomView:authorBtn];
    
    //navbar
    UIButton *backBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    [backBtn setFrame:CGRectMake(0, 0, 30, 30)];
    [backBtn setBackgroundImage:[UIImage imageNamed:@"news_toolbar_icon_back"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
//     UIBarButtonItem *favItem=[[UIBarButtonItem alloc] initWithCustomView:favBtn];
    UIBarButtonItem *backItem=[[UIBarButtonItem alloc] initWithCustomView:backBtn];
//    self.navigationItem.leftBarButtonItem = back;
//    _isComment = true;
    NSString *commentStr = _isComment?@"news_toolbar_icon_comment_number":@"news_toolbar_icon_comment";
    UIButton *commentBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *commentImage = [UIImage imageNamed:commentStr];
    [commentBtn addTarget:self action:@selector(showComment) forControlEvents:UIControlEventTouchUpInside];
    [commentBtn setFrame:CGRectMake(0, 0, 30, 30)];
    [commentBtn setBackgroundImage:commentImage forState:UIControlStateNormal];
//    [commentBtn setImageEdgeInsets:UIEdgeInsetsMake(0.0f,(kButtonHeight- commentImage.size.width), 0.0f, 0.0f)];
//    [commentBtn addSubview:self.numberLabel];
//    UILabel *commentCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 5, 5)];
//    UIBarButtonItem *commentItem2 = [[UIBarButtonItem alloc] initWithImage:commentImage
//                                                                       style:UIBarButtonItemStylePlain
//                                                                      target:self
//                                                                      action:@selector(showComment)];
//    [commentItem2 initwit]
//    [commentItem2 badgeValue] = @"123";
//    commentItem2.badgeValue = @"1";
//    commentItem2.badgeBGColor = [UIColor orangeColor];
//    [commentBtn setBackgroundImage:btnBg forState:UIControlStateNormal];
    UIBarButtonItem *commentItem=[[UIBarButtonItem alloc] initWithCustomView:commentBtn];
    if (_isComment) {
        commentItem.badgeValue = [NSString stringWithFormat:@"%ld",_commentArray.count];
        commentItem.badgeBGColor = [UIColor clearColor];
        commentItem.badgeTextColor = [UIColor blueColor];
    }
//    commentItem.title = @"123";
//    self.navigationItem.rightBarButtonItem=right;

    
//    UIBarButtonItem *test = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"news_toolbar_icon_comment"] style:UIBarButtonItemStylePlain target:self action:nil];
//    uibarbuttonitem
    
    //blank
    UIBarButtonItem *blank=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [toolBar setItems:[NSArray arrayWithObjects:backItem,blank,commentItem,blank,favItem,blank,shareItem, nil]];
}

- (void)handleFav {
    if (isFav) {
//        if([[DBManager share] delPostFromFavorites:[self.postObj.ID stringValue]])
//        {
            isFav=!isFav;
//            [SVProgressHUD showSuccessWithStatus:@"移除收藏成功"];
            NSString *favBtnBg=isFav?@"news_toolbar_icon_favorite_blue":@"news_toolbar_icon_favorite";
            [favBtn setBackgroundImage:[UIImage imageNamed:favBtnBg] forState:UIControlStateNormal];
//        }
    }
    else
    {
//        if ([[DBManager share] insertPostToFavorites:self.postObj]) {
            isFav=!isFav;
//            [SVProgressHUD showSuccessWithStatus:@"收藏成功"];
            NSString *favBtnBg=isFav?@"news_toolbar_icon_favorite_blue":@"news_toolbar_icon_favorite";
            [favBtn setBackgroundImage:[UIImage imageNamed:favBtnBg] forState:UIControlStateNormal];
//        }
    }

}


- (void)goBack {
//    [self dismis]
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
//     [self.navigationController.navigationBar popNavigationItemAnimated:NO];
//    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)showComment {
    LMCommentViewController *commentVC = [[LMCommentViewController alloc] init];
    [commentVC initChildData:_chilData commentCount:_commentArray.count];
//    [self.navigationController setNavigationBarHidden:YES animated:YES];
    LMNavigationController *naviVC = [[LMNavigationController alloc] initWithRootViewController:commentVC];
//    [self.navigationController pushViewController:commentVC animated:YES];
    [self presentViewController:naviVC animated:YES completion:nil];
    
    //    [contentVC sethide]
//    [self.navigationController pushViewController:commentVC animated:YES];

//    navi.navigationItem.leftBarButtonItem = [UIBarButtonItem initWithNormalImage:@"common_nav_icon_back"  target:self action:@selector(back)];
//    navi.navigationItem.rightBarButtonItem = [UIBarButtonItem initWithTitle:@"写评论" titleColor:nil target:self action:@selector(writeComment)];
    
//    [navi navigationController._navigationItem.left]
//    [commentVC initChildData:_chilData];
//    CommentViewController *commentVC2= [[CommentViewController alloc] initChildData:_chilData];
//    [commentVC initChildData:_chilData];
//    commentVC
//    KeTVViewController *ketv = [[KeTVViewController alloc] init];
    
//    UINavigationController *navi = [[UINavigationController alloc] init];
    
//    navi.navigationItem.title = [NSString stringWithFormat:@"%ld条评论",_commentArray.count];
//    navi.navigationItem.leftBarButtonItem = [UIBarButtonItem initWithNormalImage:@"common_nav_icon_back"  target:self action:@selector(back)];
//    navi.navigationItem.rightBarButtonItem = [UIBarButtonItem initWithTitle:@"写评论" titleColor:nil target:self action:@selector(writeComment)];
//    [navi pushViewController:commentVC animated:YES];
    //    self.navigationItem.title = comment;
    
    
//    ContentViewController *contentVC = [[ContentViewController alloc] init];
//    [contentVC setChilData:dataChild];
//    [contentVC setHidesBottomBarWhenPushed:YES];//加上这句就可以把推出的ViewController隐藏Tabbar
//    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    
    //    [contentVC sethide]
//    [navi.navigationController pushViewController:commentVC animated:YES];
    
//    [self.navigationController pushViewController:commentVC animated:YES];
    
//    [self presentViewController:commentVC animated:YES completion:nil];

}


- (void)loadDisplayView {
    //加载显示
    loadingView=[[UIView alloc] initWithFrame:self.webView.frame];
    [loadingView setBackgroundColor:[Common translateHexStringToColor:@"#f5f5f5"]];
    actView=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    actView.center= self.webView.center;
//    NSLog(@"self.webView.center.x,---%lf",self.webView.center.x);
    loadingLabel=[[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.webView.bounds.size.width, 30)];
    loadingLabel.center=CGPointMake(self.webView.center.x, self.webView.center.y+30);
    [loadingLabel setTextColor:[UIColor lightGrayColor]];
    [loadingLabel setFont:[UIFont systemFontOfSize:12]];
    [loadingLabel setTextAlignment:NSTextAlignmentCenter];
    [loadingLabel setBackgroundColor:[UIColor clearColor]];
    [loadingView addSubview:actView];
    [loadingView addSubview:loadingLabel];

}
-(void)startLoading
{
//    [self.view addSubview:self.webView];
    [self.view addSubview:loadingView];
    [actView startAnimating];
    [loadingLabel setText:@"正在加载..."];
    [self.view bringSubviewToFront:toolBar];
}
-(void)endLoading
{
    
    [actView stopAnimating];
    [loadingView removeFromSuperview];
    
}

-(void)setChilData:(ChildData *)chilData
{
    
    [self startLoading];
    _chilData=chilData;
//    [self setComment];
    
//    [self setTabBarItems];
    [contentHandler handlerContentObject:@"https://rong.36kr.com/api/mobi/news" childData:chilData];
    
    [commentHandler handlerCommentObject:@"https://rong.36kr.com/api/mobi/news/comments" childData:chilData];
    
}


#pragma mark - CotentListJsonHandlerDelegate
- (void)ContentListJsonHandler:(ContentListJsonHandler *)handler withResult:(ContentData *)result {
//    _userArray = [NSMutableArray arrayWithArray:result];
    _contentModel = result;
    isFav = _contentModel.myFavorites;
    NSString *html=[htmTemp stringByReplacingOccurrencesOfString:@"[$Title]" withString:_contentModel.title];
    html=[html stringByReplacingOccurrencesOfString:@"[$Summary]" withString:_contentModel.summary];
    NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:_contentModel.publishTime];

    html=[html stringByReplacingOccurrencesOfString:@"[$Time]" withString:[NSDate stringFromDate:confromTimesp]];
    html=[html stringByReplacingOccurrencesOfString:@"[$Body]" withString:_contentModel.content];
    [self.webView loadHTMLString:html baseURL:nil];
//    [self.tableView reloadData];
    if (!isFirstLoad) {
        [self endLoading];
    }

    
    
}

#pragma mark - CommentListJsonHandlerDelegate
- (void)CommentListJsonHandler:(CommentListJsonHandler *)handler withResult:(NSMutableArray *)result {
    _commentArray = [NSMutableArray arrayWithArray:result];
    _isComment =  _commentArray.count > 0 ? YES : NO;
//    isFav = _chilData.fa
    [self setTabBarItems];
    
}


#pragma -
#pragma scrollview delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
//    if ([[request.URL absoluteString] hasPrefix:@"http://"]) {
//        return NO;
//    }
    return YES;
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    //获取到webview的高度
    CGFloat height = [[self.webView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight"] floatValue];
//    NSLog(@"height---%lf",height);
    self.webView.frame = CGRectMake(self.webView.frame.origin.x,self.webView.frame.origin.y, self.view.bounds.size.width, height );
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView reloadData];
    
    if (isFirstLoad) {
        [self endLoading];
        isFirstLoad=NO;
    }
}
#pragma mark - UITableViewDelegate



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"heightForRowAtIndexPath---%ld",indexPath.row);
    if (indexPath.section == 0) {
        return 50.0f;
    } else if (indexPath.section == 1) {
        return _webView.frame.size.height;
    } else if (indexPath.section == 3){
        if (_commentArray.count == 0) {
            return 1.0f;
        }
//        CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:ID]
        CommentData2 *dataComment = _commentArray[indexPath.row];
       
        CommentCell *commentCell = [CommentCell cellWithTableView:tableView model:dataComment];
        CGSize size = [commentCell.content systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
        NSLog(@"size---%lf",size.height);
         NSLog(@"CGRectGetMaxY(commentCell.content.frame) ---%lf",CGRectGetMaxY(commentCell.content.frame));
        return CGRectGetMaxY(commentCell.content.frame) + size.height   + 40;
        
    } else if (indexPath.section == 2) {
        if (_commentArray.count == 0) {
            return 1.0f;
        }
        return 50.0f;
    }
    return 50.0f;
//    return 90.0f;
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 5;
    
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 3) {
        if (_commentArray.count < 3)
            return _commentArray.count;
        else {
            return 3;
        }
    }
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if (indexPath.section == 0) {
        ContentTopCell *topCell = [ContentTopCell cellWithTableView:tableView model:_contentModel];
        [topCell setSelectionStyle:UITableViewCellSelectionStyleNone];
        return topCell;
    } else if (indexPath.section == 1){
        static NSString *identifier = @"webViewcell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell){
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
//            cell.backgroundColor = [UIColor redColor];
            [cell.contentView addSubview:_webView];
            /* 忽略点击效果 */
//            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
        return cell;
    } else if (indexPath.section == 3){
//        UITableViewCell *cell = [[UITableView alloc] init];
//        
//        return cell;
//        NSLog(@"indexPath.row---%ld",(long)indexPath.row);
        CommentData2 *dataComment = _commentArray[indexPath.row];
        CommentCell *commentCell = [CommentCell cellWithTableView:tableView model:dataComment];
        /* 忽略点击效果 */
        [commentCell setSelectionStyle:UITableViewCellSelectionStyleNone];
        return commentCell;

    } else if (indexPath.section == 2) {
        if (_commentArray.count > 0 ) {
            NewCommentCell *cell = [NewCommentCell cellWithTableView:tableView];
            return cell;
        }
        
        else {
            return [[UITableViewCell alloc] init];
        }
        

    } else if (indexPath.section == 4) {
        
        if (_commentArray.count < 3) {
            return [[UITableViewCell alloc] init];
        } else {
            static NSString *identifier = @"allCommentViewcell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            AllCommentView *commentView2 = [AllCommentView commentWithView2];
            
            if (!cell){
                cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                [cell.contentView addSubview:commentView2];
                
            }
            /* 忽略点击效果 */
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            return cell;

        }
        
    }
    return [[UITableViewCell alloc] init];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 3) {
        LMCommentViewController *commentVC = [[LMCommentViewController alloc] init];
        [commentVC initChildData:_chilData commentCount:_commentArray.count];
        //    [self.navigationController setNavigationBarHidden:YES animated:YES];
        LMNavigationController *naviVC = [[LMNavigationController alloc] initWithRootViewController:commentVC];
        //    [self.navigationController pushViewController:commentVC animated:YES];
        [self presentViewController:naviVC animated:YES completion:nil];
    }
    
    
    if (indexPath.section == 4) {
        LMCommentViewController *commentVC = [[LMCommentViewController alloc] init];
        [commentVC initChildData:_chilData commentCount:_commentArray.count];
        //    [self.navigationController setNavigationBarHidden:YES animated:YES];
        LMNavigationController *naviVC = [[LMNavigationController alloc] initWithRootViewController:commentVC];
        //    [self.navigationController pushViewController:commentVC animated:YES];
        [self presentViewController:naviVC animated:YES completion:nil];
    }
////    ChildData *dataChild = self.newsArray[indexPath.row];
//    ContentViewController *contentVC = [[ContentViewController alloc] init];
//    [contentVC setChilData:dataChild];
//    [self presentViewController:contentVC animated:YES completion:nil];
}





@end
