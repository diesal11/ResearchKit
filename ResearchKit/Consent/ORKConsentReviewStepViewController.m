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


#import "ORKConsentReviewStepViewController.h"

#import "ORKConsentReviewController.h"
#import "ORKFormStepViewController.h"
#import "ORKSignatureStepViewController.h"
#import "ORKStepViewController_Internal.h"
#import "ORKTaskViewController_Internal.h"

#import "ORKAnswerFormat_Internal.h"
#import "ORKCollectionResult_Private.h"
#import "ORKConsentDocument_Internal.h"
#import "ORKConsentReviewStep.h"
#import "ORKConsentSignature.h"
#import "ORKConsentSignatureResult.h"
#import "ORKFormStep.h"
#import "ORKQuestionResult_Private.h"
#import "ORKResult.h"
#import "ORKSignatureResult_Private.h"
#import "ORKSignatureStep.h"
#import "ORKStep_Private.h"

#import "ORKHelpers_Internal.h"
#import "UIBarButtonItem+ORKBarButtonItem.h"
#import "ORKSkin.h"


typedef NS_ENUM(NSInteger, ORKConsentReviewPhase) {
    ORKConsentReviewPhaseName,
    ORKConsentReviewPhaseReviewDocument,
    ORKConsentReviewPhaseSignature
};

@interface ORKConsentReviewStepViewController () <UIPageViewControllerDelegate, ORKStepViewControllerDelegate, ORKConsentReviewControllerDelegate> {
    ORKConsentSignature *_currentSignature;
    UIPageViewController *_pageViewController;

    NSMutableArray *_pageIndices;
    
    NSString *_signatureFirst;
    NSString *_signatureLast;
    UIImage *_signatureImage;
    BOOL _documentReviewed;
    
    NSUInteger _currentPageIndex;
}

@end


@implementation ORKConsentReviewStepViewController

- (instancetype)initWithConsentReviewStep:(ORKConsentReviewStep *)step result:(ORKConsentSignatureResult *)result {
    self = [super initWithStep:step];
    if (self) {
        _signatureFirst = [result.signature givenName];
        _signatureLast = [result.signature familyName];
        _signatureImage = [result.signature signatureImage];
        _documentReviewed = NO;
        
        _currentSignature = [result.signature copy];
        
        _currentPageIndex = NSNotFound;
    }
    return self;
}

