/*
 Copyright (c) 2017, CareEvolution, Inc.
 
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

#import "ORKWebViewStepViewController.h"
#import "ORKStepViewController_Internal.h"
#import "ORKWebViewStep.h"

#import "ORKResult_Private.h"
#import "ORKCollectionResult_Private.h"
#import "ORKWebViewStepResult.h"
#import "ORKNavigationContainerView_Internal.h"
#import "ORKSkin.h"
#import "ORKHelpers_Internal.h"
#import "ORKSignatureResult_Private.h"
#import "ORKCustomSignatureFooterView_Private.h"
#import "ORKTaskViewController_Internal.h"

static const CGFloat ORKSignatureTopPadding = 37.0;

// This view controller will hide it's view until the HTML finishes loading.
// That way, the entire view is rendered at once. For a snappier UX, the HTML
// can be preloaded using the `preloadHTML` method.

@implementation ORKWebViewStepViewController {
    UIScrollView *_scrollView;
    WKWebView *_webView;

    NSString *_receivedMessageBody;
    NSMutableArray<NSLayoutConstraint *> *_constraints;
    
    ORKCustomSignatureFooterView *_signatureFooterView;
    
    CGFloat _bottomOffset;

    BOOL _isHTMLRendered;
}

- (ORKWebViewStep *)webViewStep {
    return (ORKWebViewStep *)self.step;
}

- (void)setupSubviews {
    [self setupScrollView];
    [self setupNavigationBarView];
    [self setupNavigationFooterView];
    [self setupWebView];
    [self setupSignatureIfNeeded];
}

- (void)didFinishLoadingHTML {
    // Now that the HTML is loaded we can display the subviews
    [self addSubviews];
    [self setupConstraints];

    // Notify the delegate that the view controller has finished loading
    if (
        _webViewDelegate != nil &&
        [_webViewDelegate respondsToSelector:@selector(didFinishLoadingWebStepViewController:)]
    ) {
        [_webViewDelegate didFinishLoadingWebStepViewController:self];
    }
}

// Refresh the HTML in the web view and hide subviews until it's finished loading.
// This helps to remove flashing behavior in the UI.
- (void)refreshHTML {
    // Remove the subviews while the HTML loads
    [self removeSubviews];
    [NSLayoutConstraint deactivateConstraints:_constraints];

    // Generate the CSS for the HTML

    NSString *css = [self webViewStep].customCSS;

    if (!css) {
        UIColor *backgroundColor = ORKColor(ORKBackgroundColorKey);
        UIColor *textColor;
        if (@available(iOS 13.0, *)) {
            textColor = [UIColor labelColor];
        } else {
            textColor = [UIColor blackColor];
        }

        NSString *backgroundColorString = [self hexStringForColor:backgroundColor];
        NSString *textColorString = [self hexStringForColor:textColor];

        CGFloat horizontalPadding = [self horizontalPadding];

        css = [NSString stringWithFormat:@"body { margin: 0px; font-size: 17px; font-family: \"-apple-system\"; padding-left: %fpx; padding-right: %fpx; background-color: %@; color: %@; }",
               horizontalPadding,
               horizontalPadding,
               backgroundColorString,
               textColorString];
    }

    // Apply the CSS to the HTML using JS

    NSString *js = @"var style = document.createElement('style'); style.innerHTML = '%@'; document.head.appendChild(style);";
    NSString *formattedString = [NSString stringWithFormat:js, css];
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:formattedString injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:true];

    WKUserContentController *controller = _webView.configuration.userContentController;
    [controller removeAllUserScripts];      // Clear the previous script and CSS
    [controller addUserScript:userScript];

    // Kick off loading the HTML. Once it's completed, make sure to call `didFinishLoadingHTML`.
    [_webView loadHTMLString:[self webViewStep].html baseURL:nil];
}


- (CGFloat)horizontalPadding {
    return self.step.useExtendedPadding ?
        ORKStepContainerExtendedLeftRightPaddingForWindow(self.view.window) :
        ORKStepContainerLeftRightPaddingForWindow(self.view.window);
}

- (void)setupWebView {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.allowsInlineMediaPlayback = true;
    if ([config respondsToSelector:@selector(mediaTypesRequiringUserActionForPlayback)]) {
        config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    }

    WKUserContentController *controller = [[WKUserContentController alloc] init];
    [controller addScriptMessageHandler:self name:@"ResearchKit"];
    config.userContentController = controller;

    _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
    _webView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _webView.navigationDelegate = self;
    _webView.scrollView.scrollEnabled = NO;
    _webView.scrollView.delegate = self;
}

- (void)setupScrollView {
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [_scrollView setDelegate:self];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    // We need to re-render the HTML if the interface style has changed
    // so that the CSS adopts the new color scheme.
    if (@available(iOS 13, *)) {
        if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle ||
            self.traitCollection.preferredContentSizeCategory != previousTraitCollection.preferredContentSizeCategory) {
            [self refreshHTML];
        }
    }
}

- (void)setupSignatureIfNeeded {
    if (![self webViewStep].showSignatureAfterContent) {
        return;
    }
    _signatureFooterView = [[ORKCustomSignatureFooterView alloc] init];
    _signatureFooterView.signatureViewDelegate = self;
    _signatureFooterView.delegate = self;
    _signatureFooterView.customViewProvider = [self webViewStep].customViewProvider;

    if ([_signatureFooterView.customViewProvider respondsToSelector:@selector(keyboardDismissModeForCustomView)]) {
        #if TARGET_OS_IOS
        [_scrollView setKeyboardDismissMode:[_signatureFooterView.customViewProvider keyboardDismissModeForCustomView]];
        #endif
    }
}

- (void)setupNavigationBarView {
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *navBarAppearance = [[UINavigationBarAppearance alloc] init];
        [navBarAppearance configureWithOpaqueBackground];
        UINavigationBar *navigationBar = self.navigationController.navigationBar;
        navigationBar.standardAppearance = navBarAppearance;
        navigationBar.scrollEdgeAppearance = navBarAppearance;
    }
}

- (void)setupNavigationFooterView {
    _navigationFooterView = [ORKNavigationContainerView new];
    [_navigationFooterView removeStyling];
    
    _navigationFooterView.continueButtonItem = self.continueButtonItem;
    _navigationFooterView.continueEnabled = YES;
    _navigationFooterView.optional = [self webViewStep].isOptional;
    [_navigationFooterView updateContinueAndSkipEnabled];
    [_navigationFooterView setUseExtendedPadding:[self.step useExtendedPadding]];
    
    if ([self webViewStep].showSignatureAfterContent) {
        _navigationFooterView.continueEnabled = NO;
    }
}

- (void)addSubviews {
    [self.view addSubview:_scrollView];
    [_scrollView addSubview:_navigationFooterView];
    [_scrollView addSubview:_webView];

    if (_signatureFooterView) {
        [_scrollView addSubview:_signatureFooterView];
    }
}

- (void)removeSubviews {
    [_scrollView removeFromSuperview];
    [_navigationFooterView removeFromSuperview];
    [_webView removeFromSuperview];

    if (_signatureFooterView) {
        [_signatureFooterView removeFromSuperview];
    }
}

- (void)setSkipButtonItem:(UIBarButtonItem *)skipButtonItem {
    [super setSkipButtonItem:skipButtonItem];
    _navigationFooterView.skipButtonItem = self.skipButtonItem;
}

- (void)setupConstraints {
    
    if (_constraints) {
        [NSLayoutConstraint deactivateConstraints:_constraints];
    }

    UIView *viewForiPad = [self viewForiPadLayoutConstraints];

    _constraints = nil;
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    _navigationFooterView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _signatureFooterView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _constraints = [[NSMutableArray alloc] initWithArray:@[
        [NSLayoutConstraint constraintWithItem:_scrollView
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:viewForiPad ? : self.view.safeAreaLayoutGuide
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1.0
                                      constant:0.0],
        [NSLayoutConstraint constraintWithItem:_scrollView
                                     attribute:NSLayoutAttributeLeading
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:viewForiPad ? : self.view
                                     attribute:NSLayoutAttributeLeading
                                    multiplier:1.0
                                      constant:0.0],
        [NSLayoutConstraint constraintWithItem:_scrollView
                                     attribute:NSLayoutAttributeTrailing
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:viewForiPad ? : self.view
                                     attribute:NSLayoutAttributeTrailing
                                    multiplier:1.0
                                      constant:0.0],
        [NSLayoutConstraint constraintWithItem:_scrollView
                                     attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:viewForiPad ? : self.view
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1.0
                                      constant:0.0],
        
        [NSLayoutConstraint constraintWithItem:_webView
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:_scrollView
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1.0
                                      constant:0.0],
        [NSLayoutConstraint constraintWithItem:_webView
                                     attribute:NSLayoutAttributeLeft
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.view
                                     attribute:NSLayoutAttributeLeft
                                    multiplier:1.0
                                      constant:0.0],
        [NSLayoutConstraint constraintWithItem:_webView
                                     attribute:NSLayoutAttributeRight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.view
                                     attribute:NSLayoutAttributeRight
                                    multiplier:1.0
                                      constant:0.0],
        [NSLayoutConstraint constraintWithItem:_navigationFooterView
                                     attribute:NSLayoutAttributeLeft
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:viewForiPad ? : self.view
                                     attribute:NSLayoutAttributeLeft
                                    multiplier:1.0
                                      constant:0],
        [NSLayoutConstraint constraintWithItem:_navigationFooterView
                                     attribute:NSLayoutAttributeRight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:viewForiPad ? : self.view
                                     attribute:NSLayoutAttributeRight
                                    multiplier:1.0
                                      constant:0]
    ]];
    
    if ([[self webViewStep] showSignatureAfterContent]) {
        CGFloat horizontalPadding = [self horizontalPadding];

        [_constraints addObjectsFromArray:@[
            [NSLayoutConstraint constraintWithItem:_signatureFooterView
                                         attribute:NSLayoutAttributeTop
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:_webView
                                         attribute:NSLayoutAttributeBottom
                                        multiplier:1.0
                                          constant:ORKSignatureTopPadding / 2.0],
            [NSLayoutConstraint constraintWithItem:_signatureFooterView
                                         attribute:NSLayoutAttributeLeading
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:self.view
                                         attribute:NSLayoutAttributeLeading
                                        multiplier:1.0
                                          constant:horizontalPadding],
            [NSLayoutConstraint constraintWithItem:_signatureFooterView
                                         attribute:NSLayoutAttributeTrailing
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:self.view
                                         attribute:NSLayoutAttributeTrailing
                                        multiplier:1.0
                                          constant:-horizontalPadding],
            
            [NSLayoutConstraint constraintWithItem:_navigationFooterView
                                         attribute:NSLayoutAttributeTop
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:_signatureFooterView
                                         attribute:NSLayoutAttributeBottom
                                        multiplier:1.0
                                          constant:ORKSignatureTopPadding / 2.0],
            [NSLayoutConstraint constraintWithItem:_navigationFooterView
                                         attribute:NSLayoutAttributeBottom
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:_scrollView
                                         attribute:NSLayoutAttributeBottom
                                        multiplier:1.0
                                          constant:0.0],
        ]];
    } else {        
        [_constraints addObjectsFromArray:@[
            [NSLayoutConstraint constraintWithItem:_navigationFooterView
                                         attribute:NSLayoutAttributeTop
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:_webView
                                         attribute:NSLayoutAttributeBottom
                                        multiplier:1.0
                                          constant:ORKSignatureTopPadding / 2.0],
            [NSLayoutConstraint constraintWithItem:_navigationFooterView
                                         attribute:NSLayoutAttributeBottom
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:_scrollView
                                         attribute:NSLayoutAttributeBottom
                                        multiplier:1.0
                                          constant:0.0],
        ]];
    }
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Note, the subviews will not be added to the view hierarchy
    // until the HTML is loaded
    [self setupSubviews];
    [self refreshHTML];
    [self.taskViewController setNavigationBarColor:[self.view backgroundColor]];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    _webView.scrollView.contentOffset = CGPointZero;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    // To prevent zooming
    scrollView.pinchGestureRecognizer.enabled = NO;
}

/**
 This will modify the `contentOffset` on `_scrollView` so the bottom of the provided rect aligns with the provided endPoint.
 
 @param rect                     A rect in `_signatureView` used as a reference point for the scroll.
 @param endPoint            The point the bottom of the rect should be scrolled to.
 @param animated            A boolean value indicating wether the scroll should be animated or not.
 */
