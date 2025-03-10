/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
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


#import "ORKVideoCaptureStep.h"
#import "ORKHelpers_Internal.h"
#import "ORKStep_Private.h"
#import "ORKVideoCaptureStepViewController.h"


@implementation ORKVideoCaptureStep

+ (Class)stepViewControllerClass {
    return [ORKVideoCaptureStepViewController class];
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super initWithIdentifier:identifier];
    if (self) {
        self.optional = YES;
        self.duration = @120;
        self.audioMute = NO;
        self.torchMode = AVCaptureTorchModeAuto;
        self.devicePosition = AVCaptureDevicePositionBack;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK_DECODE_IMAGE(aDecoder, templateImage);
        ORK_DECODE_UIEDGEINSETS(aDecoder, templateImageInsets);
        ORK_DECODE_OBJ_CLASS(aDecoder, duration, NSNumber);
        ORK_DECODE_BOOL(aDecoder, audioMute);
        ORK_DECODE_ENUM(aDecoder, torchMode);
        ORK_DECODE_ENUM(aDecoder, devicePosition);
        ORK_DECODE_OBJ_CLASS(aDecoder, accessibilityHint, NSString);
        ORK_DECODE_OBJ_CLASS(aDecoder, accessibilityInstructions, NSString);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK_ENCODE_IMAGE(aCoder, templateImage);
    ORK_ENCODE_UIEDGEINSETS(aCoder, templateImageInsets);
    ORK_ENCODE_OBJ(aCoder, duration);
    ORK_ENCODE_BOOL(aCoder, audioMute);
    ORK_ENCODE_ENUM(aCoder, torchMode);
    ORK_ENCODE_ENUM(aCoder, devicePosition);
    ORK_ENCODE_OBJ(aCoder, accessibilityHint);
    ORK_ENCODE_OBJ(aCoder, accessibilityInstructions);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKVideoCaptureStep *step = [super copyWithZone:zone];
    step.templateImage = self.templateImage;
    step.templateImageInsets = self.templateImageInsets;
    step.duration = self.duration;
    step.audioMute = self.audioMute;
    step.torchMode = self.torchMode;
    step.devicePosition = self.devicePosition;
    step.accessibilityHint = self.accessibilityHint;
    step.accessibilityInstructions = self.accessibilityInstructions;
    return step;
}

- (NSUInteger)hash {
    return super.hash ^ self.templateImage.hash ^ self.duration.hash ^ self.audioMute ^ self.torchMode ^ self.devicePosition ^ self.accessibilityHint.hash ^ self.accessibilityInstructions.hash;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return isParentSame &&
    ORKEqualObjects(self.templateImage, castObject.templateImage) &&
    UIEdgeInsetsEqualToEdgeInsets(self.templateImageInsets, castObject.templateImageInsets) &&
    ORKEqualObjects(self.duration, castObject.duration) &&
    (self.audioMute == castObject.audioMute) &&
    (self.torchMode == castObject.torchMode) &&
    (self.devicePosition == castObject.devicePosition) &&
    ORKEqualObjects(self.accessibilityHint, castObject.accessibilityHint) &&
    ORKEqualObjects(self.accessibilityInstructions, castObject.accessibilityInstructions);
}

@end

#endif
