/*
 Fraise version 3.7 - Based on Smultron by Peter Borg
 Written by Jean-François Moy - jeanfrancois.moy@gmail.com
 Find the latest version at http://github.com/jfmoy/Fraise
 
 Copyright 2010 Jean-François Moy
 
 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

#import "NSToolbarItem+Fraise.h"
#import "FRACommandsController.h"
#import "FRADocumentsListCell.h"
#import "FRAApplicationDelegate.h"
#import "FRABasicPerformer.h"
#import "FRADragAndDropController.h"
#import "FRAToolsMenuController.h"
#import "FRAInterfacePerformer.h"
#import "FRAProjectsController.h"
#import "FRAVariousPerformer.h"
#import "FRAOpenSavePerformer.h"
#import "FRATextView.h"

@implementation FRACommandsController

static id sharedInstance = nil;

@synthesize commandsTextView, commandsWindow, commandCollectionsArrayController, commandCollectionsTableView, commandsTableView, commandsArrayController;


+ (FRACommandsController *)sharedInstance
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
		[[NSBundle mainBundle] loadNibNamed:@"FRACommands" owner:self topLevelObjects:nil];
		
		[commandCollectionsTableView setDataSource:[FRADragAndDropController sharedInstance]];
		[commandsTableView setDataSource:[FRADragAndDropController sharedInstance]];
		
		[commandCollectionsTableView registerForDraggedTypes:@[NSFilenamesPboardType, @"FRAMovedCommandType"]];
		[commandCollectionsTableView setDraggingSourceOperationMask:(NSDragOperationCopy) forLocal:NO];
		
		[commandsTableView registerForDraggedTypes:@[NSStringPboardType]];
		[commandsTableView setDraggingSourceOperationMask:(NSDragOperationCopy) forLocal:NO];
		
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
		[commandCollectionsArrayController setSortDescriptors:@[sortDescriptor]];
		[commandsArrayController setSortDescriptors:@[sortDescriptor]];
		
		FRADocumentsListCell *cell = [[FRADocumentsListCell alloc] init];
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
	}
	
	[commandsWindow makeKeyAndOrderFront:self];
	[[FRAToolsMenuController sharedInstance] buildRunCommandMenu];
}


- (IBAction)newCollectionAction:(id)sender
{
	[commandCollectionsArrayController commitEditing];
	[commandsArrayController commitEditing];
	id collection = [FRABasic createNewObjectForEntity:@"CommandCollection"];
	
	[FRAManagedObjectContext processPendingChanges];
	[commandCollectionsArrayController setSelectedObjects:@[collection]];
	
	[commandsWindow makeFirstResponder:commandCollectionsTableView];
	[commandCollectionsTableView editColumn:0 row:[commandCollectionsTableView selectedRow] withEvent:nil select:NO];
}


- (IBAction)newCommandAction:(id)sender
{
	id collection;
	NSArray *commandCollections = [FRABasic fetchAll:@"CommandCollectionSortKeyName"];
	if ([commandCollections count] == 0) {
		collection = [FRABasic createNewObjectForEntity:@"CommandCollection"];
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
	NSArray *commandCollections = [FRABasic fetchAll:@"CommandCollectionSortKeyName"];
	if ([commandCollections count] == 0) {
		collection = [FRABasic createNewObjectForEntity:@"CommandCollection"];
		[collection setValue:COLLECTION_STRING forKey:@"name"];
	} else {
		if (commandsWindow != nil && [[commandCollectionsArrayController selectedObjects] count] != 0) {
			collection = [commandCollectionsArrayController selectedObjects][0];
		} else { // If no collection is selected choose the last one in the array
			collection = [commandCollections lastObject];
		}
	}
	
	id item = [FRABasic createNewObjectForEntity:@"Command"];
	[[collection mutableSetValueForKey:@"commands"] addObject:item];
	[FRAManagedObjectContext processPendingChanges];
	[commandsArrayController setSelectedObjects:@[item]];
	
	return item;
}


- (void)performDeleteCollection
{
	id collection = [commandCollectionsArrayController selectedObjects][0];
	
	[FRAManagedObjectContext deleteObject:collection];
	
	[[FRAToolsMenuController sharedInstance] buildRunCommandMenu];
}


- (void)importCommands
{
	[self openCommandsWindow];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setResolvesAliases:YES];
    [openPanel setDirectoryURL: [NSURL fileURLWithPath: [FRAInterface whichDirectoryForOpen]]];
    [openPanel setAllowedFileTypes: @[@"fraiseCommands"]];
    [openPanel beginSheetModalForWindow: commandsWindow
                      completionHandler: (^(NSInteger returnCode)
                                          {
                                              if (returnCode == NSModalResponseOK) {
                                                  [self performCommandsImportWithPath: [[openPanel URL] path]];
                                              }
                                              [commandsWindow makeKeyAndOrderFront:nil];
                                          })];
}


- (void)performCommandsImportWithPath:(NSString *)path
{
	NSData *data = [NSData dataWithContentsOfFile:path];
	NSArray *commands = (NSArray *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	if ([commands count] == 0) {
		return;
	}
	
	id collection = [FRABasic createNewObjectForEntity:@"CommandCollection"];
	[collection setValue:[commands[0] valueForKey:@"collectionName"] forKey:@"name"];
	
	id item;
	for (item in commands) {
		id command = [FRABasic createNewObjectForEntity:@"Command"];
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
	
	[FRAManagedObjectContext processPendingChanges];
	
	[commandCollectionsArrayController setSelectedObjects:@[collection]];
}


- (void)exportCommands
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes: @[@"fraiseCommands"]];
    [savePanel setDirectoryURL: [NSURL fileURLWithPath: [FRAInterface whichDirectoryForSave]]];
    [savePanel setNameFieldStringValue: [[commandCollectionsArrayController selectedObjects][0] valueForKey:@"name"]];
    [savePanel beginSheetModalForWindow: commandsWindow
                      completionHandler: (^(NSInteger returnCode)
                                          {
                                              if (returnCode == NSModalResponseOK)
                                              {
                                                  id collection = [commandCollectionsArrayController selectedObjects][0];
                                                  
                                                  NSMutableArray *exportArray = [NSMutableArray array];
                                                  NSEnumerator *enumerator = [[collection mutableSetValueForKey:@"commands"] objectEnumerator];
                                                  for (NSDictionary *item in enumerator)
                                                  {
                                                      NSMutableDictionary *command = [[NSMutableDictionary alloc] init];
                                                      [command setValue:[item valueForKey:@"name"] forKey:@"name"];
                                                      [command setValue:[item valueForKey:@"text"] forKey:@"text"];
                                                      [command setValue:[collection valueForKey:@"name"] forKey:@"collectionName"];
                                                      [command setValue:[item valueForKey:@"shortcutDisplayString"] forKey:@"shortcutDisplayString"];
                                                      [command setValue:[item valueForKey:@"shortcutMenuItemKeyString"] forKey:@"shortcutMenuItemKeyString"];
                                                      [command setValue:[item valueForKey:@"shortcutModifier"] forKey:@"shortcutModifier"];
                                                      [command setValue:[item valueForKey:@"sortOrder"] forKey:@"sortOrder"];
                                                      [command setValue:@3 forKey:@"version"];
                                                      [command setValue:[item valueForKey:@"inline"] forKey:@"inline"];
                                                      [command setValue:[item valueForKey:@"interpreter"] forKey:@"interpreter"];
                                                      [exportArray addObject:command];
                                                  }
                                                  
                                                  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:exportArray];
                                                  [FRAOpenSave performDataSaveWith: data
                                                                              path: [[savePanel URL] path]];
                                              }
                                              
                                              [commandsWindow makeKeyAndOrderFront:nil];

                                          })];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[commandCollectionsArrayController commitEditing];
	[commandsArrayController commitEditing];
}


- (NSManagedObjectContext *)managedObjectContext
{
	return FRAManagedObjectContext;
}


- (IBAction)runAction:(id)sender
{
	[self runCommand:[commandsArrayController selectedObjects][0]];
}


- (IBAction)insertPathAction:(id)sender
{
	id document = FRACurrentDocument;
	if (document == nil || [document valueForKey:@"path"] == nil) {
		NSBeep();
		return;
	}
	
	[commandsTextView insertText:[document valueForKey:@"path"] replacementRange:[commandsTextView selectedRange]];
}


- (IBAction)insertDirectoryAction:(id)sender
{
	id document = FRACurrentDocument;
	if (document == nil || [document valueForKey:@"path"] == nil) {
		NSBeep();
		return;
	}
	
	[commandsTextView insertText:[[document valueForKey:@"path"] stringByDeletingLastPathComponent] replacementRange:[commandsTextView selectedRange]];
}


- (NSString *)commandToRunFromString:(NSString *)string
{
	NSMutableString *returnString = [NSMutableString stringWithString:string];
	id document = FRACurrentDocument;
	if (document == nil || [[document valueForKey:@"isNewDocument"] boolValue] == YES || [document valueForKey:@"path"] == nil) {
		[returnString replaceOccurrencesOfString:@"%%p" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
		[returnString replaceOccurrencesOfString:@"%%d" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
	} else {
		NSString *path = [NSString stringWithFormat:@"\"%@\"", [document valueForKey:@"path"]]; // If there's a space in the path
		NSString *directory;
		if ([[FRADefaults valueForKey:@"PutQuotesAroundDirectory"] boolValue] == YES) {
			directory = [NSString stringWithFormat:@"\"%@\"", [[document valueForKey:@"path"] stringByDeletingLastPathComponent]];
		} else {
			directory = [NSString stringWithFormat:@"%@", [[document valueForKey:@"path"] stringByDeletingLastPathComponent]];
		}
		[returnString replaceOccurrencesOfString:@"%%p" withString:path options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
		[returnString replaceOccurrencesOfString:@"%%d" withString:directory options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
	}
	
	if ([FRACurrentTextView selectedRange].length > 0) {
		[returnString replaceOccurrencesOfString:@"%%s" withString:[FRACurrentText substringWithRange:[FRACurrentTextView selectedRange]] options:NSLiteralSearch range:NSMakeRange(0, [returnString length])];
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
		
		if ([FRACurrentTextView selectedRange].length > 0 && [commandString rangeOfString:@"%%s"].location != NSNotFound) {
			selectionStringPath = [FRABasic genererateTemporaryPath];
			NSString *selectionString = [FRACurrentText substringWithRange:[FRACurrentTextView selectedRange]];
			[selectionString writeToFile:selectionStringPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
			[temporaryFilesArray addObject:selectionStringPath];
			[commandToWrite replaceOccurrencesOfString:@"%%s" withString:selectionStringPath options:NSLiteralSearch range:NSMakeRange(0, [commandToWrite length])];
		}
		
		id document = FRACurrentDocument;
		NSString *path = [NSString stringWithFormat:@"\"%@\"", [document valueForKey:@"path"]]; // If there's a space in the path
		NSString *directory = [NSString stringWithFormat:@"\"%@\"", [[document valueForKey:@"path"] stringByDeletingLastPathComponent]];
		[commandToWrite replaceOccurrencesOfString:@"%%p" withString:path options:NSLiteralSearch range:NSMakeRange(0, [commandToWrite length])];
		[commandToWrite replaceOccurrencesOfString:@"%%d" withString:directory options:NSLiteralSearch range:NSMakeRange(0, [commandToWrite length])];
		
		NSString *commandPath = [FRABasic genererateTemporaryPath];
		[commandToWrite writeToFile:commandPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
		[temporaryFilesArray addObject:commandPath];
		
		if ([command valueForKey:@"interpreter"] != nil && ![[command valueForKey:@"interpreter"] isEqualToString:@""]) {
			[FRAVarious performCommandAsynchronously:[NSString stringWithFormat:@"%@ %@", [command valueForKey:@"interpreter"], commandPath]];
		} else {
			[FRAVarious performCommandAsynchronously:[NSString stringWithFormat:@"%@ %@", [FRADefaults valueForKey:@"RunText"], commandPath]];
		}
		
		if (checkIfTemporaryFilesCanBeDeletedTimer != nil) {
			[checkIfTemporaryFilesCanBeDeletedTimer invalidate];
		}
		checkIfTemporaryFilesCanBeDeletedTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(checkIfTemporaryFilesCanBeDeleted) userInfo:nil repeats:YES];
		
	} else {
		[FRAVarious performCommandAsynchronously:[self commandToRunFromString:commandString]];
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
	if ([[FRADefaults valueForKey:@"SizeOfDocumentsListTextPopUp"] integerValue] == 0) {
		[aCell setFont:[NSFont systemFontOfSize:11.0]];
	} else {
		[aCell setFont:[NSFont systemFontOfSize:13.0]];
	}
}


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return @[@"NewCommandCollectionToolbarItem",
             @"NewCommandToolbarItem",
             @"FilterCommandsToolbarItem",
             @"RunCommandToolbarItem",
             NSToolbarFlexibleSpaceItemIdentifier];
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return @[@"NewCommandCollectionToolbarItem",
             NSToolbarFlexibleSpaceItemIdentifier,
             @"RunCommandToolbarItem",
             NSToolbarFlexibleSpaceItemIdentifier,
             @"FilterCommandsToolbarItem",
             @"NewCommandToolbarItem"];
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)willBeInserted
{
    if ([itemIdentifier isEqualToString:@"NewCommandCollectionToolbarItem"]) {
        
		NSImage *newCommandCollectionImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRANewCollectionIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
		[[newCommandCollectionImage representations][0] setAlpha:YES];
		
		return [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:NEW_COLLECTION_STRING image:newCommandCollectionImage action:@selector(newCollectionAction:) tag:0 target:self];
		
		
	} else if ([itemIdentifier isEqualToString:@"NewCommandToolbarItem"]) {
        
		NSImage *newCommandImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRANewIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
		[[newCommandImage representations][0] setAlpha:YES];
		
		return [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedStringFromTable(@"New Command", @"Localizable3", @"New Command") image:newCommandImage action:@selector(newCommandAction:) tag:0 target:self];
        
		
	} else if ([itemIdentifier isEqualToString:@"RunCommandToolbarItem"]) {
        
		NSImage *runCommandImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRARunIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
		[[runCommandImage representations][0] setAlpha:YES];
		
		return [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedStringFromTable(@"Run", @"Localizable3", @"Run") image:runCommandImage action:@selector(runAction:) tag:0 target:self];
        
		
		
	} else if ([itemIdentifier isEqualToString:@"FilterCommandsToolbarItem"]) {
		
		return [NSToolbarItem createSeachFieldToolbarItemWithIdentifier:itemIdentifier name:FILTER_STRING view:commandsFilterView];		
        
	}
	
	return nil;
}




@end
