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

#import "FRAProject+TableViewDelegate.h"
#import "FRAApplicationDelegate.h"
#import "FRADocumentsListCell.h"
#import "FRAInterfacePerformer.h"
#import "FRAVariousPerformer.h"
#import "FRALineNumbers.h"
#import "FRAProject+DocumentViewsController.h"

@implementation FRAProject (TableViewDelegate)


- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSTableView *tableView = [aNotification object];
	if (tableView == [self documentsTableView] || aNotification == nil) {
		if ([[FRAApplicationDelegate sharedInstance] isTerminatingApplication] == YES) {
			return;
		}
		if ([[[self documentsArrayController] arrangedObjects] count] < 1 || [[[self documentsArrayController] selectedObjects] count] < 1) {
			[self updateWindowTitleBarForDocument:nil];
			return;
		}
		
		id document = [[self documentsArrayController] selectedObjects][0];
		
		[self performInsertFirstDocument:document];
	}
	
}


- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ([[FRADefaults valueForKey:@"SizeOfDocumentsListTextPopUp"] integerValue] == 0) {
		[aCell setFont:[NSFont systemFontOfSize:11.0]];
	} else {
		[aCell setFont:[NSFont systemFontOfSize:13.0]];
	}
	
	if (aTableView == [self documentsTableView]) {
		id document = [[self documentsArrayController] arrangedObjects][rowIndex];
		
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

			[(FRADocumentsListCell *)aCell setHeightAndWidth:[[[self valueForKey:@"project"] valueForKey:@"viewSize"] doubleValue]];
			[(FRADocumentsListCell *)aCell setImage:image];
			
			if ([[FRADefaults valueForKey:@"ShowFullPathInDocumentsList"] boolValue] == YES) {
				[(FRADocumentsListCell *)aCell setStringValue:[document valueForKey:@"nameWithPath"]];
			} else {
				[(FRADocumentsListCell *)aCell setStringValue:[document valueForKey:@"name"]];
			}
		}
		
	}
}


- (void)performInsertFirstDocument:(id)document
{	
	[self setFirstDocument:document];
	
	[FRAInterface removeAllSubviewsFromView:firstContentView];
	[firstContentView addSubview:[document valueForKey:@"firstTextScrollView"]];
	if ([[document valueForKey:@"showLineNumberGutter"] boolValue] == YES) {
		[firstContentView addSubview:[document valueForKey:@"firstGutterScrollView"]];
	}
	
	[self updateWindowTitleBarForDocument:document];
	[self resizeViewsForDocument:document]; // If the window has changed since the view was last visible
	[[self documentsTableView] scrollRowToVisible:[[self documentsTableView] selectedRow]];
	
	[[self window] makeFirstResponder:[document valueForKey:@"firstTextView"]];
	[[document valueForKey:@"lineNumbers"] updateLineNumbersForClipView:[[document valueForKey:@"firstTextScrollView"] contentView] checkWidth:NO recolour:YES]; // If the window has changed since the view was last visible
	[FRAInterface updateStatusBar];
	
	[self selectSameDocumentInTabBarAsInDocumentsList];
}

@end
