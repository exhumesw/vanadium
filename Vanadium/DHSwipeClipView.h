#import <Cocoa/Cocoa.h>
#import "VBrowser.h"

@interface DHSwipeClipView : NSClipView {
    CGFloat currentSum;
    NSTimer *drawTimer;
    BOOL canGoLeft;
    BOOL canGoRight;
    VBrowser *webView;
    BOOL isHandlingEvent;
    BOOL _haveAdditionalClip;
    NSRect _additionalClip;
    CGFloat scrollDeltaX;
    CGFloat scrollDeltaY;
}

@property (retain) NSTimer *drawTimer;
@property (assign) CGFloat currentSum;
@property (retain) VBrowser *webView;
@property (assign) BOOL isHandlingEvent;

- (id)initWithFrame:(NSRect)frame webView:(VBrowser *)aWebView;

@end
