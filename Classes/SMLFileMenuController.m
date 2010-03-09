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

#import "SMLFileMenuController.h"
#import "SMLProjectsController.h"
#import "SMLExtraInterfaceController.h"
#import "SMLBasicPerformer.h"
#import "SMLOpenSavePerformer.h"
#import "SMLInterfacePerformer.h"
#import "SMLVariousPerformer.h"
#import "SMLPrintTextView.h"
#import "SMLLayoutManager.h"
#import "SMLSyntaxColouring.h"
#import "SMLProject.h"
#import "SMLLineNumbers.h"


@implementation SMLFileMenuController


static id sharedInstance = nil;

+ (SMLFileMenuController *)sharedInstance
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


- (IBAction)newAction:(id)sender
{
	if (SMLCurrentProject == nil) {
		[[SMLProjectsController sharedDocumentController] newDocument:nil];
	}
	id document = [SMLCurrentProject createNewDocumentWithContents:@""];
	[SMLCurrentProject insertDefaultIconsInDocument:document];
	[SMLCurrentProject selectionDidChange];
}


- (IBAction)newProjectAction:(id)sender
{
	[[[SMLExtraInterfaceController sharedInstance] newProjectWindow] makeKeyAndOrderFront:nil];
}


- (IBAction)openAction:(id)sender
{
	[SMLBasic removeAllItemsFromMenu:[[[SMLExtraInterfaceController sharedInstance] openPanelEncodingsPopUp] menu]];

	NSEnumerator *enumerator = [[SMLBasic fetchAll:@"EncodingSortKeyName"] reverseObjectEnumerator];
	NSMenuItem *menuItem;
	for (id item in enumerator) {
		if ([[item valueForKey:@"active"] boolValue] == YES) {
			NSUInteger encoding = [[item valueForKey:@"encoding"] unsignedIntegerValue];
			menuItem = [[NSMenuItem alloc] initWithTitle:[NSString localizedNameOfStringEncoding:encoding] action:nil keyEquivalent:@""];
			[menuItem setTag:encoding];
			[[[[SMLExtraInterfaceController sharedInstance] openPanelEncodingsPopUp] menu] insertItem:menuItem atIndex:0];
		}
	}

	menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Use settings from Preferences", @"Use settings from Preferences in openAction") action:nil keyEquivalent:@""];
	[menuItem setTag:0];
	[[[[SMLExtraInterfaceController sharedInstance] openPanelEncodingsPopUp] menu] insertItem:menuItem atIndex:0];

	[[[SMLExtraInterfaceController sharedInstance] openPanelEncodingsPopUp] selectItemAtIndex:0]; // Reset it to: Use settings from Preferences
	
	if ([sender tag] == 7) { // Needs to be set before it is created
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"AppleShowAllFiles"];
	}
	
	openPanel = [[NSOpenPanel alloc] init];

	[openPanel setResolvesAliases:YES];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel setAccessoryView:[[SMLExtraInterfaceController sharedInstance] openPanelAccessoryView]];
	
	if ([[SMLDefaults valueForKey:@"OpenAllFilesWithinAFolder"] boolValue] == YES) {
		[openPanel setCanChooseDirectories:YES];
	}
	
	if ([sender tag] == 7) {
		[openPanel setTreatsFilePackagesAsDirectories:YES];
	}
	
	[openPanel beginSheetForDirectory:[SMLInterface whichDirectoryForOpen]
							 file:nil
							types:nil
				   modalForWindow:SMLCurrentWindow
					modalDelegate:self
				   didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
					  contextInfo:nil];
}


- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"AppleShowAllFiles"];
	
	if (returnCode == NSOKButton) {	
		[SMLDefaults setValue:[[sheet filename] stringByDeletingLastPathComponent] forKey:@"LastOpenDirectory"];
		NSArray *array = [sheet filenames];
		for (id item in array) {
			[SMLOpenSave shouldOpen:item withEncoding:[[[SMLExtraInterfaceController sharedInstance] openPanelEncodingsPopUp] selectedTag]];
		}
	}
}


- (IBAction)saveAction:(id)sender
{
	if ([[SMLCurrentDocument valueForKey:@"isNewDocument"] boolValue] == YES) {   
		[[SMLProjectsController sharedDocumentController] selectDocument:SMLCurrentDocument]; // If one has saved from a single document window it should select the proper document in the project
		[self saveAsAction:sender];    
	} else {
		[SMLOpenSave performSaveOfDocument:SMLCurrentDocument fromSaveAs:NO];
	}
}


