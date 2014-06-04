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

#import "NSImage+Fraise.h"
#import "FRAProject.h"
#import "FRABasicPerformer.h"
#import "FRAProjectsController.h"
#import "FRADocumentsListCell.h"
#import "FRAViewMenuController.h"
#import "FRADragAndDropController.h"
#import "FRAApplicationDelegate.h"
#import "FRAInterfacePerformer.h"
#import "FRAViewMenuController.h"
#import "FRAVariousPerformer.h"
#import "FRASyntaxColouring.h"
#import "FRAFileMenuController.h"
#import "FRAAdvancedFindController.h"
#import "FRAProject+DocumentViewsController.h"
#import "FRAProject+ToolbarController.h"
#import "FRALineNumbers.h"
#import "FRAPrintViewController.h"
#import "FRAPrintTextView.h"
#import "PSMTabBarControl.h"

@implementation FRAProject

@synthesize firstDocument, secondDocument, lastTextViewInFocus, project, documentsArrayController, documentsTableView, firstContentView, secondContentView, statusBarTextField, mainSplitView, contentSplitView, secondContentViewNavigationBar, secondContentViewPopUpButton, leftDocumentsView, leftDocumentsTableView, tabBarControl, tabBarTabView;


- (id)init
{
    self = [super init];
    if (self) {
		project = [FRABasic createNewObjectForEntity:@"Project"];
		[[FRAProjectsController sharedDocumentController] setCurrentProject:self];
    }
    return self;
}


#pragma mark -
#pragma mark Overrides


- (NSString *)windowNibName
{
    return @"FRAProject";
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
	[super windowControllerDidLoadNib:aController];
	
	[[self windowControllers][0] setWindowFrameAutosaveName:@"FraiseProjectWindow"];
	[[self window] setFrameAutosaveName:@"FraiseProjectWindow"];
	//[[[self windowControllers] objectAtIndex:0] setShouldCascadeWindows:NO];
	
	[self setDefaultAppearanceAtStartup];
	
	[self setDefaultViews];
	
	[documentsTableView setDelegate:self];
	[mainSplitView setDelegate:self];
	//[mainSplitView setAutosaveName:@"MainSplitView"];
	[contentSplitView setDelegate:self];	
	
	[[FRAViewMenuController sharedInstance] performCollapse];
	[self performSelector:@selector(performSetupAfterItIsCurrentProject) withObject:nil afterDelay:0.0];
	
	[[self window] setDelegate:self];
	
	[documentsTableView setDataSource:[FRADragAndDropController sharedInstance]];
	[documentsTableView registerForDraggedTypes:@[NSFilenamesPboardType, NSStringPboardType, @"FRAMovedDocumentType"]];
	[documentsTableView setDraggingSourceOperationMask:(NSDragOperationCopy | NSDragOperationMove) forLocal:NO];
	
	
//	splitWindowImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRASplitWindowIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
//	[[[splitWindowImage representations] objectAtIndex:0] setAlpha:YES];
//	closeSplitImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRACloseSplitIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
//	[[[closeSplitImage representations] objectAtIndex:0] setAlpha:YES];
//	lineWrapImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRALineWrapIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
//	[[[lineWrapImage representations] objectAtIndex:0] setAlpha:YES];
//	dontLineWrapImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRADontLineWrapIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
//	[[[dontLineWrapImage representations] objectAtIndex:0] setAlpha:YES];
	saveImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRASaveIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
	//[[[saveImage representations] objectAtIndex:0] setAlpha:YES];
	openDocumentImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRAOpenIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
	//[[[openDocumentImage representations] objectAtIndex:0] setAlpha:YES];
	newImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRANewIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
	//[[[newImage representations] objectAtIndex:0] setAlpha:YES];
	closeImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRACloseIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
	//[[[closeImage representations] objectAtIndex:0] setAlpha:YES];
	//preferencesImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRAPreferencesIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
	//[[[preferencesImage representations] objectAtIndex:0] setAlpha:YES];
	advancedFindImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRAAdvancedFindIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
	[[advancedFindImage representations][0] setAlpha:YES];
	previewImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRAPreviewIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
	//[[[previewImage representations] objectAtIndex:0] setAlpha:YES];
	functionImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRAFunctionIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
	//[[[functionImage representations] objectAtIndex:0] setAlpha:YES];
	infoImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRAInfoIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
	//[[[infoImage representations] objectAtIndex:0] setAlpha:YES];
	
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"ToolbarIdentifier"];
    [toolbar setShowsBaselineSeparator:YES];
	[toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDisplayMode:NSToolbarDisplayModeDefault];
    [toolbar setDelegate:self];
	//[toolbar setSizeMode:NSToolbarSizeModeSmall];
    [[self window] setToolbar:toolbar];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES];
	[documentsArrayController setSortDescriptors:@[sortDescriptor]];

	if ([[FRAApplicationDelegate sharedInstance] shouldCreateEmptyDocument] == YES) {
		id document = [self createNewDocumentWithContents:@""];
		[self insertDefaultIconsInDocument:document];
		[self selectionDidChange];
	}
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{	
	return [NSArchiver archivedDataWithRootObject:[self dictionaryOfDocumentsInProject]];
}


- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
{
    [savePanel setDirectoryURL: [NSURL fileURLWithPath: [FRAInterface whichDirectoryForSave]]];
	
	return YES;
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	return NO;
}

/**
 * This method creates a NSPrintOperation object to allow the user to print its document or to export it. It also
 * shows the Printing panel so the user can modify settings concerning the document printing. The printing operation
 * is executed in a new thread so the user can still interact with the application.
 */
- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError
{
	NSPrintInfo *printInfo = [self printInfo]; 
	FRAPrintTextView *printTextView = [[FRAPrintTextView alloc] initWithFrame:NSMakeRect([printInfo leftMargin], [printInfo bottomMargin], [printInfo paperSize].width - [printInfo leftMargin] - [printInfo rightMargin], [printInfo paperSize].height - [printInfo topMargin] - [printInfo bottomMargin])];
	
	NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:printTextView printInfo:printInfo];
    [printOperation setShowsPrintPanel:YES];
	[printOperation setCanSpawnSeparateThread:YES]; // Allow the printing process to be executed in a new thread.
    
    NSPrintPanel *printPanel = [printOperation printPanel];
	FRAPrintViewController *printViewController = [[FRAPrintViewController alloc] init];    
	[printPanel addAccessoryController:printViewController];
	
    return printOperation;
}


- (NSPrintInfo *)printInfo
{
    NSPrintInfo *printInfo = [super printInfo];
	
	CGFloat marginsMin = [[FRADefaults valueForKey:@"MarginsMin"] doubleValue];
	if ([[FRADefaults valueForKey:@"PrintHeader"] boolValue] == YES) {
		[printInfo setTopMargin:(marginsMin + 22)];
	} else {
		[printInfo setTopMargin:marginsMin];
	}
	[printInfo setLeftMargin:marginsMin];	
	[printInfo setRightMargin:marginsMin];
	[printInfo setBottomMargin:marginsMin];
	
	[printInfo setHorizontallyCentered:NO];    
	[printInfo setVerticallyCentered:NO];
	
	[printInfo setHorizontalPagination:NSAutoPagination];
	[printInfo setVerticalPagination:NSAutoPagination];
	
    return printInfo;
}


#pragma mark -
#pragma mark Others

- (void)performSetupAfterItIsCurrentProject
{
	[[FRAProjectsController sharedDocumentController] setCurrentProject:nil];
	
	[documentsTableView setTarget:self];
	[documentsTableView setDoubleAction:@selector(doubleClick:)];
	
	if ([[documentsArrayController arrangedObjects] count] > 0) {
		[self updateWindowTitleBarForDocument:[documentsArrayController selectedObjects][0]];
	} else {
		[self updateWindowTitleBarForDocument:nil];
	}
	
	[self extraToolbarValidation];
}


