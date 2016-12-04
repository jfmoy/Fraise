/*
 Fraise version 3.7 - Based on Smultron by Peter Borg
 
 Current Maintainer (2016): 
 Andreas Bentele: abentele.github@icloud.com (https://github.com/abentele/Fraise)
 
 Maintainer before macOS Sierra (2010-2016): 
 Jean-François Moy: jeanfrancois.moy@gmail.com (http://github.com/jfmoy/Fraise)

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "FRATableView.h"
#import "FRASnippetsController.h"
#import "FRACommandsController.h"
#import "FRAToolsMenuController.h"
#import "FRAProjectsController.h"
#import "FRAProject.h"


@implementation FRATableView




- (void)keyDown:(NSEvent *)event
{
	if (self == [[FRACommandsController sharedInstance] commandCollectionsTableView] || self == [[FRACommandsController sharedInstance] commandsTableView] || self == [[FRASnippetsController sharedInstance] snippetCollectionsTableView] || self == [[FRASnippetsController sharedInstance] snippetsTableView] || self == [FRACurrentProject documentsTableView]) {
	
		unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
		NSInteger keyCode = [event keyCode];
		NSUInteger flags = ([event modifierFlags] & 0x00FF);
		
		if ((key == NSDeleteCharacter || keyCode == 0x75) && flags == 0) { // 0x75 is forward delete 
			if ([self selectedRow] == -1) {
				NSBeep();
			} else {
				
				// Snippet collection
				if (self == [[FRASnippetsController sharedInstance] snippetCollectionsTableView]) {
					
					id collection = [[[FRASnippetsController sharedInstance] snippetCollectionsArrayController] selectedObjects][0];
					NSMutableSet *snippetsToDelete = [collection mutableSetValueForKey:@"snippets"];
					if ([snippetsToDelete count] == 0) {
						[[FRASnippetsController sharedInstance] performDeleteCollection];
					} else {
						NSString *title = [NSString stringWithFormat:WILL_DELETE_ALL_ITEMS_IN_COLLECTION, [collection valueForKey:@"name"]];
                        
                        NSAlert* alert = [[NSAlert alloc] init];
                        [alert setMessageText:title];
                        [alert setInformativeText:NSLocalizedString(@"Please consider exporting the snippets first. There is no undo available.", @"Please consider exporting the snippets first. There is no undo available. when deleting a collection")];
                        [alert addButtonWithTitle:DELETE_BUTTON];
                        [alert addButtonWithTitle:CANCEL_BUTTON];
                        [alert setAlertStyle:NSAlertStyleInformational];
                        
                        [alert beginSheetModalForWindow:[[FRASnippetsController sharedInstance] snippetsWindow] completionHandler:^(NSInteger returnCode) {
                            if (returnCode == NSAlertFirstButtonReturn) {
                                [[FRASnippetsController sharedInstance] performDeleteCollection];
                            }
                        }];
					}
					[[FRAToolsMenuController sharedInstance] buildInsertSnippetMenu];
					
				// Snippet
				} else if (self == [[FRASnippetsController sharedInstance] snippetsTableView]) {
					
					id snippet = [[[FRASnippetsController sharedInstance] snippetsArrayController] selectedObjects][0];
					[[[FRASnippetsController sharedInstance] snippetsArrayController] removeObject:snippet];
					[[FRAToolsMenuController sharedInstance] buildInsertSnippetMenu];
					
				// Command collection
				} else if (self == [[FRACommandsController sharedInstance] commandCollectionsTableView]) {
					
					id collection = [[[FRACommandsController sharedInstance] commandCollectionsArrayController] selectedObjects][0];
					NSMutableSet *commandsToDelete = [collection mutableSetValueForKey:@"commands"];
					if ([commandsToDelete count] == 0) {
						[[FRACommandsController sharedInstance] performDeleteCollection];
					} else {
						NSString *title = [NSString stringWithFormat:WILL_DELETE_ALL_ITEMS_IN_COLLECTION, [collection valueForKey:@"name"]];
                        
                        NSAlert* alert = [[NSAlert alloc] init];
                        [alert setMessageText:title];
                        [alert setInformativeText:NSLocalizedStringFromTable(@"Please consider exporting the commands first. There is no undo available", @"Localizable3", @"Please consider exporting the commands first. There is no undo available")];
                        [alert addButtonWithTitle:DELETE_BUTTON];
                        [alert addButtonWithTitle:CANCEL_BUTTON];
                        [alert setAlertStyle:NSAlertStyleInformational];
                        
                        [alert beginSheetModalForWindow:[[FRACommandsController sharedInstance] commandsWindow] completionHandler:^(NSInteger returnCode) {
                            if (returnCode == NSAlertFirstButtonReturn) {
                                [[FRACommandsController sharedInstance] performDeleteCollection];
                            }
                        }];
					}
					[[FRAToolsMenuController sharedInstance] buildRunCommandMenu];
				
				// Command
				} else if (self == [[FRACommandsController sharedInstance] commandsTableView]) {
					
					id command = [[[FRACommandsController sharedInstance] commandsArrayController] selectedObjects][0];
					[[[FRACommandsController sharedInstance] commandsArrayController] removeObject:command];
					[[FRAToolsMenuController sharedInstance] buildRunCommandMenu];
				
				// Document
				} else if (self == [FRACurrentProject documentsTableView]) {
					id document = [[FRACurrentProject documentsArrayController] selectedObjects][0];
					[FRACurrentProject checkIfDocumentIsUnsaved:document keepOpen:NO];
				}
			}
		}
		
	} else {
		[super keyDown:event];
	}
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
	if ([[aNotification userInfo][@"NSTextMovement"] integerValue] == NSReturnTextMovement) {
		[[self window] endEditingFor:self];
		[self reloadData];
		[[self window] makeFirstResponder:self];
	} else {
		[super textDidEndEditing:aNotification];
	}
}

@end
