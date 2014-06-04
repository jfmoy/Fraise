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

#import "FRAServicesController.h"
#import "FRAProjectsController.h"
#import "FRAOpenSavePerformer.h"
#import "FRAProject.h"


@implementation FRAServicesController

static id sharedInstance = nil;

+ (FRAServicesController *)sharedInstance
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
	
	if (FRACurrentProject == nil) {
		if ([[[FRAProjectsController sharedDocumentController] documents] count] > 0) {
			[[FRAProjectsController sharedDocumentController] setCurrentProject:[[FRAProjectsController sharedDocumentController] documentForWindow:[NSApp orderedWindows][0]]];
		} else {
			[[FRAProjectsController sharedDocumentController] newDocument:nil];
		}
	}
	if (![[FRACurrentDocument valueForKey:@"firstTextView"] readSelectionFromPasteboard:pboard type:NSStringPboardType]) {
		NSBeep();
	}
}


- (void)openSelection:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error 
{
	if (![[pboard types] containsObject:NSStringPboardType]) {
		NSBeep();
		return;
	}
	
	if (FRACurrentProject == nil) {
		if ([[[FRAProjectsController sharedDocumentController] documents] count] > 0) {
			[[FRAProjectsController sharedDocumentController] setCurrentProject:[[FRAProjectsController sharedDocumentController] documentForWindow:[NSApp orderedWindows][0]]];
		} else {
			[[FRAProjectsController sharedDocumentController] newDocument:nil];
		}
	}
	
	id document = [FRACurrentProject createNewDocumentWithContents:@""];

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
	
	NSString *path = [pboard propertyListForType:NSFilenamesPboardType][0];
	[FRAOpenSave shouldOpen:path withEncoding:0];
}


@end
