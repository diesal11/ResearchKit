//
/*
 Copyright (c) 2024, Apple Inc. All rights reserved.
 
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

#import "ORKHelpers_Internal.h"
#import "ORKTextButton_Internal.h"
#import "ORKTriangleTappingButton.h"
#import "ORKBorderedButton.h"

@interface ORKTriangleTappingButton ()
@property (strong,nonatomic) UIBezierPath *triangleShape;
@property (strong,nonatomic) CAShapeLayer *triangleLayer;
@end

@implementation ORKTriangleTappingButton

- (void)init_ORKTextButton {
    [super init_ORKTextButton];
    
    _triangleShape = [UIBezierPath new];
    _triangleLayer = [CAShapeLayer new];
    _triangleLayer.path = _triangleShape.CGPath;
    self.pointsUpwards = NO;
    [self.layer insertSublayer: _triangleLayer atIndex: 0];
}

- (void)tintColorDidChange {
    //    [super tintColorDidChange];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.7] forState:UIControlStateHighlighted];
}

+ (UIFont *)defaultFont {
    // regular, 20
    UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleHeadline];
    return [UIFont systemFontOfSize:((NSNumber *)[descriptor objectForKey:UIFontDescriptorSizeAttribute]).doubleValue + 3.0];
}

- (UIColor*)getBackgroundColor {
    id tintColor = ORKViewTintColor(self);
    id highlightedColor = [tintColor colorWithAlphaComponent:0.7f];
    id disabledColor = [tintColor colorWithAlphaComponent:0.3f];

    if (self.enabled && (self.highlighted || self.selected)) {
        return highlightedColor;
    } else if(self.enabled && !(self.highlighted || self.selected)) {
        return tintColor;
    } else {
        return disabledColor;
    }
}

- (void)setPointsUpwards:(BOOL)pointsUpwards {
    if (pointsUpwards) {
        self.titleEdgeInsets = UIEdgeInsetsMake(30, 0, 0, 0);
    } else {
        self.titleEdgeInsets = UIEdgeInsetsMake(-30, 0, 0, 0);
    }

    _pointsUpwards = pointsUpwards;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];

    [self updateBackgroundColor];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];

    [self updateBackgroundColor];
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];

    [self updateBackgroundColor];
}

- (void)updateBackgroundColor {
    _triangleLayer.fillColor = [self getBackgroundColor].CGColor;
}

- (void)drawRect:(CGRect)rect {
    CGFloat xMin = CGRectGetMinX(rect);
    CGFloat xMax = CGRectGetMaxX(rect);
    CGFloat xHalf = ((xMax - xMin) / 2) + xMin;

    CGFloat yMin = CGRectGetMinY(rect);
    CGFloat yMax = CGRectGetMaxY(rect);

    if (_pointsUpwards) {
        [_triangleShape moveToPoint: CGPointMake(xHalf, yMin)];
        [_triangleShape addLineToPoint: CGPointMake(xMax, yMax)];
        [_triangleShape addLineToPoint: CGPointMake(xMin, yMax)];
    } else {
        [_triangleShape moveToPoint: CGPointMake(xMin, yMin)];
        [_triangleShape addLineToPoint: CGPointMake(xMax, yMin)];
        [_triangleShape addLineToPoint: CGPointMake(xHalf, yMax)];
    }
    [_triangleShape closePath];

    if (!self.isEnabled) {
        [self setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.3f] forState:UIControlStateDisabled];
    } else if (self.isHighlighted) {
        [self setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.7f] forState:UIControlStateHighlighted];
    } else {
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }

    _triangleLayer.path = _triangleShape.CGPath;
    [self updateBackgroundColor];

    [super drawRect: rect];
}

@end
