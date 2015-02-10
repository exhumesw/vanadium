/*
 VBrowswer.h
 Vanadium
 
 Created by Benjamin King on 1/20/15.
 Copyright (C) 2015 Exhume Software
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class DHSwipeIndicator;

@interface VBrowser : WebView{
    BOOL isReady;
    BOOL isSearching;
    BOOL isViewingSource;
    
    DHSwipeIndicator *swipeIndicator;
    
    NSString* version;
}

@property BOOL isReady;
@property BOOL isSearching;
@property (retain) DHSwipeIndicator *swipeIndicator;

- (IBAction)zoomOut:(id)sender;
- (IBAction)zoomIn:(id)sender;
- (IBAction)resetZoom:(id)sender;
- (IBAction)takeStringRequestFrom:(id)sender;
- (IBAction)toggleViewSource:(id)sender;
- (IBAction)toggleFullScreen:(id)sender;
- (IBAction)toggleWebInspector:(id)sender;

- (NSString*)requestStringToURL:(NSString*)requestString sender:(id)sender;

- (void)setupPreferences:(BOOL)privateMode;
- (NSRect)clippedDocumentFrame;

- (void)readSafariBookmarksFromPath:(NSString*)path filter:(NSString*)filter;
- (void)parseSafariList:(NSDictionary*)plist toHTML:(NSMutableString*)html filter:(NSString*)filter;

@end


@interface WebPreferences (WebPrivate)
- (void)setTextAreasAreResizable:(BOOL)flag;
- (void)setDeveloperExtrasEnabled:(BOOL)flag;
- (void)setZoomsTextOnly:(BOOL)zoomsTextOnly;
- (void)setWebSecurityEnabled:(BOOL)flag;
@end


@protocol WebInspectorProtocol
- (void)show:(id)sender;
@end


@interface WebView (WebPrivate)
- (id<WebInspectorProtocol>)inspector;

+ (BOOL)_canHandleRequest:(NSURLRequest *)request forMainFrame:(BOOL)forMainFrame;
- (void)_setInViewSourceMode:(BOOL)flag;

- (IBAction)_zoomOut:(id)sender isTextOnly:(BOOL)isTextOnly;
- (IBAction)_zoomIn:(id)sender isTextOnly:(BOOL)isTextOnly;
- (IBAction)_resetZoom:(id)sender isTextOnly:(BOOL)isTextOnly;
@end


@interface WebFrame (WebPrivate)
- (void)reloadFromOrigin;
- (NSString *)_stringByEvaluatingJavaScriptFromString:(NSString *)string forceUserGesture:(BOOL)forceUserGesture; // Safari4
@end


@interface NSResponder (SnowLeopard)
- (void)swipeWithEvent:(NSEvent *)event;
@end