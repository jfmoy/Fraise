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

#import "FRAVariousPerformer.h"
#import "NSString+Fraise.h"
#import "FRABasicPerformer.h"
#import "FRAProjectsController.h"
#import "FRAMainController.h"
#import "FRACommandsController.h"
#import "FRAFileMenuController.h"
#import "FRAExtraInterfaceController.h"
#import "FRAProject.h"
#import "FRAProject+DocumentViewsController.h"
#import "NSImage+Fraise.h"

#import "ODBEditorSuite.h"
#import "FRATextView.h"





@implementation FRAVariousPerformer

static id sharedInstance = nil;

+ (FRAVariousPerformer *)sharedInstance
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
		untitledNumber = 1;
		
		isChangingSyntaxDefinitionsProgrammatically = NO; // So that FRAManagedObject does not need to care about changes when resetting the preferences
    }
    return sharedInstance;
}



- (void)updateCheckIfAnotherApplicationHasChangedDocumentsTimer
{
	if ([[FRADefaults valueForKey:@"CheckIfDocumentHasBeenUpdated"] boolValue] == YES) {
		
		NSInteger interval = [[FRADefaults valueForKey:@"TimeBetweenDocumentUpdateChecks"] integerValue];
		if (interval < 1) {
			interval = 1;
		}
		checkIfAnotherApplicationHasChangedDocumentsTimer = 
			[NSTimer scheduledTimerWithTimeInterval:interval target:FRAVarious selector:@selector(checkIfDocumentsHaveBeenUpdatedByAnotherApplication)	userInfo:nil repeats:YES];
	} else {
		if (checkIfAnotherApplicationHasChangedDocumentsTimer) {
			[checkIfAnotherApplicationHasChangedDocumentsTimer invalidate];
			checkIfAnotherApplicationHasChangedDocumentsTimer = nil;
		}
	}
}


- (void)insertTextEncodings
{
	const NSStringEncoding *availableEncodings = [NSString availableStringEncodings];
	NSStringEncoding encoding;
	NSArray *activeEncodings = [FRADefaults valueForKey:@"ActiveEncodings"];
	while ((encoding = *availableEncodings++))
    {
		id item = [FRABasic createNewObjectForEntity:@"Encoding"];
		NSNumber *encodingObject = [NSNumber numberWithInteger:encoding];
		if ([activeEncodings containsObject:encodingObject]) {
			[item setValue:@YES forKey:@"active"];
		}
		[item setValue:encodingObject forKey:@"encoding"];
		[item setValue:[NSString localizedNameOfStringEncoding:encoding] forKey:@"name"];
	}
}