- (void)setDefaultAppearanceAtStartup
{
	[[statusBarTextField cell] setBackgroundStyle:NSBackgroundStyleRaised];
	
	FRADocumentsListCell *cell = [[FRADocumentsListCell alloc] init];
	[cell setWraps:NO];
	[cell setLineBreakMode:NSLineBreakByTruncatingMiddle];
	[[documentsTableView tableColumnWithIdentifier:@"name"] setDataCell:cell];

	if ([[FRADefaults valueForKey:@"ShowStatusBar"] boolValue] == NO) {
		[[FRAViewMenuController sharedInstance] performHideStatusBar];
	}

	if ([[FRADefaults valueForKey:@"ShowTabBar"] boolValue] == NO) {
		CGFloat tabBarHeight = [tabBarControl bounds].size.height;
		NSRect mainSplitViewRect = [mainSplitView frame];
		[tabBarControl setHidden:YES];
		[mainSplitView setFrame:NSMakeRect(mainSplitViewRect.origin.x, mainSplitViewRect.origin.y, mainSplitViewRect.size.width, mainSplitViewRect.size.height + tabBarHeight)];
	} else {
		[self updateTabBar];
	}

	if ([project valueForKey:@"dividerPosition"] == nil) {
		[project setValue:[FRADefaults valueForKey:@"DividerPosition"] forKey:@"dividerPosition"];
	}
	[self resizeMainSplitView];
}


- (void)selectDocument:(id)document
{
	[documentsArrayController setSelectedObjects:@[document]];
}


- (BOOL)areThereAnyDocuments
{
	if ([[documentsArrayController arrangedObjects] count] > 0) {
		return YES;
	} else {
		return NO;
	}
}