- (void)stepDidChange {
    if (![self isViewLoaded]) {
        return;
    }
    
    _currentPageIndex = NSNotFound;
    ORKConsentReviewStep *step = [self consentReviewStep];
    NSMutableArray *indices = [NSMutableArray array];
    if (step.consentDocument) {
        [indices addObject:@(ORKConsentReviewPhaseReviewDocument)];
    }
    if (step.signature.requiresName) {
        [indices addObject:@(ORKConsentReviewPhaseName)];
    }
    if (step.signature.requiresSignatureImage) {
        [indices addObject:@(ORKConsentReviewPhaseSignature)];
    }
    
    _pageIndices = indices;
    
    [self goToPage:0 animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Prepare pageViewController
    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                          navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                        options:nil];
    _pageViewController.delegate = self;
    
    if ([_pageViewController respondsToSelector:@selector(edgesForExtendedLayout)]) {
        _pageViewController.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    _pageViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _pageViewController.view.frame = self.view.bounds;
    [self.view addSubview:_pageViewController.view];
    [self addChildViewController:_pageViewController];
    [_pageViewController didMoveToParentViewController:self];
    
    [self stepDidChange];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([_pageViewController.viewControllers[0] isKindOfClass:[ORKConsentReviewController class]]) {
        ORKConsentReviewController *consentReviewController = _pageViewController.viewControllers[0];
        [self.taskViewController setRegisteredScrollView:consentReviewController.webView.scrollView];
    } else {
        NSAssert(NO, @"The first view controller in a consent review step should be of type ORKConsentReviewController");
    }
}

- (UIBarButtonItem *)goToPreviousPageButtonItem {
    UIBarButtonItem *button = [UIBarButtonItem ork_backBarButtonItemWithTarget:self action:@selector(goToPreviousPage)];
    button.accessibilityLabel = ORKLocalizedString(@"AX_BUTTON_BACK", nil);
    return button;
}

- (void)updateBarButtonItems {
    if (_currentPageIndex == 0) {
        [super updateBarButtonItems];
    } else {
        self.navigationItem.leftBarButtonItem = [self goToPreviousPageButtonItem];
    }
}

- (void)updateBackButton {
    if (_currentPageIndex == NSNotFound) {
        return;
    }
    
    [self updateBarButtonItems];
}

static NSString *const _NameFormIdentifier = @"nameForm";
static NSString *const _GivenNameIdentifier = @"given";
static NSString *const _FamilyNameIdentifier = @"family";

- (ORKFormStepViewController *)makeNameFormViewController {
    ORKFormStep *formStep = [[ORKFormStep alloc] initWithIdentifier:_NameFormIdentifier
                                                            title:self.step.title ? : ORKLocalizedString(@"CONSENT_NAME_TITLE", nil)
                                                             text:self.step.text];
    formStep.useSurveyMode = NO;
    
    ORKTextAnswerFormat *givenNameAnswerFormat = [ORKTextAnswerFormat textAnswerFormat];
    givenNameAnswerFormat.multipleLines = NO;
    givenNameAnswerFormat.autocapitalizationType = UITextAutocapitalizationTypeWords;
    givenNameAnswerFormat.autocorrectionType = UITextAutocorrectionTypeNo;
    givenNameAnswerFormat.spellCheckingType = UITextSpellCheckingTypeNo;
    givenNameAnswerFormat.textContentType = UITextContentTypeGivenName;
    ORKFormItem *givenNameFormItem = [[ORKFormItem alloc] initWithIdentifier:_GivenNameIdentifier
                                                              text:ORKLocalizedString(@"CONSENT_NAME_GIVEN", nil)
                                                      answerFormat:givenNameAnswerFormat];
    givenNameFormItem.placeholder = ORKLocalizedString(@"CONSENT_NAME_PLACEHOLDER", nil);
    
    ORKTextAnswerFormat *familyNameAnswerFormat = [ORKTextAnswerFormat textAnswerFormat];
    familyNameAnswerFormat.multipleLines = NO;
    familyNameAnswerFormat.autocapitalizationType = UITextAutocapitalizationTypeWords;
    familyNameAnswerFormat.autocorrectionType = UITextAutocorrectionTypeNo;
    familyNameAnswerFormat.spellCheckingType = UITextSpellCheckingTypeNo;
    familyNameAnswerFormat.textContentType = UITextContentTypeFamilyName;
    ORKFormItem *familyNameFormItem = [[ORKFormItem alloc] initWithIdentifier:_FamilyNameIdentifier
                                                             text:ORKLocalizedString(@"CONSENT_NAME_FAMILY", nil)
                                                     answerFormat:familyNameAnswerFormat];
    familyNameFormItem.placeholder = ORKLocalizedString(@"CONSENT_NAME_PLACEHOLDER", nil);
    
    givenNameFormItem.optional = NO;
    familyNameFormItem.optional = NO;
    
    ORKFormItem *sectionTitleFormItem = [[ORKFormItem alloc] initWithSectionTitle:ORKLocalizedString(@"CONSENT_NAME_SECTION_TITLE", nil)];
    
    NSArray *formItems = @[sectionTitleFormItem, givenNameFormItem, familyNameFormItem];
    if (ORKCurrentLocalePresentsFamilyNameFirst())
    {
        formItems = @[sectionTitleFormItem, familyNameFormItem, givenNameFormItem];
    }
    
    [formStep setFormItems:formItems];
    
    formStep.optional = NO;
    
    ORKTextQuestionResult *givenNameDefault = [[ORKTextQuestionResult alloc] initWithIdentifier:_GivenNameIdentifier];
    givenNameDefault.textAnswer = _signatureFirst;
    ORKTextQuestionResult *familyNameDefault = [[ORKTextQuestionResult alloc] initWithIdentifier:_FamilyNameIdentifier];
    familyNameDefault.textAnswer = _signatureLast;
    ORKStepResult *defaults = [[ORKStepResult alloc] initWithStepIdentifier:_NameFormIdentifier results:@[givenNameDefault, familyNameDefault]];
    
    ORKFormStepViewController *viewController = [[ORKFormStepViewController alloc] initWithStep:formStep result:defaults];
    viewController.delegate = self;
    
    return viewController;
}

- (ORKConsentReviewController *)makeDocumentReviewViewController {
    ORKConsentSignature *originalSignature = [self.consentReviewStep signature];
    ORKConsentDocument *origninalDocument = self.consentReviewStep.consentDocument;
    
    NSUInteger index = [origninalDocument.signatures indexOfObject:originalSignature];
    
    // Deep copy
    ORKConsentDocument *document = [origninalDocument copy];
    
    if (index != NSNotFound) {
        ORKConsentSignature *signature = document.signatures[index];
        
        if (signature.requiresName) {
            signature.givenName = _signatureFirst;
            signature.familyName = _signatureLast;
        }
    }
    
    NSString *html = [document mobileHTMLWithTitle:ORKLocalizedString(@"CONSENT_REVIEW_TITLE", nil)
                                             detail:ORKLocalizedString(@"CONSENT_REVIEW_INSTRUCTION", nil)];

    ORKConsentReviewController *reviewViewController = [[ORKConsentReviewController alloc] initWithHTML:html delegate:self requiresScrollToBottom:[[self consentReviewStep] requiresScrollToBottom]];
    if (ORKNeedWideScreenDesign(self.view)) {
        [reviewViewController setTextForiPadStepTitleLabel:self.title];
    }
    reviewViewController.localizedReasonForConsent = [[self consentReviewStep] reasonForConsent];
    reviewViewController.cancelButtonItem = self.cancelButtonItem;
    return reviewViewController;
}

static NSString *const _SignatureStepIdentifier = @"signatureStep";

- (ORKSignatureStepViewController *)makeSignatureViewController {
    ORKSignatureStep *step = [[ORKSignatureStep alloc] initWithIdentifier:_SignatureStepIdentifier];
    step.optional = NO;
    ORKSignatureStepViewController *signatureController = [[ORKSignatureStepViewController alloc] initWithStep:step];
    signatureController.delegate = self;
    return signatureController;
}

- (void)goToPreviousPage {
    [self navigateDelta:-1];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (UIViewController *)viewControllerForIndex:(NSUInteger)index {
    if (index >= _pageIndices.count) {
        return nil;
    }
    
    ORKConsentReviewPhase phase = ((NSNumber *)_pageIndices[index]).integerValue;
    
    UIViewController *viewController = nil;
    switch (phase) {
        case ORKConsentReviewPhaseName: {
            // A form step VC with a form step with a first name and a last name
            ORKFormStepViewController *formViewController = [self makeNameFormViewController];
            formViewController.cancelButtonItem = self.cancelButtonItem;
            viewController = formViewController;
            break;
        }
        case ORKConsentReviewPhaseReviewDocument: {
            // Document review VC
            ORKConsentReviewController *reviewViewController = [self makeDocumentReviewViewController];
            viewController = reviewViewController;
            break;
        }
        case ORKConsentReviewPhaseSignature: {
            // Signature VC
            ORKSignatureStepViewController *signatureViewController = [self makeSignatureViewController];
            signatureViewController.cancelButtonItem = self.cancelButtonItem;
            viewController = signatureViewController;
            break;
        }
    }
    return viewController;
}

- (ORKStepResult *)result {
    ORKStepResult *parentResult = [super result];
    if (!_currentSignature) {
        _currentSignature = [[self.consentReviewStep signature] copy];
        
        if (_currentSignature.requiresName) {
            _currentSignature.givenName = _signatureFirst;
            _currentSignature.familyName = _signatureLast;
        }
        if (_currentSignature.requiresSignatureImage) {
            _currentSignature.signatureImage = _signatureImage;
        }
        
        if (_currentSignature.signatureDateFormatString.length > 0) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:_currentSignature.signatureDateFormatString];
            _currentSignature.signatureDate = [dateFormatter stringFromDate:[NSDate date]];
        } else {
            _currentSignature.signatureDate = ORKSignatureStringFromDate([NSDate date]);
        }
    }
    
    ORKConsentSignatureResult *result = [[ORKConsentSignatureResult alloc] initWithIdentifier:self.step.identifier];
    result.signature = _currentSignature;
    result.identifier = _currentSignature.identifier;
    result.consented = _documentReviewed;
    result.startDate = parentResult.startDate;
    result.endDate = parentResult.endDate;
    
    // Add the result
    parentResult.results = [self.addedResults arrayByAddingObject:result] ? : @[result];
    
    return parentResult;
}

