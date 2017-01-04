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


#import "FRAPreferencesController.h"
#import "NSString+Fraise.h"
#import "FRABasicPerformer.h"
#import "FRAVariousPerformer.h"
#import "FRAProjectsController.h"
#import "FRAInterfacePerformer.h"
#import "FRACommandsController.h"
#import "FRASnippetsController.h"
#import "FRAAdvancedFindController.h"
#import "FRAMainController.h"
#import "FRAApplicationDelegate.h"
#import "FRAProject.h"
#import "FRALineNumbers.h"
#import "NSToolbarItem+Fraise.h"

@implementation FRAPreferencesController

@synthesize encodingsArrayController, syntaxDefinitionsArrayController, encodingsPopUp, preferencesWindow;


static id sharedInstance = nil;

+ (FRAPreferencesController *)sharedInstance
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
		
		hasPreparedAdvancedInterface = NO;
    }
    return sharedInstance;
}


- (void)setDefaults
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
	dictionary[@"CommandsColourWell"] = [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.97 alpha:1.0]];
	dictionary[@"CommentsColourWell"] = [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.0 green:0.69 blue:0.001 alpha:1.0]];
	dictionary[@"InstructionsColourWell"] = [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.45 green:0.45 blue:0.45 alpha:1.0]];
	dictionary[@"KeywordsColourWell"] = [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.84 green:0.41 blue:0.006 alpha:1.0]];
	dictionary[@"AutocompleteColourWell"] = [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.84 green:0.41 blue:0.006 alpha:1.0]];
	dictionary[@"VariablesColourWell"] = [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.73 green:0.0 blue:0.74 alpha:1.0]];
	dictionary[@"StringsColourWell"] = [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.95 green:0.0 blue:0.0 alpha:1.0]];
	dictionary[@"AttributesColourWell"] = [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.50 green:0.5 blue:0.2 alpha:1.0]];
	dictionary[@"ColourCommands"] = @YES;
	dictionary[@"ColourComments"] = @YES;
	dictionary[@"ColourInstructions"] = @YES;
	dictionary[@"ColourKeywords"] = @YES;
	dictionary[@"ColourAutocomplete"] = @NO;
	dictionary[@"ColourVariables"] = @YES;
	dictionary[@"ColourStrings"] = @YES;
	dictionary[@"ColourAttributes"] = @YES;
	
	dictionary[@"BackgroundColourWell"] = [NSArchiver archivedDataWithRootObject:[NSColor whiteColor]];
	dictionary[@"TextColourWell"] = [NSArchiver archivedDataWithRootObject:[NSColor blackColor]];
	dictionary[@"InvisibleCharactersColourWell"] = [NSArchiver archivedDataWithRootObject:[NSColor blackColor]];
	dictionary[@"HighlightLineColourWell"] = [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.96 green:0.96 blue:0.71 alpha:1.0]];
	
	dictionary[@"EncodingsMatrix"] = @0;
	dictionary[@"OpenMatrix"] = @(FRAOpenSaveRemember);
	dictionary[@"SaveMatrix"] = @(FRAOpenSaveAlways);
	dictionary[@"EncodingsPopUp"] = @(NSUTF8StringEncoding);
	dictionary[@"SizeOfDocumentsListTextPopUp"] = @0;
	dictionary[@"LineEndingsPopUp"] = @5;
	dictionary[@"SyntaxColouringMatrix"] = @0;
	dictionary[@"NSRecentDocumentsLimit"] = @12;
	dictionary[@"GutterWidth"] = @40;
	dictionary[@"TabWidth"] = @4;
	dictionary[@"IndentWidth"] = @4;
	dictionary[@"ShowPageGuideAtColumn"] = @80;
	dictionary[@"StatusBarLastSavedFormatPopUp"] = @5;
	dictionary[@"ViewSize"] = @32;
	dictionary[@"View"] = @(FRAListView);
	dictionary[@"PreviewParser"] = @(FRAPreviewHTML);
	dictionary[@"AdvancedFindScope"] = @(FRACurrentDocumentScope);
	
	dictionary[@"AutocompleteAfterDelay"] = @0.5;
	
	dictionary[@"TextFont"] = [NSArchiver archivedDataWithRootObject:[NSFont fontWithName:@"Menlo" size:11]];
	dictionary[@"OpenAlwaysUseTextField"] = [[NSString localizedStringWithFormat:@"%@/%@", NSHomeDirectory(), @"Desktop"] stringByAbbreviatingWithTildeInPath];
	dictionary[@"SaveAsAlwaysUseTextField"] = [[NSString localizedStringWithFormat:@"%@/%@", NSHomeDirectory(), @"Desktop"] stringByAbbreviatingWithTildeInPath];
	
	dictionary[@"NewDocumentAtStartup"] = @YES;
	dictionary[@"ShowFullPathInWindowTitle"] = @YES;
	dictionary[@"ShowLineNumberGutter"] = @YES;
	dictionary[@"SyntaxColourNewDocuments"] = @YES;
	dictionary[@"LineWrapNewDocuments"] = @YES;
	dictionary[@"AssignDocumentToFraiseWhenSaving"] = @YES;
	dictionary[@"IndentNewLinesAutomatically"] = @YES;
	dictionary[@"OnlyColourTillTheEndOfLine"] = @YES;
	dictionary[@"CheckIfDocumentHasBeenUpdated"] = @NO;
	dictionary[@"ShowMatchingBraces"] = @YES;
	dictionary[@"StatusBarShowEncoding"] = @YES;
	dictionary[@"StatusBarShowLength"] = @YES;
	dictionary[@"StatusBarShowSelection"] = @YES;
	dictionary[@"StatusBarShowPosition"] = @NO;
	dictionary[@"StatusBarShowSyntax"] = @NO;
	dictionary[@"StatusBarShowWhenLastSaved"] = @YES;
	dictionary[@"ShowInvisibleCharacters"] = @NO;
	dictionary[@"IndentWithSpaces"] = @NO;
	dictionary[@"OpenAllFilesWithinAFolder"] = @NO;
	dictionary[@"OpenAllDocumentsIHadOpen"] = @NO;
	dictionary[@"OpenAllProjectsIHadOpen"] = @YES;
	dictionary[@"ColourMultiLineStrings"] = @NO;
	dictionary[@"AutocompleteSuggestAutomatically"] = @NO;
	dictionary[@"AutocompleteIncludeStandardWords"] = @YES;
	dictionary[@"AutoSpellCheck"] = @NO;
	dictionary[@"AutoGrammarCheck"] = @NO;
	dictionary[@"KeepRunningAfterMainWindowIsClosed"] = @NO;
	dictionary[@"SmartInsertDelete"] = @NO;
	dictionary[@"AutomaticLinkDetection"] = @YES;
	dictionary[@"AutomaticQuoteSubstitution"] = @NO;
	dictionary[@"UseTabStops"] = @YES;
	dictionary[@"HighlightCurrentLine"] = @NO;
	
	dictionary[@"OpenAllFilesInAFolderRecursively"] = @YES;
	dictionary[@"FilterOutExtensions"] = @YES;
	dictionary[@"UseRGBRatherThanHexWhenInsertingColourValues"] = @YES;
	dictionary[@"ShowFullPathInDocumentsList"] = @NO;
	dictionary[@"AutomaticallyIndentBraces"] = @YES;
	dictionary[@"AppendNameInSaveAs"] = @NO;
	dictionary[@"AutoInsertAClosingParenthesis"] = @NO;
	dictionary[@"AutoInsertAClosingBrace"] = @NO;
	dictionary[@"OpenAllDocumentsIHadOpen"] = @NO;
	dictionary[@"OpenAllProjectsIHadOpen"] = @NO;
	
	dictionary[@"IgnoreCaseAdvancedFind"] = @YES;
	dictionary[@"UseRegularExpressionsAdvancedFind"] = @NO;
	dictionary[@"OnlyInSelectionAdvancedFind"] = @NO;
	
	dictionary[@"PrintHeader"] = @YES;
	dictionary[@"PrintSyntaxColours"] = @YES;
	dictionary[@"OnlyPrintSelection"] = @NO;
	
	dictionary[@"FilterOutExtensionsString"] = @"jpg gif png swf";
	dictionary[@"RunText"] = @"/bin/sh";
	dictionary[@"AppendNameInSaveAsWith"] = @".txt";
	dictionary[@"SyntaxColouringPopUpString"] = @"Standard";
	
	dictionary[@"MarginsMin"] = @24;
	dictionary[@"PrintFont"] = [NSArchiver archivedDataWithRootObject:[NSFont fontWithName:@"Courier" size:10]];
	
	NSArray *activeEncodings = @[@(NSASCIIStringEncoding), @(NSJapaneseEUCStringEncoding), @(NSUTF8StringEncoding), @(NSISOLatin1StringEncoding), @(NSSymbolStringEncoding), @(NSNonLossyASCIIStringEncoding), @(NSShiftJISStringEncoding), @(NSISOLatin2StringEncoding), @(NSUnicodeStringEncoding), @(NSWindowsCP1251StringEncoding), @(NSWindowsCP1252StringEncoding), @(NSWindowsCP1253StringEncoding), @(NSWindowsCP1254StringEncoding), @(NSWindowsCP1250StringEncoding), @(NSISO2022JPStringEncoding), @(NSMacOSRomanStringEncoding)];
	
	
	dictionary[@"ActiveEncodings"] = activeEncodings;
	
	// Users can't set these in Preferences
	dictionary[@"ShowStatusBar"] = @YES;
	dictionary[@"ShowTabBar"] = @NO;
	dictionary[@"HasInsertedDefaultSnippets"] = @NO;
	dictionary[@"HasImportedFromVersion2"] = @NO;
	dictionary[@"HasInsertedDefaultCommands3"] = @NO;
	dictionary[@"UpdateDocumentAutomaticallyWithoutWarning"] = @NO;
	dictionary[@"SpacesPerTabEntabDetab"] = @4;
	dictionary[@"TimeBetweenDocumentUpdateChecks"] = @15;
	dictionary[@"UserDateFormat"] = @"yyyy-MM-dd HH:mm 'w:'w 'd:'D";
	dictionary[@"AlwaysEndFileWithLineFeed"] = @NO;
	dictionary[@"SuppressReplaceWarning"] = @NO;
	dictionary[@"WhatKindOfProject"] = @(FRAVirtualProject);
	dictionary[@"LiveUpdatePreview"] = @NO;
	dictionary[@"LiveUpdatePreviewDelay"] = @1.0;
	dictionary[@"DividerPosition"] = @0.2;
	dictionary[@"ShowSizeSlider"] = @YES;
	dictionary[@"PutQuotesAroundDirectory"] = @YES;
	dictionary[@"FocusOnTextInAdvancedFind"] = @NO;
	dictionary[@"KeepEmptyWindowOpen"] = @NO;
	dictionary[@"UseQuickLookIcon"] = @YES;
	dictionary[@"UpdateIconForEverySave"] = @YES;
	
	dictionary[@"BaseURL"] = @"";
	
	NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	[defaultsController setInitialValues: dictionary];
	
	[defaultsController addObserver:self forKeyPath:@"values.StatusBarShowEncoding" options:NSKeyValueObservingOptionNew context:@"StatusBarChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.StatusBarShowLength" options:NSKeyValueObservingOptionNew context:@"StatusBarChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.StatusBarShowSelection" options:NSKeyValueObservingOptionNew context:@"StatusBarChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.StatusBarShowPosition" options:NSKeyValueObservingOptionNew context:@"StatusBarChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.StatusBarShowSyntax" options:NSKeyValueObservingOptionNew context:@"StatusBarChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.StatusBarShowWhenLastSaved" options:NSKeyValueObservingOptionNew context:@"StatusBarChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.StatusBarLastSavedFormatPopUp" options:NSKeyValueObservingOptionNew context:@"StatusBarLastSavedFormatChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.SizeOfDocumentsListTextPopUp" options:NSKeyValueObservingOptionNew context:@"SizeOfDocumentsListTextPopUpChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.ShowFullPathInWindowTitle" options:NSKeyValueObservingOptionNew context:@"ShowFullPathInWindowTitleChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.CheckIfDocumentHasBeenUpdated" options:NSKeyValueObservingOptionNew context:@"CheckIfDocumentHasBeenUpdatedChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.ShowFullPathInDocumentsList" options:NSKeyValueObservingOptionNew context:@"DocumentsListPathSettingsChanged"];
    
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([(__bridge NSString *)context isEqualToString:@"StatusBarChanged"]) {
		[FRAInterface updateStatusBar];
		
	} else if ([(__bridge NSString *)context isEqualToString:@"StatusBarLastSavedFormatChanged"]) {
		NSArray *array = [FRABasic fetchAll:@"Document"];
		for (id item in array) {
			if ([[item valueForKey:@"isNewDocument"] boolValue] == NO) {
				[FRAVarious setLastSavedDateForDocument:item date:[[item valueForKey:@"fileAttributes"] fileModificationDate]];
			}
		}
		[FRAInterface updateStatusBar];
		
	} else if ([(__bridge NSString *)context isEqualToString:@"ShowFullPathInWindowTitleChanged"]) {
		NSArray *projectsArray = [[FRAProjectsController sharedDocumentController] documents];
		for (id project in projectsArray) {
			NSArray *documentsArray = [FRABasic fetchAll:@"Document"];
			for (id document in documentsArray) {
				[project updateWindowTitleBarForDocument:document];
			}
		}
		
	} else if ([(__bridge NSString *)context isEqualToString:@"SizeOfDocumentsListTextPopUpChanged"]) {
		NSArray *array = [[FRAProjectsController sharedDocumentController] documents];
		for (id item in array) {
			[item reloadData];
		}
		[syntaxDefinitionsTableView reloadData];
		[encodingsTableView reloadData];
		
		if ([[FRACommandsController sharedInstance] commandsWindow] != nil) {
			[[[FRACommandsController sharedInstance] commandCollectionsTableView] reloadData];
			[[[FRACommandsController sharedInstance] commandsTableView] reloadData];
		}
		
		if ([[FRASnippetsController sharedInstance] snippetsWindow] != nil) {
			[[[FRASnippetsController sharedInstance] snippetCollectionsTableView] reloadData];
			[[[FRASnippetsController sharedInstance] snippetsTableView] reloadData];
		}
		if ([[FRAAdvancedFindController sharedInstance] advancedFindWindow] != nil) {
			[[[FRAAdvancedFindController sharedInstance] findResultsOutlineView] reloadData];
		}
		
	} else if ([(__bridge NSString *)context isEqualToString:@"CheckIfDocumentHasBeenUpdatedChanged"]) {
		[FRAVarious updateCheckIfAnotherApplicationHasChangedDocumentsTimer];
		
	} else if ([(__bridge NSString *)context isEqualToString:@"DocumentsListPathSettingsChanged"]) {
		NSArray *array = [[FRAProjectsController sharedDocumentController] documents];
		for (id item in array) {
			[item reloadData];
		}
        
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
    
}