- (void)resizeViewsForDocument:(id)document
{	
	if ([self areThereAnyDocuments] == YES) {		
		NSInteger gutterWidth;
		CGFloat subtractFromY; // To remove extra "ugly" pixel row in singleDocumentWindow
		CGFloat subtractFromHeight = 0;
		NSInteger extraHeight;
		NSInteger viewNumber = 0;
		NSView *view = firstContentView;
		NSScrollView *textScrollView = [document valueForKey:@"firstTextScrollView"];
		NSScrollView *gutterScrollView = [document valueForKey:@"firstGutterScrollView"];
		
		while (viewNumber++ < 3) {
			subtractFromY = 0;
			extraHeight = 0;
			if (viewNumber == 2) {
				if ([document valueForKey:@"secondTextView"] != nil) {
					view = secondContentView;
					textScrollView = [document valueForKey:@"secondTextScrollView"];
					gutterScrollView = [document valueForKey:@"secondGutterScrollView"];
					subtractFromY = [secondContentViewNavigationBar bounds].size.height * -1;
					subtractFromHeight = [secondContentViewNavigationBar bounds].size.height;
				} else {
					continue;
				}
			}
			if (viewNumber == 3) {
				if ([document valueForKey:@"singleDocumentWindow"] != nil) {
					view = [[document valueForKey:@"singleDocumentWindow"] contentView];
					textScrollView = [document valueForKey:@"thirdTextScrollView"];
					gutterScrollView = [document valueForKey:@"thirdGutterScrollView"];
					subtractFromY = 1;
					extraHeight = 2;
				} else {
					continue;
				}
			}
			if ([[document valueForKey:@"showLineNumberGutter"] boolValue] == YES) {
				if (![[view subviews] containsObject:gutterScrollView]) {
					[view addSubview:gutterScrollView];
				}
				gutterWidth = [[document valueForKey:@"gutterWidth"] integerValue];
				[gutterScrollView setFrame:NSMakeRect(0, 0 - subtractFromY, gutterWidth, [view bounds].size.height + extraHeight - subtractFromHeight)];
			} else {
				gutterWidth = 0;
				[gutterScrollView removeFromSuperviewWithoutNeedingDisplay];
			}

			[textScrollView setFrame:NSMakeRect(gutterWidth, 0 - subtractFromY, [view bounds].size.width - gutterWidth, [view bounds].size.height + extraHeight - subtractFromHeight)];
		}
		
		[[document valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth:YES recolour:YES];
	}
}


- (void)doubleClick:(id)sender
{
	[[FRAViewMenuController sharedInstance] viewDocumentInSeparateWindowAction:nil];
}


- (id)createNewDocumentWithContents:(NSString *)textString
{
	id document = [self createNewDocumentWithPath:nil andContents:textString];
	
	[document setValue:@YES forKey:@"isNewDocument"];
	[FRAVarious setUnsavedAsLastSavedDateForDocument:document];
	[FRAInterface updateStatusBar];
	
	return document;
}


- (id)createNewDocumentWithPath:(NSString *)path andContents:(NSString *)textString
{
	id document = [FRABasic createNewObjectForEntity:@"Document"];
	
	[[self documents] addObject:document];
	
	[FRAVarious setNameAndPathForDocument:document path:path];
	[FRAInterface createFirstViewForDocument:document];

	[[document valueForKey:@"firstTextView"] setString:textString];
	
	FRASyntaxColouring *syntaxColouring = [[FRASyntaxColouring alloc] initWithDocument:document];
	[document setValue:syntaxColouring forKey:@"syntaxColouring"];
	
	[[document valueForKey:@"lineNumbers"] updateLineNumbersForClipView:[[document valueForKey:@"firstTextScrollView"] contentView] checkWidth:NO recolour:YES];
	[document setValue:[NSNumber numberWithInteger:[[documentsArrayController arrangedObjects] count]] forKey:@"sortOrder"];
	[self documentsListHasUpdated];
	
	[documentsArrayController setSelectedObjects:@[document]];
	
	[document setValue:[NSString localizedNameOfStringEncoding:[[document valueForKey:@"encoding"] integerValue]] forKey:@"encodingName"];
	
	return document;
}


- (void)updateEditedBlobStatus
{
	id currentDocument = FRACurrentDocument;
	if ([[currentDocument valueForKey:@"isEdited"] boolValue] == YES) {
		[[self window] setDocumentEdited:YES];
		if ([currentDocument valueForKey:@"singleDocumentWindow"] != nil) {
			[[currentDocument valueForKey:@"singleDocumentWindow"] setDocumentEdited:YES];
		}
	} else {
		[[self window] setDocumentEdited:NO];
		if ([currentDocument valueForKey:@"singleDocumentWindow"] != nil) {
			[[currentDocument valueForKey:@"singleDocumentWindow"] setDocumentEdited:NO];
		}
	}
}


- (void)updateWindowTitleBarForDocument:(id)document
{
	NSWindow *currentWindow = [self window];
	NSString *projectName = nil;
	if ([self name] != nil) {
		projectName = [self name];
	}

	if ([self areThereAnyDocuments] == YES && document != nil) {
		NSWindow *singleDocumentWindow = [document valueForKey:@"singleDocumentWindow"];
		[self updateEditedBlobStatus];
		if ([document valueForKey:@"path"] != nil && [[FRADefaults valueForKey:@"ShowFullPathInWindowTitle"] boolValue] == YES) {
			
			if ([[document valueForKey:@"fromExternal"] boolValue] == YES) {
				
				if (document == [self firstDocument] || document == [self secondDocument]) {
					[currentWindow setTitleWithRepresentedFilename:[document valueForKey:@"path"]];
					if (projectName != nil) {
						[currentWindow setTitle:[NSString stringWithFormat:@"%@ - %@ (%@)", [document valueForKey:@"name"], [[document valueForKey:@"externalPath"] stringByDeletingLastPathComponent], projectName]];
					} else {
						[currentWindow setTitle:[NSString stringWithFormat:@"%@ - %@", [document valueForKey:@"name"], [[document valueForKey:@"externalPath"] stringByDeletingLastPathComponent]]];
					}
				}
				if (singleDocumentWindow != nil) {
					[singleDocumentWindow setTitleWithRepresentedFilename:[document valueForKey:@"path"]];
					[singleDocumentWindow setTitle:[NSString stringWithFormat:@"%@ - %@", [document valueForKey:@"name"], [[document valueForKey:@"externalPath"] stringByDeletingLastPathComponent]]];
				}
				
			} else {
				if (document == [self firstDocument] || document == [self secondDocument]) {
					[currentWindow setTitleWithRepresentedFilename:[document valueForKey:@"path"]];
					if (projectName != nil) {
						[currentWindow setTitle:[NSString stringWithFormat:@"%@ (%@)", [document valueForKey:@"nameWithPath"], projectName]];
					} else {
						[currentWindow setTitle:[document valueForKey:@"nameWithPath"]];
					}
				}
				if (singleDocumentWindow != nil) {
					[singleDocumentWindow setTitleWithRepresentedFilename:[document valueForKey:@"path"]];
					[singleDocumentWindow setTitle:[document valueForKey:@"nameWithPath"]];
				}
			}
			
		} else {
			if ([document valueForKey:@"path"] != nil) {
				if (document == [self firstDocument] || document == [self secondDocument]) {
					[currentWindow setTitleWithRepresentedFilename:[document valueForKey:@"path"]];
					if (projectName != nil) {
						[currentWindow setTitle:[NSString stringWithFormat:@"%@ (%@)", [document valueForKey:@"name"], projectName]];
					}
				}
				if (singleDocumentWindow != nil) {
					[singleDocumentWindow setTitleWithRepresentedFilename:[document valueForKey:@"path"]];
				}
				
			} else {
				if (document == [self firstDocument] || document == [self secondDocument]) {
					[currentWindow setRepresentedFilename:[[NSBundle mainBundle] bundlePath]];
					if (projectName != nil) {
						[currentWindow setTitle:[NSString stringWithFormat:@"%@ (%@)", [document valueForKey:@"name"], projectName]];
					} else {
						[currentWindow setTitle:[document valueForKey:@"name"]];
					}
				}
				if (singleDocumentWindow != nil) {
					[singleDocumentWindow setRepresentedFilename:[[NSBundle mainBundle] bundlePath]];
				}
			}
			
			if (document == [self firstDocument] || document == [self secondDocument]) {
				if (projectName != nil) {
					[currentWindow setTitle:[NSString stringWithFormat:@"%@ (%@)", [document valueForKey:@"name"], projectName]];
				} else {
					[currentWindow setTitle:[document valueForKey:@"name"]];
				}
			}
			if (singleDocumentWindow != nil) {
				[singleDocumentWindow setTitle:[document valueForKey:@"name"]];
			}
		}
	} else {
		[currentWindow setDocumentEdited:NO];
		[currentWindow setRepresentedFilename:[[NSBundle mainBundle] bundlePath]];
		[currentWindow setTitle:@"Fraise"];
	}
}


- (void)checkIfDocumentIsUnsaved:(id)document keepOpen:(BOOL)keepOpen
{	
	if ([[document valueForKey:@"isEdited"] boolValue] == YES) {
		[self selectDocument:document];
		NSString *title = [NSString stringWithFormat:NSLocalizedString(@"The document %@ has not been saved", @"Indicate in Close-sheet that the document %@ has not been saved."), [document valueForKey:@"name"]];
		NSBeginAlertSheet(title,
						  SAVE_STRING,
						  NSLocalizedString(@"Don't Save", @"Don't Save-button in Close-sheet"),
						  CANCEL_BUTTON,
						  [self window],
						  self,
						  @selector(closeSheetDidEnd:returnCode:contextInfo:),
						  nil,
						  (__bridge void *)@[document, @(keepOpen)],
						  NSLocalizedString(@"Your changes will be lost if you close the document without saving.", @"Your changes will be lost if you close the document without saving in Close-sheet"));
		[NSApp runModalForWindow:[[self window] attachedSheet]]; // Modal to make sure that nothing happens while the sheet is displaying
	} else {
		if (keepOpen == NO) {
			[self performCloseDocument:document];
		}
	}
}


- (void)closeSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [FRAVarious stopModalLoop];
	
	id document = ((__bridge NSArray *)contextInfo)[0];
	BOOL keepOpen = [((__bridge NSArray *)contextInfo)[1] boolValue];
	
	if (returnCode == NSAlertDefaultReturn) {
		[sheet close];
		[[FRAFileMenuController sharedInstance] saveAction:nil];
		if ([[document valueForKey:@"isEdited"] boolValue] == NO) { // Save didn't fail
			if (keepOpen == NO) {
				[self performCloseDocument:document];
			}
		} else {
			shouldWindowClose = NO;
		}
	} else if (returnCode == NSAlertAlternateReturn) {
		if (keepOpen == NO) {
			[self performCloseDocument:document];
		}
	} else { // The user wants to review the document
		shouldWindowClose = NO;
	}
}


