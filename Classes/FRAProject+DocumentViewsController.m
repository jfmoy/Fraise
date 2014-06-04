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

#import "FRAProject+DocumentViewsController.h"
#import "FRAInterfacePerformer.h"
#import "FRAApplicationDelegate.h"
#import "FRAViewMenuController.h"
#import "FRALineNumbers.h"

#import "PSMTabBarControl.h"
#import "FRADocumentManagedObject.h"

@implementation FRAProject (DocumentViewsController)


- (void)setDefaultViews
{
	[tabBarControl setTabView:tabBarTabView];
	[tabBarControl setCanCloseOnlyTab:YES];
	[tabBarControl setStyleNamed:@"Unified"];
	[tabBarControl setAllowsDragBetweenWindows:YES];
	[tabBarControl setCellMinWidth:100];
	[tabBarControl setCellMaxWidth:280];
	[tabBarControl setCellOptimumWidth:170];
	[tabBarControl setDelegate:self];
	[tabBarControl registerForDraggedTypes:@[NSFilenamesPboardType]];
	
	if ([project valueForKey:@"viewSize"] == nil) {
		[project setValue:[FRADefaults valueForKey:@"ViewSize"] forKey:@"viewSize"];
	}
	if ([project valueForKey:@"view"] == nil) {
		[project setValue:[FRADefaults valueForKey:@"View"] forKey:@"view"];
	}
	
	[self insertView:[[project valueForKey:@"view"] integerValue]];
	
	[mainSplitView adjustSubviews];
}


- (IBAction)viewSizeSliderAction:(id)sender
{
	NSInteger size = round([viewSelectionSizeSlider doubleValue]);
	
	[FRADefaults setValue:@(size) forKey:@"ViewSize"];
	[project setValue:@(size) forKey:@"viewSize"];
	
	FRAView view = [[project valueForKey:@"view"] integerValue];
	
	if (view == FRAListView) {
		[documentsTableView setRowHeight:([[project valueForKey:@"viewSize"] integerValue] + 1)];
	}
	
	[self reloadData];
}


- (void)insertView:(FRAView)view
{
	[FRADefaults setValue:[NSNumber numberWithInteger:view] forKey:@"View"];
	[project setValue:[NSNumber numberWithInteger:view] forKey:@"view"];
	
	[FRAInterface removeAllSubviewsFromView:leftDocumentsView];
	
	CGFloat viewSelectionHeight;
	if ([[FRADefaults valueForKey:@"ShowSizeSlider"] boolValue] == YES) {
		viewSelectionHeight = [viewSelectionView bounds].size.height;
	} else {
		viewSelectionHeight = 0;
	}

	if (view == FRAListView) {
		[documentsTableView setRowHeight:[[project valueForKey:@"viewSize"] integerValue]];
		[leftDocumentsTableView setFrame:NSMakeRect([leftDocumentsView bounds].origin.x, [leftDocumentsView bounds].origin.y + viewSelectionHeight, [leftDocumentsView bounds].size.width, [leftDocumentsView bounds].size.height - viewSelectionHeight)];
		[leftDocumentsView addSubview:leftDocumentsTableView];	
		
	}
	
	//if ([[FRADefaults valueForKey:@"ShowSizeSlider"] boolValue] == YES) {
		[viewSelectionView setFrame:NSMakeRect(0, 0, [leftDocumentsView bounds].size.width, viewSelectionHeight)];
		[leftDocumentsView addSubview:viewSelectionView];
	//}
	
	[viewSelectionSizeSlider setDoubleValue:[[project valueForKey:@"viewSize"] doubleValue]];
}


- (void)animateSizeSlider
{
	CGFloat viewSelectionHeight;
	if ([[FRADefaults valueForKey:@"ShowSizeSlider"] boolValue] == YES) {
		viewSelectionHeight = 22;//[viewSelectionView bounds].size.height;
	} else {
		viewSelectionHeight = 0;
	}
	
	[[leftDocumentsTableView animator] setFrame:NSMakeRect([leftDocumentsView bounds].origin.x, [leftDocumentsView bounds].origin.y + viewSelectionHeight, [leftDocumentsView bounds].size.width, [leftDocumentsView bounds].size.height - viewSelectionHeight)];

	[[viewSelectionView animator] setFrame:NSMakeRect(0, 0, [leftDocumentsView bounds].size.width, viewSelectionHeight)];
}


- (void)reloadData
{
	FRAView view = [[project valueForKey:@"view"] integerValue];
	
	if (view == FRAListView) {
		[documentsArrayController rearrangeObjects];
		[documentsTableView removeAllToolTips];
		[documentsTableView reloadData];
	
	}
}


