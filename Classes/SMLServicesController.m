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

#import "SMLServicesController.h"
#import "SMLProjectsController.h"
#import "SMLOpenSavePerformer.h"
#import "SMLProject.h"


@implementation SMLServicesController

static id sharedInstance = nil;

+ (SMLServicesController *)sharedInstance
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


- (void)insertSelection:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error 
{
	if (![[pboard types] containsObject:NSStringPboardType]) {
		NSBeep();
		return;
	}
	
	if (SMLCurrentProject == nil) {
		if ([[[SMLProjectsController sharedDocumentController] documents] count] > 0) {
			[[SMLProjectsController sharedDocumentController] setCurrentProject:[[SMLProjectsController sharedDocumentController] documentForWindow:[[NSApp orderedWindows] objectAtIndex:0]]];
		} else {
			[[SMLProjectsController sharedDocumentController] newDocument:nil];
		}
	}
	if (![[SMLCurrentDocument valueForKey:@"firstTextView"] readSelectionFromPasteboard:pboard type:NSStringPboardType]) {
		NSBeep();
	}
}


- (void)openSelection:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error 
{
	if (![[pboard types] containsObject:NSStringPboardType]) {
		NSBeep();
		return;
	}
	
	if (SMLCurrentProject == nil) {
		if ([[[SMLProjectsController sharedDocumentController] documents] count] > 0) {
			[[SMLProjectsController sharedDocumentController] setCurrentProject:[[SMLProjectsController sharedDocumentController] documentForWindow:[[NSApp orderedWindows] objectAtIndex:0]]];
		} else {
			[[SMLProjectsController sharedDocumentController] newDocument:nil];
		}
	}
	
	id document = [SMLCurrentProject createNewDocumentWithContents:@""];

	if (![[document valueForKey:@"firstTextView"] readSelectionFromPasteboard:pboard type:NSStringPboardType]) {
		NSBeep();
	}
}


- (void)openFile:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error
{
	if (![[pboard types] containsObject:NSFilenamesPboardType]) {
		NSBeep();
		return;
	}
	
	NSString *path = [[pboard propertyListForType:NSFilenamesPboardType] objectAtIndex:0];
	[SMLOpenSave shouldOpen:path withEncoding:0];
}


@end