- (IBAction)saveAsAction:(id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	NSMutableString *name = [NSMutableString stringWithString:[SMLCurrentDocument valueForKey:@"name"]];
	if ([[SMLDefaults valueForKey:@"AppendNameInSaveAs"] boolValue] == YES) {
		[name appendString:[SMLDefaults valueForKey:@"AppendNameInSaveAsWith"]];
	}
	[savePanel beginSheetForDirectory:[SMLInterface whichDirectoryForSave]				
								 file:name
					   modalForWindow:SMLCurrentWindow
						modalDelegate:self
					   didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
	
	[NSApp runModalForWindow:savePanel]; // Run as modal to handle if there are more than one document that needs saving
}


- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)context
{
	[sheet close];
	[SMLVarious stopModalLoop];
	
	if (returnCode == NSOKButton) {						
		if ([[SMLCurrentDocument valueForKey:@"fromExternal"] boolValue] == YES) {
			[SMLVarious sendClosedEventToExternalDocument:SMLCurrentDocument];
			[SMLCurrentDocument setValue:[NSNumber numberWithBool:NO] forKey:@"fromExternal"]; // If it is "fromExternal" it shouldn't be that after it has gone through a Save As, but rather, it should be a normal document
		}
		
		[SMLOpenSave performSaveOfDocument:SMLCurrentDocument path:[sheet filename] fromSaveAs:YES aCopy:NO];
		if ([[NSFileManager defaultManager] fileExistsAtPath:[sheet filename]]) {// Check that it has actually been saved
			[[SMLProjectsController sharedDocumentController] putInRecentWithPath:[sheet filename]];
		}
		[SMLDefaults setValue:[[sheet filename] stringByDeletingLastPathComponent] forKey:@"LastSaveAsDirectory"];
		[[SMLCurrentDocument valueForKey:@"syntaxColouring"] setSyntaxDefinition];
		
		[[SMLCurrentDocument valueForKey:@"syntaxColouring"] pageRecolour];
		
		[SMLInterface updateStatusBar];
	}
}


- (IBAction)saveACopyAsAction:(id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	
	NSString *copyName = [NSString stringWithFormat:@"%@ %@", [SMLCurrentDocument valueForKey:@"name"], NSLocalizedString(@"copy", @"The word to indicate that the filename is a copy in Save-A-Copy-As save-panel")];
	
	[savePanel beginSheetForDirectory:[SMLInterface whichDirectoryForSave]				
								 file:copyName
					   modalForWindow:SMLCurrentWindow
						modalDelegate:self
					   didEndSelector:@selector(saveACopyAsPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
	
}


- (void)saveACopyAsPanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)context
{
	if (returnCode == NSOKButton) {						
		[SMLOpenSave performSaveOfDocument:SMLCurrentDocument path:[sheet filename] fromSaveAs:YES aCopy:YES];
		[SMLDefaults setValue:[[sheet filename] stringByDeletingLastPathComponent] forKey:@"LastSaveAsDirectory"];
	}
}


- (IBAction)revertAction:(id)sender
{
	id document = SMLCurrentDocument;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:[document valueForKey:@"path"]]) { // Check if original file exists
		NSString *title = [NSString stringWithFormat:NSLocalizedString(@"You cannot revert this document because the file %@ doesn't exist anymore", @"Indicate that you cannot revert this document because the file %@ doesn't exist anymore Revert-file-doesn't-exist sheet"), [document valueForKey:@"path"]];
		[SMLVarious standardAlertSheetWithTitle:title message:NSLocalizedString(@"Please check if you've moved or deleted the original file", @"Indicate that they should please check if you've moved or deleted the original file in Revert-file-doesn't-exist sheet") window:SMLCurrentWindow];
		return;
	}
	
	if ([[document valueForKey:@"isEdited"] boolValue] == NO) {
		[self performRevertOfDocument:document]; // I.e an update of the document
	} else {
		if ([SMLCurrentWindow attachedSheet]) {
			[[SMLCurrentWindow attachedSheet] close];
		}
		
		NSBeginAlertSheet(NSLocalizedString(@"Are you sure you want to revert this document?", @"Ask if you are sure you want to revert this document in Revert-sheet"),
						  NSLocalizedString(@"Revert", @"Revert-button in Revert-sheet"),
						  nil,
						  CANCEL_BUTTON,
						  SMLCurrentWindow,
						  self,
						  @selector(revertSheetDidEnd:returnCode:contextInfo:),
						  nil,
						  nil,
						  NSLocalizedString(@"Your changes will be lost if you revert the document", @"Warn that changes will be lost if you revert in Revert-sheet"));
	}
}


- (void)revertSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertDefaultReturn) {
		[self performRevertOfDocument:SMLCurrentDocument];
	}
}