- (ORKConsentReviewStep *)consentReviewStep {
    assert(self.step == nil || [self.step isKindOfClass:[ORKConsentReviewStep class]]);
    return (ORKConsentReviewStep *)self.step;
}

- (void)notifyDelegateOnResultChange {
    _currentSignature = nil;
    [super notifyDelegateOnResultChange];
}

#pragma mark ORKStepViewControllerDelegate

- (void)stepViewController:(ORKStepViewController *)stepViewController didFinishWithNavigationDirection:(ORKStepViewControllerNavigationDirection)direction {
    if (_currentPageIndex == NSNotFound) {
        return;
    }
    
    NSInteger delta = (direction == ORKStepViewControllerNavigationDirectionForward) ? 1 : -1;
    [self navigateDelta:delta];
}

- (void)navigateDelta:(NSInteger)delta {
    // Entry point for forward/back navigation.
    NSUInteger pageCount = _pageIndices.count;
    
    if (_currentPageIndex == 0 && delta < 0) {
        // Navigate back in our parent task VC.
        [self goBackward];
    } else if (_currentPageIndex >= (pageCount - 1) && delta > 0) {
        // Navigate forward in our parent task VC.
        [self goForward];
    } else {
        // Navigate within our managed steps
        [self goToPage:(_currentPageIndex + delta) animated:YES];
    }
}

