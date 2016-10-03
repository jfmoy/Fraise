/*
Fraise version 3.7 - Based on Smultron by Peter Borg
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Fraise

Copyright 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "FRAStandardHeader.h"

#import "FRAApplication.H"
#import "FRAProjectsController.h"
#import "FRATextView.h"
#import "FRAApplicationDelegate.h"
#import "FRADocumentsMenuController.h"
#import "FRATextMenuController.h"
#import "FRAInterfacePerformer.h"
#import "FRAMainController.h"
#import "FRAFullScreenWindow.h"
#import "FRASnippetsController.h"
#import "FRAShortcutsController.h"
#import "FRACommandsController.h"
#import "FRALineNumbers.h"
#import "FRAProject.h"
#import "FRAProject+ToolbarController.h"
#import "FRASearchField.h"

@implementation FRAApplication

- (void)awakeFromNib
{
	textViewClass = [FRATextView class];
	
	[self setDelegate:[FRAApplicationDelegate sharedInstance]];
}


- (void)sendEvent:(NSEvent *)event
{
	if ([event type] == NSEventTypeKeyDown) {
		eventWindow = [event window];
		if (eventWindow == FRACurrentWindow) {
			flags = [event modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask;
			
			if (flags == 1703936) { // Command, Option, Shift
				keyCode = [event keyCode];
				if (keyCode == 3) { // 3 is F
					if ([[FRACurrentProject projectWindowToolbar] isVisible] && [[FRACurrentProject projectWindowToolbar] displayMode] != NSToolbarDisplayModeLabelOnly) {
						NSArray *array = [[FRACurrentProject projectWindowToolbar] visibleItems];
						for (id item in array) {
							if ([[item itemIdentifier] isEqualToString:@"FunctionToolbarItem"]) {
								[FRACurrentProject functionToolbarItemAction:[FRACurrentProject functionButton]];
								return;
							}
						}
						
					}
				}
			} else if (flags == 12058624) { // Command, Option
				keyCode = [event keyCode];
				if (keyCode == 124) { // 124 is right arrow
					if ([[FRACurrentProject documents] count] > 1) {
						[[FRADocumentsMenuController sharedInstance] nextDocumentAction:nil];
						return;
					}
				} else if (keyCode == 123) { // 123 is left arrow
					if ([[FRACurrentProject documents] count] > 1) {
						[[FRADocumentsMenuController sharedInstance] previousDocumentAction:nil];
						return;
					}
				}
			} else if (flags == 131072) { // Shift
				keyCode = [event keyCode];
				if (keyCode == 48) { // 48 is Tab
					if (FRACurrentTextView != nil) {
						[[FRATextMenuController sharedInstance] shiftLeftAction:nil];
						return;
					}
				}
			} else if (flags == 1048576 || flags == 3145728 || flags == 1179648) { // Command, command with a numerical key and command with shift for the keyboards that requires it 
				character = [event charactersIgnoringModifiers];
				if ([character isEqualToString:@"+"] || [character isEqualToString:@"="]) {
					NSFont *oldFont = [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]];
					CGFloat size = [oldFont pointSize] + 1;
					[FRADefaults setValue:[NSArchiver archivedDataWithRootObject:[NSFont fontWithName:[oldFont fontName] size:size]] forKey:@"TextFont"];
					return;
				} else if ([character isEqualToString:@"-"]) {
					NSFont *oldFont = [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]];
					CGFloat size = [oldFont pointSize];
					if (size > 4) {
						size--;
						[FRADefaults setValue:[NSArchiver archivedDataWithRootObject:[NSFont fontWithName:[oldFont fontName] size:size]] forKey:@"TextFont"];
						return;
					}
				}
			}
			
			
		} else if (eventWindow == [FRAInterface fullScreenWindow]) {
			if ([FRAMain isInFullScreenMode]) {
				flags = [event modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask;
				keyCode = [event keyCode];
				if (keyCode == 0x35 && flags == 0) { // 35 is Escape,
					[(FRAFullScreenWindow *)[FRAInterface fullScreenWindow] returnFromFullScreen];
					return;
				} else if (keyCode == 0x07 && flags == 1048576) { // 07 is X, 1048576 is Command
					[(NSTextView *)[[FRAInterface fullScreenWindow] firstResponder] cut:nil];
					return;
				} else if (keyCode == 0x08 && flags == 1048576) { // 08 is C
					[(NSTextView *)[[FRAInterface fullScreenWindow] firstResponder] copy:nil];
					return;
				} else if (keyCode == 0x09 && flags == 1048576) { // 09 is V
					[(NSTextView *)[[FRAInterface fullScreenWindow] firstResponder] paste:nil];
					return;
				} else if (keyCode == 0x06 && flags == 1048576) { // 06 is Z
					[[(NSTextView *)[[FRAInterface fullScreenWindow] firstResponder] undoManager] undo];
					return;
				}
			}
			
			
		} else if (eventWindow == [[FRASnippetsController sharedInstance] snippetsWindow]) {
			NSInteger editedColumn = [[[FRASnippetsController sharedInstance] snippetsTableView] editedColumn];
			if (editedColumn != -1) {
				NSTableColumn *tableColumn = [[[FRASnippetsController sharedInstance] snippetsTableView] tableColumns][editedColumn];
				
				if ([[tableColumn identifier] isEqualToString:@"shortcut"]) {
					key = [[event charactersIgnoringModifiers] characterAtIndex:0];
					keyCode = [event keyCode];
					if (keyCode == 0x35) { // If the user cancels by pressing Escape don't insert a hot key
						[[[FRASnippetsController sharedInstance] snippetsWindow] makeFirstResponder:[[FRASnippetsController sharedInstance] snippetsTableView]];
						return;
					} else if (keyCode == 0x30) { // Tab
						[[[FRASnippetsController sharedInstance] snippetsWindow] makeFirstResponder:[[FRASnippetsController sharedInstance] snippetsTextView]];
						return;
					} else {
						flags = ([event modifierFlags] & 0x00FF);
						if ((key == NSDeleteCharacter || keyCode == 0x75) && flags == 0) { // 0x75 is forward delete 
							[[FRAShortcutsController sharedInstance] unregisterSelectedSnippetShortcut];
						} else {
							[[FRAShortcutsController sharedInstance] registerSnippetShortcutWithEvent:event];
						}
						[[[FRASnippetsController sharedInstance] snippetsWindow] makeFirstResponder:[[FRASnippetsController sharedInstance] snippetsTableView]];
						return;
					}
				}
			}
			
			
		} else if (eventWindow == [[FRACommandsController sharedInstance] commandsWindow]) {
			NSInteger editedColumn = [[[FRACommandsController sharedInstance] commandsTableView] editedColumn];
			if (editedColumn != -1) {
				NSTableColumn *tableColumn = [[[FRACommandsController sharedInstance] commandsTableView] tableColumns][editedColumn];
				
				if ([[tableColumn identifier] isEqualToString:@"shortcut"]) {
					key = [[event charactersIgnoringModifiers] characterAtIndex:0];
					keyCode = [event keyCode];

					if (keyCode == 0x35) { // If the user cancels by pressing Escape don't insert a hot key
						[[[FRACommandsController sharedInstance] commandsWindow] makeFirstResponder:[[FRACommandsController sharedInstance] commandsTableView]];
						return;
					} else if (keyCode == 0x30) { // Tab
						[[[FRACommandsController sharedInstance] commandsWindow] makeFirstResponder:[[FRACommandsController sharedInstance] commandsTextView]];
						return;
					} else {
						flags = ([event modifierFlags] & 0x00FF);
						if ((key == NSDeleteCharacter || keyCode == 0x75) && flags == 0) { // 0x75 is forward delete 
							[[FRAShortcutsController sharedInstance] unregisterSelectedCommandShortcut];
						} else {
							[[FRAShortcutsController sharedInstance] registerCommandShortcutWithEvent:event];
						}

						[[[FRACommandsController sharedInstance] commandsWindow] makeFirstResponder:[[FRACommandsController sharedInstance] commandsTableView]];
						return;
					}
				}
			}
		}
	}
	[super sendEvent:event];
}


// See -[FRATextView complete:]
- (NSEvent *)nextEventMatchingMask:(NSUInteger)eventMask untilDate:(NSDate *)expirationDate inMode:(NSString *)runLoopMode dequeue:(BOOL)dequeue
{
	if ([runLoopMode isEqualToString:NSEventTrackingRunLoopMode]) {
		if ([FRACurrentTextView inCompleteMethod]) eventMask &= ~NSEventMaskAppKitDefined;
	}
	
	return [super nextEventMatchingMask:eventMask untilDate:expirationDate inMode:runLoopMode dequeue:dequeue];
}


#pragma mark
#pragma mark AppleScript
- (NSString *)name
{
	return [FRACurrentDocument valueForKey:@"name"];
}


- (NSString *)path
{
	return [FRACurrentDocument valueForKey:@"path"]; 
}


- (NSString *)content
{
    return [[FRACurrentDocument valueForKey:@"firstTextView"] string]; 
}


- (void)setContent:(NSString *)newContent
{
	FRATextView *textView = [FRACurrentDocument valueForKey:@"firstTextView"];
	if ([textView shouldChangeTextInRange:NSMakeRange(0, [[textView string] length]) replacementString:newContent]) { // Do it this way to mark it as an Undo
		[textView replaceCharactersInRange:NSMakeRange(0, [[textView string] length]) withString:newContent];
		[textView didChangeText];
	}
    [[FRACurrentDocument valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth:YES recolour:YES];
}


- (BOOL)edited
{
    return [[FRACurrentDocument valueForKey:@"isEdited"] boolValue];
}


- (BOOL)smartInsertDelete
{
	return [[FRADefaults valueForKey:@"SmartInsertDelete"] boolValue];
}


- (void)setSmartInsertDelete:(BOOL)flag
{
	[FRADefaults setValue:@(flag) forKey:@"SmartInsertDelete"];
}

@end
