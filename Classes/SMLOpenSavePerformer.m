/*
Smultron version 3.7a1, 2009-09-12
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Smultron

Copyright 2004-2009 Peter Borg - 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "SMLStandardHeader.h"

#import "SMLOpenSavePerformer.h"
#import "NSImage+Smultron.h"

#import "SMLVariousPerformer.h"
#import "SMLProjectsController.h"
#import "SMLSnippetsController.h"
#import "SMLBasicPerformer.h"
#import "SMLAuthenticationController.h"
#import "SMLTextPerformer.h"
#import "SMLTextMenuController.h"
#import "SMLApplicationDelegate.h"
#import "SMLInterfacePerformer.h"
#import "SMLLineNumbers.h"
#import "SMLProject.h"

#import "ODBEditorSuite.h"

@implementation SMLOpenSavePerformer

static id sharedInstance = nil;

+ (SMLOpenSavePerformer *)sharedInstance
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


- (void)openAllTheseFiles:(NSArray *)arrayOfFiles
{
	NSString *filename;
	NSMutableArray *projectsArray = [NSMutableArray array];
	for (filename in arrayOfFiles) {
		if ([[filename pathExtension] isEqualToString:@"smlc"] || [[filename pathExtension] isEqualToString:@"smultronSnippets"]) { // If the file are code snippets do an import
			[[SMLSnippetsController sharedInstance] performSnippetsImportWithPath:filename];
		} else if ([[filename pathExtension] isEqualToString:@"smlp"] || [[filename pathExtension] isEqualToString:@"smultronProject"]) { // If the file is a project open all its files
			[projectsArray addObject:filename];
		} else {
			[self shouldOpen:[SMLBasic resolveAliasInPath:filename] withEncoding:0];
		}
	}
	
	id projectPath;
	for (projectPath in projectsArray) { // Do it this way so all normal documents are opened in the front window and not in any coming project, and then the projects are opened one by one
		[[SMLProjectsController sharedDocumentController] performOpenProjectWithPath:projectPath];
	}
	
	[[NSGarbageCollector defaultCollector] collectExhaustively];
}


- (void)shouldOpen:(NSString *)path withEncoding:(NSStringEncoding)chosenEncoding
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDirectory;
	if ([fileManager fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) { // Check if folder
		if ([[SMLDefaults valueForKey:@"OpenAllFilesWithinAFolder"] boolValue] == YES) {
			NSEnumerator *enumerator;
			if ([[SMLDefaults valueForKey:@"OpenAllFilesInAFolderRecursively"] boolValue] == YES){
				enumerator = [fileManager enumeratorAtPath:path];
			} else {
				enumerator = [[fileManager contentsOfDirectoryAtPath:path error:nil] objectEnumerator];
			}
			NSString *temporaryPath;
			NSMutableString *extensionsToFilterOutString = [NSMutableString stringWithString:[SMLDefaults valueForKey:@"FilterOutExtensionsString"]];
			[extensionsToFilterOutString replaceOccurrencesOfString:@"." withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [extensionsToFilterOutString length])]; // If the user has included some dots
			NSArray *extensionsToFilterOut = [extensionsToFilterOutString componentsSeparatedByString:@" "];
			for (id file in enumerator) {
				NSString *pathExtension = [[file pathExtension] lowercaseString];
				if ([[SMLDefaults valueForKey:@"FilterOutExtensions"] boolValue] == YES && [extensionsToFilterOut containsObject:pathExtension]) {
					continue;
				}
				if ([self isPathVisible:file] == NO || [self isPartOfSVN:file] == YES) {
					continue;
				}
				temporaryPath = [NSString stringWithFormat:@"%@/%@", path, file];
				if ([fileManager fileExistsAtPath:temporaryPath isDirectory:&isDirectory] && !isDirectory && ![[temporaryPath lastPathComponent] hasPrefix:@"."]) {
					[self shouldOpen:temporaryPath withEncoding:chosenEncoding];
				}
			}
			
			return;
		} else {
			NSString *title = [NSString stringWithFormat:NSLocalizedString(@"You cannot open %@ because it is a folder", @"Indicate that you cannot open %@ because it is a folder in Open-file-is-a-directory sheet"), path];
			[SMLVarious standardAlertSheetWithTitle:title message:NSLocalizedString(@"Choose something that is not a folder or change the settings in Preferences so that all items in a folder are opened", @"Indicate that they should choose something that is not a folder or change the settings in Preferences so that all items in a folder are opened in Open-file-is-a-directory sheet") window:SMLCurrentWindow];
			return;
		}
	}
	
	
	NSArray *array = [SMLCurrentProject documents];
	id document;
	BOOL documentAlreadyOpened = NO;
	for (document in array) {
		if ([[document valueForKey:@"path"] isEqualToString:path]) {
			documentAlreadyOpened = YES;
			break;
		}
	}
	
	if (documentAlreadyOpened) {
		[SMLCurrentProject selectDocument:document];
		[[SMLProjectsController sharedDocumentController] putInRecentWithPath:[document valueForKey:@"path"]];
	} else {
		if (![fileManager fileExistsAtPath:path]) {
			NSString *title = [NSString stringWithFormat:NSLocalizedString(@"The file %@ does not exist", @"Indicate that the file %@ does not exist Open-file-does-not-exist sheet"), path];
			[SMLVarious standardAlertSheetWithTitle:title message:[NSString stringWithFormat:NSLocalizedString(@"Please find it at a different location by choosing Open%C in the File menu", @"Indicate that they should find it at different location by choosing Open%C in the File menu Open-file-does-not-exist sheet"), 0x2026] window:SMLCurrentWindow];
			return;
		}
		
		if (![fileManager isReadableFileAtPath:path]) { // Check if the document can be read
			if (SMLCurrentWindow == nil) {
				[[SMLProjectsController sharedDocumentController] newDocument:nil];
			}
			
			if ([SMLCurrentWindow attachedSheet]) {
				[[SMLCurrentWindow attachedSheet] close];
			}
			if ([NSApp isHidden]) { // To display the sheet properly if the application is hidden
				[NSApp activateIgnoringOtherApps:YES]; 
				[SMLCurrentWindow makeKeyAndOrderFront:self];
			}
			
			NSString *title = [NSString stringWithFormat:NSLocalizedString(@"It seems as if you do not have permission to open the file %@", @"Indicate that it seems as if you do not have permission to open the file %@ in Not-enough-permission-to-open sheet"), path];
			NSArray *openArray = [NSArray arrayWithObjects:path, [NSNumber numberWithUnsignedInteger:chosenEncoding], nil];
			NSBeginAlertSheet(title,
							  AUTHENTICATE_STRING,
							  nil,
							  CANCEL_BUTTON,
							  SMLCurrentWindow,
							  [SMLAuthenticationController sharedInstance],
							  @selector(authenticateOpenSheetDidEnd:returnCode:contextInfo:),
							  nil,
							  (void *)openArray,
							  TRY_TO_AUTHENTICATE_STRING);
			[NSApp runModalForWindow:[SMLCurrentWindow attachedSheet]]; // Modal to allow for many documents
			return;
		}

		[self shouldOpenPartTwo:path withEncoding:chosenEncoding data:nil];
	}
	
	@try {
		NSAppleEventDescriptor *appleEventSelectionRangeDescriptor = [[[NSAppleEventManager sharedAppleEventManager] currentAppleEvent] paramDescriptorForKeyword:keyAEPosition];
		if (appleEventSelectionRangeDescriptor) {
			AppleEventSelectionRange selectionRange;
			[[appleEventSelectionRangeDescriptor data] getBytes:&selectionRange length:sizeof(AppleEventSelectionRange)];
			NSInteger lineNumber = (NSInteger)selectionRange.lineNum;
			if (lineNumber > -1) {
				[[SMLTextMenuController sharedInstance] performGoToLine:lineNumber];
			} else {
				[[SMLCurrentDocument valueForKey:@"firstTextView"] setSelectedRange:NSMakeRange((NSInteger)selectionRange.startRange, (NSInteger)selectionRange.endRange - (NSInteger)selectionRange.startRange)];
				[[SMLCurrentDocument valueForKey:@"firstTextView"] scrollRangeToVisible:NSMakeRange((NSInteger)selectionRange.startRange, (NSInteger)selectionRange.endRange - (NSInteger)selectionRange.startRange)];
			}
		}
	}
	@catch (NSException *exception) {
	}
}


// Split this method in two to allow the latter part to be called from SMLAuthenticationController
- (void)shouldOpenPartTwo:(NSString *)path withEncoding:(NSStringEncoding)chosenEncoding data:(NSData *)textData
{
	NSString *string = nil;
	NSStringEncoding encoding = 0;
	if (chosenEncoding != 0) { // 0 means that the user has not chosen an encoding
		encoding = chosenEncoding;
	} else if ([[SMLDefaults valueForKey:@"EncodingsMatrix"] integerValue] == 0) {
		NSError *error = nil;
		string = [NSString stringWithContentsOfFile:path usedEncoding:&encoding error:&error];
		if (error != nil || string == nil) { // It hasn't found an encoding so return the default
			if (textData == nil) {
				textData = [[NSData alloc] initWithContentsOfFile:path];
			}
			encoding = [SMLText guessEncodingFromData:textData];
			if (encoding == 0 || encoding == -1) { // Something has gone wrong or it hasn't found an encoding, so use default
				encoding = [[SMLDefaults valueForKey:@"EncodingsPopUp"] integerValue];
			}
		}
		
	} else {
		encoding = [[SMLDefaults valueForKey:@"EncodingsPopUp"] integerValue];
	}

	if (string == nil) {
		string = [[NSString alloc] initWithContentsOfFile:path encoding:encoding error:nil];
	}

	if (string == nil) { // Test if encoding worked, else try NSUTF8StringEncoding
		string = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
		encoding = NSUTF8StringEncoding;
		if (string == nil) { // Test if encoding worked, else try NSISOLatin1StringEncoding
			string = [[NSString alloc] initWithContentsOfFile:path encoding:NSISOLatin1StringEncoding error:nil];
			encoding = NSISOLatin1StringEncoding;
			if (string == nil) { // Test if encoding worked, else try defaultCStringEncoding
				string = [[NSString alloc] initWithContentsOfFile:path encoding:[NSString defaultCStringEncoding] error:nil];
				encoding = [NSString defaultCStringEncoding];
				if (string == nil) { // If it still is nil set it to empty string
					string = @"";
				}
			}
		}
	}

	[self performOpenWithPath:path contents:string encoding:encoding];
}

- (void)performOpenWithPath:(NSString *)path contents:(NSString *)textString encoding:(NSStringEncoding)encoding
{
	if (SMLCurrentProject == nil) {
		if ([[[SMLProjectsController sharedDocumentController] documents] count] > 0) { // When working as an external editor some programs cause Smultron to not have an active document and thus no current project
			[[SMLProjectsController sharedDocumentController] setCurrentProject:[[SMLProjectsController sharedDocumentController] documentForWindow:[[NSApp orderedWindows] objectAtIndex:0]]];
		} else {
			[[SMLProjectsController sharedDocumentController] newDocument:nil];
		}
	}
	
	id document;
	
	NSAppleEventDescriptor *appleEventDescriptor;
	if ([[SMLApplicationDelegate sharedInstance] appleEventDescriptor] != nil) {
		appleEventDescriptor = [[SMLApplicationDelegate sharedInstance] appleEventDescriptor];
	} else {
		appleEventDescriptor = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
	}
	
	NSAppleEventDescriptor *keyAEPropDataDescriptor = nil;
	BOOL fromExternal = NO;
	BOOL isKeyAEPropData = NO;
	if ([appleEventDescriptor paramDescriptorForKeyword:keyFileSender]) {
		fromExternal = YES;
	}
	
	if (!fromExternal && [appleEventDescriptor paramDescriptorForKeyword:keyAEPropData]) {
		keyAEPropDataDescriptor = [appleEventDescriptor paramDescriptorForKeyword:keyAEPropData];
		isKeyAEPropData = YES;
		if ([keyAEPropDataDescriptor paramDescriptorForKeyword:keyFileSender]) {
			fromExternal = YES;
		}
	}
	
	if (fromExternal) {
		NSString *externalPath;
		if (!isKeyAEPropData) {
			externalPath = [[appleEventDescriptor paramDescriptorForKeyword:keyFileCustomPath] stringValue];
		} else {
			externalPath = [[keyAEPropDataDescriptor paramDescriptorForKeyword:keyFileCustomPath] stringValue];
		}
		if (!externalPath) {
			externalPath = path;
		}
		
		document = [SMLCurrentProject createNewDocumentWithPath:externalPath andContents:textString];
		[document setValue:[NSNumber numberWithBool:YES] forKey:@"fromExternal"];
		
		if (!isKeyAEPropData) {
			[document setValue:[appleEventDescriptor paramDescriptorForKeyword:keyFileSender] forKey:@"externalSender"];
		} else {
			[document setValue:[keyAEPropDataDescriptor paramDescriptorForKeyword:keyFileSender] forKey:@"externalSender"];
		}
		
		[document setValue:externalPath forKey:@"externalPath"];
		//Log(appleEventDescriptor);
		if (!isKeyAEPropData) {
			if ([appleEventDescriptor paramDescriptorForKeyword:keyFileSenderToken]) {
				[document setValue:[appleEventDescriptor paramDescriptorForKeyword:keyFileSenderToken] forKey:@"externalToken"];
			}
		} else {
			if ([appleEventDescriptor paramDescriptorForKeyword:keyFileSenderToken]) {
				[document setValue:[keyAEPropDataDescriptor paramDescriptorForKeyword:keyFileSenderToken] forKey:@"externalToken"];
			}
		}
		
		[[SMLProjectsController sharedDocumentController] putInRecentWithPath:externalPath];
	} else {
		document = [SMLCurrentProject createNewDocumentWithPath:path andContents:textString];
		[[SMLProjectsController sharedDocumentController] putInRecentWithPath:path];
	}
	[[SMLApplicationDelegate sharedInstance] setAppleEventDescriptor:nil];
	
	
	[document setValue:[NSNumber numberWithInteger:encoding] forKey:@"encoding"];
	[document setValue:[NSString localizedNameOfStringEncoding:[[document valueForKey:@"encoding"] integerValue]] forKey:@"encodingName"];
	[document setValue:path forKey:@"path"];
	[SMLCurrentProject updateWindowTitleBarForDocument:document];
	
	[[document valueForKey:@"firstTextView"] setSelectedRange:NSMakeRange(0,0)];
	
	[SMLVarious insertIconsInBackground:[NSArray arrayWithObjects:document, path, nil]];
	//NSArray *icons = [NSImage iconsForPath:path];
//	[document setValue:[icons objectAtIndex:0] forKey:@"icon"];
//	[document setValue:[icons objectAtIndex:1] forKey:@"unsavedIcon"];
	
	NSDictionary *fileAttributes = [NSDictionary dictionaryWithDictionary:[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil]];
	[document setValue:fileAttributes forKey:@"fileAttributes"];
	[SMLVarious setLastSavedDateForDocument:document date:[fileAttributes fileModificationDate]];
	[SMLInterface updateStatusBar];
	[SMLCurrentWindow makeFirstResponder:[document valueForKey:@"firstTextView"]];
	[SMLCurrentProject selectionDidChange];
	
	[self performSelector:@selector(updateLineNumbers) withObject:nil afterDelay:0.0];
}


- (void)updateLineNumbers // Slight hack to make sure that the line numbers are correct under certain circumstances when opening a document as the line numbers are updated before the view has decided whether to include a scrollbar or not 
{
	[[SMLCurrentDocument valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth:NO recolour:NO];
	[[SMLProjectsController sharedDocumentController] setCurrentProject:nil];
}



- (void)performSaveOfDocument:(id)document fromSaveAs:(BOOL)fromSaveAs
{
	[self performSaveOfDocument:document path:[document valueForKey:@"path"] fromSaveAs:fromSaveAs aCopy:NO];
}


- (void)performSaveOfDocument:(id)document path:(NSString *)path fromSaveAs:(BOOL)fromSaveAs aCopy:(BOOL)aCopy
{
	NSString *string = [SMLText convertLineEndings:[[[document valueForKey:@"firstTextScrollView"] documentView] string] inDocument:document];
	if ([[SMLDefaults valueForKey:@"AlwaysEndFileWithLineFeed"] boolValue] == YES) {
		if ([string characterAtIndex:[string length] - 1] != '\n') {
			[[[document valueForKey:@"firstTextScrollView"] documentView] replaceCharactersInRange:NSMakeRange([string length], 0) withString:@"\n"];
			string = [SMLText convertLineEndings:[[[document valueForKey:@"firstTextScrollView"] documentView] string] inDocument:document];
			[[document valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth:NO recolour:NO];
		}
	}
	
	if (![string canBeConvertedToEncoding:[[document valueForKey:@"encoding"] integerValue]]) {
		NSError *error = [NSError errorWithDomain:SMULTRON_ERROR_DOMAIN code:SmultronSaveErrorEncodingInapplicable userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:NSLocalizedStringFromTable(@"This document can no longer be saved using its original %@ encoding.", @"Localizable3", @"Title of alert panel informing user that the file's string encoding needs to be changed."), [NSString localizedNameOfStringEncoding:[[document valueForKey:@"encoding"] integerValue]]], NSLocalizedDescriptionKey, NSLocalizedStringFromTable(@"Please choose another encoding (such as UTF-8).", @"Localizable3", @"Subtitle of alert panel informing user that the file's string encoding needs to be changed"), NSLocalizedRecoverySuggestionErrorKey, nil]];
		[SMLCurrentProject presentError:error modalForWindow:SMLCurrentWindow delegate:self didPresentSelector:nil contextInfo:NULL];
		return;
	}
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDirectory;
	if ([fileManager fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) { // Check if it is a folder
		NSString *title = [NSString stringWithFormat:IS_NOW_FOLDER_STRING, path];
		[SMLVarious standardAlertSheetWithTitle:title message:[NSString stringWithFormat:NSLocalizedString(@"Please save it at a different location with Save As%C in the File menu", @"Indicate that they should try to save at a different location with Save As%C in File menu in Path-is-a-directory sheet"), 0x2026] window:SMLCurrentWindow];
		return;
	}
	BOOL fileAlreadyExists = [fileManager fileExistsAtPath:path];
	BOOL folderIsWritable = YES;
	if (fileAlreadyExists) {
		folderIsWritable = [fileManager isWritableFileAtPath:[path stringByDeletingLastPathComponent]];
	}
	BOOL hasWritePermission = YES;
	
	if (fileAlreadyExists) {
		hasWritePermission = [fileManager isWritableFileAtPath:path];
	} else {
		if ([[document valueForKey:@"isNewDocument"] boolValue] == YES) { // Check only if it's anew file as if it's an old file but the path does not exist, the folder e.g. has changed name so it will be caught later
			hasWritePermission = [fileManager isWritableFileAtPath:[path stringByDeletingLastPathComponent]];
		}
	}		

	if (!hasWritePermission) { // Check permission to write file
		if ([SMLCurrentWindow attachedSheet]) {
			[[SMLCurrentWindow attachedSheet] close];
		}
		NSString *title = [NSString stringWithFormat:FILE_IS_UNWRITABLE_SAVE_STRING, path];
		NSData *data = [[NSData alloc] initWithData:[string dataUsingEncoding:[[document valueForKey:@"encoding"] integerValue] allowLossyConversion:YES]];
		NSArray *saveArray = [NSArray arrayWithObjects:document, data, path, [NSNumber numberWithBool:fromSaveAs], [NSNumber numberWithBool:aCopy], nil];
		NSBeginAlertSheet(title,
						  AUTHENTICATE_STRING,
						  nil,
						  CANCEL_BUTTON,
						  SMLCurrentWindow,
						  [SMLAuthenticationController sharedInstance],
						  @selector(authenticateSaveSheetDidEnd:returnCode:contextInfo:),
						  nil,
						  (void *)saveArray,
						  TRY_TO_AUTHENTICATE_STRING);
		[NSApp runModalForWindow:[SMLCurrentWindow attachedSheet]]; // Modal to allow for many documents
		return;
	}
	
	BOOL error = NO;
	NSMutableDictionary *attributes;
	
	if ([[document valueForKey:@"isNewDocument"] boolValue] == YES || fromSaveAs || !folderIsWritable) { // If it's a new file
		
		if (![string writeToURL:[NSURL fileURLWithPath:path] atomically:folderIsWritable encoding:[[document valueForKey:@"encoding"] integerValue] error:nil]) {
			if (![string writeToURL:[NSURL fileURLWithPath:path] atomically:NO encoding:[[document valueForKey:@"encoding"] integerValue] error:nil]) { // Try it again without backup file
				error = YES;
			}
		}
		
		if (!error) {
			if ([[document valueForKey:@"isNewDocument"] boolValue] == YES) {
				attributes = [NSMutableDictionary dictionary];
			} else {
				attributes = [NSMutableDictionary dictionaryWithDictionary:[document valueForKey:@"fileAttributes"]];
				[attributes removeObjectForKey:@"NSFileSize"]; // Remove those values which has to be updated 
				[attributes removeObjectForKey:@"NSFileModificationDate"];
				[attributes removeObjectForKey:@"NSFilePosixPermissions"];
			}
			
			if ([[SMLDefaults valueForKey:@"AssignDocumentToSmultronWhenSaving"] boolValue] == YES || [[document valueForKey:@"isNewDocument"] boolValue]) {
				[attributes setValue:[NSNumber numberWithUnsignedLong:'SMUL'] forKey:@"NSFileHFSCreatorCode"];
				[attributes setValue:[NSNumber numberWithUnsignedLong:'SMLd'] forKey:@"NSFileHFSTypeCode"];
			}
			
			[fileManager setAttributes:attributes ofItemAtPath:path error:nil];
			if (!aCopy) {
				[self updateAfterSaveForDocument:document path:path];
			}
		}
		
	} else { // There is an old file...
		
		if (![fileManager fileExistsAtPath:path]) { // Check if the old file has been removed
			NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Could not overwrite the file %@ because it has been removed", @"Indicate that the program could not overwrite the file %@ because it has been removed in File-has-been-removed sheet"), path];
			[SMLVarious standardAlertSheetWithTitle:title message:[NSString stringWithFormat:NSLocalizedString(@"Please use Save As%C in the File menu", @"Indicate that they should please use Save As%C in the File menu in File-has-been-removed sheet"), 0x2026] window:SMLCurrentWindow];
			return;
		}
		
		NSDictionary *extraMetaData = [self getExtraMetaDataFromPath:path];
		attributes = [NSMutableDictionary dictionaryWithDictionary:[fileManager attributesOfItemAtPath:path error:nil]];
		if ([[SMLDefaults valueForKey:@"AssignDocumentToSmultronWhenSaving"] boolValue] == YES) {
			[attributes setObject:[NSNumber numberWithUnsignedLong:'SMUL'] forKey:@"NSFileHFSCreatorCode"];
			[attributes setObject:[NSNumber numberWithUnsignedLong:'SMLd'] forKey:@"NSFileHFSTypeCode"];
		}
		[attributes removeObjectForKey:@"NSFileSize"]; // Remove those values which has to be updated 
		[attributes removeObjectForKey:@"NSFileModificationDate"];
		
		if (![string writeToURL:[NSURL fileURLWithPath:path] atomically:folderIsWritable encoding:[[document valueForKey:@"encoding"] integerValue] error:nil]) {
			if (![string writeToURL:[NSURL fileURLWithPath:path] atomically:NO encoding:[[document valueForKey:@"encoding"] integerValue] error:nil]) { // Try it again without backup file as e.g. sshfs seems to object otherwise when overwriting a file
				error = YES;
			}
		}
		
		if (!error) {
			[fileManager setAttributes:attributes ofItemAtPath:path error:nil];
			[self resetExtraMetaData:extraMetaData path:path];
			[self updateAfterSaveForDocument:document path:path];
		}
	}
	
	if (error) {	
		NSString *title = [NSString stringWithFormat:NSLocalizedString(@"There was a unknown error when trying to save the file %@", @"Indicate that there was a unknown error when trying to save the file %@ in Unknown-error-when-saving sheet"), path];
		[SMLVarious standardAlertSheetWithTitle:title message:[NSString stringWithFormat:NSLocalizedString(@"Please try a different location with Save As%C in the File menu or check the permissions of the file and the enclosing folder and try again", @"Indicate that you should try a different location with Save As%C in the File menu or check the permissions of the file and the enclosing folder and try again in Unknown-error-when-saving sheet"), 0x2026] window:SMLCurrentWindow];
	}
}


- (void)performDataSaveWith:(NSData *)data path:(NSString *)path
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDirectory;
	if ([fileManager fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) { // Check if folder
		NSString *title = [NSString stringWithFormat:IS_NOW_FOLDER_STRING, path];
		[SMLVarious standardAlertSheetWithTitle:title message:TRY_SAVING_AT_A_DIFFERENT_LOCATION_STRING window:SMLCurrentWindow];
		return;
	}
	
	BOOL fileExists = [fileManager fileExistsAtPath:path];
	BOOL hasPermission = ([fileManager isWritableFileAtPath:[path stringByDeletingLastPathComponent]] && (!fileExists || (fileExists && [fileManager isWritableFileAtPath:path])));
	if (!hasPermission) { // Check permission
		NSString *title = [NSString stringWithFormat:FILE_IS_UNWRITABLE_SAVE_STRING, path];
		[SMLVarious standardAlertSheetWithTitle:title message:TRY_SAVING_AT_A_DIFFERENT_LOCATION_STRING window:SMLCurrentWindow];
		return;
	}
	
	if (![data writeToURL:[NSURL fileURLWithPath:path] atomically:YES]) {
		NSString *title = [NSString stringWithFormat:NSLocalizedString(@"There was a unknown error when trying to save the file %@", @"Indicate that there was a unknown error when trying to save the file %@ in Unknown-error-when-saving sheet"), path];
		[SMLVarious standardAlertSheetWithTitle:title message:NSLocalizedString(@"Please try to save in a different location", @"Indicate that they should try to save in a different location with in Unknown-error-when-data-saving sheet") window:SMLCurrentWindow];
	}
}


- (void)updateAfterSaveForDocument:(id)document path:(NSString *)path
{
	[SMLVarious setNameAndPathForDocument:document path:path];
	if ([[document valueForKey:@"fromExternal"] boolValue] == YES) {
		[SMLVarious sendModifiedEventToExternalDocument:document path:path];
	} 
	
	[document setValue:[NSNumber numberWithBool:NO] forKey:@"isEdited"];
	[document setValue:[NSNumber numberWithBool:NO] forKey:@"isNewDocument"];
	[SMLCurrentProject updateEditedBlobStatus];
	
	[SMLCurrentProject updateWindowTitleBarForDocument:SMLCurrentDocument];
	[SMLVarious setLastSavedDateForDocument:document date:[NSDate date]];
	
	if ([[SMLDefaults valueForKey:@"UpdateIconForEverySave"] boolValue] == YES && [[SMLDefaults valueForKey:@"UseQuickLookIcon"] boolValue] == YES) {
		[SMLVarious insertIconsInBackground:[NSArray arrayWithObjects:document, path, nil]];
		
		//NSArray *icons = [NSImage iconsForPath:path];
//		[document setValue:[icons objectAtIndex:0] forKey:@"icon"];
//		[document setValue:[icons objectAtIndex:1] forKey:@"unsavedIcon"];
	}
	
	[[NSWorkspace sharedWorkspace] noteFileSystemChanged:path];
	[SMLInterface updateStatusBar];
	[document setValue:[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] forKey:@"fileAttributes"];
	
	[SMLCurrentProject documentsListHasUpdated];
	
	[[NSGarbageCollector defaultCollector] collectExhaustively];
}


- (NSDictionary *)getExtraMetaDataFromPath:(NSString *)path
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	
	@try {
		size_t size = listxattr([path fileSystemRepresentation], NULL, ULONG_MAX, 0);
		NSMutableData *data = [NSMutableData dataWithLength:size];
		size = listxattr([path fileSystemRepresentation], [data mutableBytes], size, 0);
		char *key;
		char *start = (char *)[data bytes];
		for (key = start; (key - start) < [data length]; key+= strlen(key) + 1) {
			size_t valueSize = getxattr([path fileSystemRepresentation], key, NULL, ULONG_MAX, 0, 0);
			NSMutableData *value = [NSMutableData dataWithLength:valueSize];
			getxattr([path fileSystemRepresentation], key, [value mutableBytes], valueSize, 0, 0);
			
			[dictionary setValue:value forKey:[NSString stringWithUTF8String:key]];
		}
	}
	@catch (NSException *exception) {
	}
	@finally {
	}
	
	return (NSDictionary *)dictionary;
}


- (void)resetExtraMetaData:(NSDictionary *)dictionary path:(NSString *)path
{
	NSArray *array = [dictionary allKeys];
	for (id item in array) {
		@try {
			NSData *value = [dictionary valueForKey:item];
			setxattr([path fileSystemRepresentation], [item UTF8String], [value bytes], [value length], 0, 0);
		}
		@catch (NSException *exception) {
		}
		@finally {
		}
	}
}


- (BOOL)isPathVisible:(NSString *)path
{
	LSItemInfoRecord itemInfo;
	LSCopyItemInfoForURL((CFURLRef)[NSURL URLWithString:[@"file:///" stringByAppendingString:path]], kLSRequestAllInfo, &itemInfo);
	
	if ((itemInfo.flags & kLSItemInfoIsInvisible) != 0) {
		return NO;
	} else {
		if ([path isEqualToString:@"/.vol"] || [path isEqualToString:@"/automount"] || [path isEqualToString:@"/dev"] || [path isEqualToString:@"/mach"] || [path isEqualToString:@"/mach.sym"]) { // It seems to miss these...
			return NO;
		} else {
			return YES;
		}
	}
}


- (BOOL)isPartOfSVN:(NSString *)path
{
	NSArray *array = [path pathComponents];
	for (id item in array) {
		if ([item isEqualToString:@".svn"]) {
			return YES;
		}
	}
	
	return NO;
}
@end