- (void)insertSyntaxDefinitions
{
	isChangingSyntaxDefinitionsProgrammatically = YES;
	NSMutableArray *syntaxDefinitionsArray = [[NSMutableArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SyntaxDefinitions" ofType:@"plist"]];
	NSString *path = [[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Fraise"] stringByAppendingPathComponent:@"SyntaxDefinitions.plist"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path] == YES) {
		NSArray *syntaxDefinitionsUserArray = [[NSArray alloc] initWithContentsOfFile:path];
		[syntaxDefinitionsArray addObjectsFromArray:syntaxDefinitionsUserArray];
	}
	
	NSArray *keys = @[@"name", @"file", @"extensions"];
	NSDictionary *standard = [NSDictionary dictionaryWithObjects:@[@"Standard", @"standard", [NSString string]] forKeys:keys];
	NSDictionary *none = [NSDictionary dictionaryWithObjects:@[@"None", @"none", [NSString string]] forKeys:keys];
	[syntaxDefinitionsArray insertObject:none atIndex:0];
	[syntaxDefinitionsArray insertObject:standard atIndex:0];
	
	NSMutableArray *changedSyntaxDefinitionsArray = nil;
	if ([FRADefaults valueForKey:@"ChangedSyntaxDefinitions"]) {
		changedSyntaxDefinitionsArray = [NSMutableArray arrayWithArray:[FRADefaults valueForKey:@"ChangedSyntaxDefinitions"]];
	}
	
	id item;
	NSInteger index = 0;
	for (item in syntaxDefinitionsArray) {
		if ([[item valueForKey:@"extensions"] isKindOfClass:[NSArray class]]) { // If extensions is an array instead of a string, i.e. an older version
			continue;
		}
		id syntaxDefinition = [FRABasic createNewObjectForEntity:@"SyntaxDefinition"];
		NSString *name = [item valueForKey:@"name"];
		[syntaxDefinition setValue:name forKey:@"name"];
		[syntaxDefinition setValue:[item valueForKey:@"file"] forKey:@"file"];
		[syntaxDefinition setValue:@(index) forKey:@"sortOrder"];
		index++;
		
		BOOL hasInsertedAChangedValue = NO;
		if (changedSyntaxDefinitionsArray != nil) {
			for (id changedObject in changedSyntaxDefinitionsArray) {
				if ([[changedObject valueForKey:@"name"] isEqualToString:name]) {
					[syntaxDefinition setValue:[changedObject valueForKey:@"extensions"] forKey:@"extensions"];
					hasInsertedAChangedValue = YES;
					break;
				}					
			}
		} 
		
		if (hasInsertedAChangedValue == NO) {
			[syntaxDefinition setValue:[item valueForKey:@"extensions"] forKey:@"extensions"];
		}		
	}

	isChangingSyntaxDefinitionsProgrammatically = NO;
}


- (void)insertDefaultSnippets
{
	if ([[FRABasic fetchAll:@"Snippet"] count] == 0 && [[FRADefaults valueForKey:@"HasInsertedDefaultSnippets"] boolValue] == NO) {
		NSDictionary *defaultSnippets = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultSnippets" ofType:@"plist"]];
		
		NSEnumerator *collectionEnumerator = [defaultSnippets keyEnumerator];
		for (id collection in collectionEnumerator) {
			id newCollection = [FRABasic createNewObjectForEntity:@"SnippetCollection"];
			[newCollection setValue:collection forKey:@"name"];
			NSArray *array = [defaultSnippets valueForKey:collection];
			for (id snippet in array) {
				id newSnippet = [FRABasic createNewObjectForEntity:@"Snippet"];
				[newSnippet setValue:[snippet valueForKey:@"name"] forKey:@"name"];
				[newSnippet setValue:[snippet valueForKey:@"text"] forKey:@"text"];
				[[newCollection mutableSetValueForKey:@"snippets"] addObject:newSnippet];
			}
		}
		
		[FRADefaults setValue:@YES forKey:@"HasInsertedDefaultSnippets"];
	}
}


- (void)insertDefaultCommands
{
	if ([[FRADefaults valueForKey:@"HasInsertedDefaultCommands3"] boolValue] == NO) {
		
		NSDictionary *defaultCommands = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultCommands" ofType:@"plist"]];
		
		NSEnumerator *collectionEnumerator = [defaultCommands keyEnumerator];
		for (id collection in collectionEnumerator) {
			id newCollection = [FRABasic createNewObjectForEntity:@"CommandCollection"];
			[newCollection setValue:collection forKey:@"name"];
			NSEnumerator *snippetEnumerator = [[defaultCommands valueForKey:collection] objectEnumerator];
			for (id command in snippetEnumerator) {
				id newCommand = [FRABasic createNewObjectForEntity:@"Command"];
				[newCommand setValue:[command valueForKey:@"name"] forKey:@"name"];
				[newCommand setValue:[command valueForKey:@"text"] forKey:@"text"];
				if ([command valueForKey:@"inline"] != nil) {
					[newCommand setValue:[command valueForKey:@"inline"] forKey:@"inline"];
				}
				if ([command valueForKey:@"interpreter"] != nil) {
					[newCommand setValue:[command valueForKey:@"interpreter"] forKey:@"interpreter"];
				}
				[[newCollection mutableSetValueForKey:@"commands"] addObject:newCommand];
			}
		}
		
		[FRADefaults setValue:@YES forKey:@"HasInsertedDefaultCommands3"];
	}
}


- (void)standardAlertSheetWithTitle:(NSString *)title message:(NSString *)message window:(NSWindow *)window
{
	if ([window attachedSheet]) {
		[[window attachedSheet] close];
	}
    
    NSAlert* alert = [[NSAlert alloc] init];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert addButtonWithTitle:OK_BUTTON];
    [alert setAlertStyle:NSAlertStyleInformational];
    
    [alert beginSheetModalForWindow:window completionHandler:^(NSInteger returnCode) {
        [self stopModalLoop];
    }];

    [NSApp runModalForWindow:[window attachedSheet]]; // Modal to catch if there are sheets for many files to be displayed
}


- (void)sheetDidDismiss:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
	[sheet close];
	[self stopModalLoop];
}


- (void)stopModalLoop
{
	[NSApp stopModal];
	[[FRACurrentWindow standardWindowButton:NSWindowCloseButton] setEnabled:YES];
	[[FRACurrentWindow standardWindowButton:NSWindowMiniaturizeButton] setEnabled:YES];
	[[FRACurrentWindow standardWindowButton:NSWindowZoomButton] setEnabled:YES];
}


- (void)sendModifiedEventToExternalDocument:(id)document path:(NSString *)path
{
	BOOL fromSaveAs = NO;
	NSString *currentPath = [document valueForKey:@"path"];
	if ([path isEqualToString:currentPath] == NO) {
		fromSaveAs = YES;
	}
	
	NSURL *url = [NSURL fileURLWithPath:currentPath];
	NSData *data = [[url absoluteString] dataUsingEncoding:NSUTF8StringEncoding];
	
	OSType signature = [[document valueForKey:@"externalSender"] typeCodeValue];
	NSAppleEventDescriptor *descriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature bytes:&signature length:sizeof(OSType)];
	NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kODBEditorSuite eventID:kAEModifiedFile targetDescriptor:descriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithDescriptorType:typeFileURL data:data] forKeyword:keyDirectObject];
	
	if ([document valueForKey:@"externalToken"]) {
		[event setParamDescriptor:[document valueForKey:@"externalToken"] forKeyword:keySenderToken];
	}
	if (fromSaveAs) {
		[descriptor setParamDescriptor:[NSAppleEventDescriptor descriptorWithDescriptorType:typeFileURL data:data] forKeyword:keyNewLocation];
		[document setValue:@NO forKey:@"fromExternal"]; // If it's a Save As it no longer belongs to the external program
	}
	
	AppleEvent *eventPointer = (AEDesc *)[event aeDesc];
	
	if (eventPointer) {
		AESendMessage(eventPointer, NULL, kAENoReply, kAEDefaultTimeout);
	}
}


