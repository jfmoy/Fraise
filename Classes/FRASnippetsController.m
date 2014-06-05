/*
 Fraise version 3.7 - Based on Smultron by Peter Borg
 Written by Jean-François Moy - jeanfrancois.moy@gmail.com
 Find the latest version at http://github.com/jfmoy/Fraise
 
 Copyright 2010 Jean-François Moy
 
 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

#import "FRASnippetsController.h"
#import "NSToolbarItem+Fraise.h"
#import "FRADragAndDropController.h"
#import "FRATextView.h"
#import "FRAMainController.h"
#import "FRAInterfacePerformer.h"
#import "FRABasicPerformer.h"
#import "FRAOpenSavePerformer.h"
#import "FRADocumentsListCell.h"
#import "FRAApplicationDelegate.h"
#import "FRAToolsMenuController.h"
#import "FRAProjectsController.h"

@implementation FRASnippetsController

@synthesize snippetsTextView, snippetsWindow, snippetCollectionsArrayController, snippetCollectionsTableView, snippetsTableView, snippetsArrayController;

static id sharedInstance = nil;

+ (FRASnippetsController *)sharedInstance
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
    }
    return sharedInstance;
}


- (void)openSnippetsWindow
{
	if (snippetsWindow == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"FRASnippets" owner:self topLevelObjects:nil];
		
		[snippetCollectionsTableView setDataSource:[FRADragAndDropController sharedInstance]];
		[snippetsTableView setDataSource:[FRADragAndDropController sharedInstance]];
		
		[snippetCollectionsTableView registerForDraggedTypes:@[NSFilenamesPboardType, @"FRAMovedSnippetType"]];
		[snippetCollectionsTableView setDraggingSourceOperationMask:(NSDragOperationCopy) forLocal:NO];
		
		[snippetsTableView registerForDraggedTypes:@[NSStringPboardType]];
		[snippetsTableView setDraggingSourceOperationMask:(NSDragOperationCopy) forLocal:NO];
		
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
		[snippetCollectionsArrayController setSortDescriptors:@[sortDescriptor]];
		[snippetsArrayController setSortDescriptors:@[sortDescriptor]];
		
		FRADocumentsListCell *cell = [[FRADocumentsListCell alloc] init];
		[cell setWraps:NO];
		[cell setLineBreakMode:NSLineBreakByTruncatingMiddle];
		[[snippetCollectionsTableView tableColumnWithIdentifier:@"collection"] setDataCell:cell];
		
		NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"SnippetsToolbarIdentifier"];
		[toolbar setShowsBaselineSeparator:YES];
		[toolbar setAllowsUserCustomization:YES];
		[toolbar setAutosavesConfiguration:YES];
		[toolbar setDisplayMode:NSToolbarDisplayModeDefault];
		[toolbar setSizeMode:NSToolbarSizeModeSmall];
		[toolbar setDelegate:self];
		[snippetsWindow setToolbar:toolbar];
	}
	
	[snippetsWindow makeKeyAndOrderFront:self];
	[[FRAToolsMenuController sharedInstance] buildInsertSnippetMenu];
	
}


- (IBAction)newCollectionAction:(id)sender
{
	[snippetCollectionsArrayController commitEditing];
	id collection = [FRABasic createNewObjectForEntity:@"SnippetCollection"];
	
	[FRAManagedObjectContext processPendingChanges];
	[snippetCollectionsArrayController setSelectedObjects:@[collection]];
	
	[snippetsWindow makeFirstResponder:snippetCollectionsTableView];
	[snippetCollectionsTableView editColumn:0 row:[snippetCollectionsTableView selectedRow] withEvent:nil select:NO];
}


- (IBAction)newSnippetAction:(id)sender
{
	NSArray *snippetCollections = [FRABasic fetchAll:@"SnippetCollectionSortKeyName"];
	if ([snippetCollections count] == 0) {
		id collection = [FRABasic createNewObjectForEntity:@"SnippetCollection"];
		[collection setValue:COLLECTION_STRING forKey:@"name"];
	}
	[snippetsArrayController commitEditing];
	[self performInsertNewSnippet];
	
	[snippetsWindow makeFirstResponder:snippetsTableView];
	[snippetsTableView editColumn:0 row:[snippetsTableView selectedRow] withEvent:nil select:NO];
}


- (id)performInsertNewSnippet
{
	id collection;
	NSArray *snippetCollections = [FRABasic fetchAll:@"SnippetCollectionSortKeyName"];
	if ([snippetCollections count] == 0) {
		collection = [FRABasic createNewObjectForEntity:@"SnippetCollection"];
		[collection setValue:COLLECTION_STRING forKey:@"name"];
	} else {
		if (snippetsWindow != nil && [[snippetCollectionsArrayController selectedObjects] count] != 0) {
			collection = [snippetCollectionsArrayController selectedObjects][0];
		} else { // If no collection is selected choose the last one in the array
			collection = [snippetCollections lastObject];
		}
	}
	
	id item = [FRABasic createNewObjectForEntity:@"Snippet"];
	[[collection mutableSetValueForKey:@"snippets"] addObject:item];
	[FRAManagedObjectContext processPendingChanges];
	[snippetsArrayController setSelectedObjects:@[item]];
	
	return item;
}


- (void)insertSnippet:(id)snippet
{
	FRATextView *textView = FRACurrentTextView;
	if (textView == nil) {
		NSBeep();
		return;
	}
	
	NSRange selectedRange = [FRACurrentTextView selectedRange];
	NSString *selectedText = [[FRACurrentTextView string] substringWithRange:selectedRange];
	if (selectedText == nil) {
		selectedText = @"";
	}
	
	NSMutableString *insertString = [NSMutableString stringWithString:[snippet valueForKey:@"text"]];
	[insertString replaceOccurrencesOfString:@"%%s" withString:selectedText options:NSLiteralSearch range:NSMakeRange(0, [insertString length])];
	NSInteger locationOfSelectionInString = [insertString rangeOfString:@"%%c"].location;
	[insertString replaceOccurrencesOfString:@"%%c" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [insertString length])];
	[textView insertText:insertString replacementRange:[textView selectedRange]];
	if (locationOfSelectionInString != NSNotFound) {
		[textView setSelectedRange:NSMakeRange(selectedRange.location + locationOfSelectionInString, 0)];
	}
}


- (void)performDeleteCollection
{
	id collection = [snippetCollectionsArrayController selectedObjects][0];
    
	[FRAManagedObjectContext deleteObject:collection];
	
	[[FRAToolsMenuController sharedInstance] buildInsertSnippetMenu];
}


- (void)importSnippets
{
	[self openSnippetsWindow];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setResolvesAliases:YES];
	[openPanel setDirectoryURL: [NSURL fileURLWithPath: [FRAInterface whichDirectoryForOpen]]];
    [openPanel setAllowedFileTypes: @[@"frac", @"smlc", @"fraiseSnippets"]];
    [openPanel beginSheetModalForWindow: snippetsWindow
                      completionHandler: (^(NSInteger result)
                                          {
                                              
                                              if (result == NSModalResponseOK)
                                              {
                                                  [self performSnippetsImportWithPath: [[openPanel URL] path]];
                                              }
                                              [snippetsWindow makeKeyAndOrderFront:nil];
                                          })];
}


- (void)performSnippetsImportWithPath:(NSString *)path
{
	NSData *data = [NSData dataWithContentsOfFile:path];
	NSArray *snippets = (NSArray *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	if ([snippets count] == 0) {
		NSBeep();
		return;
	}
	
	if ([[snippets[0] valueForKey:@"version"] integerValue] == 2 || [[snippets[0] valueForKey:@"version"] integerValue] == 3) {
		
		id collection = [FRABasic createNewObjectForEntity:@"SnippetCollection"];
		[collection setValue:[snippets[0] valueForKey:@"collectionName"] forKey:@"name"];
		
		id item;
		for (item in snippets) {
			id snippet = [FRABasic createNewObjectForEntity:@"Snippet"];
			[snippet setValue:[item valueForKey:@"name"] forKey:@"name"];
			[snippet setValue:[item valueForKey:@"text"] forKey:@"text"];
			[snippet setValue:[item valueForKey:@"collectionName"] forKey:@"collectionName"];
			[snippet setValue:[item valueForKey:@"shortcutDisplayString"] forKey:@"shortcutDisplayString"];
			[snippet setValue:[item valueForKey:@"shortcutMenuItemKeyString"] forKey:@"shortcutMenuItemKeyString"];
			[snippet setValue:[item valueForKey:@"shortcutModifier"] forKey:@"shortcutModifier"];
			[snippet setValue:[item valueForKey:@"sortOrder"] forKey:@"sortOrder"];
			[[collection mutableSetValueForKey:@"snippets"] addObject:snippet];
		}
		
		[FRAManagedObjectContext processPendingChanges];
		
		[snippetCollectionsArrayController setSelectedObjects:@[collection]];
	} else {
		NSBeep();
	}
}


- (void)exportSnippets
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setAllowedFileTypes: @[@"fraiseSnippets"]];
    [savePanel setDirectoryURL: [NSURL fileURLWithPath: [FRAInterface whichDirectoryForSave]]];
    [savePanel setNameFieldStringValue: [[snippetCollectionsArrayController selectedObjects][0] valueForKey:@"name"]];
    [savePanel beginSheetModalForWindow: snippetsWindow
                      completionHandler: (^(NSInteger result)
                                          {
                                              if (result == NSModalResponseOK)
                                              {
                                                  id collection = [snippetCollectionsArrayController selectedObjects][0];
                                                  
                                                  NSMutableArray *exportArray = [NSMutableArray array];
                                                  NSArray *array = [[collection mutableSetValueForKey:@"snippets"] allObjects];
                                                  for (id item in array)
                                                  {
                                                      NSMutableDictionary *snippet = [NSMutableDictionary dictionary];
                                                      snippet[@"name"] = [item valueForKey:@"name"];
                                                      snippet[@"text"] = [item valueForKey:@"text"];
                                                      snippet[@"collectionName"] = [collection valueForKey:@"name"];
                                                      snippet[@"shortcutDisplayString"] = [item valueForKey:@"shortcutDisplayString"];
                                                      snippet[@"shortcutMenuItemKeyString"] = [item valueForKey:@"shortcutMenuItemKeyString"];
                                                      snippet[@"shortcutModifier"] = [item valueForKey:@"shortcutModifier"];
                                                      snippet[@"sortOrder"] = [item valueForKey:@"sortOrder"];
                                                      snippet[@"version"] = @3;
                                                      [exportArray addObject:snippet];
                                                  }
                                                  
                                                  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:exportArray];
                                                  [FRAOpenSave performDataSaveWith: data
                                                                              path: [[savePanel URL] path]];
                                              }
                                              
                                              [snippetsWindow makeKeyAndOrderFront:nil];
                                          })];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[snippetCollectionsArrayController commitEditing];
	[snippetsArrayController commitEditing];
}


- (NSManagedObjectContext *)managedObjectContext
{
	return FRAManagedObjectContext;
}


- (NSTextView *)snippetsTextView
{
	return snippetsTextView;
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
    return @[@"NewSnippetCollectionToolbarItem",
             @"NewSnippetToolbarItem",
             @"FilterSnippetsToolbarItem",
             NSToolbarFlexibleSpaceItemIdentifier];
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return @[@"NewSnippetCollectionToolbarItem",
             NSToolbarFlexibleSpaceItemIdentifier,
             @"FilterSnippetsToolbarItem",
             @"NewSnippetToolbarItem"];
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)willBeInserted
{
    if ([itemIdentifier isEqualToString:@"NewSnippetCollectionToolbarItem"]) {
        
		NSImage *newSnippetCollectionImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRANewCollectionIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
		[[newSnippetCollectionImage representations][0] setAlpha:YES];
		
		return [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:NEW_COLLECTION_STRING image:newSnippetCollectionImage action:@selector(newCollectionAction:) tag:0 target:self];
		
		
	} else if ([itemIdentifier isEqualToString:@"NewSnippetToolbarItem"]) {
        
		NSImage *newSnippetImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRANewIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
		[[newSnippetImage representations][0] setAlpha:YES];
		
		return [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedStringFromTable(@"New Snippet", @"Localizable3", @"New Snippet") image:newSnippetImage action:@selector(newSnippetAction:) tag:0 target:self];
		
		
	} else if ([itemIdentifier isEqualToString:@"FilterSnippetsToolbarItem"]) {
		
		return [NSToolbarItem createSeachFieldToolbarItemWithIdentifier:itemIdentifier name:FILTER_STRING view:snippetsFilterView];
		
	}
	
	return nil;
}
@end