- (void)scrollSignatureViewRect:(CGRect)rect toPoint:(CGPoint)endPoint animated:(BOOL)animated {
    CGRect rectInView = [_signatureFooterView convertRect:rect toView:self.view];
    
    CGFloat offset = endPoint.y - (rectInView.origin.y + rectInView.size.height);
    
    if (offset < 0) {
        CGFloat xOffset = _scrollView.contentOffset.x;
        CGFloat yOffset = _scrollView.contentOffset.y - offset;
    
        if (animated) {
            [UIView animateWithDuration:0.2 animations:^{
                [_scrollView setContentOffset:CGPointMake(xOffset, yOffset)];
            }];
        } else {
            [_scrollView setContentOffset:CGPointMake(xOffset, yOffset)];
        }
    }
}

- (void)setBottomOffset:(CGFloat)bottomOffset {
    _bottomOffset = bottomOffset;
    [_scrollView setContentInset:UIEdgeInsetsMake(0, 0, bottomOffset, 0)];
}

- (CGFloat)bottomOffset {
    return _bottomOffset;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [_scrollView setContentInset:UIEdgeInsetsMake(0, 0, _bottomOffset, 0)];
}

- (void)setContinueButtonItem:(UIBarButtonItem *)continueButtonItem {
    [super setContinueButtonItem:continueButtonItem];
    _navigationFooterView.continueButtonItem = continueButtonItem;
}