- (void)performCloseDocument:(id)document
{
	if (document == nil) {
		return;
	}
	
	NSInteger documentIndex = [[[self documentsArrayController] arrangedObjects] indexOfObject:document];

	[self cleanUpDocument:document];
	
	if ([self areThereAnyDocuments]) {
		if (documentIndex > 0) {
			documentIndex--;
			[[self documentsArrayController] setSelectionIndex:documentIndex];
		} else {
			[[self documentsArrayController] setSelectionIndex:0];
			[self selectionDidChange]; // Doesn't seem to send this notification otherwise
		}
		[self updateWindowTitleBarForDocument:FRACurrentDocument];
	
		[self documentsListHasUpdated];
	} else {
		if ([[FRAApplicationDelegate sharedInstance] filesToOpenArray] == nil) { // A hack to make it only close the window when there no documents to open, from e.g. a FTP-program
			if ([[self window] attachedSheet]) {
				[self performSelector:@selector(performCloseWindow) withObject:nil afterDelay:0.0]; // Do it this way to allow a possible attached sheet to close, otherwise it won't work
			} else {
				if ([[FRADefaults valueForKey:@"KeepEmptyWindowOpen"] boolValue] == NO) {
					[[self window] performClose:nil];
				}
			}
		}
	}
	
	[FRAVarious resetSortOrderNumbersForArrayController:documentsArrayController];
	
//	[[NSGarbageCollector defaultCollector] collectExhaustively];
}


