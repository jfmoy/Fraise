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

#import "SMLApplicationDelegate.h"
#import "SMLOpenSavePerformer.h"
#import "SMLProjectsController.h"
#import "SMLCommandsController.h"
#import "SMLBasicPerformer.h"
#import "SMLServicesController.h"
#import "SMLToolsMenuController.h"
#import "SMLProject.h"
#import "SMLVariousPerformer.h"

#import "ODBEditorSuite.h"

@implementation SMLApplicationDelegate
	
@synthesize persistentStoreCoordinator,  managedObjectModel, managedObjectContext, shouldCreateEmptyDocument, hasFinishedLaunching, isTerminatingApplication, filesToOpenArray, appleEventDescriptor;


static id sharedInstance = nil;

+ (SMLApplicationDelegate *)sharedInstance
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
		
		shouldCreateEmptyDocument = YES;
		hasFinishedLaunching = NO;
		isTerminatingApplication = NO;
		appleEventDescriptor = nil;
    }
	
    return sharedInstance;
}


- (NSString *)applicationSupportFolder
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"Smultron"];
}


- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"SMLDataModel3" ofType:@"mom"]]];
    
    return managedObjectModel;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }

    NSString *applicationSupportFolder = nil;
    NSError *error;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if (![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }

	NSString *storePath = [applicationSupportFolder stringByAppendingPathComponent: @"Smultron3.smultron"];
	
	NSURL *url = [NSURL fileURLWithPath:storePath];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSBinaryStoreType configuration:nil URL:url options:nil error:&error]){
        [[NSApplication sharedApplication] presentError:error];
    }    

    return persistentStoreCoordinator;
}

 
- (NSManagedObjectContext *)managedObjectContext
{
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
}

 
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
	return [[self managedObjectContext] undoManager];
}

 
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

 
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	id item;
	NSArray *array = [[SMLProjectsController sharedDocumentController] documents];
	for (item in array) {
		[item autosave];
		if ([item areAllDocumentsSaved] == NO) {
			return NSTerminateCancel;
		}
	}

	isTerminatingApplication = YES; // This is to avoid changing the document when quiting the application because otherwise it "flashes" when removing the documents
	
	[[SMLCommandsController sharedInstance] clearAnyTemporaryFiles];
	
	if ([[SMLDefaults valueForKey:@"OpenAllDocumentsIHadOpen"] boolValue] == YES) {

		NSMutableArray *documentsArray = [NSMutableArray array];
		NSArray *projects = [[SMLProjectsController sharedDocumentController] documents];
		for (id project in projects) {
			if ([project fileURL] == nil) {
				NSArray *documents = [[project documentsArrayController] arrangedObjects];
				for (id document in documents) {
					if ([document valueForKey:@"path"] != nil && [[document valueForKey:@"fromExternal"] boolValue] != YES) {
						[documentsArray addObject:[document valueForKey:@"path"]];
					}
				}
			}
		}
		
		[SMLDefaults setValue:documentsArray forKey:@"OpenDocuments"];
	}
	
	if ([[SMLDefaults valueForKey:@"OpenAllProjectsIHadOpen"] boolValue] == YES) {
		NSMutableArray *projectsArray = [NSMutableArray array];
		NSArray *array = [[SMLProjectsController sharedDocumentController] documents];
		for (id project in array) {
			if ([project fileURL] != nil) {
				[projectsArray addObject:[[project fileURL] path]];
			}
		}
		
		[SMLDefaults setValue:projectsArray forKey:@"OpenProjects"];
	}
	
	array = [SMLBasic fetchAll:@"Document"]; // Mark any external documents as closed
	for (item in array) {
		if ([[item valueForKey:@"fromExternal"] boolValue] == YES) {
			[SMLVarious sendClosedEventToExternalDocument:item];
		}
	}
	
	[SMLBasic removeAllObjectsForEntity:@"Document"];
	[SMLBasic removeAllObjectsForEntity:@"Encoding"];
	[SMLBasic removeAllObjectsForEntity:@"SyntaxDefinition"];
	[SMLBasic removeAllObjectsForEntity:@"Project"];
	
	NSError *error;
    NSInteger reply = NSTerminateNow;
    
    if (managedObjectContext != nil) {
        if ([managedObjectContext commitEditing]) {
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) { 

                BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
                if (errorResult == YES) {
                    reply = NSTerminateCancel;
                } else {
                    NSInteger alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
                    if (alertReturn == NSAlertAlternateReturn) {
                        reply = NSTerminateCancel;	
                    }
                }
            }
        } else {
            reply = NSTerminateCancel;
        }
    }
    
	if (reply == NSTerminateCancel) {
		isTerminatingApplication = NO;
	}
	
    return reply;
}


- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	filesToOpenArray = [[NSMutableArray alloc] initWithArray:filenames];
	[filesToOpenArray sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	shouldCreateEmptyDocument = NO;
	
	if (hasFinishedLaunching) {
		[SMLOpenSave openAllTheseFiles:filesToOpenArray];
		filesToOpenArray = nil;
	} else if ([[[NSAppleEventManager sharedAppleEventManager] currentAppleEvent] paramDescriptorForKeyword:keyFileSender] != nil || [[[NSAppleEventManager sharedAppleEventManager] currentAppleEvent] paramDescriptorForKeyword:keyAEPropData] != nil) {
		if (appleEventDescriptor == nil) {
			appleEventDescriptor = [[NSAppleEventDescriptor alloc] initWithDescriptorType:[[[NSAppleEventManager sharedAppleEventManager] currentAppleEvent] descriptorType] data:[[[NSAppleEventManager sharedAppleEventManager] currentAppleEvent] data]];
			shouldCreateEmptyDocument = NO;
		}
	}
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[NSApp setServicesProvider:[SMLServicesController sharedInstance]];
	
	[self performSelector:@selector(markItAsTrulyFinishedWithLaunching) withObject:nil afterDelay:0.0]; // Do it this way because otherwise this is called before the values are inserted by Core Data
}


- (void)markItAsTrulyFinishedWithLaunching
{
	if (filesToOpenArray != nil && [filesToOpenArray count] > 0) {
		NSArray *openDocument = [SMLBasic fetchAll:@"Document"];
		if ([openDocument count] != 0) {
			if (SMLCurrentProject != nil) {
				[SMLCurrentProject performCloseDocument:[openDocument objectAtIndex:0]];
			}
		}
		[SMLManagedObjectContext processPendingChanges];
		[SMLOpenSave openAllTheseFiles:filesToOpenArray];
		[SMLCurrentProject selectionDidChange];
		filesToOpenArray = nil;
	} else { // Open previously opened documents/projects only if Smultron wasn't opened by e.g. dragging a document onto the icon
		
		if ([[SMLDefaults valueForKey:@"OpenAllDocumentsIHadOpen"] boolValue] == YES && [[SMLDefaults valueForKey:@"OpenDocuments"] count] > 0) {
			shouldCreateEmptyDocument = NO;
			NSArray *openDocument = [SMLBasic fetchAll:@"Document"];
			if ([openDocument count] != 0) {
				if (SMLCurrentProject != nil) {
					filesToOpenArray = [[NSMutableArray alloc] init]; // A hack so that -[SMLProject performCloseDocument:] won't close the window
					[SMLCurrentProject performCloseDocument:[openDocument objectAtIndex:0]];
					filesToOpenArray = nil;
				}
			}
			[SMLManagedObjectContext processPendingChanges];
			[SMLOpenSave openAllTheseFiles:[SMLDefaults valueForKey:@"OpenDocuments"]];
			[SMLCurrentProject selectionDidChange];
		}
		
		if ([[SMLDefaults valueForKey:@"OpenAllProjectsIHadOpen"] boolValue] == YES && [[SMLDefaults valueForKey:@"OpenProjects"] count] > 0) {
			shouldCreateEmptyDocument = NO;
			[SMLOpenSave openAllTheseFiles:[SMLDefaults valueForKey:@"OpenProjects"]];
		}
	}

	hasFinishedLaunching = YES;
	shouldCreateEmptyDocument = NO;

	// Do this here so that it won't slow down the perceived start-up time
	[[SMLToolsMenuController sharedInstance] buildInsertSnippetMenu];
	[[SMLToolsMenuController sharedInstance] buildRunCommandMenu];
	
	if ([[SMLDefaults valueForKey:@"HasImportedFromVersion2"] boolValue] == NO) {
		[self importFromVersion2];
	}

}


