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

#import "FRADocumentsMenuController.h"
#import "FRAProjectsController.h"
#import "FRAProject.h"

@implementation FRADocumentsMenuController

static id sharedInstance = nil;

+ (FRADocumentsMenuController *)sharedInstance
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


- (void)awakeFromNib
{
	[documentsMenu setDelegate:self];
}


- (IBAction)nextDocumentAction:(id)sender
{
	NSInteger currentDocument = [[FRACurrentProject documentsArrayController] selectionIndex];
	if (currentDocument + 2 > [[FRACurrentProject documents] count]) {
		[[FRACurrentProject documentsArrayController] setSelectedObjects:@[[[FRACurrentProject documentsArrayController] arrangedObjects][0]]];
	} else {
		[[FRACurrentProject documentsArrayController] setSelectedObjects:@[[[FRACurrentProject documentsArrayController] arrangedObjects][(currentDocument + 1)]]];
	}
}


- (IBAction)previousDocumentAction:(id)sender
{
	NSInteger currentDocument = [[FRACurrentProject documentsArrayController] selectionIndex];
	if (currentDocument == 0) {
		[[FRACurrentProject documentsArrayController] setSelectedObjects:@[[[FRACurrentProject documentsArrayController] arrangedObjects][[[FRACurrentProject documents] count] - 1]]];
	} else {
		[[FRACurrentProject documentsArrayController] setSelectedObjects:@[[[FRACurrentProject documentsArrayController] arrangedObjects][(currentDocument - 1)]]];
	}
}


- (void)buildDocumentsMenu
{
	NSMenuItem *menuItem;
	NSArray *array = [documentsMenu itemArray];
	for (menuItem in array) {
		if ([menuItem action] != @selector(nextDocumentAction:) && [menuItem action] != @selector(previousDocumentAction:) && [menuItem isSeparatorItem] == NO) {
			[documentsMenu removeItem:menuItem];
		}
	}
	
	array = [[FRACurrentProject documentsArrayController] arrangedObjects];

	NSInteger index = 1;
	for (id document in array) {
		if (index < 10) {
			menuItem = [[NSMenuItem alloc] initWithTitle:[document valueForKey:@"name"] action:@selector(changeSelectedDocument:) keyEquivalent:[[NSNumber numberWithUnsignedShort:index] stringValue]];
		} else if (index == 10) {
			menuItem = [[NSMenuItem alloc] initWithTitle:[document valueForKey:@"name"] action:@selector(changeSelectedDocument:) keyEquivalent:@"0"];
		} else {
			menuItem = [[NSMenuItem alloc] initWithTitle:[document valueForKey:@"name"] action:@selector(changeSelectedDocument:) keyEquivalent:@""];
		}

		[menuItem setTarget:self];
		[menuItem setRepresentedObject:document];
		[documentsMenu insertItem:menuItem atIndex:index + 2];
		index++;
	}

	array = [[FRAProjectsController sharedDocumentController] documents];
	for (id project in array) {
		if (project == FRACurrentProject) {
			continue;
		}
		NSMenu *menu;
		if ([project valueForKey:@"name"] == nil) {
			menu = [[NSMenu alloc] initWithTitle:UNTITLED_PROJECT_NAME];
		} else {
			menu = [[NSMenu alloc] initWithTitle:[project valueForKey:@"name"]];
		}
		
		NSEnumerator *documentsEnumerator = [[[(FRAProject *)project documents] allObjects] reverseObjectEnumerator];
		for (id document in documentsEnumerator) {
			menuItem = [[NSMenuItem alloc] initWithTitle:[document valueForKey:@"name"] action:@selector(changeSelectedDocument:) keyEquivalent:@""];
			[menuItem setTarget:self];
			[menuItem setRepresentedObject:document];
			[menu insertItem:menuItem atIndex:0];
		}
		
		NSMenuItem *subMenuItem = [[NSMenuItem alloc] initWithTitle:[menu title] action:nil keyEquivalent:@""];
		[subMenuItem setSubmenu:menu];
		[documentsMenu addItem:subMenuItem];
	}

}


- (void)changeSelectedDocument:(id)sender
{
	[[FRAProjectsController sharedDocumentController] selectDocument:[sender representedObject]];
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	BOOL enableMenuItem = YES;
	if ([[FRACurrentProject documents] count] < 2) {
		if ([anItem action] == @selector(nextDocumentAction:) || [anItem action] == @selector(previousDocumentAction:)) { // Next and Previous document
			enableMenuItem = NO;
		}
	}
	
	return enableMenuItem;
}


- (void)menuNeedsUpdate:(NSMenu *)menu
{
	[self buildDocumentsMenu];
}
@end
