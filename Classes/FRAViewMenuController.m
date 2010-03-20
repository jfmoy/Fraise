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

#import "FRAViewMenuController.h"
#import "FRAProjectsController.h"
#import "FRAInterfacePerformer.h"
#import "FRAMainController.h"
#import "FRAVariousPerformer.h"
#import "FRALineNumbers.h"
#import "FRAProject.h"
#import "FRASyntaxColouring.h"
#import "FRAProject+ToolbarController.h"
#import "FRAProject+DocumentViewsController.h"
#import "FRALayoutManager.h"

#import "PSMTabBarControl.h"

@implementation FRAViewMenuController

static id sharedInstance = nil;

+ (FRAViewMenuController *)sharedInstance
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


- (IBAction)splitWindowAction:(id)sender;
{
	if ([FRACurrentProject secondDocument] != nil) {
		[self performCollapse];
	} else {
		CGFloat newFraction = 0.5;
		
		NSSplitView *splitView = [FRACurrentProject contentSplitView];		
		NSRect firstViewFrame = [[[splitView subviews] objectAtIndex:0] frame];
		NSRect secondViewFrame = [[[splitView subviews] objectAtIndex:1] frame];
		
		
		BOOL optionKeyDown = ((GetCurrentKeyModifiers() & (optionKey | rightOptionKey)) != 0) ? YES : NO;
		if (optionKeyDown == NO) {
			[splitView setVertical:NO];
			
			firstViewFrame.size.height = newFraction * splitView.frame.size.height;
			secondViewFrame.size.height = splitView.frame.size.height - firstViewFrame.size.height - [splitView dividerThickness];
			
		} else {
			[splitView setVertical:YES];
			
			firstViewFrame.size.width = newFraction * splitView.frame.size.width;
			secondViewFrame.size.width = splitView.frame.size.width - firstViewFrame.size.width - [splitView dividerThickness];
		}
		
		[[[[splitView subviews] objectAtIndex:0] animator] setFrame:firstViewFrame];		
		[[[[splitView subviews] objectAtIndex:1] animator] setFrame:secondViewFrame];
		[[[splitView subviews] objectAtIndex:1] setHidden:NO];
		
		[splitView adjustSubviews];
		
		[FRAInterface insertDocumentIntoSecondContentView:FRACurrentDocument];
		[FRACurrentProject buildSecondContentViewNavigationBarMenu];
		[[[FRACurrentProject firstDocument] valueForKey:@"syntaxColouring"] pageRecolour];
	}
	
	//[FRACurrentProject updateSplitWindowToolbarItem];
}