- (void)performRevertOfDocument:(id)document
{	
	NSData *textData = [[NSData alloc] initWithContentsOfFile:[document valueForKey:@"path"]];
	
	// UTF-8 e.g. encoding returns nil if the file is not properly formed so check for that and try others if it's nil
	NSString *string = [[NSString alloc] initWithData:textData encoding:[[document valueForKey:@"encoding"] integerValue]];
	
	if (string == nil) { // Test if encoding worked, else try NSISOLatin1StringEncoding
		string = [[NSString alloc] initWithData:textData encoding:NSISOLatin1StringEncoding];
		if (string == nil) { // Test if encoding worked, else try defaultCStringEncoding
			string = [[NSString alloc] initWithData:textData encoding:[NSString defaultCStringEncoding]];
			if (string == nil) { // If it still is nil set it to empty string
				string = @"";
			}
		}
	}
	[[[document valueForKey:@"firstTextView"] undoManager] removeAllActions];
	[[document valueForKey:@"firstTextView"] setString:string];
	[[document valueForKey:@"syntaxColouring"] pageRecolour];
	[[document valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth:NO recolour:NO];
	[[document valueForKey:@"firstTextView"] setSelectedRange:NSMakeRange(0,0)];
	[document setValue:[NSNumber numberWithBool:NO] forKey:@"isEdited"];
	[SMLCurrentProject updateEditedBlobStatus];
	[SMLCurrentProject reloadData];
	[SMLInterface updateStatusBar];
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	BOOL enableMenuItem = YES;
	NSInteger tag = [anItem tag];
	if (SMLCurrentProject != nil && [SMLCurrentProject areThereAnyDocuments]) {
		if (tag == 2) { // Save All
			NSArray *array = [SMLCurrentProject documents];
			for (id item in array) {
				if ([[item valueForKey:@"isEdited"] boolValue] == YES) {
					enableMenuItem = YES;
					break;
				}
				enableMenuItem = NO;
			}

		} else if (tag == 4 || tag == 8 ) { // Revert & Reveal In Finder
			enableMenuItem = ![[SMLCurrentDocument valueForKey:@"isNewDocument"] boolValue];
		} else if (tag == 5) { // Save Documents As Project
			if ([SMLCurrentProject fileURL] != nil) {
				enableMenuItem = NO;
			}
		} else if (tag == 6) { // Close
			if ([NSApp mainWindow] == nil && [NSApp keyWindow] == nil) {
				enableMenuItem = NO;
			}
		} else if (tag == 9) { // Close Project
			if ([NSApp mainWindow] == nil) {
				enableMenuItem = NO;
			}
		}
			
	} else {
		if (tag == 1 || tag == 7) { // All items that should be active all the time and Open Hidden...
			enableMenuItem = YES;
		} else if (tag == 6) { // Close
			if ([NSApp mainWindow] == nil && [NSApp keyWindow] == nil) {
				enableMenuItem = NO;
			}
		} else {
			enableMenuItem = NO;
		}
	}
	
	return enableMenuItem;
}


- (IBAction)closeAction:(id)sender
{
	NSWindow *window = [NSApp keyWindow];
	if (window == SMLCurrentWindow && [[SMLCurrentProject documents] count] > 0) {
		[SMLCurrentProject checkIfDocumentIsUnsaved:SMLCurrentDocument keepOpen:NO];
	} else {
		[window performClose:nil];
	}
}


- (IBAction)saveAllAction:(id)sender
{
	NSArray *array = [SMLCurrentProject documents];
	for (id item in array) {
		if ([[item valueForKey:@"isEdited"] boolValue] == YES) {
			if ([[item valueForKey:@"isNewDocument"] boolValue] == YES) {
				[[SMLProjectsController sharedDocumentController] selectDocument:item];
				[self saveAsInSaveAllForDocument:item];
			} else {
				[SMLOpenSave performSaveOfDocument:item fromSaveAs:NO];
			}
		}
	}
	[SMLInterface updateStatusBar]; // Might be needed if the current document has saved with a new name 
}


- (void)saveAsInSaveAllForDocument:(id)document
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];				
	
	[savePanel beginSheetForDirectory:[SMLInterface whichDirectoryForSave]				
								 file:[document valueForKey:@"name"]
					   modalForWindow:SMLCurrentWindow
						modalDelegate:self
					   didEndSelector:@selector(saveAsPanelInSaveAllDidEnd:returnCode:contextInfo:)
						  contextInfo:(void *)[NSArray arrayWithObject:document]];
	
	[NSApp runModalForWindow:savePanel]; // Run as modal to handle if there are more than one document that needs saving
}


- (void)saveAsPanelInSaveAllDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)context
{
	[sheet close];
	[SMLVarious stopModalLoop];
	
	if (returnCode == NSOKButton) {
		id document = [(NSArray *)context objectAtIndex:0];
		NSString *path = [sheet filename];
		[SMLOpenSave performSaveOfDocument:document path:path fromSaveAs:NO aCopy:NO];
		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) { // Check that it has actually been saved
			[[SMLProjectsController sharedDocumentController] putInRecentWithPath:path];
		}
		[SMLDefaults setValue:[path stringByDeletingLastPathComponent] forKey:@"LastSaveAsDirectory"];
		[[document valueForKey:@"syntaxColouring"] setSyntaxDefinition];
		[[document valueForKey:@"syntaxColouring"] pageRecolour];
	}
}


- (void)printAction:(id)sender 
{
	[SMLCurrentProject printDocument:sender];
}




- (IBAction)revealInFinderAction:(id)sender
{
	[[NSWorkspace sharedWorkspace] selectFile:[SMLCurrentDocument valueForKey:@"path"] inFileViewerRootedAtPath:@""];
}
	

- (IBAction)saveDocumentsAsProjectAction:(id)sender
{
	[SMLCurrentProject saveDocumentAs:nil];
}

@end