- (void)goToPage:(NSInteger)page animated:(BOOL)animated {
    UIViewController *viewController = [self viewControllerForIndex:page];
    
    if (!viewController) {
        ORK_Log_Debug("No view controller!");
        return;
    }
    
    NSUInteger currentIndex = _currentPageIndex;
    if (currentIndex == NSNotFound) {
        animated = NO;
    }
    
    UIPageViewControllerNavigationDirection direction = (!animated || page > currentIndex) ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
    
    ORKAdjustPageViewControllerNavigationDirectionForRTL(&direction);
    
    _currentPageIndex = page;
    ORKWeakTypeOf(self) weakSelf = self;
    
    //unregister ScrollView to clear hairline
    [self.taskViewController setRegisteredScrollView:nil];
    
    [_pageViewController setViewControllers:@[viewController] direction:direction animated:animated completion:^(BOOL finished) {
        if (finished) {
            ORKStrongTypeOf(weakSelf) strongSelf = weakSelf;
            [strongSelf updateBackButton];
            
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
        }
    }];
}

- (void)stepViewControllerResultDidChange:(ORKStepViewController *)stepViewController {
    if ([stepViewController.step.identifier isEqualToString:_NameFormIdentifier]) {
        // If this is the form step then update the values from the form
        ORKStepResult *result = [stepViewController result];
        ORKTextQuestionResult *fnr = (ORKTextQuestionResult *)[result resultForIdentifier:_GivenNameIdentifier];
        _signatureFirst = (NSString *)fnr.textAnswer;
        ORKTextQuestionResult *lnr = (ORKTextQuestionResult *)[result resultForIdentifier:_FamilyNameIdentifier];
        _signatureLast = (NSString *)lnr.textAnswer;
        [self notifyDelegateOnResultChange];
        
    } else if ([stepViewController.step.identifier isEqualToString:_SignatureStepIdentifier]) {
        // If this is the signature step then update the image from the signature
        ORKStepResult *result = [stepViewController result];
        [result.results enumerateObjectsUsingBlock:^(ORKResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[ORKSignatureResult class]]) {
                _signatureImage = ((ORKSignatureResult *)obj).signatureImage;
                *stop = YES;
    }
        }];
        [self notifyDelegateOnResultChange];
    }
}

