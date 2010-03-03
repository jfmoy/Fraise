/*
Smultron version 3.6b1, 2009-09-12
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://smultron.sourceforge.net

Copyright 2004-2009 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import <Cocoa/Cocoa.h>

@interface SMLPreferencesController : NSObject <NSToolbarDelegate, NSWindowDelegate>
{
	NSToolbar *preferencesToolbar;
	
	IBOutlet NSWindow *preferencesWindow;
	IBOutlet NSView *generalView;
	IBOutlet NSView *appearanceView;
	IBOutlet NSView *openSaveView;
	IBOutlet NSView *advancedView;
	IBOutlet NSArrayController *syntaxDefinitionsArrayController;
	
	IBOutlet NSTextField *noUpdateAvailableTextField;
	IBOutlet NSPopUpButton *encodingsPopUp;
	IBOutlet NSPopUpButton *syntaxColouringPopUp;
	IBOutlet NSPopUpButton *lastSavedFormatPopUp;
	
	IBOutlet NSArrayController *encodingsArrayController;
	
	IBOutlet NSTableView *syntaxDefinitionsTableView; 
	IBOutlet NSTableView *encodingsTableView;
	
	BOOL hasPreparedAdvancedInterface;
	
	NSView *currentView;
}

@property (readonly) IBOutlet NSArrayController *encodingsArrayController;
@property (readonly) IBOutlet NSArrayController *syntaxDefinitionsArrayController;
@property (readonly) IBOutlet NSPopUpButton *encodingsPopUp;
@property (readonly) IBOutlet NSWindow *preferencesWindow;


+ (SMLPreferencesController *)sharedInstance;

- (void)setDefaults;

- (void)showPreferencesWindow;

- (NSRect)getRectForView:(NSView *)view;
- (CGFloat)toolbarHeight;

- (IBAction)setFontAction:(id)sender;
- (IBAction)checkNowAction:(id)sender;

- (NSTextField *)noUpdateAvailableTextField;

- (IBAction)revertToStandardSettingsAction:(id)sender;
- (void)buildEncodingsMenu;

- (IBAction)openSetFolderAction:(id)sender;
- (IBAction)saveAsSetFolderAction:(id)sender;



- (NSManagedObjectContext *)managedObjectContext;

@end
