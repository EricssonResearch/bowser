//
//  BowserViewController.m
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

#import "BowserViewController.h"
#import "BowserHistoryTableViewCell.h"
#include <owr_bridge.h>

static NSString *const kGetUserMedia = @"getUserMedia";
static NSString *const kGetIpAndPort = @"qd_v1_getLocal";
static NSString *const kConsoleLog = @"console.log";

static NSString *startHtml = @"<style>body{background-color:#ededed;font-family:'Courier New',Courier,monospace;font-size:10px;}.__log{border-top:1px solid #ddd;margin:2px;}.__error{border-top:1px solid #ddd;margin:2px;color: red}</style><body><b>Console log</b><pre id='log'></pre>";
static NSString *logHtml = @"document.getElementById('log').innerText += \"%@\n\";window.scrollTo(0, document.body.scrollHeight);";
static NSString *logDividerHtml = @"</div><div class='__log'>";
static NSString *errorDividerHtml = @"</div><div class='__error'>";

static UIImageView *selfView;
static UIImageView *remoteView;

#define kDefaultStartURL @"http://www.openwebrtc.io/bowser"
#define kSearchEngineURL @"http://www.google.com/search?q=%@"
#define kBridgeLocalURL @"http://localhost:10717/owr.js"

@interface BowserViewController ()

@property (nonatomic, strong) NSMutableArray *consoleLogArray;
@property (nonatomic, strong) NSMutableDictionary *mediaPermissionURLs;
@property (nonatomic, strong) NSString *mediaPermissionsURLsFilePath;

- (void)consoleLog:(NSString *)logString isError:(BOOL)isError;
- (void)loadRequestWithURL:(NSString *)url;

@end

@implementation BowserViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.javascriptCode = @
        "(function () {"
        "    if (window.RTCPeerConnection)"
        "        return \"\";"
        "    var xhr = new XMLHttpRequest();"
        "    xhr.open(\"GET\", \"" kBridgeLocalURL "\", false);"
        "    xhr.send();"
        "    eval(xhr.responseText);"
        "    return \"ok\";"
        "})()";

    self.browserView.scrollView.delegate = self;
    self.browserView.bowserDelegate = self;
    self.consoleLogView.scrollView.scrollsToTop = NO;
    self.consoleLogView.scrollView.bounces = NO;
    self.headerView.scrollsToTop = NO;
    self.headerView.contentSize = CGSizeMake(self.view.bounds.size.width+1, self.headerView.bounds.size.height);
    consoleIsVisible = NO;
    bookmarksAreVisible = NO;
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    historyFilePath = [documentsDirectory stringByAppendingPathComponent:@"BowserHistory.plist"];
    bookmarksFilePath = [documentsDirectory stringByAppendingPathComponent:@"Bookmarks.plist"];
    self.mediaPermissionsURLsFilePath = [documentsDirectory stringByAppendingPathComponent:@"BowserMediaPermissionURLs.plist"];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:historyFilePath]) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"BowserHistory" ofType:@"plist"];
        [fileManager copyItemAtPath:filePath toPath:historyFilePath error:&error];
    }
    if (![fileManager fileExistsAtPath:bookmarksFilePath]) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Bookmarks" ofType:@"plist"];
        [fileManager copyItemAtPath:filePath toPath:bookmarksFilePath error:&error];
    }
    if (![fileManager fileExistsAtPath:self.mediaPermissionsURLsFilePath]) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"BowserMediaPermissionURLs" ofType:@"plist"];
        [fileManager copyItemAtPath:filePath toPath:self.mediaPermissionsURLsFilePath error:&error];
    }

    self.mediaPermissionURLs = [[NSMutableDictionary alloc] initWithContentsOfFile:self.mediaPermissionsURLsFilePath];
    bowserHistory = [[NSMutableArray alloc] initWithContentsOfFile:historyFilePath];
    [self.confirmView setUpView];

    canChange = YES;
    headerIsAbove = YES;
    self.historyTableView.layer.borderWidth = 2.0;
    self.historyTableView.layer.borderColor = [UIColor blackColor].CGColor;
    self.historyTableView.layer.shadowColor = [UIColor grayColor].CGColor;
    self.historyTableView.layer.shadowRadius = 5.0;
    self.historyTableView.layer.shadowOpacity = 0.7;

    //Make native video elements
    UIImageView *aSelfView = [[UIImageView alloc] initWithFrame:CGRectZero];
    UIImageView *aRemoteView = [[UIImageView alloc] initWithFrame:CGRectZero];
    selfView = aSelfView;
    remoteView = aRemoteView;

    [self.browserView.scrollView addSubview:remoteView];
    [self.browserView.scrollView addSubview:selfView];
    [self.headerView addSubview:self.bookmarkButton];
    [self.consoleLogView loadHTMLString:[startHtml stringByAppendingString:@"</div></body>"] baseURL:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    static BOOL isBridgeInitialized = NO;
    if (isBridgeInitialized)
        return;

    NSString *startURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastURL"];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"has_started"] || !startURL) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"has_started"];
        startURL = kDefaultStartURL;
    }

    dispatch_queue_t queue = dispatch_queue_create("OWR init queue", NULL);
    dispatch_async(queue, ^{

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Initializing"
                                                                       message:@"Please wait..."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated:YES completion:nil];

        NSLog(@"OWR bridge starting...");
        owr_bridge_start_in_thread();
        NSLog(@"OWR bridge started");

        [alert dismissViewControllerAnimated:YES completion:^{
            // Let's get started...
            self.urlField.text = startURL;
            [self loadRequestWithURL:startURL];
        }];
    });

    isBridgeInitialized = YES;
}

