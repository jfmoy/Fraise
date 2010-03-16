/*
Smultron version 3.7
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Smultron

Copyright 2004-2009 Peter Borg - 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "SMLStandardHeader.h"

#import "SMLProject+TableViewDelegate.h"
#import "SMLApplicationDelegate.h"
#import "SMLDocumentsListCell.h"
#import "SMLInterfacePerformer.h"
#import "SMLVariousPerformer.h"
#import "SMLLineNumbers.h"
#import "SMLProject+DocumentViewsController.h"

@implementation SMLProject (TableViewDelegate)


- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSTableView *tableView = [aNotification object];
	if (tableView == [self documentsTableView] || aNotification == nil) {
		if ([[SMLApplicationDelegate sharedInstance] isTerminatingApplication] == YES) {
			return;
		}
		if ([[[self documentsArrayController] arrangedObjects] count] < 1 || [[[self documentsArrayController] selectedObjects] count] < 1) {
			[self updateWindowTitleBarForDocument:nil];
			return;
		}
		
		id document = [[[self documentsArrayController] selectedObjects] objectAtIndex:0];
		
		[self performInsertFirstDocument:document];
	}
	
}


- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ([[SMLDefaults valueForKey:@"SizeOfDocumentsListTextPopUp"] integerValue] == 0) {
		[aCell setFont:[NSFont systemFontOfSize:11.0]];
	} else {
		[aCell setFont:[NSFont systemFontOfSize:13.0]];
	}
	
	if (aTableView == [self documentsTableView]) {
		id document = [[[self documentsArrayController] arrangedObjects] objectAtIndex:rowIndex];
		
		if ([[document valueForKey:@"isNewDocument"] boolValue] == YES) {
			[aTableView addToolTipRect:[aTableView rectOfRow:rowIndex] owner:UNSAVED_STRING userData:nil];
		} else {
			if ([[document valueForKey:@"fromExternal"] boolValue]) {
				[aTableView addToolTipRect:[aTableView rectOfRow:rowIndex] owner:[document valueForKey:@"externalPath"] userData:nil];
			} else {
				[aTableView addToolTipRect:[aTableView rectOfRow:rowIndex] owner:[document valueForKey:@"path"] userData:nil];
			}
		}
		
		if ([[aTableColumn identifier] isEqualToString:@"name"]) {
			NSImage *image;
			if ([[document valueForKey:@"isEdited"] boolValue] == YES) {
				image = [document valueForKey:@"unsavedIcon"];
			} else {
				image = [document valueForKey:@"icon"];
			}

			[(SMLDocumentsListCell *)aCell setHeightAndWidth:[[[self valueForKey:@"project"] valueForKey:@"viewSize"] doubleValue]];
			[(SMLDocumentsListCell *)aCell setImage:image];
			
			if ([[SMLDefaults valueForKey:@"ShowFullPathInDocumentsList"] boolValue] == YES) {
				[(SMLDocumentsListCell *)aCell setStringValue:[document valueForKey:@"nameWithPath"]];
			} else {
				[(SMLDocumentsListCell *)aCell setStringValue:[document valueForKey:@"name"]];
			}
		}
		
	}
}


- (void)performInsertFirstDocument:(id)document
{	
	[self setFirstDocument:document];
	
	[SMLInterface removeAllSubviewsFromView:firstContentView];
	[firstContentView addSubview:[document valueForKey:@"firstTextScrollView"]];
	if ([[document valueForKey:@"showLineNumberGutter"] boolValue] == YES) {
		[firstContentView addSubview:[document valueForKey:@"firstGutterScrollView"]];
	}
	
	[self updateWindowTitleBarForDocument:document];
	[self resizeViewsForDocument:document]; // If the window has changed since the view was last visible
	[[self documentsTableView] scrollRowToVisible:[[self documentsTableView] selectedRow]];
	
	[[self window] makeFirstResponder:[document valueForKey:@"firstTextView"]];
	[[document valueForKey:@"lineNumbers"] updateLineNumbersForClipView:[[document valueForKey:@"firstTextScrollView"] contentView] checkWidth:NO recolour:YES]; // If the window has changed since the view was last visible
	[SMLInterface updateStatusBar];
	
	[self selectSameDocumentInTabBarAsInDocumentsList];
}

@end
