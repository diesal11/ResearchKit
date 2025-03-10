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

@import AVFoundation;
@import Speech;

@class ORKSpeechRecognizer;

@protocol ORKSpeechRecognitionDelegate <NSObject>

@optional
/**
 Tells the delegate when the recognition of requested utterance is finished.
 */
- (void)didFinishRecognitionWithError:(null_unspecified NSError *)error;

/**
 Tells the delegate that a hypothesized transcription is available.
 */
- (void)didHypothesizeTranscription:(null_unspecified SFTranscription *)transcription;

/**
 Tells the delegate the recognizer finished recognition, and passes back the full result.
 */
- (void)didFinishRecognition:(nonnull SFSpeechRecognitionResult *)recognitionResult;

/**
 Tells the delegate when the availability of the speech recognizer has changed
 */
- (void)availabilityDidChange:(BOOL)available;

@end

/**
 The `ORKSpeechRecognizer` class is a wrapper for the Speech API framework
 */
@interface ORKSpeechRecognizer: NSObject

/**
 Queries the client application for speech recognition authorization status.
 
 @return The current authorization status of the client application.
 
*/
+ (SFSpeechRecognizerAuthorizationStatus)authorizationStatus;

/**
 Asks the user to grant your app permission to perform speech recognition.
 */
+ (void)requestAuthorization;

/**
 Asks the user to grant your app permission to perform speech recognition.
 
 @param handler A block to execute after the authorization attempt finishes. Not guaranteed to run on the apps main dispatch queue.
 
 */
+ (void)requestAuthorization:(void (^ _Nonnull)(SFSpeechRecognizerAuthorizationStatus authorizationStatus))handler;

/**
 Starts speech recognition for the specified locale
 
 @param locale  Device's locale
 @param reportPartialResults    A boolean value that indicates whether partial, nonfinal results for each utterance are reported.
 @param delegate    The delegate for speech recognition response
 @param handler A handler to report errors

 */
- (void)startRecognitionWithLocale:(null_unspecified NSLocale *)locale reportPartialResults:(BOOL)reportPartialResults responseDelegate:(null_unspecified id<ORKSpeechRecognitionDelegate>)delegate errorHandler:(void (^ _Null_unspecified)(NSError * _Null_unspecified error))handler;

/**
 Appends audio to the end of the recognition request.
 
 @param audioBuffer A buffer of audio
 */
- (void)addAudio:(null_unspecified AVAudioPCMBuffer *)audioBuffer;

/**
 Indicates that the audio source is finished and no more audio will be appended to the
 recognition request.
 */
- (void)endAudio;

@end

#endif
