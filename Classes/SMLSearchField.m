/*
Smultron version 3.6b1, 2009-09-12
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://smultron.sourceforge.net

Copyright 2004-2009 Peter Borg

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "SMLStandardHeader.h"

#import "SMLSearchField.h"
#import "SMLProjectsController.h"
#import "SMLProject.h"


@implementation SMLSearchField

- (BOOL)performKeyEquivalent:(NSEvent *)anEvent
{
	NSUInteger flags = [anEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
	unsigned short keyCode = [anEvent keyCode];
	
	if (flags == 1048576 && keyCode == 5) { // Command-G
		NSToolbarItem *dummyToolbarItem = [[NSToolbarItem alloc] init];
		[dummyToolbarItem setTag:NSFindPanelActionNext];
		[[SMLCurrentProject lastTextViewInFocus] performFindPanelAction:dummyToolbarItem];
		
		return YES;
	} else if (flags == 1179648 && keyCode == 5) { // Command-Shift-G
		NSToolbarItem *dummyToolbarItem = [[NSToolbarItem alloc] init];
		[dummyToolbarItem setTag:NSFindPanelActionPrevious];
		[[SMLCurrentProject lastTextViewInFocus] performFindPanelAction:dummyToolbarItem];
		
		return YES;
	} else {
		[super performKeyEquivalent:anEvent];
		
		return NO;
	}
}
@end