- (void)showPreferencesWindow
{
	if (preferencesWindow == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"FRAPreferences" owner:self topLevelObjects:nil];
		[preferencesWindow setShowsToolbarButton:NO];
		
		preferencesToolbar = [[NSToolbar alloc] initWithIdentifier:@"PreferencesToolbarIdentifier"];
		[preferencesToolbar setAllowsUserCustomization:NO];
		[preferencesToolbar setAutosavesConfiguration:NO];
		[preferencesToolbar setShowsBaselineSeparator:YES];
		[preferencesToolbar setDelegate:self];
		[preferencesWindow setToolbar:preferencesToolbar];
		
		
		[preferencesWindow setTitle:NSLocalizedStringFromTable(@"Preferences - Fraise", @"Localizable3", @"Preferences - Fraise")];
	}
	
	if ([preferencesToolbar selectedItemIdentifier] == nil) {
		if (generalView == nil) {
			[[NSBundle mainBundle] loadNibNamed:@"FRAPreferencesGeneral" owner:self topLevelObjects:nil];
		}
		[preferencesToolbar setSelectedItemIdentifier:@"GeneralPreferencesToolbarItem"];
		if ([FRADefaults valueForKey:@"PreferencesGeneralViewSavedFrame"] == nil) {
			[preferencesWindow setFrame:[self getRectForView:generalView] display:YES animate:NO];
		} else { // It sometimes get the frame wrong after it has been resized so use the own saved version
			NSRect temporaryRect = NSRectFromString([FRADefaults valueForKey:@"PreferencesGeneralViewSavedFrame"]);
			[preferencesWindow setFrame:NSMakeRect(temporaryRect.origin.x, temporaryRect.origin.y, temporaryRect.size.width, temporaryRect.size.height) display:YES animate:NO];
		}
		[[preferencesWindow contentView] addSubview:generalView];
		currentView = generalView;
		
		[preferencesWindow setDelegate:self]; // So that it catches the changeFont action
	}
	
	[preferencesWindow makeKeyAndOrderFront:self];
}


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return @[@"GeneralPreferencesToolbarItem",
             @"AppearancePreferencesToolbarItem",
             @"SyntaxColoursPreferencesToolbarItem",
             @"SyntaxDefinitionsPreferencesToolbarItem",
             @"OpenSavePreferencesToolbarItem",
             @"AdvancedPreferencesToolbarItem"];
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return @[@"GeneralPreferencesToolbarItem",
             @"AppearancePreferencesToolbarItem",
             @"SyntaxColoursPreferencesToolbarItem",
             @"SyntaxDefinitionsPreferencesToolbarItem",
             @"OpenSavePreferencesToolbarItem",
             @"AdvancedPreferencesToolbarItem"];
    
}


