/*
 VBrowswer.m
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

#import "VBrowser.h"
#import "DHSwipeIndicator.h"
@implementation VBrowser

@synthesize isReady;
@synthesize isSearching;
@synthesize swipeIndicator;

- (void)awakeFromNib{
    [super awakeFromNib];
    if(NSClassFromString(@"NSPopover")) // this is my dumb way of checking if 10.7+
    {
        self.swipeIndicator = [[DHSwipeIndicator alloc] initWithWebView:self];
    }
    isReady = NO;
    isSearching = NO;
    isViewingSource = NO;
    
    NSDictionary* bundle = [[NSBundle mainBundle] infoDictionary];
    version = [[NSString alloc] initWithString:[bundle objectForKey:@"CFBundleVersion"]];
    
    NSString* userAgent = [NSString stringWithFormat:@"Vanadium/%@ like Version/7.0.5 Safari/537.77.4", version];
    [self setApplicationNameForUserAgent:userAgent];
}

- (IBAction)toggleViewSource:(id)sender;
{
    isViewingSource = !isViewingSource;
    
    [self _setInViewSourceMode:isViewingSource];
    [self reload:self];
}

- (IBAction)toggleWebInspector:(id)sender
{
    [[self inspector] show:sender];
}

- (IBAction)takeStringRequestFrom:(id)sender
{
    if([sender respondsToSelector:@selector(stringValue)] == NO)
        return;
    
    NSString* requestString = [[sender stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if([requestString length] == 0) {
        NSBeep();
        return;
    }
    else if([requestString hasPrefix:@"javascript:"]) {
        if([self isLoading] == NO) {
            [[self window] makeFirstResponder:self];
            
            NSString* script = [requestString substringFromIndex:11];
            NSString* unescapedScript = [script stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            WebFrame* mainFrame = [self mainFrame];
            if([mainFrame respondsToSelector:@selector(_stringByEvaluatingJavaScriptFromString:forceUserGesture:)])
                [mainFrame _stringByEvaluatingJavaScriptFromString:unescapedScript forceUserGesture:YES];
            else {
                WebScriptObject* wso = [self windowScriptObject];
                [wso evaluateWebScript:unescapedScript];
            }
        }
    }
    else if([requestString hasPrefix:@"bookmarks:"]) {
        NSString* bookmarks = [requestString substringFromIndex:10];
        if([bookmarks hasPrefix:@"safari "]) {
            NSString* filter = [bookmarks substringFromIndex:7];
            NSString* bookmarksPath = [NSString stringWithFormat:@"%@/Library/Safari/Bookmarks.plist", NSHomeDirectory()];
            [self readSafariBookmarksFromPath:bookmarksPath filter:filter];
        }
        else if([bookmarks isEqualToString:@"safari"]) {
            NSString* bookmarksPath = [NSString stringWithFormat:@"%@/Library/Safari/Bookmarks.plist", NSHomeDirectory()];
            [self readSafariBookmarksFromPath:bookmarksPath filter:nil];
        }
    }
    else {
        NSString* urlString = [self requestStringToURL:requestString sender:sender];
        
        if(urlString == nil) {
            NSBeep();
            return;
        }
        
        if([self isLoading])
            [self stopLoading:self];
        
        [[self window] makeFirstResponder:self];
        
        NSURL* url = [NSURL URLWithString:urlString];
        [[self mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
    }
}

- (NSString*)requestStringToURL:(NSString*)requestString sender:(id)sender
{
    NSString* urlString = nil;
    
    if([requestString hasPrefix:@"about:"]) {
        NSString* about = [requestString substringFromIndex:6];
        
        if(
           [about isEqualToString:@"about"] ||
           [about isEqualToString:@"shortcuts"] ||
           [about isEqualToString:@"help"] ||
           [about isEqualToString:@"stainless"] ||
           [about isEqualToString:@"vanadium"] ||
           [about isEqualToString:@"exhume"] ||
           [about isEqualToString:@"license"] ||
           [about isEqualToString:@"notes"] ||
           [about isEqualToString:@"private"] ||
           [about isEqualToString:@"sessions"] ||
           [about isEqualToString:@"updates"] ||
           [about isEqualToString:@"welcome"]
           ) {
            //NSDictionary* bundle = [[NSBundle mainBundle] infoDictionary];
            //urlString = [NSString stringWithFormat:@"http://www.exhume.us/doc/about_%@.php?v=%@", about, [bundle objectForKey:@"CFBundleVersion"]];
            //FIXME
            NSURL *url = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"doc/about_%@",about] withExtension:@"html"];
            urlString = [NSString stringWithFormat:@"%@",url];
        }
        else if([about isEqualToString:@"blank"])
            urlString = @"";
        else
            return nil;
    }
    
    if(urlString == nil) {
        if([requestString hasPrefix:@"http://"] || [requestString hasPrefix:@"https://"] || [requestString hasPrefix:@"file://"] || [requestString hasPrefix:@"feed://"] || [requestString hasPrefix:@"javascript:"]) {
            NSArray* cleanArray = [requestString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            urlString = [cleanArray componentsJoinedByString:@""];
        }
    }
    
    BOOL forceURL = NO;
    if([requestString hasPrefix:@"!:"]) {
        requestString = [requestString substringFromIndex:2];
        forceURL = YES;
    }
    else {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary* stainlessDefaults = [defaults persistentDomainForName:@"us.exhume.Vanadium"];
        
        NSNumber* searchValue = [stainlessDefaults objectForKey:@"DisableSearching"];
        
        if(searchValue && [searchValue boolValue])
            forceURL = YES;
    }
    
    BOOL forceSearch = NO;
    if([requestString hasPrefix:@"?:"]) {
        requestString = [requestString substringFromIndex:2];
        forceSearch = YES;
        forceURL = NO;
    }
    
    if(urlString == nil) {
        NSRange colonRange = [requestString rangeOfString:@":"];
        NSRange slashRange = [requestString rangeOfString:@"/"];
        NSRange spaceRange = [requestString rangeOfString:@" "];
        NSRange periodRange = [requestString rangeOfString:@"."];
        
        if(!forceURL && (
                         forceSearch ||
                         spaceRange.location != NSNotFound ||
                         (periodRange.location == NSNotFound && colonRange.location == NSNotFound && slashRange.location == NSNotFound) ||
                         [requestString hasPrefix:@"\""])
           ) {
            NSString* query = requestString;
            
            {
                NSMutableString* mutableQuery = [query mutableCopy];
                //[mutableQuery replaceOccurrencesOfString:@"(" withString:@"%28" options:0 range:NSMakeRange(0, [mutableQuery length])];
                //[mutableQuery replaceOccurrencesOfString:@")" withString:@"%29" options:0 range:NSMakeRange(0, [mutableQuery length])];
                //[mutableQuery replaceOccurrencesOfString:@"!" withString:@"%21" options:0 range:NSMakeRange(0, [mutableQuery length])];
                //[mutableQuery replaceOccurrencesOfString:@"%" withString:@"%25" options:0 range:NSMakeRange(0, [mutableQuery length])];
                //[mutableQuery replaceOccurrencesOfString:@"&" withString:@"%26" options:0 range:NSMakeRange(0, [mutableQuery length])];
                //[mutableQuery replaceOccurrencesOfString:@"+" withString:@"%2B" options:0 range:NSMakeRange(0, [mutableQuery length])];
                //[mutableQuery replaceOccurrencesOfString:@"," withString:@"%2C" options:0 range:NSMakeRange(0, [mutableQuery length])];
                //[mutableQuery replaceOccurrencesOfString:@"/" withString:@"%2F" options:0 range:NSMakeRange(0, [mutableQuery length])];
                //[mutableQuery replaceOccurrencesOfString:@"=" withString:@"%3D" options:0 range:NSMakeRange(0, [mutableQuery length])];
                //[mutableQuery replaceOccurrencesOfString:@"?" withString:@"%3F" options:0 range:NSMakeRange(0, [mutableQuery length])];
                //[mutableQuery replaceOccurrencesOfString:@" " withString:@"+" options:0 range:NSMakeRange(0, [mutableQuery length])];
                query = mutableQuery;
            }
            
            NSArray* local = [[NSUserDefaults standardUserDefaults] objectForKey: @"AppleLanguages"];
            NSString* language = @"en-US";
            NSString* preferredLanguage = [local objectAtIndex:0];
            if(preferredLanguage)
                language = preferredLanguage;
            
            if([language isEqualToString:@"en"])
                language = @"en-US";
            
            CFStringRef escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)query, CFSTR("%+"), NULL, kCFStringEncodingUTF8);
            NSString* escapedQuery = [NSString stringWithString:(__bridge NSString*)escaped];
            CFRelease(escaped);
            
            NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
            NSDictionary* stainlessDefaults = [defaults persistentDomainForName:@"us.exhume.Vanadium"];
            
            NSString* engine = [stainlessDefaults objectForKey:@"DefaultSearch"];
            if(engine) {
                NSString* search = [NSString stringWithString:engine];
                if([search isEqualToString:@"Google"])
                    urlString = [NSString stringWithFormat:@"https://encrypted.google.com/search?hl=en&q=%@", escapedQuery];
                else if([search isEqualToString:@"Yahoo!"])
                    urlString = [NSString stringWithFormat:@"http://search.yahoo.com/search?ei=UTF-8&p=%@", escapedQuery];
                else if([search isEqualToString:@"Live Search"] || [search isEqualToString:@"Bing"])
                    urlString = [NSString stringWithFormat:@"http://www.bing.com/search?setlang=%@&mkt=%@&q=%@", language, language, escapedQuery];
                else if([search isEqualToString:@"AOL"])
                    urlString = [NSString stringWithFormat:@"http://search.aol.com/aol/search?query=%@", escapedQuery];
                else if([search isEqualToString:@"Ask"])
                    urlString = [NSString stringWithFormat:@"http://www.ask.com/web?q=%@", escapedQuery];
            }
            
            if(urlString == nil)
                //urlString = [NSString stringWithFormat:@"http://www.google.com/search?hl=%@&q=%@&rls=%@&client=stainless&ie=UTF-8", language, escapedQuery, version];
                
                urlString = [NSString stringWithFormat:@"https://duckduckgo.com/?q=%@&kl=us-EN", escapedQuery];
        }
        else {
            if([requestString hasPrefix:@"http://"] == NO && [requestString hasPrefix:@"https://"] == NO && [requestString hasPrefix:@"file://"] == NO && [requestString hasPrefix:@"feed://"] == NO && [requestString hasPrefix:@"javascript:"] == NO)
                urlString = [NSString stringWithFormat:@"http://%@", requestString];
            else
                urlString = [NSString stringWithString:requestString];
            
            //if(periodRange.location == NSNotFound)
            //	urlString = [NSString stringWithFormat:@"%@.com", urlString];
            
            if(sender)
                [sender setStringValue:urlString];
        }
    }
    
    return urlString;
}
- (void)setupPreferences:(BOOL)privateMode
{
    if(privateMode)
        [self setPreferencesIdentifier:@"us.exhume.Vanadium.private."];
    else {
        WebHistory* clientHistory = [[WebHistory alloc] init];
        [WebHistory setOptionalSharedHistory:clientHistory];
        //[clientHistory release];
        
        [self setPreferencesIdentifier:@"us.exhume.Vanadium."];
    }
    
    WebPreferences* preferences = [self preferences];
    
    if(privateMode)
        [preferences setPrivateBrowsingEnabled:YES];
    
    [preferences setAutosaves:NO];
    
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* libraryPath = [NSString stringWithFormat:@"%@/Library/Caches/Vanadium", NSHomeDirectory()];
    if([fm fileExistsAtPath:libraryPath] == NO)
        //deprecation fix
        //[fm createDirectoryAtPath:libraryPath attributes:nil];
        [fm createDirectoryAtPath:libraryPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    if([fm fileExistsAtPath:libraryPath]) {
        NSString* cachePath = [NSString stringWithFormat:@"%@/%d", libraryPath, [[NSProcessInfo processInfo] processIdentifier]];
        if([fm fileExistsAtPath:cachePath])
            [fm removeItemAtPath:cachePath error:nil];
        
        NSURLCache* cache = [[NSURLCache alloc] initWithMemoryCapacity:(1*1024*1024) diskCapacity:(5*1024*1024) diskPath:cachePath];
        [NSURLCache setSharedURLCache:cache];
    }
    
    [preferences setUsesPageCache:NO];
    
    if(privateMode) {
        [[NSURLCache sharedURLCache] setMemoryCapacity:0];
        [[NSURLCache sharedURLCache] setDiskCapacity:0];
        
        [preferences setCacheModel:WebCacheModelDocumentViewer];
    }
    else {
        [preferences setCacheModel:WebCacheModelPrimaryWebBrowser];
    }
    
    [preferences setShouldPrintBackgrounds:YES];
    
    if([preferences respondsToSelector:@selector(setTextAreasAreResizable:)])
        [preferences setTextAreasAreResizable:YES];
    
    if([preferences respondsToSelector:@selector(setZoomsTextOnly:)])
        [preferences setZoomsTextOnly:NO];
    
    if([preferences respondsToSelector:@selector(setWebSecurityEnabled:)])
        [preferences setWebSecurityEnabled:YES];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary* stainlessDefaults = [defaults persistentDomainForName:@"us.exhume.Vanadium"];
    
    NSNumber* extras = [stainlessDefaults objectForKey:@"EnableDeveloperExtras"];
    if(extras && [extras boolValue] && [preferences respondsToSelector:@selector(setDeveloperExtrasEnabled:)])
        [preferences setDeveloperExtrasEnabled:YES];
    else
        [preferences setDeveloperExtrasEnabled:NO];
    
    NSNumber* plugins = [stainlessDefaults objectForKey:@"DisablePlugins"];
    if(plugins && [plugins boolValue])
        [preferences setPlugInsEnabled:NO];
    else
        [preferences setPlugInsEnabled:YES];
    
    NSNumber* java = [stainlessDefaults objectForKey:@"DisableJava"];
    if(java && [java boolValue])
        [preferences setJavaEnabled:NO];
    else
        [preferences setJavaEnabled:YES];
    
    NSNumber* javaScript = [stainlessDefaults objectForKey:@"DisableJavaScript"];
    if(javaScript && [javaScript boolValue])
        [preferences setJavaScriptEnabled:NO];
    else
        [preferences setJavaScriptEnabled:YES];
    
    NSNumber* popupBlock = [stainlessDefaults objectForKey:@"DisablePopupBlock"];
    if(popupBlock && [popupBlock boolValue]) {
        [preferences setJavaScriptCanOpenWindowsAutomatically:YES];
    }
    else
        [preferences setJavaScriptCanOpenWindowsAutomatically:NO];
}

- (NSRect)clippedDocumentFrame
{
    WebFrame* mainFrame = [self mainFrame];
    WebFrameView* mainFrameView = [mainFrame frameView];
    NSView* documentView = [mainFrameView documentView];
    NSClipView* clipView = (NSClipView *)[documentView superview];
    
    NSRect windowFrame = [[self window] frame];
    NSRect webFrame = [self frame];
    NSRect frame = NSOffsetRect([clipView frame], windowFrame.origin.x, windowFrame.origin.y);
    frame.origin.x += webFrame.origin.x;
    frame.origin.y += webFrame.size.height + webFrame.origin.y;
    frame.origin.y -= frame.size.height;
    
    return frame;
}
- (BOOL)maintainsInactiveSelection
{
    return isSearching;
}

- (IBAction)reload:(id)sender
{
    // note: we do this to mimic Safari
    //this was legacy (carbon) code, but we seemed to have fixed it.
    //extern UInt32 GetCurrentKeyModifiers();
    
    NSUInteger flags = [[NSApp currentEvent] modifierFlags];
    
    if((flags & NSShiftKeyMask))
        [[self mainFrame] reloadFromOrigin];
    else
        [[self mainFrame] reload];
}

- (IBAction)zoomOut:(id)sender
{
    if([self respondsToSelector:@selector(_zoomOut:isTextOnly:)])
        [self _zoomOut:sender isTextOnly:NO];
    else
        [self makeTextSmaller:sender];
}

- (IBAction)zoomIn:(id)sender
{
    if([self respondsToSelector:@selector(_zoomIn:isTextOnly:)])
        [self _zoomIn:sender isTextOnly:NO];
    else
        [self makeTextLarger:sender];
}

- (IBAction)resetZoom:(id)sender
{
    if([self respondsToSelector:@selector(_resetZoom:isTextOnly:)])
        [self _resetZoom:sender isTextOnly:NO];
    else
        [self makeTextStandardSize:sender];
}
- (void)readSafariBookmarksFromPath:(NSString*)path filter:(NSString*)filter
{
    if(filter && [filter length] == 0)
        filter = nil;
    
    if(filter) {
        NSMutableString* mutableFilter = [filter mutableCopy];
        [mutableFilter replaceOccurrencesOfString:@"+" withString:@" " options:0 range:NSMakeRange(0, [mutableFilter length])];
        filter = [mutableFilter stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    
    @try {
        id plist = nil;
        
        if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSString* error = nil;
            NSData* data = [NSData dataWithContentsOfFile:path];
            plist = [NSPropertyListSerialization propertyListFromData:data
                                                     mutabilityOption:NSPropertyListImmutable
                                                               format:nil
                                                     errorDescription:&error];
            
            if(error) {
                NSLog(@"Error deserializing %@: %@", path, error);
                plist = nil;
            }
        }
        
        NSMutableString* html = [NSMutableString stringWithCapacity:1024];
        if(filter)
            [html appendString:[NSString stringWithFormat:@"<html><head><title>Safari Bookmarks matching \"%@\"</title>", [filter lowercaseString]]];
        else
            [html appendString:@"<html><head><title>Safari Bookmarks</title>"];
        [html appendString:@"<meta http-equiv=\"content-type\" content=\"text/html;charset=iso-8859-1\">"];
        [html appendString:@"</head><body><span style=\" font-family: 'LucidaGrande', 'Lucida Grande', 'Lucida Sans Unicode', sans-serif; font-size: 12px;\">"];
        
        [html appendString:@"<form action=\"safari_StainlessImport.php\" method=\"get\">"];
        if(filter)
            [html appendString:[NSString stringWithFormat:@"<input type=\"search\" name=\"search\" value=\"%@\" ", filter]];
        else
            [html appendString:@"<input type=\"search\" name=\"search\" "];
        [html appendString:@"autosave=\"safari_bookmarks\" results=\"10\" /> "];
        [html appendString:@"<input type=\"submit\" value=\"Search\" />"];
        [html appendString:@"</form>"];
        
        [self parseSafariList:plist toHTML:html filter:filter];
        [html appendString:@"</span></body></html>"];
        
        NSString* newPath = [NSString stringWithFormat:@"%@/safari_StainlessImport.html", NSTemporaryDirectory()];
        if([[NSFileManager defaultManager] createFileAtPath:newPath contents:[html dataUsingEncoding:NSUTF8StringEncoding] attributes:nil]) {
            NSURL* url = [NSURL fileURLWithPath:newPath];
            
            NSURLRequest* request = [NSURLRequest
                                     requestWithURL:url
                                     cachePolicy:NSURLRequestReloadIgnoringCacheData
                                     timeoutInterval:10.0];
            
            [[self window] makeFirstResponder:self];
            
            [[self mainFrame] loadRequest:request];
        }
    }
    
    @catch (NSException* anException) {
        NSLog(@"%@ exception reading %@: %@", [anException name], path, [anException reason]);
    }
}

- (void)parseSafariList:(NSDictionary*)plist toHTML:(NSMutableString*)html filter:(NSString*)filter
{
    if(plist == nil)
        return;
    
    NSString* leafID = [plist objectForKey:@"WebBookmarkUUID"];
    NSString* leafType = [plist objectForKey:@"WebBookmarkType"];
    
    BOOL closeList = NO;
    
    if([leafID isEqualToString:@"Root"] == NO) {
        if([leafType isEqualToString:@"WebBookmarkTypeLeaf"]) {
            NSString* urlString = [plist objectForKey:@"URLString"];
            NSDictionary* uriDictionary = [plist objectForKey:@"URIDictionary"];
            NSString* urlTitle = [uriDictionary objectForKey:@"title"];
            if(urlTitle == nil)
                urlTitle = urlString;
            
            NSRange r1;
            if(filter)
                r1 = [urlTitle rangeOfString:filter options:NSCaseInsensitiveSearch];
            NSRange r2;
            if(filter)
                r2 = [urlString rangeOfString:filter options:NSCaseInsensitiveSearch];
            
            if(filter == nil || r1.location != NSNotFound || r2.location != NSNotFound)
                [html appendString:[NSString stringWithFormat:@"<li><a href=\"%@\">%@</a></li>\r", urlString, urlTitle]];
        }
        else if([leafType isEqualToString:@"WebBookmarkTypeList"]) {
            NSString* leafTitle = [plist objectForKey:@"Title"];
            if(leafTitle == nil)
                leafTitle = @"Untitled";
            
            [html appendString:[NSString stringWithFormat:@"<li>%@\r", leafTitle]];
            closeList = YES;
        }
    }
    
    NSMutableArray* children = [plist objectForKey:@"Children"];
    if(children) {
        if([leafID isEqualToString:@"Root"])
            [html appendString:@"<ul class=\"outline\">\r"];
        else
            [html appendString:@"<ul>\r"];
        
        for(NSDictionary* leaf in children) {
            [self parseSafariList:leaf toHTML:html filter:filter];
        }
        
        [html appendString:@"</ul>\r"];
    }
    
    if(closeList)
        [html appendString:@"</li>\r"];
}

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
    // Only report feedback for the main frame.
    if (frame == [sender mainFrame]){
        NSString *url = [[[[frame provisionalDataSource] request] URL] absoluteString];
        //[textField setStringValue:url];
    }
}

@end