- (void)startPreload {
    if (self.viewLoaded) {
        [self didFinishLoadingHTML];
    } else {
        [self loadViewIfNeeded];
    }
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([message.body isKindOfClass:[NSString class]]){
        _receivedMessageBody = ORKDynamicCast(message.body, NSString);
        [self goForward];
    }
}

- (ORKStepResult *)result {
    ORKStepResult *stepResult = [super result];
    if (stepResult) {
        NSString *webViewResultIdentifier = @"WebView";
        ORKWebViewStepResult *webViewResult = [[ORKWebViewStepResult alloc] initWithIdentifier:webViewResultIdentifier];
        webViewResult.result = _receivedMessageBody;
        webViewResult.endDate = stepResult.endDate;
        webViewResult.userInfo = @{@"html": [self webViewStep].html};
        stepResult.results = [stepResult.results arrayByAddingObject:webViewResult] ? : @[webViewResult];
        
        if ([[self webViewStep] showSignatureAfterContent] && [_signatureFooterView isComplete]) {
            NSString *signatureResultIdentifier = @"Signature";
            ORKSignatureResult *signatureResult = [_signatureFooterView resultWithIdentifier: signatureResultIdentifier];
            stepResult.results = [stepResult.results arrayByAddingObject:signatureResult] ? : @[signatureResult];
        }
    }
    return stepResult;
}