- (NSArray *)toolbarSelectableItemIdentifiers: (NSToolbar *)toolbar
{
    return @[@"GeneralPreferencesToolbarItem",
             @"AppearancePreferencesToolbarItem",
             @"SyntaxColoursPreferencesToolbarItem",
             @"SyntaxDefinitionsPreferencesToolbarItem",
             @"OpenSavePreferencesToolbarItem",
             @"AdvancedPreferencesToolbarItem"];
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)willBeInserted
{
    if ([itemIdentifier isEqualToString:@"GeneralPreferencesToolbarItem"]) {
        
		NSImage *generalImage = [NSImage imageNamed:NSImageNamePreferencesGeneral];
		[generalImage setSize:NSMakeSize(32.0, 32.0)];
		return [NSToolbarItem createPreferencesToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedString(@"General", @"General preferences toolbar item Label") image:generalImage action:@selector(changeTabInPreferences:) target:self];
        
		
	} else if ([itemIdentifier isEqualToString:@"AppearancePreferencesToolbarItem"]) {
		
		NSImage *appearanceImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRAAppearanceIcon" ofType:@"pdf" inDirectory:@"Preferences Icons"]];
		[[appearanceImage representations][0] setAlpha:YES];
		return [NSToolbarItem createPreferencesToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedString(@"Appearance", @"Appearance preferences toolbar item Label") image:appearanceImage action:@selector(changeTabInPreferences:) target:self];
        
		
	} else if ([itemIdentifier isEqualToString:@"OpenSavePreferencesToolbarItem"]) {
        
		NSImage *openSaveImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FRAOpenSaveIcon" ofType:@"pdf" inDirectory:@"Preferences Icons"]];
		[[openSaveImage representations][0] setAlpha:YES];
		return [NSToolbarItem createPreferencesToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedString(@"Open & Save", @"OpenSave preferences toolbar item Label") image:openSaveImage action:@selector(changeTabInPreferences:) target:self];
		
		
	} else if ([itemIdentifier isEqualToString:@"AdvancedPreferencesToolbarItem"]) {
        
		NSImage *advancedImage = [NSImage imageNamed:NSImageNameAdvanced];
		[advancedImage setSize:NSMakeSize(32.0, 32.0)];
		return [NSToolbarItem createPreferencesToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedString(@"Advanced", @"Advanced preferences toolbar item Label") image:advancedImage action:@selector(changeTabInPreferences:) target:self];
		
	}
	
	return nil;
}


