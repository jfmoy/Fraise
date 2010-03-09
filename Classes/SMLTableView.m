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

#import "SMLTableView.h"
#import "SMLSnippetsController.h"
#import "SMLCommandsController.h"
#import "SMLToolsMenuController.h"
#import "SMLProjectsController.h"
#import "SMLProject.h"


@implementation SMLTableView




- (void)keyDown:(NSEvent *)event
{
	if (self == [[SMLCommandsController sharedInstance] commandCollectionsTableView] || self == [[SMLCommandsController sharedInstance] commandsTableView] || self == [[SMLSnippetsController sharedInstance] snippetCollectionsTableView] || self == [[SMLSnippetsController sharedInstance] snippetsTableView] || self == [SMLCurrentProject documentsTableView]) {
	
		unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
		NSInteger keyCode = [event keyCode];
		NSUInteger flags = ([event modifierFlags] & 0x00FF);
		
		if ((key == NSDeleteCharacter || keyCode == 0x75) && flags == 0) { // 0x75 is forward delete 
			if ([self selectedRow] == -1) {
				NSBeep();
			} else {
				
				// Snippet collection
				if (self == [[SMLSnippetsController sharedInstance] snippetCollectionsTableView]) {
					
					id collection = [[[[SMLSnippetsController sharedInstance] snippetCollectionsArrayController] selectedObjects] objectAtIndex:0];
					NSMutableSet *snippetsToDelete = [collection mutableSetValueForKey:@"snippets"];
					if ([snippetsToDelete count] == 0) {
						[[SMLSnippetsController sharedInstance] performDeleteCollection];
					} else {
						NSString *title = [NSString stringWithFormat:WILL_DELETE_ALL_ITEMS_IN_COLLECTION, [collection valueForKey:@"name"]];
						NSBeginAlertSheet(title,
										  DELETE_BUTTON,
										  nil,
										  CANCEL_BUTTON,
										  [[SMLSnippetsController sharedInstance] snippetsWindow],
										  self,
										  nil,
										  @selector(snippetSheetDidDismiss:returnCode:contextInfo:),
										  nil,
										  NSLocalizedString(@"Please consider exporting the snippets first. There is no undo available.", @"Please consider exporting the snippets first. There is no undo available. when deleting a collection"));
					}
					[[SMLToolsMenuController sharedInstance] buildInsertSnippetMenu];
					
				// Snippet
				} else if (self == [[SMLSnippetsController sharedInstance] snippetsTableView]) {
					
					id snippet = [[[[SMLSnippetsController sharedInstance] snippetsArrayController] selectedObjects] objectAtIndex:0];
					[[[SMLSnippetsController sharedInstance] snippetsArrayController] removeObject:snippet];
					[[SMLToolsMenuController sharedInstance] buildInsertSnippetMenu];
					
				// Command collection
				} else if (self == [[SMLCommandsController sharedInstance] commandCollectionsTableView]) {
					
					id collection = [[[[SMLCommandsController sharedInstance] commandCollectionsArrayController] selectedObjects] objectAtIndex:0];
					NSMutableSet *commandsToDelete = [collection mutableSetValueForKey:@"commands"];
					if ([commandsToDelete count] == 0) {
						[[SMLCommandsController sharedInstance] performDeleteCollection];
					} else {
						NSString *title = [NSString stringWithFormat:WILL_DELETE_ALL_ITEMS_IN_COLLECTION, [collection valueForKey:@"name"]];
						NSBeginAlertSheet(title,
										  DELETE_BUTTON,
										  nil,
										  CANCEL_BUTTON,
										  [[SMLCommandsController sharedInstance] commandsWindow],
										  self,
										  nil,
										  @selector(commandSheetDidDismiss:returnCode:contextInfo:),
										  nil,
										  NSLocalizedStringFromTable(@"Please consider exporting the commands first. There is no undo available", @"Localizable3", @"Please consider exporting the commands first. There is no undo available"));
					}
					[[SMLToolsMenuController sharedInstance] buildRunCommandMenu];
				
				// Command
				} else if (self == [[SMLCommandsController sharedInstance] commandsTableView]) {
					
					id command = [[[[SMLCommandsController sharedInstance] commandsArrayController] selectedObjects] objectAtIndex:0];
					[[[SMLCommandsController sharedInstance] commandsArrayController] removeObject:command];
					[[SMLToolsMenuController sharedInstance] buildRunCommandMenu];
				
				// Document
				} else if (self == [SMLCurrentProject documentsTableView]) {
					id document = [[[SMLCurrentProject documentsArrayController] selectedObjects] objectAtIndex:0];
					[SMLCurrentProject checkIfDocumentIsUnsaved:document keepOpen:NO];
				}
			}
		}
		
	} else {
		[super keyDown:event];
	}
}


- (void)snippetSheetDidDismiss:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
	[sheet close];
	
	if (returnCode == NSAlertDefaultReturn) {
		[[SMLSnippetsController sharedInstance] performDeleteCollection];
		
	}
}


- (void)commandSheetDidDismiss:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
	[sheet close];
	
	if (returnCode == NSAlertDefaultReturn) {
		[[SMLCommandsController sharedInstance] performDeleteCollection];
	}
}


- (void)textDidEndEditing:(NSNotification *)aNotification
{
	if ([[[aNotification userInfo] objectForKey:@"NSTextMovement"] integerValue] == NSReturnTextMovement) {
		[[self window] endEditingFor:self];
		[self reloadData];
		[[self window] makeFirstResponder:self];
	} else {
		[super textDidEndEditing:aNotification];
	}
}

@end
