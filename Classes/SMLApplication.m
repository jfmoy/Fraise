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

#import "SMLApplication.H"
#import "SMLProjectsController.h"
#import "SMLTextView.h"
#import "SMLApplicationDelegate.h"
#import "SMLDocumentsMenuController.h"
#import "SMLTextMenuController.h"
#import "SMLInterfacePerformer.h"
#import "SMLMainController.h"
#import "SMLFullScreenWindow.h"
#import "SMLSnippetsController.h"
#import "SMLShortcutsController.h"
#import "SMLCommandsController.h"
#import "SMLLineNumbers.h"
#import "SMLProject.h"
#import "SMLProject+ToolbarController.h"
#import "SMLSearchField.h"

@implementation SMLApplication

- (void)awakeFromNib
{
	textViewClass = [SMLTextView class];
	
	[self setDelegate:[SMLApplicationDelegate sharedInstance]];
}


- (void)sendEvent:(NSEvent *)event
{
	if ([event type] == NSKeyDown) {
		eventWindow = [event window];
		if (eventWindow == SMLCurrentWindow) {
			flags = [event modifierFlags] & NSDeviceIndependentModifierFlagsMask;
			
			if (flags == 1703936) { // Command, Option, Shift
				keyCode = [event keyCode];
				if (keyCode == 3) { // 3 is F
					if ([[SMLCurrentProject projectWindowToolbar] isVisible] && [[SMLCurrentProject projectWindowToolbar] displayMode] != NSToolbarDisplayModeLabelOnly) {
						NSArray *array = [[SMLCurrentProject projectWindowToolbar] visibleItems];
						for (id item in array) {
							if ([[item itemIdentifier] isEqualToString:@"FunctionToolbarItem"]) {
								[SMLCurrentProject functionToolbarItemAction:[SMLCurrentProject functionButton]];
								return;
							}
						}
						
					}
				}
			} else if (flags == 12058624) { // Command, Option
				keyCode = [event keyCode];
				if (keyCode == 124) { // 124 is right arrow
					if ([[SMLCurrentProject documents] count] > 1) {
						[[SMLDocumentsMenuController sharedInstance] nextDocumentAction:nil];
						return;
					}
				} else if (keyCode == 123) { // 123 is left arrow
					if ([[SMLCurrentProject documents] count] > 1) {
						[[SMLDocumentsMenuController sharedInstance] previousDocumentAction:nil];
						return;
					}
				}
			} else if (flags == 131072) { // Shift
				keyCode = [event keyCode];
				if (keyCode == 48) { // 48 is Tab
					if (SMLCurrentTextView != nil) {
						[[SMLTextMenuController sharedInstance] shiftLeftAction:nil];
						return;
					}
				}
			} else if (flags == 1048576 || flags == 3145728 || flags == 1179648) { // Command, command with a numerical key and command with shift for the keyboards that requires it 
				character = [event charactersIgnoringModifiers];
				if ([character isEqualToString:@"+"] || [character isEqualToString:@"="]) {
					NSFont *oldFont = [NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:@"TextFont"]];
					CGFloat size = [oldFont pointSize] + 1;
					[SMLDefaults setValue:[NSArchiver archivedDataWithRootObject:[NSFont fontWithName:[oldFont fontName] size:size]] forKey:@"TextFont"];
					return;
				} else if ([character isEqualToString:@"-"]) {
					NSFont *oldFont = [NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:@"TextFont"]];
					CGFloat size = [oldFont pointSize];
					if (size > 4) {
						size--;
						[SMLDefaults setValue:[NSArchiver archivedDataWithRootObject:[NSFont fontWithName:[oldFont fontName] size:size]] forKey:@"TextFont"];
						return;
					}
				}
			}
			
			
		} else if (eventWindow == [SMLInterface fullScreenWindow]) {
			if ([SMLMain isInFullScreenMode]) {
				flags = [event modifierFlags] & NSDeviceIndependentModifierFlagsMask;
				keyCode = [event keyCode];
				if (keyCode == 0x35 && flags == 0) { // 35 is Escape,
					[(SMLFullScreenWindow *)[SMLInterface fullScreenWindow] returnFromFullScreen];
					return;
				} else if (keyCode == 0x07 && flags == 1048576) { // 07 is X, 1048576 is Command
					[(NSTextView *)[[SMLInterface fullScreenWindow] firstResponder] cut:nil];
					return;
				} else if (keyCode == 0x08 && flags == 1048576) { // 08 is C
					[(NSTextView *)[[SMLInterface fullScreenWindow] firstResponder] copy:nil];
					return;
				} else if (keyCode == 0x09 && flags == 1048576) { // 09 is V
					[(NSTextView *)[[SMLInterface fullScreenWindow] firstResponder] paste:nil];
					return;
				} else if (keyCode == 0x06 && flags == 1048576) { // 06 is Z
					[[(NSTextView *)[[SMLInterface fullScreenWindow] firstResponder] undoManager] undo];
					return;
				}
			}
			
			
		} else if (eventWindow == [[SMLSnippetsController sharedInstance] snippetsWindow]) {
			NSInteger editedColumn = [[[SMLSnippetsController sharedInstance] snippetsTableView] editedColumn];
			if (editedColumn != -1) {
				NSTableColumn *tableColumn = [[[[SMLSnippetsController sharedInstance] snippetsTableView] tableColumns] objectAtIndex:editedColumn];
				
				if ([[tableColumn identifier] isEqualToString:@"shortcut"]) {
					key = [[event charactersIgnoringModifiers] characterAtIndex:0];
					keyCode = [event keyCode];
					if (keyCode == 0x35) { // If the user cancels by pressing Escape don't insert a hot key
						[[[SMLSnippetsController sharedInstance] snippetsWindow] makeFirstResponder:[[SMLSnippetsController sharedInstance] snippetsTableView]];
						return;
					} else if (keyCode == 0x30) { // Tab
						[[[SMLSnippetsController sharedInstance] snippetsWindow] makeFirstResponder:[[SMLSnippetsController sharedInstance] snippetsTextView]];
						return;
					} else {
						flags = ([event modifierFlags] & 0x00FF);
						if ((key == NSDeleteCharacter || keyCode == 0x75) && flags == 0) { // 0x75 is forward delete 
							[[SMLShortcutsController sharedInstance] unregisterSelectedSnippetShortcut];
						} else {
							[[SMLShortcutsController sharedInstance] registerSnippetShortcutWithEvent:event];
						}
						[[[SMLSnippetsController sharedInstance] snippetsWindow] makeFirstResponder:[[SMLSnippetsController sharedInstance] snippetsTableView]];
						return;
					}
				}
			}
			
			
		} else if (eventWindow == [[SMLCommandsController sharedInstance] commandsWindow]) {
			NSInteger editedColumn = [[[SMLCommandsController sharedInstance] commandsTableView] editedColumn];
			if (editedColumn != -1) {
				NSTableColumn *tableColumn = [[[[SMLCommandsController sharedInstance] commandsTableView] tableColumns] objectAtIndex:editedColumn];
				
				if ([[tableColumn identifier] isEqualToString:@"shortcut"]) {
					key = [[event charactersIgnoringModifiers] characterAtIndex:0];
					keyCode = [event keyCode];

					if (keyCode == 0x35) { // If the user cancels by pressing Escape don't insert a hot key
						[[[SMLCommandsController sharedInstance] commandsWindow] makeFirstResponder:[[SMLCommandsController sharedInstance] commandsTableView]];
						return;
					} else if (keyCode == 0x30) { // Tab
						[[[SMLCommandsController sharedInstance] commandsWindow] makeFirstResponder:[[SMLCommandsController sharedInstance] commandsTextView]];
						return;
					} else {
						flags = ([event modifierFlags] & 0x00FF);
						if ((key == NSDeleteCharacter || keyCode == 0x75) && flags == 0) { // 0x75 is forward delete 
							[[SMLShortcutsController sharedInstance] unregisterSelectedCommandShortcut];
						} else {
							[[SMLShortcutsController sharedInstance] registerCommandShortcutWithEvent:event];
						}

						[[[SMLCommandsController sharedInstance] commandsWindow] makeFirstResponder:[[SMLCommandsController sharedInstance] commandsTableView]];
						return;
					}
				}
			}
		}
	}
	[super sendEvent:event];
}


