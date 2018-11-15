//
//  LDSModuleViewController.m
//  Smarthome
//
//  Created by leedarson on 2018/11/7.
//  Copyright © 2018年 com.lds. All rights reserved.
//

#import "LDSModuleViewController.h"

#import <WebViewJavascriptBridge/WebViewJavascriptBridge.h>


@interface LDSModuleViewController ()<WKNavigationDelegate,UIScrollViewDelegate>
@property(nonatomic, strong) WKWebView *webView;

@property(nonatomic, strong) WebViewJavascriptBridge *bridage;
@end

@implementation LDSModuleViewController
- (WKWebView* )webView {
    if (_webView==nil) {
        _webView =[[WKWebView alloc]initWithFrame:CGRectMake(0, -0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) ];
        
        NSString *base = [[UIWebView new] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        NSString *userAgent = [NSString stringWithFormat:@"%@++++my userAgent"];
        [_webView setCustomUserAgent:userAgent];
        
        _webView.navigationDelegate =self;
        _webView.UIDelegate = (id<WKUIDelegate>)self;
        _webView.scrollView.delegate = self;
        [_webView.scrollView setBounces:NO];
        _webView.scrollView.scrollEnabled = NO;
        [self.view addSubview:_webView];
        _webView.allowsLinkPreview = NO;

        self.edgesForExtendedLayout = UIRectEdgeNone;

        if (@available(iOS 11.0, *)) {
            _webView.scrollView.contentInsetAdjustmentBehavior=UIScrollViewContentInsetAdjustmentNever;
        } else {
            // Fallback on earlier versions
            
            self.automaticallyAdjustsScrollViewInsets =NO;
        }

    }
    return _webView;
}

static double sinit;
static double start;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.webView];
    [self registe];
    sinit = CFAbsoluteTimeGetCurrent();
}

- (void)setUrl:(NSString *)url {
    _url = url;
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_url]]];
}
-(void)setFilepath:(NSString *)filepath {
    _filepath = filepath;
//    [self.webView loadFileURL:[NSURL fileURLWithPath:_filepath] allowingReadAccessToURL:nil];
    //获取bundlePath 路径
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    //获取本地html目录 basePath
//    NSString *basePath = [NSString stringWithFormat: @"%@", kSandboxDucumentPath(kBuildPath)];
    NSString *basePath = [NSString stringWithFormat: @"%@/build/", bundlePath];
    //获取本地html目录 baseUrl
    NSURL *baseUrl = [NSURL fileURLWithPath: basePath isDirectory: YES];
    NSLog(@"%@", baseUrl);
    //html 路径
    NSString *indexPath = [NSString stringWithFormat: @"%@index.html", basePath];
    //html 文件中内容
    NSString *indexContent = [NSString stringWithContentsOfFile:
                              indexPath encoding: NSUTF8StringEncoding error:nil];
    //显示内容
    [self.webView loadHTMLString: indexContent baseURL: baseUrl];

}
- (void)registe {
    self.bridage = [WebViewJavascriptBridge bridgeForWebView:self.webView];
    [self.bridage setWebViewDelegate:self];
    [self.bridage registerHandler:@"send" handler:^(id data, WVJBResponseCallback responseCallback) {
        
    }];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - WKWebView代理
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"webViewDidStartLoad url:%@",webView.URL);
    start = CFAbsoluteTimeGetCurrent();

}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"webview初始化 到加载完成 %f",CFAbsoluteTimeGetCurrent() - sinit);
//    sinit = 0.0000001;
    NSLog(@"webview开始 到加载完成 %f",CFAbsoluteTimeGetCurrent() - start);
    NSLog(@"webViewDidFinishLoad");

}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView API_AVAILABLE(macosx(10.11), ios(9.0)){
    NSLog(@"内存溢出，白屏问题，重新加载");
    
    [self.webView reload];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error{

    [self.webView reload];
    NSLog(@"页面加载失败 error %@",error);
}
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    //证书认证
    if (serverTrust) {
        //加服务端证书校验
        NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"CA" ofType:@"der"];//自签名证书
        NSData* caCert = [NSData dataWithContentsOfFile:cerPath];
        //        NSArray *cerArray = @[caCert];
        
        SecCertificateRef caRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)caCert);
        NSCAssert(caRef != nil, @"caRef is nil");
        
        NSArray *caArray = @[(__bridge id)(caRef)];
        NSCAssert(caArray != nil, @"caArray is nil");
        //把自签名证书加入到信任列表
        OSStatus status = SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)caArray);
        SecTrustSetAnchorCertificatesOnly(serverTrust,NO);
        CFDataRef exceptions = SecTrustCopyExceptions (serverTrust);
        status = SecTrustSetExceptions (serverTrust, exceptions);
        CFRelease (exceptions);
        CFRelease(caRef);
        completionHandler (NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:serverTrust]);
    }else {//权限认证
        completionHandler (NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialWithUser:@"asml" password:@"pwd" persistence:NSURLCredentialPersistenceForSession]);
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end