- (void)performCloseWindow
{
	[[self window] performClose:nil];
}


- (void)cleanUpDocument:(id)document
{
	[[NSNotificationCenter defaultCenter] removeObserver:[document valueForKey:@"lineNumbers"]];
	
	if ([self secondDocument] == document && [[document valueForKey:@"secondTextScrollView"] contentView] != nil) {
		[[FRAViewMenuController sharedInstance] performCollapse];
	}
	
	if ([document valueForKey:@"singleDocumentWindow"] != nil) {
		[[document valueForKey:@"singleDocumentWindow"] performClose:nil];
	}	
	
	if ([[FRAAdvancedFindController sharedInstance] currentlyDisplayedDocumentInAdvancedFind] == document) {
		[[FRAAdvancedFindController sharedInstance] removeCurrentlyDisplayedDocumentInAdvancedFind];
	}
	
	if ([[document valueForKey:@"fromExternal"] boolValue] == YES) {
		[FRAVarious sendClosedEventToExternalDocument:document];
	}
	
	if ([self firstDocument] == document) {
		[FRAInterface removeAllSubviewsFromView:[self firstContentView]];
		[self setFirstDocument:nil];
	}
	
    [documentsArrayController removeObject:document];
	[[FRAApplicationDelegate sharedInstance] saveAction:nil]; // To remove it from memory
	[[FRAManagedObjectContext undoManager] removeAllActions];
}


