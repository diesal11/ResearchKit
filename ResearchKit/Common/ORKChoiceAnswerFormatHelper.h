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

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class ORKAnswerFormat;
@class ORKImageChoice;
@class ORKTextChoice;
@protocol ORKAnswerOption;

@protocol ORKChoiceAnswerFormatHelper <NSObject>

- (NSArray *)choices;

- (BOOL)isValuePicker;

@end

@interface ORKChoiceAnswerFormatHelper : NSObject

- (instancetype)initWithAnswerFormat:(ORKAnswerFormat *)answerFormat;

- (NSUInteger)choiceCount;

- (nullable id<ORKAnswerOption>)answerOptionAtIndex:(NSUInteger)index;

- (nullable ORKTextChoice *)textChoiceAtIndex:(NSUInteger)index;

- (nullable id)answerForSelectedIndex:(NSUInteger)index;
- (nullable id)answerForSelectedIndexes:(NSArray *)indexes;

- (nullable NSNumber *)selectedIndexForAnswer:(nullable id)answer;
- (NSArray *)selectedIndexesForAnswer:(nullable id)answer;

- (nullable NSString *)stringForChoiceAnswer:(id)answer;
- (nullable NSString *)labelForChoiceAnswer:(id)answer;

@end

#if TARGET_OS_IOS || TARGET_OS_VISION
#pragma mark - iOS
@interface ORKChoiceAnswerFormatHelper ()

- (nullable ORKImageChoice *)imageChoiceAtIndex:(NSUInteger)index;

@end
#endif

NS_ASSUME_NONNULL_END
