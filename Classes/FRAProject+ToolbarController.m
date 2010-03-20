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

#import "FRAProject+ToolbarController.h"

#import "NSToolbarItem+Fraise.h"
#import "FRAFileMenuController.h"
#import "FRAPreferencesController.h"
#import "FRAAdvancedFindController.h"
#import "FRAInfoController.h"
#import "FRAProjectsController.h"
#import "FRAToolsMenuController.h"
#import "FRAViewMenuController.h"
#import "FRAApplicationDelegate.h"
#import "FRABasicPerformer.h"
#import "FRAInterfacePerformer.h"
#import "FRATextView.h"


@implementation FRAProject (ToolbarController)


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:@"SaveDocumentToolbarItem",
		@"OpenDocumentToolbarItem",
		@"NewDocumentToolbarItem",
		@"CloseDocumentToolbarItem",
		@"QuicklyFindNextToolbarItem",
		@"AdvancedFindToolbarItem",
		@"PreviewToolbarItem",
		@"FunctionToolbarItem",
		@"InfoToolbarItem",
		NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarSeparatorItemIdentifier,
		nil];
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar  
{      
	return [NSArray arrayWithObjects:@"NewDocumentToolbarItem",
		@"OpenDocumentToolbarItem",
		@"SaveDocumentToolbarItem",
		@"CloseDocumentToolbarItem",
		NSToolbarFlexibleSpaceItemIdentifier,
		@"QuicklyFindNextToolbarItem",
		@"AdvancedFindToolbarItem",
		NSToolbarFlexibleSpaceItemIdentifier,
		@"InfoToolbarItem",
		nil];  
} 


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)willBeInserted
{
    if ([itemIdentifier isEqualToString:@"SaveDocumentToolbarItem"]) {
        
		saveToolbarItem = [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:SAVE_STRING image:saveImage action:@selector(save:) tag:0 target:self];
		return saveToolbarItem;

		
	} else if ([itemIdentifier isEqualToString:@"OpenDocumentToolbarItem"]) {
        
		return [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedString(@"Open", @"Open") image:openDocumentImage action:@selector(open:) tag:1 target:self];
		
		
	} else if ([itemIdentifier isEqualToString:@"NewDocumentToolbarItem"]) {
        
		return [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedString(@"New", @"New") image:newImage action:@selector(new:) tag:1 target:self];
		
		
	} else if ([itemIdentifier isEqualToString:@"CloseDocumentToolbarItem"]) {
        
		closeToolbarItem = [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedString(@"Close", @"Close") image:closeImage action:@selector(close:) tag:0 target:self];
		return closeToolbarItem;
		
		
//	} else if ([itemIdentifier isEqualToString:@"PreferencesToolbarItem"]) {
//        
//		return [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedString(@"Preferences", @"Preferences") image:preferencesImage action:@selector(preferences:) tag:1 target:self];
//		
		
	} else if ([itemIdentifier isEqualToString:@"QuicklyFindNextToolbarItem"]) {
		
		return [NSToolbarItem createSeachFieldToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedString(@"Live Find", @"Live Find") view:liveFindSearchField];
	
		
	} else if ([itemIdentifier isEqualToString:@"AdvancedFindToolbarItem"]) {
        
		advancedFindToolbarItem = [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedString(@"Advanced Find", @"Advanced Find") image:advancedFindImage action:@selector(advancedFind:) tag:0 target:self];
		return advancedFindToolbarItem;
		
		
	} else if ([itemIdentifier isEqualToString:@"PreviewToolbarItem"]) {
        
		previewToolbarItem = [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:PREVIEW_STRING image:previewImage action:@selector(preview:) tag:0 target:self];
		return previewToolbarItem;

	
	} else if ([itemIdentifier isEqualToString:@"InfoToolbarItem"]) {
        
		infoToolbarItem = [NSToolbarItem createToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedString(@"Info", @"Info") image:infoImage action:@selector(info:) tag:0 target:self];
		return infoToolbarItem;
		
	
	} else if ([itemIdentifier isEqualToString:@"FunctionToolbarItem"]) {
		functionToolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
		
		NSRect toolbarItemRect = NSMakeRect(0.0, 0.0, 38.0, 27.0);
		
		NSView *view = [[NSView alloc] initWithFrame:toolbarItemRect];
		functionButton = [[NSButton alloc] initWithFrame:toolbarItemRect];
		[functionButton setBezelStyle:NSTexturedRoundedBezelStyle];
		[functionButton setTitle:@""];
		[functionButton setImage:functionImage];
		[functionButton setTarget:self];
		[functionButton setAction:@selector(functionToolbarItemAction:)];
		//[[functionButton cell] setImageScaling:NSImageScaleProportionallyDown];
		[functionButton setImagePosition:NSImageOnly];
		
		[functionToolbarItem setLabel:FUNCTION_STRING];
		[functionToolbarItem setPaletteLabel:FUNCTION_STRING];
		[functionToolbarItem setToolTip:FUNCTION_STRING];
		
		[view addSubview:functionButton];
		
		[functionToolbarItem setView:view];
		
//		[functionToolbarItem setLabel:FUNCTION_STRING];
//		[functionToolbarItem setToolTip:FUNCTION_STRING];
//		[functionToolbarItem setPaletteLabel:FUNCTION_STRING];
//		[functionToolbarItem setView:functionButton];
//		[functionToolbarItem setMinSize:NSMakeSize(32.0, 32.0)];
//		[functionToolbarItem setMaxSize:NSMakeSize(32.0, 32.0)];
//		[functionButton setImage:functionImage];
		
		menuFormRepresentation = [[NSMenuItem alloc] init];
		NSMenu *functionTextOnlyMenu = [[NSMenu alloc] initWithTitle:@""];
		[functionTextOnlyMenu setDelegate:self];
		[menuFormRepresentation setSubmenu:functionTextOnlyMenu];
		[menuFormRepresentation setTitle:FUNCTION_STRING];
		[functionToolbarItem setMenuFormRepresentation:menuFormRepresentation];
		
		return functionToolbarItem;
		
		
//	} else if ([itemIdentifier isEqualToString:@"SplitWindowToolbarItem"]) {
//		NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
//		[toolbarItem setLabel:SPLIT_WINDOW_STRING];
//		[toolbarItem setToolTip:SPLIT_WINDOW_STRING];
//		[toolbarItem setImage:splitWindowImage];
//		[toolbarItem setPaletteLabel:NSLocalizedString(@"Split Window / Close Split", @"Split Window / Close Split toolbar item Palette Label")];
//		[toolbarItem setTarget:self];
//		[toolbarItem setAction:@selector(splitWindow:)];
//		
//		return toolbarItem;
//		
//		
//	} else if ([itemIdentifier isEqual:@"LineWrapToolbarItem"]) {
//		NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
//		if ([[FRADefaults valueForKey:@"LineWrapNewDocuments"] boolValue] == NO) {
//			[toolbarItem setLabel:LINE_WRAP_STRING];
//			[toolbarItem setToolTip:LINE_WRAP_STRING];
//			[toolbarItem setImage:lineWrapImage];
//		} else {
//			[toolbarItem setLabel:DONT_LINE_WRAP_STRING];
//			[toolbarItem setToolTip:DONT_LINE_WRAP_STRING];
//			[toolbarItem setImage:dontLineWrapImage];
//		}
//        [toolbarItem setPaletteLabel:NSLocalizedString(@"Line Wrap / Don't Line Wrap",@"Line Wrap / Don't Line Wrap toolbar item Palette Label")];
//        [toolbarItem setTarget:self];
//        [toolbarItem setAction:@selector(lineWrap:)];
//		
//		return toolbarItem;
//		
//		
	}
		
	return nil;
}



- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem *toolbarItem = [[notification userInfo] valueForKey:@"item"];
	
	if ([[toolbarItem itemIdentifier] isEqualToString:@"QuicklyFindNextToolbarItem"]) {
		liveFindToolbarItem = toolbarItem;
	} else if ([[toolbarItem itemIdentifier] isEqualToString:@"FunctionToolbarItem"]) {
		functionToolbarItem = toolbarItem;
		[functionButton sendActionOn:NSLeftMouseDownMask];
//	} else if ([[toolbarItem itemIdentifier] isEqualToString:@"SplitWindowToolbarItem"]) {
//		splitWindowToolbarItem = toolbarItem;
//	} else if ([[toolbarItem itemIdentifier] isEqual:@"LineWrapToolbarItem"]) {
//		lineWrapToolbarItem = toolbarItem;
	}
} 


//- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem 
//{
//	// Function and Live Find are validated in -[FRAProject documentsListHasUpdated] so that they don't need to be updated all the time as they would have been here 
//	
//	BOOL enableItem = YES;
//	Log(toolbarItem);
//	if ([self areThereAnyDocuments] == NO) {
//		if ([toolbarItem tag] != 1) { // All the items that should always be active have the tag 1
//			//enableItem = NO;
//			//[(NSButton *)[[[toolbarItem view] subviews] objectAtIndex:0] setEnabled:NO];
//			//[(NSButtonCell *)[[[[toolbarItem view] subviews] objectAtIndex:0] cell] setEnabled:NO];
//			[toolbarItem setEnabled:NO];
//			Pos;
//		}
//	}
//
//    return enableItem;
//}


