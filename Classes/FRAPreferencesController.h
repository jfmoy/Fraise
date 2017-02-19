/*
 Fraise version 3.7 - Based on Smultron by Peter Borg
 
 Current Maintainer (since 2016): 
 Andreas Bentele: abentele.github@icloud.com (https://github.com/abentele/Fraise)
 
 Maintainer before macOS Sierra (2010-2016): 
 Jean-François Moy: jeanfrancois.moy@gmail.com (http://github.com/jfmoy/Fraise)

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

#import <Cocoa/Cocoa.h>

@interface FRAPreferencesController : NSObject <NSToolbarDelegate, NSWindowDelegate>
{
	NSToolbar *preferencesToolbar;
	
	IBOutlet NSWindow * preferencesWindow;
	IBOutlet NSView *generalView;
	IBOutlet NSView *appearanceView;
	IBOutlet NSView *openSaveView;
	IBOutlet NSView *advancedView;
	IBOutlet NSArrayController* syntaxDefinitionsArrayController;
	
	IBOutlet NSPopUpButton* encodingsPopUp;
	IBOutlet NSPopUpButton* syntaxColouringPopUp;
	IBOutlet NSPopUpButton* lastSavedFormatPopUp;
	
	IBOutlet NSArrayController* encodingsArrayController;
	
	IBOutlet NSTableView *syntaxDefinitionsTableView; 
	IBOutlet NSTableView *encodingsTableView;
	
	BOOL hasPreparedAdvancedInterface;
	
	NSView *currentView;
}

@property (strong, readonly) IBOutlet NSArrayController *encodingsArrayController;
@property (strong, readonly) IBOutlet NSArrayController *syntaxDefinitionsArrayController;
@property (strong, readonly) IBOutlet NSPopUpButton *encodingsPopUp;
@property (strong, readonly) IBOutlet NSWindow *preferencesWindow;


+ (FRAPreferencesController *)sharedInstance;

- (void)setDefaults;

- (void)showPreferencesWindow;

- (NSRect)getRectForView:(NSView *)view;
- (CGFloat)toolbarHeight;

- (IBAction)setFontAction:(id)sender;

- (IBAction)revertToStandardSettingsAction:(id)sender;
- (void)buildEncodingsMenu;

- (IBAction)openSetFolderAction:(id)sender;
- (IBAction)saveAsSetFolderAction:(id)sender;

- (IBAction)changeGutterWidth:(id)sender;

- (NSManagedObjectContext *)managedObjectContext;

@end
