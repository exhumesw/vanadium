//
//  Document.m
/*
 Document.m
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

#import "Document.h"

@interface Document ()

@end

@implementation Document

- (instancetype)init {
    self = [super init];
    //if a new window is spawned...
    if (self) {
        // do something
    }
    return self;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    [webView setUIDelegate:self];
}

- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Document";
}


- (IBAction)clickToggle:(id)sender
{
    int clickedSegment = (int)[sender selectedSegment];
    int clickedSegmentTag = (int)[[sender cell] tagForSegment:clickedSegment];
    
    if(clickedSegmentTag == 0)
        [webView goBack:self];
    else
        [webView goForward:self];
}

@end