- (void)save:(id)sender
{
	[[FRAFileMenuController sharedInstance] saveAction:nil];
}


- (void)open:(id)sender
{
	[[FRAFileMenuController sharedInstance] openAction:nil];
}


- (void)new:(id)sender
{
	[[FRAFileMenuController sharedInstance] newAction:nil];
}


- (void)close:(id)sender
{
	[self checkIfDocumentIsUnsaved:FRACurrentDocument keepOpen:NO];
}


- (void)print:(id)sender
{
	[[FRAFileMenuController sharedInstance] printAction:nil];
}


//- (void)preferences:(id)sender
//{
//	[[FRAPreferencesController sharedInstance] showPreferencesWindow];
//}


- (IBAction)liveFindToolbarItemAction:(id)sender;
{
	NSString *searchString = [liveFindSearchField objectValue];
	id document = [[[self documentsArrayController] selectedObjects] objectAtIndex:0];
	NSTextView *textView = [self lastTextViewInFocus];
	if (textView == nil || (textView != [document valueForKey:@"firstTextView"] && textView != [document valueForKey:@"secondTextView"] && textView != [document valueForKey:@"thirdTextView"])) {
		textView = [document valueForKey:@"firstTextView"];
	}
	if (![searchString length] > 0 || document == nil) {
		[self removeLiveFindSession];
		NSBeep();
		return;
	}
	
	if (liveFindSessionTimer) { // For some reason it didn't work to set the timer 6 seconds forward so just destroy it and create a new
		[liveFindSessionTimer invalidate];
		liveFindSessionTimer = nil;
	}
		
	liveFindSessionTimer = [NSTimer scheduledTimerWithTimeInterval:6.0 target:self selector:@selector(removeLiveFindSession) userInfo:nil repeats:NO];
	
	
	NSString *text = [textView string];
	NSInteger startLocation;
	if (originalPosition == -1) {
		startLocation = [textView selectedRange].location;
		originalPosition = startLocation;
	} else {
		startLocation = originalPosition;
	}
	
	[liveFindSearchField setNextKeyView:textView];
	
	NSRange foundRange = [text rangeOfString:searchString options:NSCaseInsensitiveSearch range:NSMakeRange(startLocation, [text length] - startLocation)];
	if (foundRange.location == NSNotFound) {
		foundRange = [text rangeOfString:searchString options:NSCaseInsensitiveSearch range:NSMakeRange(0, startLocation)]; // If it can't be found, "forward" wrap around and look for it
		if (foundRange.location == NSNotFound) {
			NSBeep();
		}
	}
	
	if (foundRange.location != NSNotFound) {
		[textView setSelectedRange:foundRange];
		[textView scrollRangeToVisible:foundRange];
		[textView showFindIndicatorForRange:foundRange];
		
		// I suppose there's a better way of doing this...but it works, so I'll stick with it until something better comes along...
		NSToolbarItem *dummyToolbarItem = [[NSToolbarItem alloc] init];
		[dummyToolbarItem setTag:NSFindPanelActionSetFindString];
		[textView performFindPanelAction:dummyToolbarItem];
	}
}


