//
//  BowserViewController.h
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

#import <UIKit/UIKit.h>
#import "BowserWebView.h"
#import "AboutViewController.h"
#import "BowserConfirmView.h"
#import "BowserMediaAlertView.h"
#import "BookmarksViewController.h"
#import "AddBookmarkViewController.h"

typedef enum {
    BowserMenuOptionClearHistory,
    BowserMenuOptionShowConsole,
    BowserMenuOptionAboutPage,
    BowserMenuOptionShowBookmarks,
    BowserMenuOptionAddBookmark,
} BowserMenuOption;

@interface BowserViewController : UIViewController <UIWebViewDelegate, UIScrollViewDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, BowserWebViewDelegate, BookmarkSelectionDelegate, UIAlertViewDelegate>
{
    bool canChange;
    bool headerIsAbove;
    bool consoleIsVisible;
    bool bookmarksAreVisible;
    NSMutableArray *bowserHistory;
    NSArray *filteredHistory;
    NSTimer *pageNavigationTimer;
    __strong NSString *historyFilePath, *bookmarksFilePath;
}

@property (weak, nonatomic) IBOutlet UITableView *historyTableView;

@property (weak, nonatomic) IBOutlet UIScrollView *headerView;
@property (weak, nonatomic) IBOutlet UIButton *bookmarkButton;
@property (weak, nonatomic) IBOutlet BowserWebView *browserView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet BowserConfirmView *confirmView;

@property (weak, nonatomic) IBOutlet UITextField *urlField;
@property (weak, nonatomic) IBOutlet UIWebView *consoleLogView;
@property (nonatomic, strong) NSString *lastURL;
@property (nonatomic, strong) NSString *javascriptCode;
@property (weak, nonatomic) IBOutlet UIView *bookMarkView;

- (void)saveFiles;

@end
