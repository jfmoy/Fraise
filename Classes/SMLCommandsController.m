/*
Smultron version 3.7a1, 2009-09-12
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Smultron

Copyright 2004-2009 Peter Borg - 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "SMLStandardHeader.h"

#import "NSToolbarItem+Smultron.h"
#import "SMLCommandsController.h"
#import "SMLDocumentsListCell.h"
#import "SMLApplicationDelegate.h"
#import "SMLBasicPerformer.h"
#import "SMLDragAndDropController.h"
#import "SMLToolsMenuController.h"
#import "SMLInterfacePerformer.h"
#import "SMLProjectsController.h"
#import "SMLVariousPerformer.h"
#import "SMLOpenSavePerformer.h"

@implementation SMLCommandsController

static id sharedInstance = nil;

@synthesize commandsTextView, commandsWindow, commandCollectionsArrayController, commandCollectionsTableView, commandsTableView, commandsArrayController;


+ (SMLCommandsController *)sharedInstance
{ 
	if (sharedInstance == nil) { 
		sharedInstance = [[self alloc] init];
	}
	
	return sharedInstance;
} 


- (id)init 
{
    if (sharedInstance == nil) {
        sharedInstance = [super init];
		
		temporaryFilesArray = [[NSMutableArray alloc] init];
    }
    return sharedInstance;
}


- (void)openCommandsWindow
{
	if (commandsWindow == nil) {
		[NSBundle loadNibNamed:@"SMLCommands.nib" owner:self];
		
		[commandCollectionsTableView setDataSource:[SMLDragAndDropController sharedInstance]];
		[commandsTableView setDataSource:[SMLDragAndDropController sharedInstance]];
		
		[commandCollectionsTableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, @"SMLMovedCommandType", nil]];
		[commandCollectionsTableView setDraggingSourceOperationMask:(NSDragOperationCopy) forLocal:NO];
		
		[commandsTableView registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, nil]];
		[commandsTableView setDraggingSourceOperationMask:(NSDragOperationCopy) forLocal:NO];
		
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
		[commandCollectionsArrayController setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		[commandsArrayController setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		
		SMLDocumentsListCell *cell = [[SMLDocumentsListCell alloc] init];
		[cell setWraps:NO];
		[cell setLineBreakMode:NSLineBreakByTruncatingMiddle];
		[[commandCollectionsTableView tableColumnWithIdentifier:@"collection"] setDataCell:cell];
		
		
		NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"CommandsToolbarIdentifier"];
		[toolbar setShowsBaselineSeparator:YES];
		[toolbar setAllowsUserCustomization:YES];
		[toolbar setAutosavesConfiguration:YES];
		[toolbar setDisplayMode:NSToolbarDisplayModeDefault];
		[toolbar setSizeMode:NSToolbarSizeModeSmall];
		[toolbar setDelegate:self];
		[commandsWindow setToolbar:toolbar];
		
		//[commandCollectionsTableView setBackgroundColor:[[NSColor controlAlternatingRowBackgroundColors] objectAtIndex:1]];
	
	}
	
	[commandsWindow makeKeyAndOrderFront:self];
	[[SMLToolsMenuController sharedInstance] buildRunCommandMenu];
}


- (IBAction)newCollectionAction:(id)sender
{
	[commandCollectionsArrayController commitEditing];
	[commandsArrayController commitEditing];
	id collection = [SMLBasic createNewObjectForEntity:@"CommandCollection"];
	
	[SMLManagedObjectContext processPendingChanges];
	[commandCollectionsArrayController setSelectedObjects:[NSArray arrayWithObject:collection]];
	
	[commandsWindow makeFirstResponder:commandCollectionsTableView];
	[commandCollectionsTableView editColumn:0 row:[commandCollectionsTableView selectedRow] withEvent:nil select:NO];
}


- (IBAction)newCommandAction:(id)sender
{
	id collection;
	NSArray *commandCollections = [SMLBasic fetchAll:@"CommandCollectionSortKeyName"];
	if ([commandCollections count] == 0) {
		collection = [SMLBasic createNewObjectForEntity:@"CommandCollection"];
		[collection setValue:COLLECTION_STRING forKey:@"name"];
	}
	[commandsArrayController commitEditing];
	[commandCollectionsArrayController commitEditing];
	[self performInsertNewCommand];
	
	[commandsWindow makeFirstResponder:commandsTableView];
	[commandsTableView editColumn:0 row:[commandsTableView selectedRow] withEvent:nil select:NO];
}


- (id)performInsertNewCommand
{
	id collection;
	NSArray *commandCollections = [SMLBasic fetchAll:@"CommandCollectionSortKeyName"];
	if ([commandCollections count] == 0) {
		collection = [SMLBasic createNewObjectForEntity:@"CommandCollection"];
		[collection setValue:COLLECTION_STRING forKey:@"name"];
	} else {
		if (commandsWindow != nil && [[commandCollectionsArrayController selectedObjects] count] != 0) {
			collection = [[commandCollectionsArrayController selectedObjects] objectAtIndex:0];
		} else { // If no collection is selected choose the last one in the array
			collection = [commandCollections lastObject];
		}
	}	 
	
	id item = [SMLBasic createNewObjectForEntity:@"Command"];
	[[collection mutableSetValueForKey:@"commands"] addObject:item];
	[SMLManagedObjectContext processPendingChanges];
	[commandsArrayController setSelectedObjects:[NSArray arrayWithObject:item]];
	
	return item;
}


- (void)performDeleteCollection
{
	id collection = [[commandCollectionsArrayController selectedObjects] objectAtIndex:0];
	
	[SMLManagedObjectContext deleteObject:collection];
	
	[[SMLToolsMenuController sharedInstance] buildRunCommandMenu];
}


- (void)importCommands
{
	[self openCommandsWindow];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setResolvesAliases:YES];		
	[openPanel beginSheetForDirectory:[SMLInterface whichDirectoryForOpen] 
							file:nil 
						   types:[NSArray arrayWithObject:@"smultronCommands"] 
				  modalForWindow:commandsWindow
				   modalDelegate:self
				  didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
					 contextInfo:nil];
}


- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(NSInteger)returnCode  contextInfo:(void  *)contextInfo
{
	if (returnCode == NSOKButton) {
		[self performCommandsImportWithPath:[panel filename]];
	}
	[commandsWindow makeKeyAndOrderFront:nil];
}


- (void)performCommandsImportWithPath:(NSString *)path
{
	NSData *data = [NSData dataWithContentsOfFile:path];
	NSArray *commands = (NSArray *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	if ([commands count] == 0) {
		return;
	}
	
	id collection = [SMLBasic createNewObjectForEntity:@"CommandCollection"];
	[collection setValue:[[commands objectAtIndex:0] valueForKey:@"collectionName"] forKey:@"name"];
	
	id item;
	for (item in commands) {
		id command = [SMLBasic createNewObjectForEntity:@"Command"];
		[command setValue:[item valueForKey:@"name"] forKey:@"name"];
		[command setValue:[item valueForKey:@"text"] forKey:@"text"];			
		[command setValue:[item valueForKey:@"collectionName"] forKey:@"collectionName"];
		[command setValue:[item valueForKey:@"shortcutDisplayString"] forKey:@"shortcutDisplayString"];
		[command setValue:[item valueForKey:@"shortcutMenuItemKeyString"] forKey:@"shortcutMenuItemKeyString"];
		[command setValue:[item valueForKey:@"shortcutModifier"] forKey:@"shortcutModifier"];
		[command setValue:[item valueForKey:@"sortOrder"] forKey:@"sortOrder"];
		if ([item valueForKey:@"inline"] != nil) {
			[command setValue:[item valueForKey:@"inline"] forKey:@"inline"];
		}
		if ([item valueForKey:@"interpreter"] != nil) {
			[command setValue:[item valueForKey:@"interpreter"] forKey:@"interpreter"];
		}
		[[collection mutableSetValueForKey:@"commands"] addObject:command];
	}
	
	[SMLManagedObjectContext processPendingChanges];
	
	[commandCollectionsArrayController setSelectedObjects:[NSArray arrayWithObject:collection]];
}


- (void)exportCommands
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setRequiredFileType:@"smultronCommands"];
	[savePanel beginSheetForDirectory:[SMLInterface whichDirectoryForSave]				
								 file:[[[commandCollectionsArrayController selectedObjects] objectAtIndex:0] valueForKey:@"name"]
					   modalForWindow:commandsWindow
						modalDelegate:self
					   didEndSelector:@selector(exportCommandsPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
	
}


- (void)exportCommandsPanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)context
{
	if (returnCode == NSOKButton) {
		id collection = [[commandCollectionsArrayController selectedObjects] objectAtIndex:0];
		
		NSMutableArray *exportArray = [NSMutableArray array];
		NSEnumerator *enumerator = [[collection mutableSetValueForKey:@"commands"] objectEnumerator];
		for (id item in enumerator) {
			NSMutableDictionary *command = [[NSMutableDictionary alloc] init];
			[command setValue:[item valueForKey:@"name"] forKey:@"name"];
			[command setValue:[item valueForKey:@"text"] forKey:@"text"];
			[command setValue:[collection valueForKey:@"name"] forKey:@"collectionName"];
			[command setValue:[item valueForKey:@"shortcutDisplayString"] forKey:@"shortcutDisplayString"];
			[command setValue:[item valueForKey:@"shortcutMenuItemKeyString"] forKey:@"shortcutMenuItemKeyString"];
			[command setValue:[item valueForKey:@"shortcutModifier"] forKey:@"shortcutModifier"];
			[command setValue:[item valueForKey:@"sortOrder"] forKey:@"sortOrder"];
			[command setValue:[NSNumber numberWithInteger:3] forKey:@"version"];
			[command setValue:[item valueForKey:@"inline"] forKey:@"inline"];
			[command setValue:[item valueForKey:@"interpreter"] forKey:@"interpreter"];
			[exportArray addObject:command];
		}
		
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:exportArray];
		[SMLOpenSave performDataSaveWith:data path:[sheet filename]];
	}
	
	[commandsWindow makeKeyAndOrderFront:nil];
}


- (void)windowWillClose:(NSNotification *)aNotification
{
	[commandCollectionsArrayController commitEditing];
	[commandsArrayController commitEditing];
}


- (NSManagedObjectContext *)managedObjectContext
{
	return SMLManagedObjectContext;
}


- (IBAction)runAction:(id)sender
{
	[self runCommand:[[commandsArrayController selectedObjects] objectAtIndex:0]];
}


- (IBAction)insertPathAction:(id)sender
{
	id document = SMLCurrentDocument;
	if (document == nil || [document valueForKey:@"path"] == nil) {
		NSBeep();
		return;
	}
	
	[commandsTextView insertText:[document valueForKey:@"path"]];
}


- (IBAction)insertDirectoryAction:(id)sender
{
	id document = SMLCurrentDocument;
	if (document == nil || [document valueForKey:@"path"] == nil) {
		NSBeep();
		return;
	}
	
	[commandsTextView insertText:[[document valueForKey:@"path"] stringByDeletingLastPathComponent]];
}


- (NSString *)commandToRunFromString:(NSString *)string
{
	NSMutableString *returnString = [NSMutableString stringWithString:string];
	id document = SMLCurrentDocument;
	if (document == nil || [[document valueForKey:@"isNewDocument"] boolValue] == YES || [document valueForKey:@"path"] == nil) {
		[returnString replaceOccurrencesOfString:@"%%p" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
		[returnString replaceOccurrencesOfString:@"%%d" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
	} else {
		NSString *path = [NSString stringWithFormat:@"\"%@\"", [document valueForKey:@"path"]]; // If there's a space in the path
		NSString *directory;
		if ([[SMLDefaults valueForKey:@"PutQuotesAroundDirectory"] boolValue] == YES) { 
			directory = [NSString stringWithFormat:@"\"%@\"", [[document valueForKey:@"path"] stringByDeletingLastPathComponent]];
		} else {
			directory = [NSString stringWithFormat:@"%@", [[document valueForKey:@"path"] stringByDeletingLastPathComponent]];
		}
		[returnString replaceOccurrencesOfString:@"%%p" withString:path options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
		[returnString replaceOccurrencesOfString:@"%%d" withString:directory options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
	}
	
	if ([SMLCurrentTextView selectedRange].length > 0) {
		[returnString replaceOccurrencesOfString:@"%%s" withString:[SMLCurrentText substringWithRange:[SMLCurrentTextView selectedRange]] options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
	}	
	
	[returnString replaceOccurrencesOfString:@" ~" withString:[NSString stringWithFormat:@" %@", NSHomeDirectory()] options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];

	return returnString;
}


- (void)runCommand:(id)command
{
	[commandCollectionsArrayController commitEditing];
	[commandsArrayController commitEditing];
	
	isCommandRunning = YES;
	
	if ([command valueForKey:@"inline"] != nil && [[command valueForKey:@"inline"] boolValue] == YES) {
		currentCommandShouldBeInsertedInline = YES;
	} else {
		currentCommandShouldBeInsertedInline = NO;
	}
	
	NSString *commandString = [command valueForKey:@"text"];
	if (commandString == nil || [commandString length] < 1) {
		NSBeep();
		return;
	}
	
	if ([commandString length] > 2 && [commandString rangeOfString:@"#!" options:NSLiteralSearch range:NSMakeRange(0, 2)].location != NSNotFound) { // The command starts with a shebang so run it specially
		NSString *selectionStringPath;
		NSMutableString *commandToWrite = [NSMutableString stringWithString:commandString];
		
		if ([SMLCurrentTextView selectedRange].length > 0 && [commandString rangeOfString:@"%%s"].location != NSNotFound) {
			selectionStringPath = [SMLBasic genererateTemporaryPath];
			NSString *selectionString = [SMLCurrentText substringWithRange:[SMLCurrentTextView selectedRange]];
			[selectionString writeToFile:selectionStringPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
			[temporaryFilesArray addObject:selectionStringPath];
			[commandToWrite replaceOccurrencesOfString:@"%%s" withString:selectionStringPath options:NSLiteralSearch range:NSMakeRange(0, [commandToWrite length])];
		}
		
		id document = SMLCurrentDocument;
		NSString *path = [NSString stringWithFormat:@"\"%@\"", [document valueForKey:@"path"]]; // If there's a space in the path
		NSString *directory = [NSString stringWithFormat:@"\"%@\"", [[document valueForKey:@"path"] stringByDeletingLastPathComponent]];
		[commandToWrite replaceOccurrencesOfString:@"%%p" withString:path options:NSLiteralSearch range:NSMakeRange(0, [commandToWrite length])];
		[commandToWrite replaceOccurrencesOfString:@"%%d" withString:directory options:NSLiteralSearch range:NSMakeRange(0, [commandToWrite length])];
		
		NSString *commandPath = [SMLBasic genererateTemporaryPath];
		[commandToWrite writeToFile:commandPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
		[temporaryFilesArray addObject:commandPath];
		
		if ([command valueForKey:@"interpreter"] != nil && ![[command valueForKey:@"interpreter"] isEqualToString:@""]) {
			[SMLVarious performCommandAsynchronously:[NSString stringWithFormat:@"%@ %@", [command valueForKey:@"interpreter"], commandPath]];
		} else {
			[SMLVarious performCommandAsynchronously:[NSString stringWithFormat:@"%@ %@", [SMLDefaults valueForKey:@"RunText"], commandPath]];
		}
		
		if (checkIfTemporaryFilesCanBeDeletedTimer != nil) {
			[checkIfTemporaryFilesCanBeDeletedTimer invalidate];
		}
		checkIfTemporaryFilesCanBeDeletedTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(checkIfTemporaryFilesCanBeDeleted) userInfo:nil repeats:YES];
		
	} else {
		[SMLVarious performCommandAsynchronously:[self commandToRunFromString:commandString]];
	}
}


- (BOOL)currentCommandShouldBeInsertedInline
{
    return currentCommandShouldBeInsertedInline;
}


- (void)setCommandRunning:(BOOL)flag
{
    isCommandRunning = flag;
}


- (void)checkIfTemporaryFilesCanBeDeleted
{
	if (isCommandRunning == YES) {
		return;
	}
	
	if (checkIfTemporaryFilesCanBeDeletedTimer != nil) {
		[checkIfTemporaryFilesCanBeDeletedTimer invalidate];
		checkIfTemporaryFilesCanBeDeletedTimer = nil;
	}
	
	[self clearAnyTemporaryFiles];
}


- (void)clearAnyTemporaryFiles
{
	NSArray *enumeratorArray = [NSArray arrayWithArray:temporaryFilesArray];
	id item;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	for (item in enumeratorArray) {
		if ([fileManager fileExistsAtPath:item]) {
			[fileManager removeItemAtPath:item error:nil];
		}
		[temporaryFilesArray removeObject:item];
	}
}


- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ([[SMLDefaults valueForKey:@"SizeOfDocumentsListTextPopUp"] integerValue] == 0) {
		[aCell setFont:[NSFont systemFontOfSize:11.0]];
	} else {
		[aCell setFont:[NSFont systemFontOfSize:13.0]];
	}
}


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:@"NewCommandCollectionToolbarItem",
		@"NewCommandToolbarItem",
		@"FilterCommandsToolbarItem",
		@"RunCommandToolbarItem",
		NSToolbarFlexibleSpaceItemIdentifier,
		nil];
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar  
{      
	return [NSArray arrayWithObjects:@"NewCommandCollectionToolbarItem",
		NSToolbarFlexibleSpaceItemIdentifier,
		@"RunCommandToolbarItem",
		NSToolbarFlexibleSpaceItemIdentifier,
		@"FilterCommandsToolbarItem",
		@"NewCommandToolbarItem",
		nil];  
} 


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)willBeInserted
{
    if ([itemIdentifier isEqualToString:@"NewCommandCollectionToolbarItem"]) {

		NSImage *newCommandCollectionImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SMLNewCollectionIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
		[[[newCommandCollectionImage representations] objectAtIndex:0] setAlpha:YES];
		
		return [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:NEW_COLLECTION_STRING image:newCommandCollectionImage action:@selector(newCollectionAction:) tag:0 target:self];
		
		
	} else if ([itemIdentifier isEqualToString:@"NewCommandToolbarItem"]) {

		NSImage *newCommandImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SMLNewIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
		[[[newCommandImage representations] objectAtIndex:0] setAlpha:YES];
		
		return [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedStringFromTable(@"New Command", @"Localizable3", @"New Command") image:newCommandImage action:@selector(newCommandAction:) tag:0 target:self];

		
	} else if ([itemIdentifier isEqualToString:@"RunCommandToolbarItem"]) {

		NSImage *runCommandImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SMLRunIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
		[[[runCommandImage representations] objectAtIndex:0] setAlpha:YES];
		
		return [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedStringFromTable(@"Run", @"Localizable3", @"Run") image:runCommandImage action:@selector(runAction:) tag:0 target:self];

		
		
	} else if ([itemIdentifier isEqualToString:@"FilterCommandsToolbarItem"]) {
		
		return [NSToolbarItem createSeachFieldToolbarItemWithIdentifier:itemIdentifier name:FILTER_STRING view:commandsFilterView];		
				
	}
	
	return nil;
}




@end
