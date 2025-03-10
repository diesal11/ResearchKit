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

#import "ORKAmslerGridContentView.h"

@interface ORKAmslerGridContentView() {
    UIBezierPath *path;
    CGFloat dimension;
}
@end

@implementation ORKAmslerGridContentView

- (void)plotAmslerGrid {
    dimension = MIN(self.bounds.size.width, self.bounds.size.height);
    
    path = [[UIBezierPath alloc] init];
    path.lineWidth = _lineWidth;
    
    CGFloat cellSize = dimension/_numberOfCellsPerSide;
    
    for (int index = 0; index < _numberOfCellsPerSide; index ++) {
        CGPoint startVertical = CGPointMake((CGFloat)index * cellSize, 0);
        CGPoint endVertical = CGPointMake((CGFloat)index * cellSize, dimension);
        [path moveToPoint:startVertical];
        [path addLineToPoint:endVertical];
        
        CGPoint startHorizontal = CGPointMake(0, (CGFloat)index * cellSize);
        CGPoint endHorizontal = CGPointMake(dimension, (CGFloat)index * cellSize);
        [path moveToPoint:startHorizontal];
        [path addLineToPoint:endHorizontal];
    }
    [path closePath];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [_backgroundColor setFill];
    CGContextFillRect(UIGraphicsGetCurrentContext(), rect);
    
    [self plotAmslerGrid];
    [_lineColor setStroke];
    [path stroke];
    UIBezierPath *circleInTheCenter = [UIBezierPath bezierPathWithArcCenter:CGPointMake(dimension/2, dimension/2) radius:dimension/_ratioOfWidthToRadius startAngle:0 endAngle:360 clockwise:YES];
    [_lineColor setFill];
    [circleInTheCenter fill];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _numberOfCellsPerSide = 10;
        _lineWidth = 1.0;
        _ratioOfWidthToRadius = 75;
        _lineColor = [UIColor blackColor];
        _backgroundColor = [UIColor whiteColor];
        [self setDimensionConstraint];
    }
    return self;
}

- (void)setDimensionConstraint {
    [NSLayoutConstraint activateConstraints:@[
                                              [NSLayoutConstraint constraintWithItem:self
                                                                           attribute:NSLayoutAttributeHeight
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self
                                                                           attribute:NSLayoutAttributeWidth
                                                                          multiplier:1.0
                                                                            constant:0.0]
                                              ]];
}

@end

#endif