- (void)changeFont:(id)sender // When you change the font in the print panel
{
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSFont *panelFont = [fontManager convertFont:[fontManager selectedFont]];
	[SMLDefaults setValue:[NSArchiver archivedDataWithRootObject:panelFont] forKey:@"PrintFont"];
}


- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	if ([[SMLDefaults valueForKey:@"OpenAllProjectsIHadOpen"] boolValue] == YES && [[SMLDefaults valueForKey:@"OpenProjects"] count] > 0 || [[[SMLProjectsController sharedDocumentController] documents] count] > 0) {
		return NO;
	} else {
		return [[SMLDefaults valueForKey:@"NewDocumentAtStartup"] boolValue];
	}
}


- (NSMenu *)applicationDockMenu:(NSApplication *)sender
{
	NSMenu *returnMenu = [[NSMenu alloc] init];
	NSMenuItem *menuItem;
	id document;
	
	NSEnumerator *currentProjectEnumerator = [[[SMLCurrentProject documentsArrayController] arrangedObjects] reverseObjectEnumerator];
	for (document in currentProjectEnumerator) {
		menuItem = [[NSMenuItem alloc] initWithTitle:[document valueForKey:@"name"] action:@selector(selectDocumentFromTheDock:) keyEquivalent:@""];
		[menuItem setTarget:[SMLProjectsController sharedDocumentController]];
		[menuItem setRepresentedObject:document];
		[returnMenu insertItem:menuItem atIndex:0];
	}
	
	NSArray *projects = [[SMLProjectsController sharedDocumentController] documents];
	for (id project in projects) {
		if (project == SMLCurrentProject) {
			continue;
		}
		NSMenu *menu;
		if ([project valueForKey:@"name"] == nil) {
			menu = [[NSMenu alloc] initWithTitle:UNTITLED_PROJECT_NAME];
		} else {
			menu = [[NSMenu alloc] initWithTitle:[project valueForKey:@"name"]];
		}
		
		NSEnumerator *documentsEnumerator = [[[(SMLProject *)project documents] allObjects] reverseObjectEnumerator];
		for (document in documentsEnumerator) {
			menuItem = [[NSMenuItem alloc] initWithTitle:[document valueForKey:@"name"] action:@selector(selectDocumentFromTheDock:) keyEquivalent:@""];
			[menuItem setTarget:[SMLProjectsController sharedDocumentController]];
			[menuItem setRepresentedObject:document];
			[menu insertItem:menuItem atIndex:0];
		}
		
		NSMenuItem *subMenuItem = [[NSMenuItem alloc] initWithTitle:[menu title] action:nil keyEquivalent:@""];
		[subMenuItem setSubmenu:menu];
		[returnMenu addItem:subMenuItem];
	}

	return returnMenu;
}


- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
	if ([[SMLDefaults valueForKey:@"CheckIfDocumentHasBeenUpdated"] boolValue] == YES) { // Check for updates directly when Smultron gets focus
		[SMLVarious checkIfDocumentsHaveBeenUpdatedByAnotherApplication];
	}
}


#pragma mark
#pragma mark Import from version 2