- (void)changeTabInPreferences:(id)sender
{
	NSString *identifier = [sender itemIdentifier];
	if ([identifier isEqualToString:@"GeneralPreferencesToolbarItem"]) {
		if (generalView == nil) {
			[[NSBundle mainBundle] loadNibNamed:@"FRAPreferencesGeneral" owner:self topLevelObjects:nil];
		}
		if (currentView == generalView) {
			return;
		}
		[[preferencesWindow contentView] addSubview:generalView];
		[FRAInterface changeViewWithAnimationForWindow:preferencesWindow oldView:currentView newView:generalView newRect:[self getRectForView:generalView]];
		[currentView removeFromSuperviewWithoutNeedingDisplay];
		currentView = generalView;
		
	} else if ([identifier isEqualToString:@"AppearancePreferencesToolbarItem"]) {
		if (appearanceView == nil) {
			[[NSBundle mainBundle] loadNibNamed:@"FRAPreferencesAppearance" owner:self topLevelObjects:nil];
		}
		
		NSDate *now = [NSDate date];
		NSMenu *lastSavedFormatMenu = [lastSavedFormatPopUp menu];
		NSInteger index;
		for (index = 0; index < 9; index++) {
			[[lastSavedFormatMenu itemWithTag:index] setTitle:[NSString dateStringForDate:now formatIndex:index]];
		}
		if (currentView == appearanceView) {
			return;
		}
		[[preferencesWindow contentView] addSubview:appearanceView];
		[FRAInterface changeViewWithAnimationForWindow:preferencesWindow oldView:currentView newView:appearanceView newRect:[self getRectForView:appearanceView]];
		[currentView removeFromSuperviewWithoutNeedingDisplay];
		currentView = appearanceView;
		
	} else if ([identifier isEqualToString:@"OpenSavePreferencesToolbarItem"]) {
		if (openSaveView == nil) {
			[[NSBundle mainBundle] loadNibNamed:@"FRAPreferencesOpenSave" owner:self topLevelObjects:nil];
		}
		if (currentView == openSaveView) {
			return;
		}
		[[preferencesWindow contentView] addSubview:openSaveView];
		[FRAInterface changeViewWithAnimationForWindow:preferencesWindow oldView:currentView newView:openSaveView newRect:[self getRectForView:openSaveView]];
		[currentView removeFromSuperviewWithoutNeedingDisplay];
		currentView = openSaveView;
		
	} else if ([identifier isEqualToString:@"AdvancedPreferencesToolbarItem"]) {
		if (advancedView == nil) {
			[[NSBundle mainBundle] loadNibNamed:@"FRAPreferencesAdvanced" owner:self topLevelObjects:nil];
		}
		if (currentView == advancedView) {
			return;
		}
		if (hasPreparedAdvancedInterface == NO) {
			[FRABasic removeAllItemsFromMenu:[encodingsPopUp menu]];
			
			[self buildEncodingsMenu];
			
			// Build syntax definitions menu
			[FRABasic removeAllItemsFromMenu:[syntaxColouringPopUp menu]];
            
			NSEnumerator *enumerator = [[FRABasic fetchAll:@"SyntaxDefinitionSortKeySortOrder"] reverseObjectEnumerator];
			NSMenuItem *menuItem;
			for (id item in enumerator) {
				menuItem = [[NSMenuItem alloc] initWithTitle:[item valueForKey:@"name"] action:nil keyEquivalent:@""];
				[[syntaxColouringPopUp menu] insertItem:menuItem atIndex:0];
			}
			
			// Bind values here rather than in IB because otherwise there is no menu yet
			[encodingsPopUp bind:@"selectedTag" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.EncodingsPopUp" options:nil];
			[syntaxColouringPopUp bind:@"selectedValue" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.SyntaxColouringPopUpString" options:nil];
			
			NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
			[encodingsArrayController setSortDescriptors:@[sortDescriptor]];
			
			sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES];
			[syntaxDefinitionsArrayController setSortDescriptors:@[sortDescriptor]];
			
			hasPreparedAdvancedInterface = YES;
		}
		
		[[preferencesWindow contentView] addSubview:advancedView];
		[FRAInterface changeViewWithAnimationForWindow:preferencesWindow oldView:currentView newView:advancedView newRect:[self getRectForView:advancedView]];
		[currentView removeFromSuperviewWithoutNeedingDisplay];
		currentView = advancedView;
	}
    
	[preferencesToolbar setSelectedItemIdentifier:identifier]; // Needed to make the selection "stick" in the toolbar
	NSRect generalViewFrame = [self getRectForView:generalView];
	[FRADefaults setValue:NSStringFromRect(NSMakeRect(generalViewFrame.origin.x, generalViewFrame.origin.y, (generalViewFrame.size.width), (generalViewFrame.size.height))) forKey:@"PreferencesGeneralViewSavedFrame"]; // It sometimes get the frame wrong after it has been resized so save a version to be used when displayed the next time
    
}


- (NSRect)getRectForView:(NSView *)view
{
	NSPoint windowOrigin = [preferencesWindow frame].origin;
	NSSize windowSize = [preferencesWindow frame].size;
	NSSize viewSize = [view bounds].size;
	CGFloat newY = windowOrigin.y + (windowSize.height - viewSize.height - [self toolbarHeight]);
	
	NSRect rectWithoutTitleBar = NSMakeRect(windowOrigin.x, newY, viewSize.width, viewSize.height);
	NSRect rectWithTitleBar = [NSWindow frameRectForContentRect:rectWithoutTitleBar styleMask:NSWindowStyleMaskTitled];
	
	CGFloat titleBarHeight = rectWithTitleBar.size.height - rectWithoutTitleBar.size.height;
	
	return NSMakeRect(windowOrigin.x, newY - titleBarHeight, viewSize.width, (viewSize.height + [self toolbarHeight] + titleBarHeight));
}


- (CGFloat)toolbarHeight
{
	CGFloat toolbarHeight = 0.0;
	NSRect windowFrame;
	
	if (preferencesToolbar && [preferencesToolbar isVisible]) {
		windowFrame = [NSWindow contentRectForFrameRect:[preferencesWindow frame] styleMask:[preferencesWindow styleMask]];
		toolbarHeight = NSHeight(windowFrame) - NSHeight([[preferencesWindow contentView] frame]);
	}
	
	return toolbarHeight;
}


- (IBAction)setFontAction:(id)sender
{
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	[fontManager setSelectedFont:[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]] isMultiple:NO];
	[fontManager orderFrontFontPanel:nil];
}