- (void)performCollapse
{
	CGFloat newFraction = 1.0;
	
	NSSplitView *splitView = [FRACurrentProject contentSplitView];
	NSRect firstViewFrame = [[[splitView subviews] objectAtIndex:0] frame];
	NSRect secondViewFrame = [[[splitView subviews] objectAtIndex:1] frame];
	[splitView setVertical:NO];

	CGFloat total = firstViewFrame.size.height + secondViewFrame.size.height + [splitView dividerThickness];
	firstViewFrame.size.height = newFraction * total;
	secondViewFrame.size.height = 0.0;

	[[[[splitView subviews] objectAtIndex:0] animator] setFrame:firstViewFrame];
	[[[[splitView subviews] objectAtIndex:1] animator] setFrame:secondViewFrame];
	[[[splitView subviews] objectAtIndex:1] setHidden:YES];
	
	[splitView adjustSubviews];
	
	[FRAInterface removeAllSubviewsFromView:[FRACurrentProject secondContentView]];	
	[[[FRACurrentProject firstDocument] valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth:NO recolour:YES];
	
	[[FRACurrentProject secondDocument] setValue:nil forKey:@"secondTextView"];
	[[FRACurrentProject secondDocument] setValue:nil forKey:@"secondTextScrollView"];
	[[[FRACurrentProject secondDocument] valueForKey:@"syntaxColouring"] setSecondLayoutManager:nil];
	[FRACurrentProject setSecondDocument:nil];
}


- (IBAction)lineWrapTextAction:(id)sender
{
	id document = FRACurrentDocument;
	
	FRATextView *textView = [document valueForKey:@"firstTextView"];
	NSScrollView *textScrollView = [document valueForKey:@"firstTextScrollView"];
	NSScrollView *gutterScrollView = [document valueForKey:@"firstGutterScrollView"];
	NSInteger viewNumber = 0;
	while (viewNumber++ < 3) {
		if (viewNumber == 2) {
			if ([document valueForKey:@"secondTextView"] != nil) {
				textView = [document valueForKey:@"secondTextView"];
				textScrollView = [document valueForKey:@"secondTextScrollView"];
				gutterScrollView = [document valueForKey:@"secondGutterScrollView"];
			} else {
				continue;
			}
		}
		if (viewNumber == 3) {
			if ([document valueForKey:@"singleDocumentWindow"] != nil) {
				textView = [document valueForKey:@"thirdTextView"];
				textScrollView = [document valueForKey:@"thirdTextScrollView"];
				gutterScrollView = [document valueForKey:@"thirdGutterScrollView"];
			} else {
				continue;
			}
		}
		NSRange selectedRange = [textView selectedRange];
		if ([[document valueForKey:@"isLineWrapped"] boolValue] == YES) {
			[[textView textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
			[[textView textContainer] setWidthTracksTextView:NO];
			[textView setHorizontallyResizable:YES];
			[textScrollView setHasHorizontalScroller:YES];
		} else {
			NSString *string = [NSString stringWithString:[textView string]];
			[textScrollView setHasHorizontalScroller:NO];
			[textView setString:@""];
			[[textView textContainer] setWidthTracksTextView:YES];
			[[textView textContainer] setContainerSize:NSMakeSize([textScrollView contentSize].width, CGFLOAT_MAX)];
			[textView setString:string]; // To reflow/rewrap the text
			[textView setHorizontallyResizable:NO];
		}
		[textScrollView display]; // Otherwise -[FRAMainController resizeViewsForDocument:] won't know if it has a scrollbar or not
		
		[textView setSelectedRange:selectedRange];
		[textView scrollRangeToVisible:selectedRange];
	}
	
	if ([[document valueForKey:@"isLineWrapped"] boolValue] == YES) {
		[document setValue:[NSNumber numberWithBool:NO] forKey:@"isLineWrapped"];
	} else {
		[document setValue:[NSNumber numberWithBool:YES] forKey:@"isLineWrapped"];
	}
	
	[FRACurrentProject resizeViewsForDocument:document];
	//[FRACurrentProject updateLineWrapToolbarItem];
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	BOOL enableMenuItem = YES;
	NSInteger tag = [anItem tag];
	if ([FRACurrentProject areThereAnyDocuments] == YES) {
		if (tag == 9) { // Documents View
			if ([[FRADefaults valueForKey:@"ShowSizeSlider"] boolValue] == YES) {
				[anItem setTitle:NSLocalizedStringFromTable(@"Hide Size Slider", @"Localizable3", @"Hide Size Slider")];
			} else {
				[anItem setTitle:NSLocalizedStringFromTable(@"Show Size Slider", @"Localizable3", @"Show Size Slider")];
			}
		} else if (tag == 11) { // Show Syntax Colours
			if ([[FRACurrentDocument valueForKey:@"isSyntaxColoured"] boolValue] == YES) {
				[anItem setTitle:NSLocalizedString(@"Hide Syntax Colours", @"Hide Syntax Colours")];
				} else {
				[anItem setTitle:NSLocalizedString(@"Show Syntax Colours", @"Show Syntax Colours")];
				}
		} else if (tag == 19) { // Show Line Numbers
			if ([[FRACurrentDocument valueForKey:@"showLineNumberGutter"] boolValue] == YES) {
				[anItem setTitle:NSLocalizedString(@"Hide Line Numbers",@"Hide Line Numbers")];
			} else {
				[anItem setTitle:NSLocalizedString(@"Show Line Numbers", @"Show Line Numbers")];
			}
		} else if (tag == 17) { // Show Status Bar
			if ([[FRADefaults valueForKey:@"ShowStatusBar"] boolValue] == YES) {
				[anItem setTitle:NSLocalizedString(@"Hide Status Bar", @"Hide Status Bar in View-menu")];
			} else {
				[anItem setTitle:NSLocalizedString(@"Show Status Bar", @"Show Status Bar in View-menu")];
			}
		} else if (tag == 18) { // Show Invisible Characters
			if ([[FRACurrentDocument valueForKey:@"showInvisibleCharacters"] boolValue] == YES) {
				[anItem setTitle:NSLocalizedString(@"Hide Invisible Characters", @"Hide Invisible Characters in View-menu")];
			} else {
				[anItem setTitle:NSLocalizedString(@"Show Invisible Characters", @"Show Invisible Characters in View-menu")];
			}
		} else if (tag == 10) { // Line Wrap Text
			if ([[FRACurrentDocument valueForKey:@"isLineWrapped"] boolValue] == YES) {
				[anItem setTitle:DONT_LINE_WRAP_STRING];
			} else {
				[anItem setTitle:LINE_WRAP_STRING];
			}
		} else if (tag == 100) { // Split Window
			if ([FRACurrentProject secondDocument] != nil) {
				[anItem setTitle:CLOSE_SPLIT_STRING];
			} else {
				[anItem setTitle:SPLIT_WINDOW_STRING];
			}
		} else if (tag == 101) { // Split Window Vertically
			if ([FRACurrentProject secondDocument] != nil) {
				[anItem setTitle:CLOSE_SPLIT_STRING];
			} else {
				[anItem setTitle:NSLocalizedStringFromTable(@"Split Window Vertically", @"Localizable3", @"Split Window Vertically")];
			}
		} else if (tag == 15) { // Show Tab Bar
			if ([[FRADefaults valueForKey:@"ShowTabBar"] boolValue] == YES) {
				[anItem setTitle:NSLocalizedString(@"Hide Tab Bar", @"Hide Tab Bar in View menu")];
			} else {
				[anItem setTitle:NSLocalizedString(@"Show Tab Bar", @"Show Tab Bar in View menu")];
			}
		} else if (tag == 14) { // Show Documents List
			if ([[[[FRACurrentProject mainSplitView] subviews] objectAtIndex:0] frame].size.width != 0.0) {
				[anItem setTitle:NSLocalizedString(@"Hide Documents List", @"Hide Documents List in View menu")];
			} else {
				[anItem setTitle:NSLocalizedString(@"Show Documents List", @"Show Documents List in View menu")];
			}
		}
		
		
	} else {
		enableMenuItem = NO;
	}
	
	return enableMenuItem;
}


- (IBAction)showSyntaxColoursAction:(id)sender
{
	id document = FRACurrentDocument;
	if ([[document valueForKey:@"isSyntaxColoured"] boolValue] == YES) {
		[[document valueForKey:@"syntaxColouring"] removeAllColours];
		[document setValue:[NSNumber numberWithBool:NO] forKey:@"isSyntaxColoured"];
	} else {
		[document setValue:[NSNumber numberWithBool:YES] forKey:@"isSyntaxColoured"];
		[[document valueForKey:@"syntaxColouring"] pageRecolour];
	}

	[FRAInterface updateStatusBar];
}


- (IBAction)showLineNumbersAction:(id)sender
{
	id document = FRACurrentDocument;
	if ([[document valueForKey:@"showLineNumberGutter"] boolValue] == YES) {
		[document setValue:[NSNumber numberWithBool:NO] forKey:@"showLineNumberGutter"];
	} else {
		[document setValue:[NSNumber numberWithBool:YES] forKey:@"showLineNumberGutter"];
	}
	
	[FRACurrentProject resizeViewsForDocument:document];	
}


- (IBAction)showStatusBarAction:(id)sender
{
	if ([[FRADefaults valueForKey:@"ShowStatusBar"] boolValue] == YES) {
		[FRADefaults setValue:[NSNumber numberWithBool:NO] forKey:@"ShowStatusBar"];
		[self performHideStatusBar];
		
	} else {
		[FRADefaults setValue:[NSNumber numberWithBool:YES] forKey:@"ShowStatusBar"];
		NSArray *array = [[FRAProjectsController sharedDocumentController] documents];
		for (id item in array) {
			CGFloat statusBarHeight = [[item statusBarTextField] bounds].size.height;
			NSRect mainSplitViewRect = [[item mainSplitView] frame];
			
			[[item statusBarTextField] setHidden:NO];
			[[[item mainSplitView] animator] setFrame:NSMakeRect(mainSplitViewRect.origin.x, mainSplitViewRect.origin.y + statusBarHeight, mainSplitViewRect.size.width, mainSplitViewRect.size.height - statusBarHeight)];
			[[item mainSplitView] adjustSubviews];
			
			[FRAInterface updateStatusBar];
		}
		if ([[FRADefaults valueForKey:@"StatusBarShowWhenLastSaved"] boolValue] == NO && [[FRADefaults valueForKey:@"StatusBarShowLength"] boolValue] == NO && [[FRADefaults valueForKey:@"StatusBarShowSelection"] boolValue] == NO  && [[FRADefaults valueForKey:@"StatusBarShowEncoding"] boolValue] == NO  && [[FRADefaults valueForKey:@"StatusBarShowSyntax"] boolValue] == NO) {
			[FRAVarious standardAlertSheetWithTitle:NSLocalizedString(@"You have set the preferences to not show anything in the status bar", @"Indicate that they have set the preferences to not show anything in the status bar in Show-status-bar-action") message:NSLocalizedString(@"Please change the preferences if you want any information in the bar", @"Indicate that they should please change the preferences if you want any information in the bar in Show-status-bar-action") window:FRACurrentWindow];
		}
		
	}
}


- (void)performHideStatusBar
{
	NSArray *array = [[FRAProjectsController sharedDocumentController] documents];
	for (id item in array) {
		CGFloat statusBarHeight = [[item statusBarTextField] bounds].size.height;
		NSRect mainSplitViewRect = [[item mainSplitView] frame];
		[FRAInterface clearStatusBar];
		[[item statusBarTextField] setHidden:YES];
		
		[[[item mainSplitView] animator] setFrame:NSMakeRect(mainSplitViewRect.origin.x, mainSplitViewRect.origin.y - statusBarHeight, mainSplitViewRect.size.width, mainSplitViewRect.size.height + statusBarHeight)];
		[[item mainSplitView] adjustSubviews];
	}
}


- (IBAction)showInvisibleCharactersAction:(id)sender
{
	id document = FRACurrentDocument;
	if ([[document valueForKey:@"showInvisibleCharacters"] boolValue] == YES) {
		[document setValue:[NSNumber numberWithBool:NO] forKey:@"showInvisibleCharacters"];
	} else {
		[document setValue:[NSNumber numberWithBool:YES] forKey:@"showInvisibleCharacters"];
	}
	
	// To update visible range in all three (possible) views
	NSArray *array = [[[document valueForKey:@"firstTextView"] textStorage] layoutManagers];
	for (id item in array) {
		NSTextContainer *textContainer = [[item textContainers] objectAtIndex:0];
		NSScrollView *scrollView = [[textContainer textView] enclosingScrollView];
		NSRect visibleRect = [[scrollView contentView] documentVisibleRect];
		NSRange visibleRange = [item glyphRangeForBoundingRect:visibleRect inTextContainer:textContainer];
		[item invalidateDisplayForGlyphRange:visibleRange];
		[item setShowInvisibleCharacters:[[document valueForKey:@"showInvisibleCharacters"] boolValue]];
	}
}


- (IBAction)viewDocumentInSeparateWindowAction:(id)sender
{
	id document = [[[FRACurrentProject documentsArrayController] selectedObjects] objectAtIndex:0];
	[FRAInterface insertDocumentIntoThirdContentView:document orderFront:YES];
	[FRACurrentProject updateWindowTitleBarForDocument:document];
	
}


- (IBAction)viewDocumentInFullScreenAction:(id)sender
{
	if ([FRAMain isInFullScreenMode] == NO) {
		if ([[FRADefaults valueForKey:@"UserHasBeenShownAlertHowToReturnFromFullScreen"] boolValue] == NO) {
			[FRAVarious alertWithMessage:NSLocalizedString(@"Press the Escape-button on the keyboard to return from the full screen mode", @"Press the Escape-button on the keyboard to return from the full screen mode in Show Document In Full Screen") informativeText:NSLocalizedString(@"This message will NOT appear again so try to remember it:-)", @"This message will NOT appear again so try to remember it:-) in Show Document In Full Screen") defaultButton:OK_BUTTON alternateButton:nil otherButton:nil];
			[FRADefaults setValue:[NSNumber numberWithBool:YES] forKey:@"UserHasBeenShownAlertHowToReturnFromFullScreen"];
		}
		id currentDocument = [[[FRACurrentProject documentsArrayController] selectedObjects] objectAtIndex:0];
		if ([currentDocument valueForKey:@"singleDocumentWindow"] == nil) {
			[FRAInterface insertDocumentIntoThirdContentView:currentDocument orderFront:NO];
			[FRAMain setSingleDocumentWindowWasOpenBeforeEnteringFullScreen:NO];
		} else {
			[FRAMain setSingleDocumentWindowWasOpenBeforeEnteringFullScreen:YES];
		}
		
		[FRAInterface enterFullScreenForDocument:currentDocument];
		[FRAMain setIsInFullScreenMode:YES];
	}
}


- (IBAction)showTabBarAction:(id)sender
{
	NSArray *selectedObjects = [[FRACurrentProject documentsArrayController] selectedObjects];
	id selectedDocument = nil;
	if ([selectedObjects count] > 0) {
		selectedDocument = [selectedObjects objectAtIndex:0];
	}
	
	if ([[FRADefaults valueForKey:@"ShowTabBar"] boolValue] == YES) {
		[FRADefaults setValue:[NSNumber numberWithBool:NO] forKey:@"ShowTabBar"];
		[self performHideTabBar];
		
	} else {
		
		NSArray *array = [[FRAProjectsController sharedDocumentController] documents];
		for (id item in array) {
			CGFloat tabBarHeight = [[item tabBarControl] bounds].size.height;
			NSRect mainSplitViewRect = [[item mainSplitView] frame];
			[FRADefaults setValue:[NSNumber numberWithBool:YES] forKey:@"ShowTabBar"];
			[[item tabBarControl] setHidden:NO];
			[[item tabBarControl] hideTabBar:NO animate:YES];
			[[item tabBarTabView] setHidden:NO];
			
			[[[item mainSplitView] animator] setFrame:NSMakeRect(mainSplitViewRect.origin.x, mainSplitViewRect.origin.y, mainSplitViewRect.size.width, mainSplitViewRect.size.height - tabBarHeight)];
			[[item mainSplitView] adjustSubviews];
			
			
			[item updateTabBar];
			[[item window] setToolbar:[item projectWindowToolbar]];
		}
	}
	
	if (selectedDocument != nil) {
		[[FRACurrentProject documentsArrayController] setSelectedObjects:[NSArray arrayWithObject:selectedDocument]]; // Otherwise the selected document gets unselected when showing or hiding the tab bar
	}
}


- (void)performHideTabBar
{
	NSArray *array = [[FRAProjectsController sharedDocumentController] documents];
	for (id item in array) {
		[FRAInterface removeAllTabBarObjectsForTabView:[item tabBarTabView]];
		
		CGFloat tabBarHeight = [[item tabBarControl] bounds].size.height;
		NSRect mainSplitViewRect = [[item mainSplitView] frame];
		
		[[item tabBarControl] setHidden:YES];
		//[[item tabBarControl] hideTabBar:YES animate:YES];
		[[item tabBarTabView] setHidden:YES];
		
		[[[item mainSplitView] animator] setFrame:NSMakeRect(mainSplitViewRect.origin.x, mainSplitViewRect.origin.y, mainSplitViewRect.size.width, mainSplitViewRect.size.height + tabBarHeight)];
		[[item mainSplitView] adjustSubviews];
	}
}


- (IBAction)showDocumentsViewAction:(id)sender
{
	NSSplitView *splitView = [FRACurrentProject mainSplitView];
	
	if ([[[splitView subviews] objectAtIndex:0] frame].size.width != 0.0) {
		[self performCollapseDocumentsView];
	} else {
		CGFloat newFraction = [[[FRACurrentProject valueForKey:@"project"] valueForKey:@"dividerPosition"] doubleValue];
		if (newFraction == 0.0) { // If it was hidden from the beginning there's no last value to return to...
			newFraction = 0.2;
		}
		
		NSRect firstViewFrame = [[[splitView subviews] objectAtIndex:0] frame];
		NSRect secondViewFrame = [[[splitView subviews] objectAtIndex:1] frame];
		
		CGFloat total = firstViewFrame.size.width + secondViewFrame.size.width + [splitView dividerThickness];
		firstViewFrame.size.width = newFraction * total;
		secondViewFrame.size.width = total - firstViewFrame.size.width - [splitView dividerThickness];
		
		[[[[splitView subviews] objectAtIndex:0] animator] setFrame:firstViewFrame];		
		[[[[splitView subviews] objectAtIndex:1] animator] setFrame:secondViewFrame];
		
		[FRACurrentProject insertView:[[[FRACurrentProject valueForKey:@"project"] valueForKey:@"view"] integerValue]];
		[FRACurrentProject resizeViewSizeSlider];
		[splitView adjustSubviews];
	}
}


- (void)performCollapseDocumentsView
{
	[FRACurrentProject saveMainSplitViewFraction];
	
	CGFloat newFraction = 1.0;
	
	NSSplitView *splitView = [FRACurrentProject mainSplitView];
	NSRect firstViewFrame = [[[splitView subviews] objectAtIndex:0] frame];
	NSRect secondViewFrame = [[[splitView subviews] objectAtIndex:1] frame];
	
	CGFloat total = firstViewFrame.size.width + secondViewFrame.size.width + [splitView dividerThickness];
	firstViewFrame.size.width = newFraction * total;
	secondViewFrame.size.width = 0.0;
	
	[[[[splitView subviews] objectAtIndex:1] animator] setFrame:firstViewFrame];
	[[[[splitView subviews] objectAtIndex:0] animator] setFrame:secondViewFrame];
	
	[splitView adjustSubviews];
}


- (IBAction)documentsViewAction:(id)sender
{
	[FRACurrentProject insertView:[sender tag]];
}


- (IBAction)emptyDummyAction:(id)sender
{
	// An easy way to enable menu items with submenus without setting an action which actually does something
}


- (IBAction)showSizeSliderAction:(id)sender
{
	if ([[FRADefaults valueForKey:@"ShowSizeSlider"] boolValue] == YES) {
		[FRADefaults setValue:[NSNumber numberWithBool:NO] forKey:@"ShowSizeSlider"];
	} else {
		[FRADefaults setValue:[NSNumber numberWithBool:YES] forKey:@"ShowSizeSlider"];
	}
	
	NSArray *array = [[FRAProjectsController sharedDocumentController] documents];
	for (id item in array) {
		[item animateSizeSlider];//insertView:FRAListView];
	}
}
@end
