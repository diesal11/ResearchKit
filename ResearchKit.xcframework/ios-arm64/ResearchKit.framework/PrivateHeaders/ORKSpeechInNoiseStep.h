/*
 Copyright (c) 2018, Apple Inc. All rights reserved.
 
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


@import Foundation;
#import <ResearchKit/ORKDefines.h>
#import <ResearchKit/ORKActiveStep.h>

NS_ASSUME_NONNULL_BEGIN

ORK_CLASS_AVAILABLE
/**
 This active step programatically mixes the speech file with noise file and applies the filter.
 */
@interface ORKSpeechInNoiseStep : ORKActiveStep

/**
 This property accepts the speech file Path.
*/
@property (nonatomic, copy, nullable) NSString *speechFilePath;

/**
 This property acceopts the string representation of the speech to be played.
 */
@property (nonatomic, copy, nullable) NSString *targetSentence;

/**
 This property accepts the speech file.
 */
@property (nonatomic, copy, nullable) NSString *speechFileNameWithExtension;

/**
 This property accepts the noise file.
 */
@property (nonatomic, copy, nullable) NSString *noiseFileNameWithExtension;

/**
 This property accepts the filter file.
 */
@property (nonatomic, copy, nullable) NSString *filterFileNameWithExtension;

/**
 The linear gain applied to the noise file before mixing it with the speech file.
 */
@property (nonatomic, assign) double gainAppliedToNoise;

/**
 This boolean determines the repetitions of the file.
 */
@property (nonatomic, assign) BOOL willAudioLoop;

@property (nonatomic) BOOL hideGraphView;

@end

NS_ASSUME_NONNULL_END

#endif
