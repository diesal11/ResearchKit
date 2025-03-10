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


@import UIKit;
#import "ORKFormStep.h"

NS_ASSUME_NONNULL_BEGIN

@class ORKFormItem;
@class ORKFormItemCell;

@protocol ORKFormItemCellDelegate <NSObject>

@required
- (void)formItemCell:(ORKFormItemCell *)cell answerDidChangeTo:(nullable id)answer;
- (void)formItemCellDidBecomeFirstResponder:(ORKFormItemCell *)cell;
- (void)formItemCellDidResignFirstResponder:(ORKFormItemCell *)cell;
- (void)formItemCell:(ORKFormItemCell *)cell invalidInputAlertWithMessage:(NSString *)input;
- (void)formItemCell:(ORKFormItemCell *)cell invalidInputAlertWithTitle:(NSString *)title message:(NSString *)message;
- (BOOL)formItemCellShouldDismissKeyboard:(ORKFormItemCell *)cell;

@end


@interface ORKFormItemCell : UITableViewCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
                               formItem:(ORKFormItem *)formItem
                                 answer:(nullable id)answer
                          maxLabelWidth:(CGFloat)maxLabelWidth
                               delegate:(id<ORKFormItemCellDelegate>)delegate;

@property (nonatomic, weak, readonly) id<ORKFormItemCellDelegate> delegate;
@property (nonatomic, copy, nullable) id answer;
@property (nonatomic, strong) ORKFormItem *formItem;
@property (nonatomic, copy, nullable) id defaultAnswer;
@property (nonatomic) CGFloat maxLabelWidth;
@property (nonatomic) CGFloat expectedLayoutWidth;
@property (nonatomic) NSDictionary *savedAnswers;
@property (nonatomic) BOOL useCardView;
@property (nonatomic) BOOL isLastItem;
@property (nonatomic) BOOL isFirstItemInSectionWithoutTitle;
@property (nonatomic) ORKCardViewStyle cardViewStyle;

@end


@interface ORKFormItemTextFieldBasedCell : ORKFormItemCell <UITextFieldDelegate>

- (void)removeEditingHighlight;

@end


@interface ORKFormItemTextFieldCell : ORKFormItemTextFieldBasedCell

@end


@interface ORKFormItemConfirmTextCell : ORKFormItemTextFieldCell

@end


@interface ORKFormItemNumericCell : ORKFormItemTextFieldBasedCell

@end


@interface ORKFormItemTextCell : ORKFormItemCell <UITextViewDelegate>

@end


@interface ORKFormItemImageSelectionCell : ORKFormItemCell

@end


@interface ORKFormItemPickerCell : ORKFormItemTextFieldBasedCell

@end


@interface ORKFormItemScaleCell : ORKFormItemCell

@end

#if !TARGET_OS_VISION
@interface ORKFormItemLocationCell : ORKFormItemCell

@end
#endif

@interface ORKFormItemSESCell : ORKFormItemCell

@end

NS_ASSUME_NONNULL_END
