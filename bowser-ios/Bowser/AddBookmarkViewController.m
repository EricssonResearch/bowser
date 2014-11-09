//
//  AddBookmarkViewController.m
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

#import "AddBookmarkViewController.h"

@interface AddBookmarkViewController () <UITextFieldDelegate>
{
    IBOutlet UITextField *titleTextField;
    IBOutlet UITextField *urlTextField;
}

@end

@implementation AddBookmarkViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    titleTextField.delegate = self;
    urlTextField.delegate = self;

    titleTextField.text = self.bookmarkTitle;
    urlTextField.text = self.bookmarkURL;
}

- (IBAction)cancelButtonTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveButtonTapped:(id)sender
{
    if (![titleTextField.text isEqualToString:@""] && ![urlTextField.text isEqualToString:@""]) {
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *bookmarksFilePath = [documentsDirectory stringByAppendingPathComponent:@"Bookmarks.plist"];
        NSMutableArray *currentBookmarks = [NSMutableArray arrayWithContentsOfFile:bookmarksFilePath];

        NSDictionary *bookmark = @{@"title": titleTextField.text, @"url": urlTextField.text};
        [currentBookmarks addObject:bookmark];

        NSLog(@"Writing new bookmarks to file at %@", bookmarksFilePath);
        [currentBookmarks writeToFile:bookmarksFilePath atomically:YES];

        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
