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


#import <ResearchKit/ORKStepViewController.h>


NS_ASSUME_NONNULL_BEGIN

@class ORKNavigationContainerView;

#if TARGET_OS_IOS || TARGET_OS_VISION
@interface ORKStepViewController () <UIViewControllerRestoration> {
    @protected ORKNavigationContainerView *_navigationFooterView;
}

- (void)stepDidChange;

@property (nonatomic, copy, nullable) NSURL *outputDirectory;
@property (nonatomic, copy, readonly, nullable) NSArray <ORKResult *> *addedResults;

@property (nonatomic, strong, nullable) UIBarButtonItem *internalContinueButtonItem;
@property (nonatomic, strong, nullable) UIBarButtonItem *internalDoneButtonItem;

@property (nonatomic, strong, nullable) UIBarButtonItem *internalSkipButtonItem;

@property (nonatomic, strong, nullable) UIBarButtonItem *continueButtonItem;
@property (nonatomic, strong, nullable) UIBarButtonItem *learnMoreButtonItem;
@property (nonatomic, strong, nullable) UIBarButtonItem *skipButtonItem;

@property (nonatomic, copy, nullable) NSDate *presentedDate;
@property (nonatomic, copy, nullable) NSDate *dismissedDate;

@property (nonatomic, copy, nullable) NSString *restoredStepIdentifier;
@property (nonatomic, assign) BOOL shouldIgnoreiPadDesign;
@property (nonatomic) BOOL shouldPresentInReview;

+ (UIInterfaceOrientationMask)supportedInterfaceOrientations;

// this property is set to `YES` when the step is part of a standalone review step. If set to `YES it will prevent any user input that might change the step result.
@property (nonatomic, readonly) BOOL readOnlyMode;

@property (nonatomic, readonly) BOOL isBeingReviewed;

@property (nonatomic, nullable) ORKReviewStep* parentReviewStep;

@property (nonatomic, assign) BOOL isEarlyTerminationStep;

- (void)willNavigateDirection:(ORKStepViewControllerNavigationDirection)direction;

- (void)notifyDelegateOnResultChange;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

- (BOOL)showValidityAlertWithMessage:(NSString *)text;

- (BOOL)showValidityAlertWithTitle:(NSString *)title message:(NSString *)message;

- (void)initializeInternalButtonItems;

// internal method for updating the bar button items.
- (void)updateBarButtonItems;

// Use this view to layout iPad Constraints.
- (UIView *)viewForiPadLayoutConstraints;

// internal method for updating title label for iPad designs.
- (void)setiPadStepTitleLabelText:(NSString *)text;

// internal method for updating iPadBackgroundViewColor.
- (void)setiPadBackgroundViewColor:(UIColor *)color;

// internal method for enabling back navigation.
- (void)enableBackNavigation;

@end
#endif

NS_ASSUME_NONNULL_END