- (void)advancedFind:(id)sender
{
	[[FRAAdvancedFindController sharedInstance] showAdvancedFindWindow];
}


- (void)preview:(id)sender
{
	[[FRAToolsMenuController sharedInstance] previewAction:nil];
}


- (IBAction)functionToolbarItemAction:(id)sender
{
	NSMenu *functionMenu = [functionPopUpButton menu];
	[FRABasic removeAllItemsFromMenu:functionMenu];
	[FRAInterface insertAllFunctionsIntoMenu:functionMenu];
	[functionPopUpButton selectItem:nil];
	[[functionPopUpButton cell] performClickWithFrame:[sender frame] inView:[sender superview]];
}


- (void)prepareForLiveFind
{
	[FRACurrentWindow makeKeyAndOrderFront:nil];
	[liveFindSearchField selectText:nil];
}


- (void)removeLiveFindSession
{
	id firstResponder = [FRACurrentWindow firstResponder];
	[FRACurrentWindow makeFirstResponder:liveFindSearchField];
	NSText *fieldEditor = (NSText *)[[liveFindSearchField window] firstResponder];
	if (firstResponder == fieldEditor) {
		[liveFindSessionTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:5]];
		return;
	}
	
	originalPosition = -1;
	
	if (liveFindSessionTimer != nil) {
		[liveFindSessionTimer invalidate];
		liveFindSessionTimer = nil;
	}
	
	[liveFindSearchField setStringValue:@""];
	[FRACurrentWindow makeFirstResponder:firstResponder];
}


- (NSSearchField *)liveFindSearchField
{
    return liveFindSearchField; 
}


- (void)info:(id)sender
{
	[[FRAInfoController sharedInstance] openInfoWindow];
}


- (NSToolbarItem *)liveFindToolbarItem
{
    return liveFindToolbarItem; 
}


- (NSToolbarItem *)functionToolbarItem
{
    return functionToolbarItem; 
}


- (void)menuNeedsUpdate:(NSMenu *)menu
{
	if ([[self projectWindowToolbar] displayMode] == NSToolbarDisplayModeLabelOnly) { // This is only needed if the toolbar is text only
		[FRABasic removeAllItemsFromMenu:menu];
		[FRAInterface insertAllFunctionsIntoMenu:menu];
		[self performSelector:@selector(updateLabelsInToolbar) withObject:nil afterDelay:0.0]; // This is because otherwise the label Function disappears after one has been shown the menu for the first time
	}
}


- (void)updateLabelsInToolbar
{
	[[self window] setToolbar:[self projectWindowToolbar]];
}


- (void)removeFunctionMenuFormRepresentation
{
	[functionToolbarItem setMenuFormRepresentation:nil];
}


- (void)reinsertFunctionMenuFormRepresentation
{
	[functionToolbarItem setMenuFormRepresentation:menuFormRepresentation];
}


- (NSButton *)functionButton
{
    return functionButton; 
}


//- (void)splitWindow:(id)sender
//{
//	[[FRAViewMenuController sharedInstance] splitWindowAction:nil];
//}


//- (void)updateSplitWindowToolbarItem
//{
//	if (secondDocument == nil) {
//		[splitWindowToolbarItem setLabel:SPLIT_WINDOW_STRING];
//		[splitWindowToolbarItem setToolTip:SPLIT_WINDOW_STRING];
//		[splitWindowToolbarItem setImage:splitWindowImage];
//	} else {
//		[splitWindowToolbarItem setLabel:CLOSE_SPLIT_STRING];
//		[splitWindowToolbarItem setToolTip:CLOSE_SPLIT_STRING];
//		[splitWindowToolbarItem setImage:closeSplitImage];
//	}
//}


//- (void)lineWrap:(id)sender
//{
//	[[FRAViewMenuController sharedInstance] lineWrapTextAction:nil];
//}
//
//
//- (void)updateLineWrapToolbarItem
//{
//	if ([[FRAApplicationDelegate sharedInstance] hasFinishedLaunching] == YES) {
//		if ([[FRACurrentDocument valueForKey:@"isLineWrapped"] boolValue] == NO) {
//			[lineWrapToolbarItem setLabel:LINE_WRAP_STRING];
//			[lineWrapToolbarItem setToolTip:LINE_WRAP_STRING];
//			[lineWrapToolbarItem setImage:lineWrapImage];
//		} else {
//			[lineWrapToolbarItem setLabel:DONT_LINE_WRAP_STRING];
//			[lineWrapToolbarItem setToolTip:DONT_LINE_WRAP_STRING];
//			[lineWrapToolbarItem setImage:dontLineWrapImage];
//		}
//	}
//}