- (void)loadRequestWithURL:(NSString *)url
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:10];
    [self.browserView loadRequest:request];
}

- (IBAction)reloadButtonTapped:(id)sender
{
    if (!pageNavigationTimer.isValid) {
        pageNavigationTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(insertJavascript:) userInfo:nil repeats:YES];
    }
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [self loadRequestWithURL:self.lastURL];
}

- (IBAction)toggleBookmarks
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Bowser Options"
                                                             delegate:self
                                                    cancelButtonTitle:@"Close"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:
                                  @"Clear History",
                                  consoleIsVisible? @"Hide Console": @"Show Console",
                                  @"About Bowser",
                                  @"Bookmarks",
                                  @"Add bookmark", nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == BowserMenuOptionClearHistory) {
        [bowserHistory removeAllObjects];
        [self.mediaPermissionURLs removeAllObjects];
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
    } else if (buttonIndex == BowserMenuOptionShowConsole) {
        if (consoleIsVisible) {
            [self slideDownView:self.consoleLogView];
        } else {
            [self slideUpView:self.consoleLogView];
        }
        consoleIsVisible = !consoleIsVisible;
    } else if (buttonIndex == BowserMenuOptionAboutPage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"aboutPageSegue" sender:self];
        });
    } else if (buttonIndex == BowserMenuOptionShowBookmarks) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"bookmarksSegue" sender:self];
        });
    } else if (buttonIndex == BowserMenuOptionAddBookmark) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"addBookmarkSegue" sender:self];
        });
    }
}

#pragma mark textfield delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *urlString;
    int colonPos = [textField.text rangeOfString:@":"].location;
    int dotPos = [textField.text rangeOfString:@"."].location;

    if (colonPos != NSNotFound && colonPos <= 10 && (dotPos == NSNotFound || colonPos < dotPos))
        urlString = textField.text;
    else if (dotPos == NSNotFound)
        urlString = [NSString stringWithFormat:kSearchEngineURL, textField.text];
    else
        urlString = [NSString stringWithFormat:@"http://%@", textField.text];
    
    [self.browserView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    textField.text = urlString;
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.historyTableView reloadData];
    self.historyTableView.hidden = NO;

    if (textField.text.length >0) [textField selectAll:nil];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.historyTableView.hidden = YES;
    if (textField.text.length == 0) {
        textField.text = self.lastURL;
    }
}

