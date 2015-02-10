#import <Cocoa/Cocoa.h>
#import "VBrowser.h"
#import "DHSwipeClipView.h"

@interface DHSwipeIndicator : NSView {
    VBrowser *webView;
    DHSwipeClipView *clipView;
}

@property (retain) VBrowser *webView;
@property (retain) DHSwipeClipView *clipView;

- (id)initWithWebView:(VBrowser *)aWebView;

@end
