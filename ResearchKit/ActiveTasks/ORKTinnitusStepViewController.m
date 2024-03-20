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


#import "ORKTinnitusStepViewController.h"

#import "ORKActiveStepTimer.h"
#import "ORKAudioGenerator.h"
#import "ORKRoundTappingButton.h"
#import "ORKTinnitusStepContentView.h"
#import "ORKStepContainerView_Private.h"
#import "ORKStepView_Private.h"
#import "ORKActiveStepViewController_Internal.h"
#import "ORKStepViewController_Internal.h"

#import "ORKActiveStepView.h"
#import "ORKCollectionResult_Private.h"
#import "ORKStep.h"
#import "ORKTinnitusStep.h"
#import "ORKTinnitusStepResult.h"
#import "ORKNavigationContainerView_Internal.h"

#import "ORKHelpers_Internal.h"


@interface ORKTinnitusStepViewController ()

@property (nonatomic, strong) ORKSubheadlineLabel *textLabel;
@property (nonatomic, strong) ORKAudioGenerator *audioGenerator;

@end


@implementation ORKTinnitusStepViewController {
    ORKTinnitusStepContentView *_tinnitusContentView;

    UIGestureRecognizer *_touchDownRecognizer;
}

- (instancetype)initWithStep:(ORKStep *)step {
    self = [super initWithStep:step];
    if (self) {
        self.suspendIfInactive = YES;
        _audioGenerator = [ORKAudioGenerator new];
    }
    return self;
}

- (void)initializeInternalButtonItems {
    [super initializeInternalButtonItems];

    // Don't show next button
    self.internalContinueButtonItem = nil;
    self.internalDoneButtonItem = nil;
}

- (ORKTinnitusStep *)tinnitusStep {
    return (ORKTinnitusStep *)self.step;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ORKTinnitusStep *step = [self tinnitusStep];

    _tinnitusContentView = [[ORKTinnitusStepContentView alloc] init];
    _tinnitusContentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.activeStepView.customContentFillsAvailableSpace = YES;
    self.activeStepView.isNavigationContainerScrollable = NO;
    self.activeStepView.delaysContentTouches = NO;
    self.activeStepView.activeCustomView = _tinnitusContentView;

    [_tinnitusContentView.tapCaptionLabel setText: step.stepDescription];

//    [_tinnitusContentView.tapButtonDown addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
//    [_tinnitusContentView.tapButtonUp addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
//    [_tinnitusContentView.tapButtonMatches addTarget:self action:@selector(buttonPressed:forEvent:) forControlEvents:UIControlEventTouchDown];
//    [_tinnitusContentView.tapButtonDown addTarget:self action:@selector(buttonReleased:forEvent:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
//    [_tinnitusContentView.tapButtonUp addTarget:self action:@selector(buttonReleased:forEvent:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
//    [_tinnitusContentView.tapButtonMatches addTarget:self action:@selector(buttonReleased:forEvent:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self start];
//    [_audioGenerator stop]
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

//    [self.audioGenerator stop];
}

- (ORKStepResult *)result {
    ORKStepResult *sResult = [super result];
    
    // "Now" is the end time of the result, which is either actually now,
    // or the last time we were in the responder chain.
//    NSDate *now = sResult.endDate;
    
    NSMutableArray *results = [NSMutableArray arrayWithArray:sResult.results];

    ORKTinnitusStepResult *tinnitusResult = [[ORKTinnitusStepResult alloc] initWithIdentifier: self.step.identifier];

    tinnitusResult.measurement = ORKTinnitusStepMeasurementLoudness;

    [results addObject:tinnitusResult];
    sResult.results = [results copy];
    
    return sResult;
}

