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

#ifdef DEVELOPMENT_STYLE_BUILD
	#define LogBool(bool) NSLog(@"The value of "#bool" is %@", bool ? @"YES" : @"NO")
	#define LogInt(number) NSLog(@"The value of "#number" is %d", number)
	#define LogFloat(number) NSLog(@"The value of "#number" is %f", number)
	#define Log(obj) NSLog(@"The value of "#obj" is %@", obj)
	#define LogChar(characters) NSLog(@#characters)
	#define Start NSDate *then = [NSDate date]
	#define Stop NSLog(@"Time elapsed: %f seconds", [then timeIntervalSinceNow] * -1)
	#define Pos NSLog(@"File=%s line=%d proc=%s", strrchr("/" __FILE__,'/')+1, __LINE__, __PRETTY_FUNCTION__)
#endif

#define FRAISE_ERROR_DOMAIN @"org.fraise.Fraise.ErrorDomain"

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

#import <SystemConfiguration/SCNetwork.h>

#import <ApplicationServices/ApplicationServices.h>

#import <WebKit/WebKit.h>

#import <QuartzCore/QuartzCore.h>

#import <QuickLook/QuickLook.h>



#import <unistd.h>

#import <unistd.h>
#import <sys/param.h>
#import <sys/mount.h>
#import <sys/xattr.h>

enum {
	FRADefaultsLineEndings = 0,
	FRAUnixLineEndings = 1,
	FRAMacLineEndings = 2,
	FRADarkSideLineEndings = 3,
	FRALeaveLineEndingsUnchanged = 6
};
typedef NSUInteger FRALineEndings;


enum {
	FRACurrentDocumentScope = 0,
	FRACurrentProjectScope = 1,
	FRAAllDocumentsScope = 2,
	FRAParentDirectoryScope = 3
};
typedef NSUInteger FRAAdvancedFindScope;

enum {
	FRAListView = 0
};
typedef NSUInteger FRAView;

enum {
	FRAVirtualProject = 0,
	FRAPermantProject = 1
};
typedef NSUInteger FRAWhatKindOfProject;

enum {
	FRAPreviewHTML = 0,
	FRAPreviewMarkdown = 1,
	FRAPreviewMultiMarkdown = 2,
};
typedef NSUInteger FRAPreviewParser;

enum {
	FRAOpenSaveRemember = 0,
	FRAOpenSaveCurrent = 1,
	FRAOpenSaveAlways = 2
};
typedef NSUInteger FRAOpenSaveMatrix;

typedef struct _AppleEventSelectionRange {
	short unused1; // 0 (not used)
	short lineNum; // line to select (<0 to specify range)
	long startRange; // start of selection range (if line < 0)
	long endRange; // end of selection range (if line < 0)
	long unused2; // 0 (not used)
	long theDate; // modification date/time
} AppleEventSelectionRange;

enum {
    FraiseSaveErrorEncodingInapplicable = 1,
};
typedef NSUInteger FRAErrors;



#define OK_BUTTON NSLocalizedString(@"OK", @"OK-button")
#define CANCEL_BUTTON NSLocalizedString(@"Cancel", @"Cancel-button")
#define DELETE_BUTTON NSLocalizedString(@"Delete", @"Delete-button")

#define UNSAVED_STRING NSLocalizedString(@"(unsaved)", @"(unsaved)")
#define AUTHENTICATE_STRING NSLocalizedString(@"Authenticate", @"Authenticate")
#define SAVE_STRING NSLocalizedString(@"Save", @"Save")
#define PREVIEW_STRING NSLocalizedString(@"Preview", @"Preview")
#define FUNCTION_STRING NSLocalizedString(@"Function", @"Function")
#define CLOSE_SPLIT_STRING NSLocalizedString(@"Close Split", @"Close Split")
#define COLLECTION_STRING NSLocalizedString(@"Collection", @"Collection")
#define TRY_TO_AUTHENTICATE_STRING NSLocalizedString(@"If you want you can try to authenticate with an administrators username and password", @"Indicate that if you want you can try to authenticate with an administrators username and password")

#define TRY_SAVING_AT_A_DIFFERENT_LOCATION_STRING NSLocalizedString(@"Please save it at a different location", @"Indicate that they should try to save in a different location")
#define SPLIT_WINDOW_STRING NSLocalizedString(@"Split Window", @"Split Window")

#define IS_NOW_FOLDER_STRING NSLocalizedString(@"You can not save this file because %@ is now a folder", @"Indicate that you can not save this file because %@ is now a folder")
#define NAME_FOR_UNDO_CHANGE_ENCODING NSLocalizedString(@"Change Encoding", @"Name for undo Change Encoding")
#define NAME_FOR_UNDO_CHANGE_LINE_ENDINGS NSLocalizedString(@"Change Line Endings", @"Name for undo Change Line Endings")
#define DONT_LINE_WRAP_STRING NSLocalizedString(@"Don't Line Wrap Text", @"Don't Line Wrap Text")
#define LINE_WRAP_STRING NSLocalizedString(@"Line Wrap Text", @"Line Wrap Text")
#define UNTITLED_PROJECT_NAME NSLocalizedString(@"Untitled project", @"Untitled project")

#define WILL_DELETE_ALL_ITEMS_IN_COLLECTION NSLocalizedStringFromTable(@"This will delete all items in the collection %@. Are you sure you want to continue?", @"Localizable3", @"This will delete all items in the collection %@. Are you sure you want to continue?")
#define NEW_COLLECTION_STRING NSLocalizedStringFromTable(@"New Collection", @"Localizable3", @"New Collection")
#define FILTER_STRING NSLocalizedStringFromTable(@"Filter", @"Localizable3", @"Filter")
#define COMMAND_RESULT_WINDOW_TITLE NSLocalizedStringFromTable(@"Command Result - Fraise", @"Localizable3", @"Command Result - Fraise")
#define FILE_IS_UNWRITABLE_SAVE_STRING NSLocalizedStringFromTable(@"It seems as if the file is unwritable or that you do not have permission to save the file %@", @"Localizable3", @"It seems as if the file is unwritable or that you do not have permission to save the file %@")

#define NO_DOCUMENT_SELECTED_STRING NSLocalizedString(@"No document selected", @"Indicate that no document is selected for the dummy view")

#define SNIPPET_NAME_LENGTH 26

#define ICON_MAX_SIZE 256.0

#define FRAMain [FRAMainController sharedInstance]
#define FRABasic [FRABasicPerformer sharedInstance]
#define FRAInterface [FRAInterfacePerformer sharedInstance]
#define FRAOpenSave [FRAOpenSavePerformer sharedInstance]
#define FRAText [FRATextPerformer sharedInstance]
#define FRAVarious [FRAVariousPerformer sharedInstance]
#define FRADocumentViews [FRADocumentViewsController sharedInstance]
#define FRAManagedObjectContext [[FRAApplicationDelegate sharedInstance] managedObjectContext]

#define FRADefaults [[NSUserDefaultsController sharedUserDefaultsController] values]

#define FRACurrentProject [[FRAProjectsController sharedDocumentController] currentDocument]
#define FRACurrentDocument [[FRAProjectsController sharedDocumentController] currentFRADocument]
#define FRACurrentTextView [[FRAProjectsController sharedDocumentController] currentTextView]
#define FRACurrentText [[FRAProjectsController sharedDocumentController] currentText]
#define FRACurrentWindow [[[FRACurrentProject windowControllers] objectAtIndex:0] window]