// MARK: WKWebViewDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    [webView evaluateJavaScript:@"document.readyState" completionHandler:^(id complete, NSError *readyError) {
        if (complete != nil) {
            [webView evaluateJavaScript:@"document.body.scrollHeight" completionHandler:^(id result, NSError *error) {
                if (result != nil) {
                    NSString *resultString = [NSString stringWithFormat:@"%@", result];
                    CGFloat height = [resultString floatValue];
                    [_webView.heightAnchor constraintEqualToConstant:height].active = YES;
                }

                [self didFinishLoadingHTML];
            }];
        } else {
            [self didFinishLoadingHTML];
        }
    }];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        if (_webViewDelegate != nil && [_webViewDelegate respondsToSelector:@selector(handleLinkNavigationWithURL:)]) {
            decisionHandler([_webViewDelegate handleLinkNavigationWithURL:[navigationAction.request mainDocumentURL]]);
            return;
        }
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

// MARK: UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    BOOL enabled = [self shouldEnableSignatureView] && scrollView.isDecelerating;
    [_signatureFooterView setEnabled:enabled];
    
    if ([_scrollView.panGestureRecognizer translationInView:_scrollView.superview].y > 0) {
        // Scrolling upward
        [_signatureFooterView cancelAutoScrollTimer];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [_signatureFooterView setEnabled:[self shouldEnableSignatureView]];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [_signatureFooterView setEnabled:[self shouldEnableSignatureView]];
}

- (BOOL)shouldEnableSignatureView {
    CGFloat bottomOfSignature = _signatureFooterView.frame.origin.y + _signatureFooterView.signatureViewFrame.origin.y + _signatureFooterView.signatureViewFrame.size.height;
    CGFloat signaturePosition = _scrollView.contentOffset.y + _scrollView.frame.size.height;
    return (bottomOfSignature <= signaturePosition);
}

// MARK: Signature

- (void)signatureViewDidEditImage:(nonnull ORKSignatureView *)signatureView {
    _navigationFooterView.continueEnabled = [_signatureFooterView isComplete];
}

- (void)signatureViewDidEndEditingWithTimeInterval {
    if (_shouldScrollAfterSignature) {
        CGPoint bottom = CGPointMake(0, _scrollView.contentSize.height - _scrollView.bounds.size.height + _scrollView.contentInset.bottom);
        [_scrollView setContentOffset:bottom animated:YES];
    }
}

// MARK: Color

- (NSString *)hexStringForColor:(UIColor *)color {
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    size_t count = CGColorGetNumberOfComponents(color.CGColor);
    
    CGFloat r = components[0];
    
    if (count == 2) {
        return [NSString stringWithFormat:@"#%02lX%02lX%02lX", lroundf(r * 255), lroundf(r * 255), lroundf(r * 255)];
    }
    
    CGFloat g = components[1];
    CGFloat b = components[2];
    
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
}

// MARK: ORKCustomSignatureFooterViewStatusDelegate

- (void)signatureFooterView:(nonnull ORKCustomSignatureFooterView *)footerView didChangeCompletedStatus:(BOOL)isComplete {
    _navigationFooterView.continueEnabled = isComplete;
}

@end