- (void)extraToolbarValidation
{
	if ([self areThereAnyDocuments] == YES) {
		[(NSControl *)[[[functionToolbarItem view] subviews] objectAtIndex:0] setEnabled:YES];
		[[(NSControl *)[[[functionToolbarItem view] subviews] objectAtIndex:0] cell] setEnabled:YES];
		
		if (liveFindToolbarItem != nil) {
			[[liveFindSearchField cell] setEnabled:YES];
		}
		[self reinsertFunctionMenuFormRepresentation];
		
		[(NSControl *)[[[saveToolbarItem view] subviews] objectAtIndex:0] setEnabled:YES];
		[[(NSControl *)[[[saveToolbarItem view] subviews] objectAtIndex:0] cell] setEnabled:YES];
		
		[(NSControl *)[[[advancedFindToolbarItem view] subviews] objectAtIndex:0] setEnabled:YES];
		[[(NSControl *)[[[advancedFindToolbarItem view] subviews] objectAtIndex:0] cell] setEnabled:YES];
		
		[(NSControl *)[[[closeToolbarItem view] subviews] objectAtIndex:0] setEnabled:YES];
		[[(NSControl *)[[[closeToolbarItem view] subviews] objectAtIndex:0] cell] setEnabled:YES];
		
		[(NSControl *)[[[infoToolbarItem view] subviews] objectAtIndex:0] setEnabled:YES];
		[[(NSControl *)[[[infoToolbarItem view] subviews] objectAtIndex:0] cell] setEnabled:YES];
		
		[(NSControl *)[[[previewToolbarItem view] subviews] objectAtIndex:0] setEnabled:YES];
		[[(NSControl *)[[[previewToolbarItem view] subviews] objectAtIndex:0] cell] setEnabled:YES];

		
	} else {
		[(NSControl *)[[[functionToolbarItem view] subviews] objectAtIndex:0] setEnabled:NO];
		[[(NSControl *)[[[functionToolbarItem view] subviews] objectAtIndex:0] cell] setEnabled:NO];
		
		if (liveFindToolbarItem != nil && [[FRAApplicationDelegate sharedInstance] hasFinishedLaunching] == YES) {
			[[liveFindSearchField cell] setEnabled:NO];
		}
		[self removeFunctionMenuFormRepresentation];
		
		[(NSControl *)[[[saveToolbarItem view] subviews] objectAtIndex:0] setEnabled:NO];
		[[(NSControl *)[[[saveToolbarItem view] subviews] objectAtIndex:0] cell] setEnabled:NO];
		
		[(NSControl *)[[[advancedFindToolbarItem view] subviews] objectAtIndex:0] setEnabled:NO];
		[[(NSControl *)[[[advancedFindToolbarItem view] subviews] objectAtIndex:0] cell] setEnabled:NO];
		
		[(NSControl *)[[[closeToolbarItem view] subviews] objectAtIndex:0] setEnabled:NO];
		[[(NSControl *)[[[closeToolbarItem view] subviews] objectAtIndex:0] cell] setEnabled:NO];
		
		[(NSControl *)[[[infoToolbarItem view] subviews] objectAtIndex:0] setEnabled:NO];
		[[(NSControl *)[[[infoToolbarItem view] subviews] objectAtIndex:0] cell] setEnabled:NO];
		
		[(NSControl *)[[[previewToolbarItem view] subviews] objectAtIndex:0] setEnabled:NO];
		[[(NSControl *)[[[previewToolbarItem view] subviews] objectAtIndex:0] cell] setEnabled:NO];
	}
	
	
	
	[self updateLabelsInToolbar]; // Do this so the labels are properly greyed out
	//[self updateSplitWindowToolbarItem];
//	[self updateLineWrapToolbarItem];
}
@end
