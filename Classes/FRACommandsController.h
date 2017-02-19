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

@class FRATableView;

@interface FRACommandsController : NSObject <NSToolbarDelegate> {

	IBOutlet NSArrayController * commandCollectionsArrayController;
	IBOutlet NSTableView * commandCollectionsTableView;
	IBOutlet NSArrayController * commandsArrayController;
	IBOutlet NSTableView * commandsTableView;
	IBOutlet NSWindow * commandsWindow;
	IBOutlet NSTextView * commandsTextView;
	IBOutlet NSView *commandsFilterView;
	
	BOOL currentCommandShouldBeInsertedInline;
	BOOL isCommandRunning;
	NSTimer *checkIfTemporaryFilesCanBeDeletedTimer;
	NSMutableArray *temporaryFilesArray;

}

@property (strong, readonly) IBOutlet NSTextView *commandsTextView;
@property (strong, readonly) IBOutlet NSWindow *commandsWindow;
@property (strong, readonly) IBOutlet NSArrayController *commandCollectionsArrayController;
@property (strong, readonly) IBOutlet NSTableView *commandCollectionsTableView;
@property (strong, readonly) IBOutlet NSArrayController *commandsArrayController;
@property (strong, readonly) IBOutlet NSTableView *commandsTableView;

+ (FRACommandsController *)sharedInstance;

- (void)openCommandsWindow;

- (IBAction)newCollectionAction:(id)sender;
- (IBAction)newCommandAction:(id)sender;

- (id)performInsertNewCommand;

- (void)performDeleteCollection;

- (void)importCommands;
- (void)performCommandsImportWithPath:(NSString *)path;
- (void)exportCommands;

- (NSManagedObjectContext *)managedObjectContext;


- (IBAction)runAction:(id)sender;

- (IBAction)insertPathAction:(id)sender;
- (IBAction)insertDirectoryAction:(id)sender;

- (NSString *)commandToRunFromString:(NSString *)string;

- (void)runCommand:(id)command;

- (BOOL)currentCommandShouldBeInsertedInline;

- (void)setCommandRunning:(BOOL)flag;

- (void)clearAnyTemporaryFiles;




@end