- (NSDictionary *)dictionaryOfDocumentsInProject
{	
	[FRAVarious resetSortOrderNumbersForArrayController:documentsArrayController];
	
	NSArray *array = [[self documents] allObjects];
	NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionary];
	NSMutableArray *documentsArray = [NSMutableArray array];
	for (id item in array) {
		if ([item valueForKey:@"path"] != nil) {
			NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
			[dictionary setValue:[item valueForKey:@"path"] forKey:@"path"];
			[dictionary setValue:[item valueForKey:@"encoding"] forKey:@"encoding"];
			[dictionary setValue:[item valueForKey:@"sortOrder"] forKey:@"sortOrder"];
			NSRange selectedRange = [[item valueForKey:@"firstTextView"] selectedRange];
			if (selectedRange.location == NSNotFound) {
				[dictionary setValue:NSStringFromRange(NSMakeRange(0, 0)) forKey:@"selectedRange"];
			} else {
				[dictionary setValue:NSStringFromRange(selectedRange) forKey:@"selectedRange"];
			}
			[documentsArray addObject:dictionary];
		}
	}
	
	[returnDictionary setValue:documentsArray forKey:@"documentsArray"];
	NSString *name;
	
	if ([self areThereAnyDocuments] == NO || [[documentsArrayController selectedObjects][0] valueForKey:@"name"] == nil) {
		name = @"";
	} else {
		name = [[documentsArrayController selectedObjects][0] valueForKey:@"name"];
	}
	[returnDictionary setValue:name forKey:@"selectedDocumentName"];
	[returnDictionary setValue:NSStringFromRect([[self window] frame]) forKey:@"windowFrame"];
	[returnDictionary setValue:[project valueForKey:@"view"] forKey:@"view"];
	[returnDictionary setValue:[project valueForKey:@"viewSize"] forKey:@"viewSize"];
	[self saveMainSplitViewFraction];
	[returnDictionary setValue:[project valueForKey:@"dividerPosition"]  forKey:@"dividerPosition"];
	[returnDictionary setValue:@3 forKey:@"version"];
	
	return returnDictionary;
}


- (void)autosave
{
	if ([self fileURL] != nil) {
		[self saveDocument:nil];
	}
}


- (NSString *)name
{
	if ([self fileURL] == nil) {
		return nil;
	}
	
	NSString *urlString = (NSString*)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (CFStringRef)[[self fileURL] absoluteString], CFSTR(""), kCFStringEncodingUTF8));
//	NSMakeCollectable(urlString);
	return [[urlString lastPathComponent] stringByDeletingPathExtension];
}


- (void)selectionDidChange
{
	[self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChangeNotification" object:documentsTableView]];
}


- (BOOL)isDocumentEdited
{
	return NO;
}


- (BOOL)areAllDocumentsSaved
{	
	[self saveMainSplitViewFraction];
	
	shouldWindowClose = YES;
	
	NSArray *array = [[self documents] allObjects];
	for (id item in array) {
		if ([[item valueForKey:@"isEdited"] boolValue] == YES) {	
			[self checkIfDocumentIsUnsaved:item keepOpen:YES];
		}
		if (shouldWindowClose == NO) { // If one has chosen Cancel to review document one should not be asked about other unsaved documents
			return NO;
		}
	}
	
	// If the user has chosen to review the document instead of closing it the application should not be closed
	if (shouldWindowClose == NO) {
		return NO;
	} else {
		return YES;
	}
}


- (void)documentsListHasUpdated
{
	[self updateTabBar];
	[self buildSecondContentViewNavigationBarMenu];
		
	[self reloadData];
	
	if ([[FRAApplicationDelegate sharedInstance] hasFinishedLaunching] == YES) { // Do this toolbar validation here so it doesn't need to be updated all the time as it would have been in validateToolbarItem
		[self extraToolbarValidation];
	}
}


- (void)buildSecondContentViewNavigationBarMenu
{
	if (secondDocument == nil) {
		return;
	}
	
	NSMenu *menu = [secondContentViewPopUpButton menu];
	[FRABasic removeAllItemsFromMenu:menu];
	
	id menuItemToSelect = nil;
	NSEnumerator *enumerator = [[documentsArrayController arrangedObjects] reverseObjectEnumerator];
	for (id item in enumerator) {
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[item valueForKey:@"name"] action:@selector(secondContentViewDocumentChanged:) keyEquivalent:@""];
		[menuItem setRepresentedObject:item];
		[menuItem setTarget:self];
		[menu insertItem:menuItem atIndex:0];
		if (item == secondDocument) {
			menuItemToSelect = menuItem;
		}
	}
	
	[secondContentViewPopUpButton selectItem:menuItemToSelect];
}


