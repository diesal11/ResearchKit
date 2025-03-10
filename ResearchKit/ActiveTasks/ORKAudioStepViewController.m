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


#import "ORKAudioStepViewController.h"

#import "ORKActiveStepTimer.h"
#import "ORKActiveStepView.h"
#import "ORKAudioContentView.h"
#import "ORKCustomStepView_Internal.h"
#import "ORKVerticalContainerView.h"

#import "ORKActiveStepViewController_Internal.h"
#import "ORKAudioRecorder.h"

#import "ORKAudioStep.h"
#import "ORKStep_Private.h"

#import "ORKHelpers_Internal.h"

@import AVFoundation;


@interface ORKAudioStepViewController ()

@property (nonatomic, strong) AVAudioRecorder *avAudioRecorder;

@end


@implementation ORKAudioStepViewController {
    ORKAudioContentView *_audioContentView;
    ORKAudioRecorder *_audioRecorder;
    ORKActiveStepTimer *_timer;
    NSTimer *_intervalTimer;
    NSError *_audioRecorderError;
}

- (instancetype)initWithStep:(ORKStep *)step {
    self = [super initWithStep:step];
    if (self) {
        // Continue audio recording in the background
        self.suspendIfInactive = NO;
    }
    return self;
}

- (void)setAlertThreshold:(CGFloat)alertThreshold {
    _alertThreshold = alertThreshold;
    if (self.isViewLoaded && alertThreshold > 0) {
        _audioContentView.alertThreshold = alertThreshold;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _audioContentView = [ORKAudioContentView new];
    _audioContentView.timeLeft = self.audioStep.stepDuration;
    _audioContentView.useRecordButton = self.audioStep.useRecordButton && self.audioStep.stepDuration == 0;
    
    __weak typeof(self) weakSelf = self;
    [_audioContentView setViewEventHandler:^(ORKAudioContentViewEvent event) {
        [weakSelf handleContentViewEvent:event];
    }];

    if (self.alertThreshold > 0) {
        _audioContentView.alertThreshold = self.alertThreshold;
    }

    self.activeStepView.activeCustomView = _audioContentView;
}

- (void)handleContentViewEvent:(ORKAudioContentViewEvent)event {
    
    switch (event) {
        case ORKAudioContentViewEventStartRecording:
            [self start];
            break;
            
        case ORKAudioContentViewEventStopRecording:
            [self finish];
            break;
    }
}

- (void)audioRecorderDidChange {
    _audioRecorder.audioRecorder.meteringEnabled = YES;
    [self setAvAudioRecorder:_audioRecorder.audioRecorder];
}

- (void)recordersDidChange {
    ORKAudioRecorder *audioRecorder = nil;
    for (ORKRecorder *recorder in self.recorders) {
        if ([recorder isKindOfClass:[ORKAudioRecorder class]]) {
            audioRecorder = (ORKAudioRecorder *)recorder;
            break;
        }
    }
    _audioRecorder = audioRecorder;
    [self audioRecorderDidChange];
}

- (ORKAudioStep *)audioStep {
    return (ORKAudioStep *)self.step;
}

- (void)doSample {
    if (_audioRecorderError) {
        return;
    }

    [_avAudioRecorder updateMeters];
    float value = [_avAudioRecorder averagePowerForChannel:0];
    // Assume value is in range roughly -60dB to 0dB
    float clampedValue = MAX(value / 60.0, -1) + 1;
    [_audioContentView addSample:@(clampedValue)];
    
    if (!self.audioStep.useRecordButton) {
        _audioContentView.timeLeft = [_timer duration] - [_timer runtime];
    }
}

- (void)startNewTimerIfNeeded {
    if (self.audioStep.useRecordButton) {
        
        if (!_intervalTimer) {
            
            _intervalTimer = [NSTimer scheduledTimerWithTimeInterval: 20 / 100
                                                              target:self selector:@selector(doSample)
                                                            userInfo:nil
                                                             repeats:YES];
        }
    } else {
        
        if (!_timer) {
            NSTimeInterval duration = self.audioStep.stepDuration;
            ORKWeakTypeOf(self) weakSelf = self;
            _timer = [[ORKActiveStepTimer alloc] initWithDuration:duration interval:duration / 100 runtime:0 handler:^(ORKActiveStepTimer *timer, BOOL finished) {
                ORKStrongTypeOf(self) strongSelf = weakSelf;
                [strongSelf doSample];
                if (finished) {
                    [strongSelf finish];
                }
            }];
            [_timer resume];
        }
    }
    
    _audioContentView.finished = NO;
}

- (void)start {
    [super start];
    [self audioRecorderDidChange];
    
    if (!self.audioStep.useRecordButton) {
        [_timer reset];
        _timer = nil;
    } else {
        [_intervalTimer invalidate];
        _intervalTimer = nil;
    }

    [self startNewTimerIfNeeded];
}

- (void)suspend {
    [super suspend];
    
    if (!self.audioStep.useRecordButton) {
        [_timer pause];
    } else {
        [_intervalTimer invalidate];
        _intervalTimer = nil;
    }
    
    if (_avAudioRecorder) {
        [_audioContentView addSample:@(0)];
    }
}

- (void)resume {
    [super resume];
    [self audioRecorderDidChange];
    
    [self startNewTimerIfNeeded];
    
    if (!self.audioStep.useRecordButton) {
        [_timer resume];
    }
}

- (void)finish {
    if (_audioRecorderError) {
        return;
    }
    [super finish];
    
    if (!self.audioStep.useRecordButton) {
        [_timer reset];
        _timer = nil;
    } else {
        [_intervalTimer invalidate];
        _intervalTimer = nil;
    }
}

- (void)stepDidFinish {
    _audioContentView.finished = YES;
}

- (void)setAvAudioRecorder:(AVAudioRecorder *)recorder {
    _avAudioRecorder = nil;
    _avAudioRecorder = recorder;
}

- (void)recorder:(ORKRecorder *)recorder didFailWithError:(NSError *)error {
    [super recorder:recorder didFailWithError:error];
    _audioRecorderError = error;
    _audioContentView.failed = YES;
}

@end


#endif