- (void)sendClosedEventToExternalDocument:(id)document
{
	NSURL *url = [NSURL fileURLWithPath:[document valueForKey:@"path"]];
	NSData *data = [[url absoluteString] dataUsingEncoding:NSUTF8StringEncoding];
	
	OSType signature = [[document valueForKey:@"externalSender"] typeCodeValue];
	NSAppleEventDescriptor *descriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature bytes:&signature length:sizeof(OSType)];
	
	NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kODBEditorSuite eventID:kAEClosedFile targetDescriptor:descriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithDescriptorType:typeFileURL data:data] forKeyword:keyDirectObject];

	if ([document valueForKey:@"externalToken"]) {
		[event setParamDescriptor:[document valueForKey:@"externalToken"] forKeyword:keySenderToken];
	}
	
	AppleEvent *eventPointer = (AEDesc *)[event aeDesc];
	
	if (eventPointer) {
		AESendMessage(eventPointer, NULL, kAENoReply, kAEDefaultTimeout);
	}
}


- (NSInteger)alertWithMessage:(NSString *)message informativeText:(NSString *)informativeText defaultButton:(NSString *)defaultButton alternateButton:(NSString *)alternateButton otherButton:(NSString *)otherButton
{	
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:message];
	[alert setInformativeText:informativeText];
	if (defaultButton != nil) {
		[alert addButtonWithTitle:defaultButton];
	}
	if (alternateButton != nil) {
		[alert addButtonWithTitle:alternateButton];
	}
	if (otherButton != nil) {
		[alert addButtonWithTitle:otherButton];
	}
	
	return [alert runModal];
	// NSAlertFirstButtonReturn
	// NSAlertSecondButtonReturn
	// NSAlertThirdButtonReturn
}