- (void)secondContentViewDocumentChanged:(id)sender
{
	[FRAInterface insertDocumentIntoSecondContentView:[sender representedObject]];
}


- (CGFloat)mainSplitViewFraction
{
	CGFloat fraction;
	if ([contentSplitView bounds].size.width + [leftDocumentsView bounds].size.width + [mainSplitView dividerThickness] != 0) {
		fraction = [leftDocumentsView bounds].size.width / ([contentSplitView bounds].size.width + [leftDocumentsView bounds].size.width + [mainSplitView dividerThickness]);
	} else {
		fraction = 0.0;
	}
	
	return fraction;
}


- (void)resizeMainSplitView
{	
	NSRect leftDocumentsViewFrame = [[mainSplitView subviews][0] frame];
    NSRect contentViewFrame = [[mainSplitView subviews][1] frame];
	CGFloat totalWidth = leftDocumentsViewFrame.size.width + contentViewFrame.size.width + [mainSplitView dividerThickness];
    leftDocumentsViewFrame.size.width = [[project valueForKey:@"dividerPosition"] doubleValue] * totalWidth;
    contentViewFrame.size.width = totalWidth - leftDocumentsViewFrame.size.width - [mainSplitView dividerThickness];
	
    [[mainSplitView subviews][0] setFrame:leftDocumentsViewFrame];
    [[mainSplitView subviews][1] setFrame:contentViewFrame];
	
    [mainSplitView adjustSubviews];
}


- (void)saveMainSplitViewFraction
{
	NSNumber *fraction = @([self mainSplitViewFraction]);
	[project setValue:fraction forKey:@"dividerPosition"];
	[FRADefaults setValue:fraction forKey:@"DividerPosition"];
}


- (void)insertDefaultIconsInDocument:(id)document
{
	NSImage *defaultIcon = [FRAInterface defaultIcon];
	[defaultIcon setScalesWhenResized:YES];
		
	NSImage *defaultUnsavedIcon = [FRAInterface defaultUnsavedIcon];
	[defaultUnsavedIcon setScalesWhenResized:YES];
	
	[document setValue:defaultIcon forKey:@"icon"];	
	[document setValue:defaultUnsavedIcon forKey:@"unsavedIcon"];
}


#pragma mark -
#pragma mark Accessors

- (void)setLastTextViewInFocus: (FRATextView *)newLastTextViewInFocus
{
	if (lastTextViewInFocus != newLastTextViewInFocus)
    {
		lastTextViewInFocus = newLastTextViewInFocus;
	}
	
	[self updateWindowTitleBarForDocument:FRACurrentDocument];
}


- (NSMutableSet *)documents
{
	return [project mutableSetValueForKey:@"documents"];
}


- (NSWindow *)window
{
	return [[self windowControllers][0] window];
}


- (NSManagedObjectContext *)managedObjectContext
{
	return FRAManagedObjectContext;
}


- (NSToolbar *)projectWindowToolbar
{
    return [[self window] toolbar];
}


#pragma mark -
#pragma mark Window delegates

- (BOOL)windowShouldClose:(id)sender
{	
	if ([self areAllDocumentsSaved] == YES) { // Has the closing been stopped, by e.g. the user wanting to review a document
		return YES;
	} else {
		return NO;
	}
}


- (void)windowWillClose:(NSNotification *)aNotification
{
	if ([[FRAApplicationDelegate sharedInstance] isTerminatingApplication] == YES) {		
		return; // No need to clean up if we are quitting
	}
	
	[self autosave];
	
	NSArray *array = [[self documents] allObjects];
	for (id item in array) {
		[self cleanUpDocument:item];
	}

	[[FRAApplicationDelegate sharedInstance] saveAction:nil]; // Make sure the documents objects really are deleted, before deleting the project

	if (project != nil) { // Remove the managed object project
		[FRAManagedObjectContext deleteObject:project];
	}

	[[FRAApplicationDelegate sharedInstance] saveAction:nil];
	[[FRAManagedObjectContext undoManager] removeAllActions];
}





@end