// See -[SMLTextView complete:]
- (NSEvent *)nextEventMatchingMask:(NSUInteger)eventMask untilDate:(NSDate *)expirationDate inMode:(NSString *)runLoopMode dequeue:(BOOL)dequeue
{
	if ([runLoopMode isEqualToString:NSEventTrackingRunLoopMode]) {
		if ([SMLCurrentTextView inCompleteMethod]) eventMask &= ~NSAppKitDefinedMask;
	}
	
	return [super nextEventMatchingMask:eventMask untilDate:expirationDate inMode:runLoopMode dequeue:dequeue];
}


#pragma mark
#pragma mark AppleScript
- (NSString *)name
{
	return [SMLCurrentDocument valueForKey:@"name"];
}


- (NSString *)path
{
	return [SMLCurrentDocument valueForKey:@"path"]; 
}


- (NSString *)content
{
    return [[SMLCurrentDocument valueForKey:@"firstTextView"] string]; 
}


- (void)setContent:(NSString *)newContent
{
	SMLTextView *textView = [SMLCurrentDocument valueForKey:@"firstTextView"];
	if ([textView shouldChangeTextInRange:NSMakeRange(0, [[textView string] length]) replacementString:newContent]) { // Do it this way to mark it as an Undo
		[textView replaceCharactersInRange:NSMakeRange(0, [[textView string] length]) withString:newContent];
		[textView didChangeText];
	}
    [[SMLCurrentDocument valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth:YES recolour:YES];
}


- (BOOL)edited
{
    return [[SMLCurrentDocument valueForKey:@"isEdited"] boolValue];
}


- (BOOL)smartInsertDelete
{
	return [[SMLDefaults valueForKey:@"SmartInsertDelete"] boolValue];
}


- (void)setSmartInsertDelete:(BOOL)flag
{
	[SMLDefaults setValue:[NSNumber numberWithBool:flag] forKey:@"SmartInsertDelete"];
}

@end