- (void)updateTabBar
{
	if ([[FRADefaults valueForKey:@"ShowTabBar"] boolValue] == NO) {
		return;
	}
	
	id savedDelegate = [tabBarControl delegate]; // So it doesn't change the selected document when it updates its documents
	[tabBarControl setDelegate:nil];
	[FRAInterface removeAllTabBarObjectsForTabView:tabBarTabView];
	
	[[[FRAApplicationDelegate sharedInstance] managedObjectContext] processPendingChanges];
	[documentsArrayController rearrangeObjects];
	NSEnumerator *enumerator = [[documentsArrayController arrangedObjects] reverseObjectEnumerator];
	for (id item in enumerator) {
		NSTabViewItem *tabViewItem = [[NSTabViewItem alloc] initWithIdentifier:item];
		if ([[item valueForKey:@"isEdited"] boolValue] == YES) {
			[tabViewItem setLabel:[NSString stringWithFormat:@"%@ %C", [item valueForKey:@"name"], 0x270E]];
		} else {
			[tabViewItem setLabel:[item valueForKey:@"name"]];
		}
		[tabBarTabView insertTabViewItem:tabViewItem atIndex:0];
	}
	
	[self selectSameDocumentInTabBarAsInDocumentsList];
	[tabBarControl setDelegate:savedDelegate];
}


- (void)selectSameDocumentInTabBarAsInDocumentsList
{
	if ([[FRADefaults valueForKey:@"ShowTabBar"] boolValue] == NO) {
		return;
	}
	NSArray *selectedObjects = [documentsArrayController selectedObjects];
	if ([selectedObjects count] == 0) {
		return;
	}
	
	id selectedDocument = selectedObjects[0];
	NSArray *array = [tabBarTabView tabViewItems];
	for (id item in array) {
		if ([item identifier] == selectedDocument) {
			[tabBarTabView selectTabViewItem:item];
			break;
		}
	}
}


- (void)resizeViewSizeSlider
{	
	CGFloat newWidth = [viewSelectionView bounds].size.width - 18;
	
	if (newWidth < 12) {
		[viewSelectionSizeSlider setHidden:YES];
	} else {
		[viewSelectionSizeSlider setHidden:NO];
		NSRect rect = [viewSelectionSizeSlider frame];
		[viewSelectionSizeSlider setFrame:NSMakeRect(10, rect.origin.y, newWidth, rect.size.height)];
	}
	
}

#pragma mark -
#pragma mark Tab bar control delegates
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	FRAView view = [[project valueForKey:@"view"] integerValue];
	
	if (view == FRAListView) {
		[documentsArrayController setSelectedObjects:@[[tabViewItem identifier]]];
	}
		
}


- (BOOL)tabView:(NSTabView *)tabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem
{
	id document = [tabViewItem identifier];
	[self checkIfDocumentIsUnsaved:document keepOpen:NO];
	if (document == nil) {
		return YES;
	} else {
		return NO;
	}
}


- (void)updateDocumentOrderFromCells:(NSMutableArray *)cells
{
	id item;
	NSInteger index = 0;
	for (item in cells) {
		[[[item representedObject] identifier] setValue:@(index) forKey:@"sortOrder"];
		index++;
	}
	
	[documentsArrayController rearrangeObjects];
}


#pragma mark -
#pragma mark Split view delegates
- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
	if ([aNotification object] == contentSplitView) {
		[[[self firstDocument] valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth:NO recolour:YES];
		if ([self secondDocument] != nil) {
			[[[self secondDocument] valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth:NO recolour:YES];
		}
	} else if ([aNotification object] == mainSplitView) {
		[self resizeViewSizeSlider];		
	}
}


- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
{
	if (splitView == mainSplitView) {
		[[FRAViewMenuController sharedInstance] performCollapseDocumentsView];
	} else if (splitView == contentSplitView) {
		[[FRAViewMenuController sharedInstance] performCollapse];
	}

	return NO;
}


- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView*)subview
{
	return YES;
}



- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	if (sender != mainSplitView) {
		[sender adjustSubviews];
		return;
	}
	
	CGFloat dividerThickness = [sender dividerThickness];
    NSRect documentsListRect  = [[sender subviews][0] frame];
    NSRect contentRect = [[sender subviews][1] frame];
    NSRect newFrame  = [sender frame];
	
    documentsListRect.size.height = newFrame.size.height;
    documentsListRect.origin = NSMakePoint(0, 0);
    contentRect.size.width = newFrame.size.width - documentsListRect.size.width - dividerThickness;
    contentRect.size.height = newFrame.size.height;
    contentRect.origin.x = documentsListRect.size.width + dividerThickness;
	
    [[sender subviews][0] setFrame:documentsListRect];
    [[sender subviews][1] setFrame:contentRect];
		
	NSRect firstViewFrame = [[contentSplitView subviews][0] frame];
	firstViewFrame.size.width = contentRect.size.width;	
	[[contentSplitView subviews][0] setFrame:firstViewFrame];		

	NSRect secondViewFrame = [[contentSplitView subviews][1] frame];
	secondViewFrame.size.width = contentRect.size.width;
	if (secondDocument == nil) {
		secondViewFrame.size.height = 0.0;
	}
	[[contentSplitView subviews][1] setFrame:secondViewFrame];

	[contentSplitView adjustSubviews];
}





@end
