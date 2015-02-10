/*
 AppDelegate.m
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

#import "AppDelegate.h"
#import "WAYTheDarkSide.h"
@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSVisualEffectView *contentView;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (void) awakeFromNib {
    [self.window setMovableByWindowBackground:YES];
    [self.contentView setState:NSVisualEffectStateActive];
    //self.window.styleMask = self.window.styleMask | NSFullSizeContentViewWindowMask;
    
    __weak typeof(self)weakSelf = self;
    
    // Let's define two handlers, which switch between the Vibrant Dark and the Vibrant Light appearance
    [WAYTheDarkSide welcomeApplicationWithBlock:^{
        [weakSelf.window setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
        [weakSelf.contentView setMaterial:NSVisualEffectMaterialDark];
    } immediately:YES];
    
    [WAYTheDarkSide outcastApplicationWithBlock:^{
        [weakSelf.window setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantLight]];
        [weakSelf.contentView setMaterial:NSVisualEffectMaterialLight];
    } immediately:YES];
    
    [self.window makeKeyAndOrderFront:self];
}

- (NSApplicationPresentationOptions)window:(NSWindow *)window willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)proposedOptions
{
    return (NSApplicationPresentationFullScreen|NSApplicationPresentationHideDock|NSApplicationPresentationAutoHideToolbar);
}
@end