- (void)changeFont:(id)sender
{
    NSFont *oldFont = [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]];
    NSFont *panelFont = [sender convertFont:oldFont];
	[FRADefaults setValue:[NSArchiver archivedDataWithRootObject:panelFont] forKey:@"TextFont"];
}


- (IBAction)revertToStandardSettingsAction:(id)sender
{
	[[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValues:nil];
	[FRADefaults setValue:nil forKey:@"ChangedSyntaxDefinitions"];
	[FRADefaults setValue:@YES forKey:@"HasImportedFromVersion2"];
	[FRABasic removeAllObjectsForEntity:@"SyntaxDefinition"];
	[FRAVarious insertSyntaxDefinitions];
}


- (void)buildEncodingsMenu
{
	[FRABasic removeAllItemsFromMenu:[encodingsPopUp menu]];
	
	NSEnumerator *enumerator = [[FRABasic fetchAll:@"EncodingSortKeyName"] reverseObjectEnumerator];
	NSMenuItem *menuItem;
	for (id item in enumerator) {
		if ([[item valueForKey:@"active"] boolValue] == YES) {
			NSUInteger encoding = [[item valueForKey:@"encoding"] unsignedIntegerValue];
			menuItem = [[NSMenuItem alloc] initWithTitle:[NSString localizedNameOfStringEncoding:encoding] action:nil keyEquivalent:@""];
			[menuItem setTag:encoding];
			[menuItem setTarget:self];
			[[encodingsPopUp menu] insertItem:menuItem atIndex:0];
		}
	}
}


- (IBAction)openSetFolderAction:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
    [openPanel setDirectoryURL: [NSURL fileURLWithPath: NSHomeDirectory()]];
    [openPanel beginSheetModalForWindow: preferencesWindow
                      completionHandler: (^(NSInteger result)
                                          {
                                              if (result == NSModalResponseOK)
                                              {
                                                  [FRADefaults setValue: [[[openPanel URL] path] stringByAbbreviatingWithTildeInPath]
                                                                 forKey: @"OpenAlwaysUseTextField"];
                                              }
                                          })];
}

- (IBAction)saveAsSetFolderAction:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
    [openPanel setDirectoryURL: [NSURL fileURLWithPath: NSHomeDirectory()]];
    [openPanel beginSheetModalForWindow: preferencesWindow
                      completionHandler: (^(NSInteger result)
                                          {
                                              if (result == NSModalResponseOK)
                                              {
                                                  [FRADefaults setValue:[[[openPanel URL] path] stringByAbbreviatingWithTildeInPath]
                                                                 forKey: @"SaveAsAlwaysUseTextField"];
                                              }
                                          })];
}

- (IBAction)changeGutterWidth:(id)sender {
	NSEnumerator *documentEnumerator =  [[[FRACurrentProject documentsArrayController] arrangedObjects] objectEnumerator];
	for (id document in documentEnumerator) {
		[FRAInterface updateGutterViewForDocument:document];
		[[document valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth:YES recolour:YES];
	}
}

- (NSManagedObjectContext *)managedObjectContext
{
	return FRAManagedObjectContext;
}

@end
