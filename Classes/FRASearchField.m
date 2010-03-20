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

#import "FRASearchField.h"
#import "FRAProjectsController.h"
#import "FRAProject.h"


@implementation FRASearchField

- (BOOL)performKeyEquivalent:(NSEvent *)anEvent
{
	NSUInteger flags = [anEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
	unsigned short keyCode = [anEvent keyCode];
	
	if (flags == 1048576 && keyCode == 5) { // Command-G
		NSToolbarItem *dummyToolbarItem = [[NSToolbarItem alloc] init];
		[dummyToolbarItem setTag:NSFindPanelActionNext];
		[[FRACurrentProject lastTextViewInFocus] performFindPanelAction:dummyToolbarItem];
		
		return YES;
	} else if (flags == 1179648 && keyCode == 5) { // Command-Shift-G
		NSToolbarItem *dummyToolbarItem = [[NSToolbarItem alloc] init];
		[dummyToolbarItem setTag:NSFindPanelActionPrevious];
		[[FRACurrentProject lastTextViewInFocus] performFindPanelAction:dummyToolbarItem];
		
		return YES;
	} else {
		[super performKeyEquivalent:anEvent];
		
		return NO;
	}
}
@end