- (void)checkIfDocumentsHaveBeenUpdatedByAnotherApplication
{
	if ([FRACurrentProject areThereAnyDocuments] == NO || [FRAMain isInFullScreenMode] == YES || [[FRADefaults valueForKey:@"CheckIfDocumentHasBeenUpdated"] boolValue] == NO || [FRACurrentWindow attachedSheet] != nil) {
		return;
	}
	
	NSArray *array = [FRABasic fetchAll:@"Document"];
	for (id item in array) {
		if ([[item valueForKey:@"isNewDocument"] boolValue] == YES || [[item valueForKey:@"ignoreAnotherApplicationHasUpdatedDocument"] boolValue] == YES) {
			continue;
		}
		NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[item valueForKey:@"path"] error:nil];
		if ([attributes fileModificationDate] == nil) {
			continue; // If fileModificationDate is nil the file has been removed or renamed there's no need to check the dates then
		}
		if (![[[item valueForKey:@"fileAttributes"] fileModificationDate] isEqualToDate:[attributes fileModificationDate]]) {
			if ([[FRADefaults valueForKey:@"UpdateDocumentAutomaticallyWithoutWarning"] boolValue] == YES) {
				[[FRAFileMenuController sharedInstance] performRevertOfDocument:item];
				[item setValue:[[NSFileManager defaultManager] attributesOfItemAtPath:[item valueForKey:@"path"] error:nil] forKey:@"fileAttributes"];
			} else {
				if ([NSApp isHidden]) { // To display the sheet properly if the application is hidden
					[NSApp activateIgnoringOtherApps:YES]; 
					[FRACurrentWindow makeKeyAndOrderFront:self];
				}
				
				NSString *title = [NSString stringWithFormat:NSLocalizedString(@"The document %@ has been updated by another application", @"Indicate that the document %@ has been updated by another application in Document-has-been-updated-alert sheet"), [item valueForKey:@"path"]];
				NSString *message;
				if ([[item valueForKey:@"isEdited"] boolValue] == YES) {
					message = NSLocalizedString(@"Do you want to ignore the updates the other application has made or reload the document and destroy any changes you have made to this document?", @"Ask whether they want to ignore the updates the other application has made or reload the document and destroy any changes you have made to this document Document-has-been-updated-alert sheet");
				} else {
					message = NSLocalizedString(@"Do you want to ignore the updates the other application has made or reload the document?", @"Ask whether they want to ignore the updates the other application has made or reload the document Document-has-been-updated-alert sheet");
				}
                
                NSAlert* alert = [[NSAlert alloc] init];
                [alert setMessageText:title];
                [alert setInformativeText:message];
                [alert addButtonWithTitle:NSLocalizedString(@"Ignore", @"Ignore-button in Document-has-been-updated-alert sheet")];
                [alert addButtonWithTitle:NSLocalizedString(@"Reload", @"Reload-button in Document-has-been-updated-alert sheet")];
                [alert setAlertStyle:NSAlertStyleInformational];
                
                [alert beginSheetModalForWindow:FRACurrentWindow completionHandler:^(NSInteger returnCode) {
                    [self stopModalLoop];
                    
                    id document = item;
                    if (returnCode == NSAlertFirstButtonReturn) {
                        [document setValue:@YES forKey:@"ignoreAnotherApplicationHasUpdatedDocument"];
                    } else if (returnCode == NSAlertSecondButtonReturn) {
                        [[FRAFileMenuController sharedInstance] performRevertOfDocument:document];
                        [document setValue:[[NSFileManager defaultManager] attributesOfItemAtPath:[document valueForKey:@"path"] error:nil] forKey:@"fileAttributes"];
                    }
                }];
                [NSApp runModalForWindow:[FRACurrentWindow attachedSheet]];
			}
		}
	}
}

