/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#if TARGET_OS_IOS


#import "ORKTinnitusStepContentView.h"

#import "ORKActiveStepTimer.h"
#import "ORKTriangleTappingButton.h"
#import "ORKBorderedButton.h"
#import "ORKSubheadlineLabel.h"
#import "ORKTapCountLabel.h"
#import "ORKNavigationContainerView_Internal.h"

#import "ORKResult.h"

#import "ORKHelpers_Internal.h"
#import "ORKSkin.h"


static const CGFloat TapCaptionLabelTopPadding = 0.0;

@implementation ORKTinnitusStepContentView {
    UIView *_buttonContainer;
    NSNumberFormatter *_formatter;
    NSLayoutConstraint *_topToCaptionLabelConstraint;
    NSLayoutConstraint *_buttonContainerToMatchesButtonConstraint;
    NSLayoutConstraint *_matchesButtonToBottomConstraint;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _tapCaptionLabel = [ORKSubheadlineLabel new];
        _tapCaptionLabel.numberOfLines = 0;
        _tapCaptionLabel.textAlignment = NSTextAlignmentCenter;
        _tapCaptionLabel.translatesAutoresizingMaskIntoConstraints = NO;

        _buttonContainer = [UIView new];
        _buttonContainer.translatesAutoresizingMaskIntoConstraints = NO;

        _tapButtonDown = [[ORKTriangleTappingButton alloc] init];
        _tapButtonDown.translatesAutoresizingMaskIntoConstraints = NO;
        [_tapButtonDown setTitle: @"Down" forState:UIControlStateNormal];
        _tapButtonDown.accessibilityLabel = @"Down";


        _tapButtonUp = [[ORKTriangleTappingButton alloc] init];
        _tapButtonUp.pointsUpwards = YES;
        _tapButtonUp.translatesAutoresizingMaskIntoConstraints = NO;
        [_tapButtonUp setTitle: @"Up" forState:UIControlStateNormal];
        _tapButtonUp.accessibilityLabel = @"Volume Up";
//        _tapButtonUp.accessibilityHint = ORKLocalizedString(@"AX_TAP_BUTTON_HINT", nil);

        _tapButtonMatches = [[ORKBorderedButton alloc] init];
        _tapButtonMatches.translatesAutoresizingMaskIntoConstraints = NO;
        [_tapButtonMatches resetAppearanceAsBorderedButton];
        _tapButtonMatches.fadeDelay = 0.2;
        [_tapButtonMatches setTitle: @"Matches" forState:UIControlStateNormal];
        _tapButtonMatches.accessibilityLabel = @"Matches";
        _tapButtonMatches.contentEdgeInsets = UIEdgeInsetsMake(15, 30, 15, 30);
//        _tapButtonUp.accessibilityHint = ORKLocalizedString(@"AX_TAP_BUTTON_HINT", nil);

        [self addSubview:_tapCaptionLabel];
        [self addSubview:_buttonContainer];
        [self addSubview:_tapButtonMatches];

        [_buttonContainer addSubview:_tapButtonDown];
        [_buttonContainer addSubview:_tapButtonUp];

        [NSLayoutConstraint activateConstraints: @[
            [_tapCaptionLabel.centerXAnchor constraintEqualToAnchor: self.safeAreaLayoutGuide.centerXAnchor],
            [_tapCaptionLabel.topAnchor constraintEqualToAnchor: self.safeAreaLayoutGuide.topAnchor],
            [_tapCaptionLabel.widthAnchor constraintEqualToAnchor: self.safeAreaLayoutGuide.widthAnchor],

            [_tapButtonMatches.centerXAnchor constraintEqualToAnchor: self.safeAreaLayoutGuide.centerXAnchor],
            [_tapButtonMatches.bottomAnchor constraintLessThanOrEqualToAnchor: self.bottomAnchor constant: -20],
            [_tapButtonMatches.bottomAnchor constraintLessThanOrEqualToAnchor: self.safeAreaLayoutGuide.bottomAnchor],

            [_buttonContainer.centerXAnchor constraintEqualToAnchor: self.safeAreaLayoutGuide.centerXAnchor],
            [_buttonContainer.widthAnchor constraintEqualToAnchor: self.safeAreaLayoutGuide.widthAnchor constant: -40],
            [_buttonContainer.heightAnchor constraintEqualToAnchor: _buttonContainer.widthAnchor multiplier:0.45 constant: 0],
            [_buttonContainer.bottomAnchor constraintEqualToAnchor: _tapButtonMatches.topAnchor constant:-40],

            [_tapButtonDown.heightAnchor constraintEqualToAnchor: _buttonContainer.heightAnchor],
            [_tapButtonDown.centerYAnchor constraintEqualToAnchor: _buttonContainer.centerYAnchor],
            [_tapButtonDown.widthAnchor constraintEqualToAnchor: _buttonContainer.widthAnchor multiplier:0.5 constant: 0],
            [_tapButtonDown.leftAnchor constraintEqualToAnchor: _buttonContainer.leftAnchor],

            [_tapButtonUp.heightAnchor constraintEqualToAnchor: _buttonContainer.heightAnchor],
            [_tapButtonUp.centerYAnchor constraintEqualToAnchor: _buttonContainer.centerYAnchor],
            [_tapButtonUp.leftAnchor constraintEqualToAnchor: _tapButtonDown.rightAnchor constant: 0],
            [_tapButtonUp.rightAnchor constraintEqualToAnchor: _buttonContainer.rightAnchor],
        ]];
    }
     return self;
}

- (void)resetStep:(ORKActiveStepViewController *)viewController {
    [super resetStep:viewController];
    _tapButtonDown.enabled = YES;
    _tapButtonUp.enabled = YES;
    _tapButtonMatches.enabled = YES;
}

- (void)finishStep:(ORKActiveStepViewController *)viewController {
    [super finishStep:viewController];
    _tapButtonDown.enabled = NO;
    _tapButtonUp.enabled = NO;
    _tapButtonMatches.enabled = NO;
}

@end

#endif