- (IBAction)urlFieldValueChanged:(id)sender
{
    if (!self.urlField.isEditing) {
        return;
    }
    NSString *currentText = self.urlField.text;
    if (currentText.length == 0) {
        [self.historyTableView reloadData];
    }
    if (currentText.length == 1) {
        filteredHistory = [bowserHistory filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"title BEGINSWITH[cd] %@", currentText]]; 
    }
    if (currentText.length > 1) {
        filteredHistory = [bowserHistory filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"url CONTAINS[cd] %@ or title CONTAINS[cd] %@", currentText, currentText]];
    }
    [self.historyTableView reloadData];

}

- (void)sortHistoryArray
{
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"url" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    [bowserHistory sortUsingDescriptors:[NSArray arrayWithObject:descriptor]];
}

- (void)viewDidUnload
{
    [self setBookMarkView:nil];
    [self setBrowserView:nil];
    [self setHeaderView:nil];
    [self setUrlField:nil];
    [self setProgressBar:nil];
    [self setBookmarkButton:nil];
    [self setHistoryTableView:nil];
    [self setConfirmView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

#pragma mark scroll view delegate methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([scrollView isEqual:self.browserView.scrollView]) {
        if (scrollView.contentOffset.y < 0) {
            scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
        } else {
            if (scrollView.scrollIndicatorInsets.top != 0) {
                scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
            }
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([scrollView isEqual:self.headerView]) {
        CGFloat scrollOffset = scrollView.contentOffset.x;
        if (scrollOffset<-40.0) {
            [self.browserView goBack];
        } else if (scrollOffset>40.0) {
            [self.browserView goForward];
        }
    }
    if ([scrollView isEqual:self.browserView.scrollView]) {
        CGFloat yOffset = scrollView.contentOffset.y;
        CGFloat xOffset = scrollView.contentOffset.x;
        CGFloat headerHeight = self.headerView.frame.size.height;

        if (headerIsAbove) {
            if (yOffset < - 20) {
                self.browserView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                self.browserView.scrollView.contentOffset = CGPointMake(xOffset, yOffset - headerHeight);
                headerIsAbove = NO;

                // TODO: Remove status bar, preferably animated.
            }
        } else if (yOffset < - headerHeight) {
            self.browserView.frame = CGRectMake(0, headerHeight, self.view.frame.size.width, self.view.frame.size.height - headerHeight);
            self.browserView.scrollView.contentOffset = CGPointMake(xOffset, yOffset + headerHeight);
            headerIsAbove = YES;
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    canChange = YES;
}

- (void)insertJavascript: (NSTimer*) theTimer
{
    //NSLog(@"timer, webview-url: %@", [self.browserView stringByEvaluatingJavaScriptFromString:@"document.location.href"]);
    if([self.browserView isOnPageWithURL:self.urlField.text]){
        NSLog(@"injecting bootstrap script");
        if ([self.browserView stringByEvaluatingJavaScriptFromString:self.javascriptCode].length > 0) {
            NSLog(@"stopping timer");
            [theTimer invalidate];
        }
    }
}

#pragma mark webview delegate stuff
- (void)webViewDidStartLoad:(BowserWebView *)webView
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    NSLog(@"webViewDidStartLoading...");
    self.progressBar.hidden = NO;
    if (pageNavigationTimer.isValid)
        [pageNavigationTimer invalidate];

    NSLog(@"creating timer");
    pageNavigationTimer = [NSTimer scheduledTimerWithTimeInterval:0
                                                           target:self
                                                         selector:@selector(insertJavascript:)
                                                         userInfo:nil
                                                          repeats:YES];
    [self newVideoRect:CGRectZero forSelfView:YES];
    [self newVideoRect:CGRectZero forSelfView:NO];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType != UIWebViewNavigationTypeOther && !self.urlField.isEditing && !self.urlField.isFirstResponder) {
        self.urlField.text = request.URL.absoluteString;
    }
    return YES;
}

- (void)newVideoRect:(CGRect)rect forSelfView:(BOOL)rectIsSelfView
{
    if (rectIsSelfView) {
        selfView.frame = rect;
    } else {
        remoteView.frame = rect;
    }
}

- (void)webviewProgress:(float)progress
{
    [self.progressBar setProgress:progress];
    if (progress == 0) {
        self.progressBar.hidden = YES;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSURL *currentURL = webView.request.URL;
    self.urlField.text = currentURL.absoluteString;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.lastURL = currentURL.absoluteString;

    [[NSUserDefaults standardUserDefaults] setValue:self.lastURL forKey:@"lastURL"];
    NSLog(@"webViewDidFinishLoading... %@", self.lastURL);

    if (pageNavigationTimer.isValid)
        [pageNavigationTimer invalidate];

    BOOL urlAlreadyExists = NO;
    for (NSDictionary *historyPost in bowserHistory) {
        if([[historyPost objectForKey:@"url"] rangeOfString:currentURL.absoluteString].location != NSNotFound){
            urlAlreadyExists = YES;
            break;
        }
    }
    if (!urlAlreadyExists) {
        NSString *pageTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        if (pageTitle.length == 0) {
            pageTitle = @"No title";
        }
        NSString *domain = [NSString stringWithFormat:@"%@://%@", currentURL.scheme, currentURL.host];
        NSDictionary *newHistoryPost = [NSDictionary dictionaryWithObjectsAndKeys:currentURL.absoluteString, @"url", pageTitle, @"title", domain, @"domain", nil];
        [bowserHistory addObject:newHistoryPost];
        [self sortHistoryArray];
    }
    // Re-set console.log()
    self.consoleLogArray = nil;
    [self.consoleLogView loadHTMLString:[startHtml stringByAppendingString:@"</div></body>"] baseURL:nil];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    //self.urlField.text = self.lastURL;
    [pageNavigationTimer invalidate];
    NSLog(@"WEBVIEW LOADING ERROR ---- %@", [error description]);
    if (error.code == -999) {
        NSLog(@"Error: %@", error.localizedDescription);
        return;
    }
    [[[UIAlertView alloc] initWithTitle:@"Bowser has a problem"
                                message:error.localizedDescription
                               delegate:nil
                      cancelButtonTitle:@"Close"
                      otherButtonTitles: nil] show];
}

- (void)showUserMediaRequestPermissionViewwithRequestId:(NSString *)requestId
{
    NSString *currentHost = [self.browserView getCurrentHost];
    if (currentHost) {
        id dictionaryPost = [self.mediaPermissionURLs objectForKey:currentHost];
        if (dictionaryPost) {
            return;
        }
    }
    /* :::::INFO: Uncomment and remove the line below, if the custom confirm view should be used
    [self.confirmView presentWithTitle:[NSString stringWithFormat:@"%@ wants to use your camera and microphone", currentHost] andRequestId:requestId];
    [self.browserView shrink];
     */
    [[[BowserMediaAlertView alloc] initWithRequestId:requestId forHost:currentHost withDelegate:self] show];
}

/* :::::INFO: This method is never called. Is called if the custom confirm view is used
-(void)bowserConfirmViewResponded:(BOOL)response withRequestId:(NSString *)requestId willRememberResponse:(BOOL)willRemember{
    [self.browserView restore];
    if (willRemember) {
        NSString *currentHost = [self.browserView getCurrentHost];
        if (currentHost) {
            [self.mediaPermissionURLs setValue:[NSNumber numberWithBool:response] forKey:currentHost];
        }
    }
}
 */

- (void)alertView:(BowserMediaAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"clicked index: %d", buttonIndex);
    if (buttonIndex == 2 && alertView.host != NULL) {
        [self.mediaPermissionURLs setValue:[NSNumber numberWithBool:YES] forKey:alertView.host];
    }
}
- (void)consoleLog:(NSString *)logString isError:(BOOL)isError
{
/*    NSLog(@"New console.log string: %@", logString);*/

    if (self.consoleLogArray == nil)
        self.consoleLogArray = [NSMutableArray array];

    if (logString) {
        [self.consoleLogArray addObject:logString];
        NSString *jsSafe = [logString stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
        jsSafe = [jsSafe stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
        jsSafe = [jsSafe stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        NSString *htmlLogString = [NSString stringWithFormat:@"document.getElementById('log').innerText += \"%@\\n\";window.scrollTo(0, document.body.scrollHeight);", jsSafe];
        if ([self.consoleLogView stringByEvaluatingJavaScriptFromString:htmlLogString] == nil) {
            NSLog(@"WARNING! Could not inject console.log message in to page.");
        }
    }
}

- (void)slideUpView:(UIView*)view
{
    [UIView animateWithDuration:0.4 animations:^(void) {
        view.frame = CGRectMake(0, self.view.bounds.size.height-view.bounds.size.height, view.frame.size.width, view.frame.size.height);
    } completion:^(BOOL finished) {
        
    }];
}

- (void)slideDownView:(UIView*)view
{
    [UIView animateWithDuration:0.4 animations:^(void){
        view.frame = CGRectMake(0, self.view.bounds.size.height, view.frame.size.width, view.frame.size.height);
    } completion:^(BOOL finished) {
        
    }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return !self.confirmView.isActive && interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
    } else {
        return !self.confirmView.isActive;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    self.headerView.contentSize = CGSizeMake(self.headerView.bounds.size.width+1, self.headerView.bounds.size.height);
}

- (IBAction)showConsole:(UIButton*)consoleButton
{
    if (consoleIsVisible) {
        [self slideDownView:self.consoleLogView];
        [consoleButton setTitle:@"Show Console" forState:UIControlStateNormal];
    } else {
        [self slideUpView:self.consoleLogView];
        [self slideDownView:self.bookMarkView];
        bookmarksAreVisible = NO;
        [consoleButton setTitle:@"Hide Console" forState:UIControlStateNormal];
    }
    consoleIsVisible = !consoleIsVisible;
}

- (IBAction)clearHistory:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Clear Bowser Data?"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Clear Data"
                                                    otherButtonTitles:nil];
    [actionSheet showInView:self.view];
}

#pragma mark table view stuff
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"storyboardcell";
    BowserHistoryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[BowserHistoryTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    NSDictionary *historyPost = (self.urlField.isEditing && self.urlField.text.length > 0)? [filteredHistory objectAtIndex:indexPath.row] : [bowserHistory objectAtIndex:indexPath.row];
    cell.urlLabel.text = [historyPost objectForKey:@"url"];
    cell.titleLabel.text = [historyPost objectForKey:@"title"];
    [(BowserFavicon*)cell.favicon downloadFaviconFromUrl:[historyPost objectForKey:@"domain"]]; 
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (self.urlField.isEditing && self.urlField.text.length > 0) ? [filteredHistory count] : [bowserHistory count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *historyPost = (self.urlField.isEditing && self.urlField.text.length > 0)? [filteredHistory objectAtIndex:indexPath.row] : [bowserHistory objectAtIndex:indexPath.row];
    NSString *historyString = [historyPost objectForKey:@"url"];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.urlField.text = historyString;
    [self loadRequestWithURL:historyString];
    [self.urlField resignFirstResponder];
    self.historyTableView.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self saveFiles];
}

- (void)saveFiles
{
    [bowserHistory writeToFile:historyFilePath atomically:YES];
    [self.mediaPermissionURLs writeToFile:self.mediaPermissionsURLsFilePath atomically:YES];
    NSLog(@"writing files!");
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"bookmarksSegue"]) {
        UINavigationController *navController = segue.destinationViewController;
        BookmarksViewController *bvc = [navController viewControllers][0];
        bvc.selectionDelegate = self;
    } else if ([segue.identifier isEqualToString:@"addBookmarkSegue"]) {
        UINavigationController *navController = segue.destinationViewController;
        AddBookmarkViewController *abvc = [navController viewControllers][0];
        abvc.bookmarkTitle = [self.browserView stringByEvaluatingJavaScriptFromString:@"document.title"];
        abvc.bookmarkURL = [self.browserView stringByEvaluatingJavaScriptFromString:@"document.URL"];
    }
}

- (void)bookmarkSelectedWithURL:(NSString *)URL
{
    [self loadRequestWithURL:URL];
}

@end