//- (void)receiveTouch:(UITouch *)touch onButton:(ORKTappingButtonIdentifier)buttonIdentifier {
//    if (_expired || self.samples == nil) {
//        return;
//    }
//    
//    NSTimeInterval mediaTime = touch.timestamp;
//    
//    if (_tappingStart == 0) {
//        _tappingStart = mediaTime;
//    }
//    
//    CGPoint location = [touch locationInView:self.view];
//    
//    // Add new sample
////    mediaTime = mediaTime-_tappingStart;
//    
////    ORKTappingSample *sample = [[ORKTappingSample alloc] init];
////    sample.buttonIdentifier = buttonIdentifier;
////    sample.location = location;
////    sample.duration = 0;
////    sample.timestamp = mediaTime;
////
////    [self.samples addObject:sample];
//
////    if (UIAccessibilityIsVoiceOverRunning()) {
////        static NSNumberFormatter *TapCountAnnouncementFormatter = nil;
////        static dispatch_once_t onceToken;
////        dispatch_once(&onceToken, ^{
////            TapCountAnnouncementFormatter = [[NSNumberFormatter alloc] init];
////        });
////        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, [TapCountAnnouncementFormatter stringFromNumber:@(_hitButtonCount)]);
////    }
//}
//
//- (void)releaseTouch:(UITouch *)touch onButton:(ORKTappingButtonIdentifier)buttonIdentifier {
//    if (self.samples == nil) {
//        return;
//    }
//    NSTimeInterval mediaTime = touch.timestamp;
//    
//    // Take last sample for buttonIdentifier, and fill duration
//    ORKTappingSample *sample = [self lastSampleWithEmptyDurationForButton:buttonIdentifier];
//    sample.duration = mediaTime - sample.timestamp - _tappingStart;
//}

//- (ORKTappingSample *)lastSampleWithEmptyDurationForButton:(ORKTappingButtonIdentifier)buttonIdentifier{
//    NSEnumerator *enumerator = [self.samples reverseObjectEnumerator];
//    for (ORKTappingSample *sample in enumerator) {
//        if (sample.buttonIdentifier == buttonIdentifier && sample.duration == 0) {
//            return sample;
//        }
//    }
//    return nil;
//}

- (void)stepDidFinish {
    [super stepDidFinish];
    
    [_tinnitusContentView finishStep:self];
    [self goForward];
}

- (void)countDownTimerFired:(ORKActiveStepTimer *)timer finished:(BOOL)finished {
    [super countDownTimerFired:timer finished:finished];
}

- (void)start {
    [super start];
    self.skipButtonItem = nil;
}

#pragma mark buttonAction

- (IBAction)buttonPressed:(id)button forEvent:(UIEvent *)event {
    NSLog(@"button");
//    NSLog(@"%@", button.state);
    NSLog(@"");

//    if (UIAccessibilityIsVoiceOverRunning()) {
//        if (!_tappingContentView.isAccessibilityElement) {
//            // Make the buttons directly tappable with VoiceOver
//            _tappingContentView.isAccessibilityElement = YES;
//            _tappingContentView.accessibilityLabel = ORKLocalizedString(@"AX_TAP_BUTTON_DIRECT_TOUCH_AREA", nil);
//            _tappingContentView.accessibilityTraits = UIAccessibilityTraitAllowsDirectInteraction;
//            // Ensure that VoiceOver is aware of the direct touch area so that the first tap gets registered
//            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, _tappingContentView);
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                // Work around an issue in VoiceOver where announcements don't get spoken if they happen during a button activation
//                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, ORKLocalizedString(@"AX_TAP_BUTTON_DIRECT_TOUCH_ANNOUNCEMENT", nil));
//            });
//            // Don't actually handle this as a tap yet.
//            return;
//        }
//    }
    
//    if (self.samples == nil) {
//        // Start timer on first touch event on button
//        _samples = [NSMutableArray array];
//        [self start];
//    }

//    [self receiveTouch:[[event touchesForView:button] anyObject] onButton:index];
}

- (IBAction)buttonReleased:(id)button forEvent:(UIEvent *)event {
//    ORKTappingButtonIdentifier index = (butto/*n == _tappingContentView.tapButton1) ? ORKTappingButtonIdentifierLeft : ORKTappingButtonIdentifierRight;*/
    
//    [self releaseTouch:[[event touchesForView:button] anyObject] onButton:index];
}

@end

#endif