- (NSString *)performCommand:(NSString *)command
{
	NSMutableString *returnString = [NSMutableString string];
	
	@try {
		NSTask *task = [[NSTask alloc] init];
		NSPipe *pipe = [[NSPipe alloc] init];
		NSPipe *errorPipe = [[NSPipe alloc] init];
		
		NSMutableArray *splitArray = [NSMutableArray arrayWithArray:[command divideCommandIntoArray]];
		[task setLaunchPath:splitArray[0]];
		[splitArray removeObjectAtIndex:0];
		
		[task setArguments:splitArray];
		[task setStandardOutput:pipe];
		[task setStandardError:errorPipe];
		
		[task launch];
		
		[task waitUntilExit];
		
		NSString *errorString = [[NSString alloc] initWithData:[[errorPipe fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding];
		NSString *outputString = [[NSString alloc] initWithData:[[pipe fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding];
		[returnString appendString:errorString];
		[returnString appendString:outputString];
	}
	@catch (NSException *exception) {
		[returnString appendString:NSLocalizedString(@"Unknown error when running the command", @"Unknown error when running the command in performCommand")];
	}
	@finally {
		return returnString;
	}
}


- (void)performCommandAsynchronously:(NSString *)command
{
	asynchronousTaskResult = [[NSMutableString alloc] initWithString:@""];
	
	asynchronousTask = [[NSTask alloc] init];
	
	if (FRACurrentDocument != nil && [FRACurrentDocument valueForKey:@"path"] != nil) {
		NSMutableDictionary *defaultEnvironment = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]];
		NSString *envPath = @(getenv("PATH"));
		NSString *directory = [[FRACurrentDocument valueForKey:@"path"] stringByDeletingLastPathComponent];
		defaultEnvironment[@"PATH"] = [NSString stringWithFormat:@"%@:%@", envPath, directory];
		defaultEnvironment[@"PWD"] = directory;
		[asynchronousTask setEnvironment:defaultEnvironment];
	}
	
	NSMutableArray *splitArray = [NSMutableArray arrayWithArray:[command divideCommandIntoArray]];
	//NSLog([splitArray description]);
	[asynchronousTask setLaunchPath:splitArray[0]];
	[splitArray removeObjectAtIndex:0];
	[asynchronousTask setArguments:splitArray];
	
	[asynchronousTask setStandardOutput:[NSPipe pipe]];
	[asynchronousTask setStandardError:[asynchronousTask standardOutput]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(asynchronousDataReceived:) name:NSFileHandleReadCompletionNotification object:[[asynchronousTask standardOutput] fileHandleForReading]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(asynchronousTaskCompleted:) name:NSTaskDidTerminateNotification object:nil];
	
	[[[asynchronousTask standardOutput] fileHandleForReading] readInBackgroundAndNotify];
	
	[asynchronousTask launch];
}


- (void)asynchronousDataReceived:(NSNotification *)aNotification
{
    NSData *data = [[aNotification userInfo] valueForKey:@"NSFileHandleNotificationDataItem"];
	
	if ([data length]) {
		NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		if (string != nil) {
			[asynchronousTaskResult appendString:string];
		}
		
		[[[asynchronousTask standardOutput] fileHandleForReading] readInBackgroundAndNotify];
	} else {
		//[self asynchronousTaskCompleted];
	}
	
}

- (void)asynchronousTaskCompleted:(NSNotification *)aNotification
{
	[asynchronousTask waitUntilExit];
	[self asynchronousTaskCompleted];
}


- (void)asynchronousTaskCompleted
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[asynchronousTask terminate];
	
	NSData *data;
	while ((data = [[[asynchronousTask standardOutput] fileHandleForReading] availableData]) && [data length]) {
		NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		if (string != nil) {
			[asynchronousTaskResult appendString:string];
		}
	}

	[[FRACommandsController sharedInstance] setCommandRunning:NO];

	if ([asynchronousTask terminationStatus] == 0) {
		if ([[FRACommandsController sharedInstance] currentCommandShouldBeInsertedInline]) {
			[FRACurrentTextView insertText:asynchronousTaskResult];
			[[[FRAExtraInterfaceController sharedInstance] commandResultTextView] setString:@""];
		} else {
			[[[FRAExtraInterfaceController sharedInstance] commandResultTextView] setString:asynchronousTaskResult];
			[[[FRAExtraInterfaceController sharedInstance] commandResultWindow] makeKeyAndOrderFront:nil];
		}
	} else {
		NSBeep();
		[[[FRAExtraInterfaceController sharedInstance] commandResultWindow] makeKeyAndOrderFront:nil];
		[[[FRAExtraInterfaceController sharedInstance] commandResultTextView] setString:asynchronousTaskResult];
	}

	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)setUnsavedAsLastSavedDateForDocument:(id)document
{
	[document setValue:UNSAVED_STRING forKey:@"lastSaved"];
}


- (void)setLastSavedDateForDocument:(id)document date:(NSDate *)lastSavedDate
{
	[document setValue:[NSString dateStringForDate:(NSCalendarDate *)lastSavedDate formatIndex:[[FRADefaults valueForKey:@"StatusBarLastSavedFormatPopUp"] integerValue]] forKey:@"lastSaved"];
}


- (void)hasChangedDocument:(id)document
{
	[document setValue:@YES forKey:@"isEdited"];
	[FRACurrentProject reloadData];
	if (document == FRACurrentDocument) {
		[FRACurrentWindow setDocumentEdited:YES];
	}
	if ([document valueForKey:@"singleDocumentWindow"] != nil) {
		[[document valueForKey:@"singleDocumentWindow"] setDocumentEdited:YES];
	}
	
	[FRACurrentProject updateTabBar];
}


- (BOOL)isChangingSyntaxDefinitionsProgrammatically
{
    return isChangingSyntaxDefinitionsProgrammatically;
}


- (void)setNameAndPathForDocument:(id)document path:(NSString *)path
{
	NSString *name;
	if (path == nil) {
		NSString *untitledName = NSLocalizedString(@"untitled", @"Name for untitled document");
		if (untitledNumber == 1) {
			name = [NSString stringWithString:untitledName];
		} else {
			name = [NSString stringWithFormat:@"%@ %ld", untitledName, untitledNumber];
		}
		untitledNumber++;
		[document setValue:name forKey:@"nameWithPath"];
		
	} else {
		
		name = [path lastPathComponent];
		[document setValue:[NSString stringWithFormat:@"%@ - %@", name, [path stringByDeletingLastPathComponent]] forKey:@"nameWithPath"];
	}
	
	[document setValue:name forKey:@"name"];
	[document setValue:path forKey:@"path"];
}





- (void)fixSortOrderNumbersForArrayController:(NSArrayController *)arrayController overIndex:(NSInteger)index
{
	NSArray *array = [arrayController arrangedObjects];
	for (id item in array) {
		if ([[item valueForKey:@"sortOrder"] integerValue] >= index) {
			[item setValue:@([[item valueForKey:@"sortOrder"] integerValue] + 1) forKey:@"sortOrder"];
		}
	}
}


- (void)resetSortOrderNumbersForArrayController:(NSArrayController *)arrayController
{
	NSInteger index = 0;
	NSArray *array = [arrayController arrangedObjects];
	for (id item in array) {
		[item setValue:@(index) forKey:@"sortOrder"];
		index++;
	}
}


- (void)insertIconsInBackground:(id)array
{
	NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(performInsertIcons:) object:array];
	
    [[FRAMain operationQueue] addOperation:operation];
}


- (void)performInsertIcons:(id)array
{
	NSArray *icons = [NSImage iconsForPath:array[1]];
	
	NSArray *resultArray = @[array[0], icons];
	
	[self performSelectorOnMainThread:@selector(performInsertIconsOnMainThread:) withObject:resultArray waitUntilDone:NO];
}
	

- (void)performInsertIconsOnMainThread:(id)array
{
	id document = array[0];
	
	NSArray *icons = array[1];
	
	if (document != nil) { // Check that the document hasn't been closed etc.
		[document setValue:icons[0] forKey:@"icon"];
		[document setValue:icons[1] forKey:@"unsavedIcon"];
		
		[FRACurrentProject reloadData];
	}
}

@end