- (void)stepViewControllerDidFail:(ORKStepViewController *)stepViewController withError:(NSError *)error {
    ORKStrongTypeOf(self.delegate) strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(stepViewControllerDidFail:withError:)]) {
        [strongDelegate stepViewControllerDidFail:self withError:error];
    }
}

- (BOOL)stepViewControllerHasNextStep:(ORKStepViewController *)stepViewController {
    if (_currentPageIndex < (_pageIndices.count - 1)) {
        return YES;
    }
    return [self hasNextStep];
}

- (BOOL)stepViewControllerHasPreviousStep:(ORKStepViewController *)stepViewController {
    return [self hasPreviousStep];
}

- (void)stepViewController:(ORKStepViewController *)stepViewController recorder:(ORKRecorder *)recorder didFailWithError:(NSError *)error {
    ORKStrongTypeOf(self.delegate) strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(stepViewController:recorder:didFailWithError:)]) {
        [strongDelegate stepViewController:self recorder:recorder didFailWithError:error];
    }
}

#pragma mark ORKConsentReviewControllerDelegate

- (void)consentReviewControllerDidAcknowledge:(ORKConsentReviewController *)consentReviewController {
    _documentReviewed = YES;
    [self notifyDelegateOnResultChange];
    [self navigateDelta:1];
}

- (void)consentReviewControllerDidCancel:(ORKConsentReviewController *)consentReviewController {
    _signatureFirst = nil;
    _signatureLast = nil;
    _signatureImage = nil;
    _documentReviewed = NO;
    [self notifyDelegateOnResultChange];
    
    [self goForward];
}

static NSString *const _ORKCurrentSignatureRestoreKey = @"currentSignature";
static NSString *const _ORKSignatureFirstRestoreKey = @"signatureFirst";
static NSString *const _ORKSignatureLastRestoreKey = @"signatureLast";
static NSString *const _ORKSignatureImageRestoreKey = @"signatureImage";
static NSString *const _ORKDocumentReviewedRestoreKey = @"documentReviewed";
static NSString *const _ORKCurrentPageIndexRestoreKey = @"currentPageIndex";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:_currentSignature forKey:_ORKCurrentSignatureRestoreKey];
    [coder encodeObject:_signatureFirst forKey:_ORKSignatureFirstRestoreKey];
    [coder encodeObject:_signatureLast forKey:_ORKSignatureLastRestoreKey];
    [coder encodeObject:_signatureImage forKey:_ORKSignatureImageRestoreKey];
    [coder encodeBool:_documentReviewed forKey:_ORKDocumentReviewedRestoreKey];
    [coder encodeInteger:_currentPageIndex forKey:_ORKCurrentPageIndexRestoreKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    _currentSignature = [coder decodeObjectOfClass:[ORKConsentSignature class]
                                            forKey:_ORKCurrentSignatureRestoreKey];
    
    _signatureFirst = [coder decodeObjectOfClass:[NSString class] forKey:_ORKSignatureFirstRestoreKey];
    _signatureLast = [coder decodeObjectOfClass:[NSString class] forKey:_ORKSignatureLastRestoreKey];
    _signatureImage = [coder decodeObjectOfClass:[NSString class] forKey:_ORKSignatureImageRestoreKey];
    _documentReviewed = [coder decodeBoolForKey:_ORKDocumentReviewedRestoreKey];
    _currentPageIndex = [coder decodeIntegerForKey:_ORKCurrentPageIndexRestoreKey];
    
    [self goToPage:_currentPageIndex animated:NO];
}

@end

#endif
