/*
 Copyright (c) 2021, Apple Inc. All rights reserved.
 
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

#if !TARGET_OS_VISION


#import "ORKLocationPermissionType.h"
#import "ORKRequestPermissionView.h"
#import "ORKHelpers_Internal.h"
#import "ORKRequestPermissionButton.h"

@import CoreLocation;

static NSString *const Symbol = @"location.circle";
static const uint32_t IconLightTintColor = 0x50C878;
static const uint32_t IconDarkTintColor = 0x00A36C;

@interface ORKLocationPermissionType()  <CLLocationManagerDelegate>
@property (nonatomic) CLLocationManager *locationManager;
@end

@implementation ORKLocationPermissionType

+ (instancetype)new {
    return [[ORKLocationPermissionType alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupCardView];
    }
    return self;
}

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDelegate:self];
    }
    return _locationManager;
}

- (void)setupCardView {
    
    UIImage *image;
    if (@available(iOS 13, *)) {
        image = [UIImage systemImageNamed:Symbol];
    }
    
    self.cardView = [[ORKRequestPermissionView alloc]
                     initWithIconImage:image
                     title:ORKLocalizedString(@"REQUEST_LOCATION_DATA_STEP_VIEW_TITLE", nil)
                     detailText:ORKLocalizedString(@"REQUEST_LOCATION_DATA_STEP_VIEW_DESCRIPTION", nil)];

    [self.cardView.requestPermissionButton addTarget:self action:@selector(requestPermissionButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    // Set the tint color for the icon
    if (@available(iOS 13, *)) {
        UIColor *dynamicTint = [[UIColor alloc] initWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            return traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? ORKRGB(IconDarkTintColor) : ORKRGB(IconLightTintColor);
        }];
        [self.cardView updateIconTintColor:dynamicTint];
    } else {
        [self.cardView updateIconTintColor:ORKRGB(IconLightTintColor)];
    }
    
    [self checkLocationAuthStatus];
}

-(void)checkLocationAuthStatus {
    switch (CLLocationManager.authorizationStatus) {
        case kCLAuthorizationStatusNotDetermined:
            [self setState:ORKRequestPermissionsButtonStateDefault canContinue:NO];
            break;

        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
            [self setState:ORKRequestPermissionsButtonStateConnected canContinue:YES];
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self checkLocationAuthStatus];
}

// Request for always permission.
- (void)requestPermissionButtonPressed {
    [self.locationManager requestAlwaysAuthorization];
}

- (void)setState:(ORKRequestPermissionsButtonState)state canContinue:(BOOL)canContinue {
    [self.cardView setEnableContinueButton:canContinue];
    [self.cardView.requestPermissionButton setState:state];
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    return YES;
}

@end

#endif
