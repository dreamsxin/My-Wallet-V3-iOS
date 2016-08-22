//
//  BCWebViewController.m
//  Blockchain
//
//  Created by Mark Pfluger on 10/9/14.
//  Copyright (c) 2014 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCWebViewController.h"
#import "RootService.h"

@interface BCWebViewController ()

@end

@implementation BCWebViewController

UIButton *backButton;
UIActivityIndicatorView *activityIndicatorView;
NSString *titleString;

// Web history
NSMutableArray *visitedPages;

- (id)initWithTitle:(NSString *)title {
    self = [super init];
    if (self) {
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        visitedPages = [NSMutableArray array];
        
        webView = [[UIWebView alloc] init];
        
        webView.delegate = self;
        
        titleString = title;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.frame = CGRectMake(0, 0, app.window.frame.size.width, app.window.frame.size.height);
    
    UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, DEFAULT_HEADER_HEIGHT)];
    topBar.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    [self.view addSubview:topBar];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 17.5, self.view.frame.size.width - 160, 40)];
    headerLabel.font = [UIFont systemFontOfSize:22.0];
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.adjustsFontSizeToFitWidth = YES;
    headerLabel.text = titleString;
    [topBar addSubview:headerLabel];
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 80, 15, 80, 51)];
    closeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    closeButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [closeButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)];
    [closeButton setTitle:BC_STRING_CLOSE forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor colorWithWhite:0.56 alpha:1.0] forState:UIControlStateHighlighted];
    closeButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [closeButton addTarget:self action:@selector(closeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:closeButton];
    
    backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0, 12, 85, 51);
    backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    backButton.contentEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
    [backButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
    [backButton setImage:[UIImage imageNamed:@"back_chevron_icon"] forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor colorWithWhite:0.56 alpha:1.0] forState:UIControlStateHighlighted];
    [backButton addTarget:self action:@selector(backButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [backButton setHidden:YES];
    [topBar addSubview:backButton];
    
    webView.frame = CGRectMake(0, DEFAULT_HEADER_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - DEFAULT_HEADER_HEIGHT);
    webView.scalesPageToFit = YES;
    [self.view addSubview:webView];
    
    activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicatorView.frame = CGRectMake(0, 0, 20, 20);
    CGFloat halfScreenHeight = (self.view.frame.size.height + DEFAULT_HEADER_HEIGHT) / 2;
    CGFloat halfScreenWidth = self.view.frame.size.width / 2;
    activityIndicatorView.center = CGPointMake(halfScreenWidth, halfScreenHeight);
    [self.view addSubview:activityIndicatorView];
    [self.view bringSubviewToFront:activityIndicatorView];
    
    // Remove Shadow
    for(UIView *wview in [[[webView subviews] objectAtIndex:0] subviews]) {
        if([wview isKindOfClass:[UIImageView class]]) { wview.hidden = YES; }
    }
}

- (void)backButtonClicked:(id)sender
{
    [visitedPages removeLastObject];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[visitedPages lastObject]]];
    [self addCookiesToRequest:request];
    
    [webView loadRequest:request];
}

- (void)closeButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark - WebView Delegate

- (void)webViewDidStartLoad:(UIWebView *)_webView
{
    [activityIndicatorView startAnimating];
    
    [backButton setHidden:visitedPages.count < 2];
}

- (void)webViewDidFinishLoad:(UIWebView *)_webView
{
    [activityIndicatorView stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if ([error code] != NSURLErrorCancelled) {
        [app standardNotify:[error localizedDescription]];
    }
    
    [activityIndicatorView stopAnimating];
}

- (BOOL)webView:(UIWebView *)_webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    // External sites open in the system browser
    NSString *hostname = [[request URL] host];
    if ([hostname rangeOfString:HOST_NAME_WALLET_SERVER].location == NSNotFound &&
        [hostname rangeOfString:HOST_NAME_DEV_SERVER].location == NSNotFound) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        
        return FALSE;
    }
    
    if (navigationType != UIWebViewNavigationTypeOther) {
        [webView stopLoading];
        
        [visitedPages addObject:[[request URL] absoluteString]];
        
        NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:[request URL]];
        [self addCookiesToRequest:mutableRequest];
        
        [webView loadRequest:mutableRequest];

        return FALSE;
    }
    
    return TRUE;
}

# pragma mark - Loading URLs

- (void)loadURL:(NSString*)url
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    [visitedPages addObject:[[request URL] absoluteString]];
    
    [self addCookiesToRequest:request];
    
    [webView loadRequest:request];
}

- (void)addCookiesToRequest:(NSMutableURLRequest*)request
{
    NSHTTPCookie *no_header_cookie = [NSHTTPCookie cookieWithProperties:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                         @"blockchain.info", NSHTTPCookieDomain,
                                                                         @"\\", NSHTTPCookiePath,  // IMPORTANT!
                                                                         @"no_header", NSHTTPCookieName,
                                                                         @"true", NSHTTPCookieValue,
                                                                         nil]];
    
    
    NSHTTPCookie *no_footer_cookie = [NSHTTPCookie cookieWithProperties:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                         @"blockchain.info", NSHTTPCookieDomain,
                                                                         @"\\", NSHTTPCookiePath,  // IMPORTANT!
                                                                         @"no_footer", NSHTTPCookieName,
                                                                         @"true", NSHTTPCookieValue,
                                                                         nil]];
    
    NSArray *cookies = [NSArray arrayWithObjects: no_header_cookie, no_footer_cookie, nil];
    
    NSDictionary *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    
    [request setAllHTTPHeaderFields:headers];
}

@end
