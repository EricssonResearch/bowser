//
//  BowserWebView.m
//  Bowser
//
//  Copyright (c) 2014, Ericsson AB.
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, this
//  list of conditions and the following disclaimer in the documentation and/or other
//  materials provided with the distribution.

//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
//  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
//  OF SUCH DAMAGE.
//

#import "BowserWebView.h"

@interface UIWebView ()

- (id)webView:(id)view identifierForInitialRequest:(id)initialRequest fromDataSource:(id)dataSource;
- (void)webView:(id)view resource:(id)resource didFinishLoadingFromDataSource:(id)dataSource;
- (void)webView:(id)view resource:(id)resource didFailLoadingWithError:(id)error fromDataSource:(id)dataSource;
- (void)webView:(UIWebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(id)frame;

@end

@implementation BowserWebView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        resourceCount = 0;
        resourceCompletedCount = 0;
    }
    return self;
}

- (BOOL)isOnPageWithURL: (NSString*) urlString
{
    return ([[self stringByEvaluatingJavaScriptFromString:@"window.location.href"] rangeOfString:urlString].location != NSNotFound);
}

- (NSString *)getCurrentHost
{
    return [self stringByEvaluatingJavaScriptFromString:@"window.location.host"];
}

- (id)webView:(id)view identifierForInitialRequest:(id)initialRequest fromDataSource:(id)dataSource
{
    resourceCount++;
    return [super webView:view identifierForInitialRequest:initialRequest fromDataSource:dataSource];
}

- (void)webView:(id)view resource:(id)resource didFailLoadingWithError:(id)error fromDataSource:(id)dataSource 
{
    [super webView:view resource:resource didFailLoadingWithError:error fromDataSource:dataSource];
    resourceCompletedCount++;
/*    NSLog(@"completed fail: %d, total: %d", resourceCompletedCount, resourceCount);*/
    [self setProgress:resourceCompletedCount ofTotal:resourceCount];
}

- (void)webView:(id)view resource:(id)resource didFinishLoadingFromDataSource:(id)dataSource
{
    [super webView:view resource:resource didFinishLoadingFromDataSource:dataSource];

    resourceCompletedCount++;
    [self setProgress:resourceCompletedCount ofTotal:resourceCount];
}

- (void)setProgress:(int)done ofTotal:(int) total
{
    float progress = 0;

    if (resourceCompletedCount >= resourceCount) {
        resourceCount = 0;
        resourceCompletedCount = 0;
    } else {
        progress = ((float)done)/((float)total);
    }
    if ([self.delegate respondsToSelector:@selector(webviewProgress:)]) {
        [self.bowserDelegate webviewProgress:progress];
    }

}

- (void)shrink
{
    [UIView animateWithDuration:0.6 animations:^{
        self.transform = CGAffineTransformMakeScale(0.82, 0.82);
    }];
}

- (void)restore
{
    [UIView animateWithDuration:0.6 animations:^{
        self.transform = CGAffineTransformMakeScale(1, 1);
    }];
}

- (void)webView:(UIWebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(id)frame
{
    if ([message rangeOfString:@"owr-message:video-rect"].location == 0) {
        CGFloat sf = 1.0/([UIScreen mainScreen].scale);
        NSArray *messageComps = [message componentsSeparatedByString:@","];
        NSString *tag = [messageComps objectAtIndex:2];
        CGFloat x = [[messageComps objectAtIndex:3] floatValue];
        CGFloat y = [[messageComps objectAtIndex:4] floatValue];
        CGFloat width = [[messageComps objectAtIndex:5] floatValue] - x;
        CGFloat height = ([[messageComps objectAtIndex:6] floatValue] - y);
        int rotation = [[messageComps objectAtIndex:7] intValue];
        CGRect newRect = CGRectMake(x * sf, y * sf, width * sf, height * sf);
        [self.bowserDelegate newVideoRect:newRect rotation:rotation tag:tag];
    } else {
        [super webView:sender runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame];
    }
}

@end
