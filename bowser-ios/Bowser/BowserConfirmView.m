//
//  BowserConfirmView.m
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

#import "BowserConfirmView.h"

@interface BowserConfirmView()

@property (nonatomic, strong) NSString *requestId;
@property (nonatomic) BOOL isActive;

@end

@implementation BowserConfirmView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.isActive = NO;
    }
    return self;
}

- (void) setUpView
{
    for (UIView *subview in self.subviews) {
        subview.layer.shadowOffset = CGSizeMake(0, 0);
        subview.layer.shadowColor = [UIColor darkGrayColor].CGColor;
        subview.layer.shadowOpacity = 0.9f;
        subview.layer.shadowRadius = 15.0f;
    }
    //self.yesButton.layer.masksToBounds = self.noButton.layer.masksToBounds = YES;
    self.yesButton.layer.cornerRadius = 10.0f;
    self.noButton.layer.cornerRadius = 10.0f;
}

- (IBAction)yesClicked
{
    [self.delegate bowserConfirmViewResponded:YES withRequestId:self.requestId willRememberResponse:self.rememberSwitch.isOn];
    [self dismiss];
}

- (IBAction)noClicked
{
    [self.delegate bowserConfirmViewResponded:NO withRequestId:self.requestId willRememberResponse:self.rememberSwitch.isOn];
    [self dismiss];
}

- (id)initWithTitle:(NSString *)title inView:(UIView *)view withDelegate:(id<BowserConfirmViewDelegate>)delegate
{
    self = [super initWithFrame:view.frame];
    if (self) {
        //UIButton *yesButton = UIbut
    }
    return self;
}

- (void)present
{
    self.hidden = NO;
    self.isActive = YES;
    CGFloat buttonWidth = self.noButton.frame.size.width;
    CGFloat viewHeight = self.frame.size.height;
    [UIView animateWithDuration:0.6 animations:^{
        self.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.4];
        self.titleLabel.transform = CGAffineTransformMakeTranslation(0, viewHeight / 2 - self.titleLabel.frame.size.height-10);
        self.titleLabel.alpha = 1.0;
        self.rememberView.transform = CGAffineTransformMakeTranslation(0, -viewHeight / 2 + self.rememberView.frame.size.height + 10);
        self.rememberView.alpha = 1.0;
        self.noButton.transform = CGAffineTransformMakeTranslation(buttonWidth - 10, 0);
        self.yesButton.transform = CGAffineTransformMakeTranslation(10-buttonWidth, 0);
    }];
}

- (void)presentWithTitle:(NSString *)title andRequestId:(NSString *)requestId
{
    if (self.isActive) {
        [self.delegate bowserConfirmViewResponded:NO withRequestId:requestId willRememberResponse:NO];
        return;
    }
    self.titleLabel.text = title;
    self.requestId = requestId;

    [self present];
}

- (void)dismiss
{
    self.isActive = NO;
    [UIView animateWithDuration:0.6 animations:^{
        self.backgroundColor = [UIColor clearColor];
        self.titleLabel.transform = CGAffineTransformMakeTranslation(0, 0);
        self.titleLabel.alpha = 0.0;
        self.rememberView.transform = CGAffineTransformMakeTranslation(0, 0);
        self.rememberView.alpha = 0.0;
        self.noButton.transform = CGAffineTransformMakeTranslation(0, 0);
        self.yesButton.transform = CGAffineTransformMakeTranslation(0, 0);
    } completion:^(BOOL finished) {
        self.hidden = YES;
        self.rememberSwitch.on = NO;
    }];
}

- (BOOL)isActive
{
    return _isActive;
}

@end