- (void)importFromVersion2
{
	[SMLDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"HasImportedFromVersion2"];
	
	@try {
		NSManagedObjectModel *managedObjectModelVersion2 = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"SMLDataModel2" ofType:@"mom"]]];
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *applicationSupportFolder = [self applicationSupportFolder];
		if (![fileManager fileExistsAtPath:[applicationSupportFolder stringByAppendingPathComponent:@"Smultron.smultron"] isDirectory:NULL]) {
			return;
		}
		
		NSURL *url = [NSURL fileURLWithPath:[applicationSupportFolder stringByAppendingPathComponent:@"Smultron.smultron"]];
		NSPersistentStoreCoordinator *persistentStoreCoordinatorVersion2 = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModelVersion2];
		if (![persistentStoreCoordinatorVersion2 addPersistentStoreWithType:NSBinaryStoreType configuration:nil URL:url options:nil error:nil]){
			return;
		}  
		
		NSManagedObjectContext *managedObjectContextVersion2 = [[NSManagedObjectContext alloc] init];
		[managedObjectContextVersion2 setPersistentStoreCoordinator:persistentStoreCoordinatorVersion2];
		
		NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Command" inManagedObjectContext:managedObjectContextVersion2];
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		[request setEntity:entityDescription];
		
		// Commands
		NSArray *oldCommands = [managedObjectContextVersion2 executeFetchRequest:request error:nil];
		if ([oldCommands count] != 0) {			
			id newCollection = [SMLBasic createNewObjectForEntity:@"CommandCollection"];
			[newCollection setValue:NSLocalizedStringFromTable(@"Old Commands", @"Localizable3", @"Old Commands") forKey:@"name"];			
			
			id command;
			for (command in oldCommands) {
				id newCommand = [SMLBasic createNewObjectForEntity:@"Command"];
				[newCommand setValue:[command valueForKey:@"command"] forKey:@"name"];
				[newCommand setValue:[command valueForKey:@"command"] forKey:@"text"];			
				[newCommand setValue:[command valueForKey:@"shortcutDisplayString"] forKey:@"shortcutDisplayString"];
				[newCommand setValue:[command valueForKey:@"shortcutMenuItemKeyString"] forKey:@"shortcutMenuItemKeyString"];
				[newCommand setValue:[command valueForKey:@"shortcutModifier"] forKey:@"shortcutModifier"];
				[newCommand setValue:[command valueForKey:@"sortOrder"] forKey:@"sortOrder"];
				[newCommand setValue:[NSNumber numberWithInteger:3] forKey:@"version"];
				[[newCollection mutableSetValueForKey:@"commands"] addObject:newCommand];
			}
		}
		
		
		// Snippets
		entityDescription = [NSEntityDescription entityForName:@"SnippetCollection" inManagedObjectContext:managedObjectContextVersion2];
		request = [[NSFetchRequest alloc] init];
		[request setEntity:entityDescription];
		
		NSArray *collections = [managedObjectContextVersion2 executeFetchRequest:request error:nil];
		for (id collection in collections) {
			id newCollection = [SMLBasic createNewObjectForEntity:@"SnippetCollection"];
			[newCollection setValue:[collection valueForKey:@"name"] forKey:@"name"];
			
			NSEntityDescription *entityDescriptionSnippet = [NSEntityDescription entityForName:@"Snippet" inManagedObjectContext:managedObjectContextVersion2];
			NSFetchRequest *requestSnippet = [[NSFetchRequest alloc] init];
			[requestSnippet setEntity:entityDescriptionSnippet];
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"collectionUUID == %@", [collection valueForKey:@"uuid"]];
			[requestSnippet setPredicate:predicate];
			
			NSArray *snippets = [managedObjectContextVersion2 executeFetchRequest:requestSnippet error:nil];
			for (id oldSnippet in snippets) {
				id snippet = [SMLBasic createNewObjectForEntity:@"Snippet"];
				[snippet setValue:[oldSnippet valueForKey:@"name"] forKey:@"name"];
				[snippet setValue:[oldSnippet valueForKey:@"text"] forKey:@"text"];			
				[snippet setValue:[oldSnippet valueForKey:@"shortcutDisplayString"] forKey:@"shortcutDisplayString"];
				[snippet setValue:[oldSnippet valueForKey:@"shortcutMenuItemKeyString"] forKey:@"shortcutMenuItemKeyString"];
				[snippet setValue:[oldSnippet valueForKey:@"shortcutModifier"] forKey:@"shortcutModifier"];
				[snippet setValue:[oldSnippet valueForKey:@"sortOrder"] forKey:@"sortOrder"];
				[[newCollection mutableSetValueForKey:@"snippets"] addObject:snippet];
			}			
		}
		
	}
	@catch (NSException *exception) {
	}
}

@end
