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

#import "SMLPreferencesController.h"
#import "NSString+Smultron.h"
#import "SMLBasicPerformer.h"
#import "SMLVariousPerformer.h"
#import "SMLProjectsController.h"
#import "SMLInterfacePerformer.h"
#import "SMLCommandsController.h"
#import "SMLSnippetsController.h"
#import "SMLAdvancedFindController.h"
#import "SMLMainController.h"
#import "SMLApplicationDelegate.h"
#import "SMLProject.h"
#import "NSToolbarItem+Smultron.h"

@implementation SMLPreferencesController

@synthesize encodingsArrayController, syntaxDefinitionsArrayController, encodingsPopUp, preferencesWindow;


static id sharedInstance = nil;

+ (SMLPreferencesController *)sharedInstance
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

	[dictionary setValue:[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.97 alpha:1.0]] forKey:@"CommandsColourWell"];
	[dictionary setValue:[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.0 green:0.69 blue:0.001 alpha:1.0]] forKey:@"CommentsColourWell"];
	[dictionary setValue:[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.45 green:0.45 blue:0.45 alpha:1.0]] forKey:@"InstructionsColourWell"];
	[dictionary setValue:[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.84 green:0.41 blue:0.006 alpha:1.0]] forKey:@"KeywordsColourWell"];
	[dictionary setValue:[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.84 green:0.41 blue:0.006 alpha:1.0]] forKey:@"AutocompleteColourWell"];
	[dictionary setValue:[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.73 green:0.0 blue:0.74 alpha:1.0]] forKey:@"VariablesColourWell"];
	[dictionary setValue:[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.95 green:0.0 blue:0.0 alpha:1.0]] forKey:@"StringsColourWell"];
	[dictionary setValue:[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.50 green:0.5 blue:0.2 alpha:1.0]] forKey:@"AttributesColourWell"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"ColourCommands"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"ColourComments"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"ColourInstructions"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"ColourKeywords"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"ColourAutocomplete"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"ColourVariables"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"ColourStrings"];	
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"ColourAttributes"];	
	
	[dictionary setValue:[NSArchiver archivedDataWithRootObject:[NSColor whiteColor]] forKey:@"BackgroundColourWell"];
	[dictionary setValue:[NSArchiver archivedDataWithRootObject:[NSColor blackColor]] forKey:@"TextColourWell"];
	[dictionary setValue:[NSArchiver archivedDataWithRootObject:[NSColor blackColor]] forKey:@"InvisibleCharactersColourWell"];
	[dictionary setValue:[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.96 green:0.96 blue:0.71 alpha:1.0]] forKey:@"HighlightLineColourWell"];
	
	[dictionary setValue:[NSNumber numberWithInteger:0] forKey:@"EncodingsMatrix"];
	[dictionary setValue:[NSNumber numberWithInteger:SMLOpenSaveRemember] forKey:@"OpenMatrix"];
	[dictionary setValue:[NSNumber numberWithInteger:SMLOpenSaveAlways] forKey:@"SaveMatrix"];
	[dictionary setValue:[NSNumber numberWithInteger:NSUTF8StringEncoding] forKey:@"EncodingsPopUp"];
	[dictionary setValue:[NSNumber numberWithInteger:0] forKey:@"SizeOfDocumentsListTextPopUp"];
	[dictionary setValue:[NSNumber numberWithInteger:5] forKey:@"LineEndingsPopUp"];
	[dictionary setValue:[NSNumber numberWithInteger:0] forKey:@"SyntaxColouringMatrix"];
	[dictionary setValue:[NSNumber numberWithInteger:12] forKey:@"NSRecentDocumentsLimit"];
	[dictionary setValue:[NSNumber numberWithInteger:40] forKey:@"GutterWidth"];
	[dictionary setValue:[NSNumber numberWithInteger:4] forKey:@"TabWidth"];
	[dictionary setValue:[NSNumber numberWithInteger:4] forKey:@"IndentWidth"];
	[dictionary setValue:[NSNumber numberWithInteger:80] forKey:@"ShowPageGuideAtColumn"];
	[dictionary setValue:[NSNumber numberWithInteger:5] forKey:@"StatusBarLastSavedFormatPopUp"];
	[dictionary setValue:[NSNumber numberWithInteger:32] forKey:@"ViewSize"];
	[dictionary setValue:[NSNumber numberWithInteger:SMLListView] forKey:@"View"];
	[dictionary setValue:[NSNumber numberWithInteger:SMLPreviewHTML] forKey:@"PreviewParser"];
	[dictionary setValue:[NSNumber numberWithInteger:SMLCurrentDocumentScope] forKey:@"AdvancedFindScope"];
	
	[dictionary setValue:[NSNumber numberWithDouble:0.5] forKey:@"AutocompleteAfterDelay"];	
	
	[dictionary setValue:[NSArchiver archivedDataWithRootObject:[NSFont fontWithName:@"Menlo" size:11]] forKey:@"TextFont"];
	[dictionary setValue:[[NSString localizedStringWithFormat:@"%@/%@", NSHomeDirectory(), @"Desktop"] stringByAbbreviatingWithTildeInPath] forKey:@"OpenAlwaysUseTextField"];
	[dictionary setValue:[[NSString localizedStringWithFormat:@"%@/%@", NSHomeDirectory(), @"Desktop"] stringByAbbreviatingWithTildeInPath] forKey:@"SaveAsAlwaysUseTextField"];
	
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"NewDocumentAtStartup"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"ShowFullPathInWindowTitle"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"ShowLineNumberGutter"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"SyntaxColourNewDocuments"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"LineWrapNewDocuments"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"AssignDocumentToSmultronWhenSaving"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"IndentNewLinesAutomatically"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"OnlyColourTillTheEndOfLine"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"CheckIfDocumentHasBeenUpdated"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"ShowMatchingBraces"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"StatusBarShowEncoding"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"StatusBarShowLength"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"StatusBarShowSelection"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"StatusBarShowPosition"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"StatusBarShowSyntax"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"StatusBarShowWhenLastSaved"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"ShowInvisibleCharacters"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"IndentWithSpaces"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"OpenAllFilesWithinAFolder"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"OpenAllDocumentsIHadOpen"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"OpenAllProjectsIHadOpen"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"ColourMultiLineStrings"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"AutocompleteSuggestAutomatically"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"AutocompleteIncludeStandardWords"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"AutoSpellCheck"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"AutoGrammarCheck"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"KeepRunningAfterMainWindowIsClosed"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"SmartInsertDelete"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"AutomaticLinkDetection"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"AutomaticQuoteSubstitution"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"UseTabStops"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"HighlightCurrentLine"];
	
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"OpenAllFilesInAFolderRecursively"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"FilterOutExtensions"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"UseRGBRatherThanHexWhenInsertingColourValues"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"ShowFullPathInDocumentsList"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"AutomaticallyIndentBraces"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"AppendNameInSaveAs"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"AutoInsertAClosingParenthesis"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"AutoInsertAClosingBrace"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"OpenAllDocumentsIHadOpen"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"OpenAllProjectsIHadOpen"];
	
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"IgnoreCaseAdvancedFind"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"UseRegularExpressionsAdvancedFind"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"OnlyInSelectionAdvancedFind"];
	
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"PrintHeader"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"PrintSyntaxColours"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"OnlyPrintSelection"];
	
	[dictionary setValue:@"jpg gif png swf" forKey:@"FilterOutExtensionsString"];
	[dictionary setValue:@"/bin/sh" forKey:@"RunText"];
	[dictionary setValue:@".txt" forKey:@"AppendNameInSaveAsWith"];
	[dictionary setValue:@"Standard" forKey:@"SyntaxColouringPopUpString"];
	
	[dictionary setValue:[NSNumber numberWithInteger:24] forKey:@"MarginsMin"];
	[dictionary setValue:[NSArchiver archivedDataWithRootObject:[NSFont fontWithName:@"Courier" size:10]] forKey:@"PrintFont"];
	
	NSArray *activeEncodings = [[NSArray alloc] initWithObjects:[NSNumber numberWithUnsignedInteger:NSASCIIStringEncoding], [NSNumber numberWithUnsignedInteger:NSJapaneseEUCStringEncoding], [NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding], [NSNumber numberWithUnsignedInteger:NSISOLatin1StringEncoding], [NSNumber numberWithUnsignedInteger:NSSymbolStringEncoding], [NSNumber numberWithUnsignedInteger:NSNonLossyASCIIStringEncoding], [NSNumber numberWithUnsignedInteger:NSShiftJISStringEncoding], [NSNumber numberWithUnsignedInteger:NSISOLatin2StringEncoding], [NSNumber numberWithUnsignedInteger:NSUnicodeStringEncoding], [NSNumber numberWithUnsignedInteger:NSWindowsCP1251StringEncoding], [NSNumber numberWithUnsignedInteger:NSWindowsCP1252StringEncoding], [NSNumber numberWithUnsignedInteger:NSWindowsCP1253StringEncoding], [NSNumber numberWithUnsignedInteger:NSWindowsCP1254StringEncoding], [NSNumber numberWithUnsignedInteger:NSWindowsCP1250StringEncoding], [NSNumber numberWithUnsignedInteger:NSISO2022JPStringEncoding], [NSNumber numberWithUnsignedInteger:NSMacOSRomanStringEncoding], nil];
	
	
	[dictionary setValue:activeEncodings forKey:@"ActiveEncodings"];
	
	// Users can't set these in Preferences
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"ShowStatusBar"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"ShowTabBar"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"HasInsertedDefaultSnippets"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"HasImportedFromVersion2"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"HasInsertedDefaultCommands3"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"UserHasBeenShownAlertHowToReturnFromFullScreen"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"UpdateDocumentAutomaticallyWithoutWarning"];
	[dictionary setValue:[NSNumber numberWithInteger:4] forKey:@"SpacesPerTabEntabDetab"];
	[dictionary setValue:[NSNumber numberWithInteger:15] forKey:@"TimeBetweenDocumentUpdateChecks"];
	[dictionary setValue:@"yyyy-MM-dd HH:mm 'w:'w 'd:'D" forKey:@"UserDateFormat"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"AlwaysEndFileWithLineFeed"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"SuppressReplaceWarning"];
	[dictionary setValue:[NSNumber numberWithInteger:SMLVirtualProject] forKey:@"WhatKindOfProject"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"LiveUpdatePreview"];
	[dictionary setValue:[NSNumber numberWithDouble:1.0] forKey:@"LiveUpdatePreviewDelay"];
	[dictionary setValue:[NSNumber numberWithDouble:0.2] forKey:@"DividerPosition"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"ShowSizeSlider"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"PutQuotesAroundDirectory"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"FocusOnTextInAdvancedFind"];
	[dictionary setValue:[NSNumber numberWithBool:NO] forKey:@"KeepEmptyWindowOpen"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"UseQuickLookIcon"];
	[dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"UpdateIconForEverySave"];
	
	[dictionary setValue:@"" forKey:@"BaseURL"];
	
	NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	[defaultsController setInitialValues:dictionary];
	
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
	if ([(NSString *)context isEqualToString:@"StatusBarChanged"]) {
		[SMLInterface updateStatusBar];
		
	} else if ([(NSString *)context isEqualToString:@"StatusBarLastSavedFormatChanged"]) {
		NSArray *array = [SMLBasic fetchAll:@"Document"];
		for (id item in array) {
			if ([[item valueForKey:@"isNewDocument"] boolValue] == NO) {
				[SMLVarious setLastSavedDateForDocument:item date:[[item valueForKey:@"fileAttributes"] fileModificationDate]];
			}
		}		
		[SMLInterface updateStatusBar];
		
	} else if ([(NSString *)context isEqualToString:@"ShowFullPathInWindowTitleChanged"]) {
		NSArray *projectsArray = [[SMLProjectsController sharedDocumentController] documents];
		for (id project in projectsArray) {
			NSArray *documentsArray = [SMLBasic fetchAll:@"Document"];
			for (id document in documentsArray) {
				[project updateWindowTitleBarForDocument:document];
			}
		}
		
	} else if ([(NSString *)context isEqualToString:@"SizeOfDocumentsListTextPopUpChanged"]) {
		NSArray *array = [[SMLProjectsController sharedDocumentController] documents];
		for (id item in array) {
			[item reloadData];
		}
		[syntaxDefinitionsTableView reloadData];
		[encodingsTableView reloadData];
		
		if ([[SMLCommandsController sharedInstance] commandsWindow] != nil) {
			[[[SMLCommandsController sharedInstance] commandCollectionsTableView] reloadData];
			[[[SMLCommandsController sharedInstance] commandsTableView] reloadData];
		}
		
		if ([[SMLSnippetsController sharedInstance] snippetsWindow] != nil) {
			[[[SMLSnippetsController sharedInstance] snippetCollectionsTableView] reloadData];
			[[[SMLSnippetsController sharedInstance] snippetsTableView] reloadData];
		}
		if ([[SMLAdvancedFindController sharedInstance] advancedFindWindow] != nil) {
			[[[SMLAdvancedFindController sharedInstance] findResultsOutlineView] reloadData];
		}	
		
	} else if ([(NSString *)context isEqualToString:@"CheckIfDocumentHasBeenUpdatedChanged"]) {
		[SMLVarious updateCheckIfAnotherApplicationHasChangedDocumentsTimer];
		
	} else if ([(NSString *)context isEqualToString:@"DocumentsListPathSettingsChanged"]) {
		NSArray *array = [[SMLProjectsController sharedDocumentController] documents];
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
		[NSBundle loadNibNamed:@"SMLPreferences.nib" owner:self];
		[preferencesWindow setShowsToolbarButton:NO];
		
		preferencesToolbar = [[NSToolbar alloc] initWithIdentifier:@"PreferencesToolbarIdentifier"];
		[preferencesToolbar setAllowsUserCustomization:NO];
		[preferencesToolbar setAutosavesConfiguration:NO];
		[preferencesToolbar setShowsBaselineSeparator:YES];
		[preferencesToolbar setDelegate:self];
		[preferencesWindow setToolbar:preferencesToolbar];
		
		
		[preferencesWindow setTitle:NSLocalizedStringFromTable(@"Preferences - Smultron", @"Localizable3", @"Preferences - Smultron")];
	}
	
	if ([preferencesToolbar selectedItemIdentifier] == nil) {
		if (generalView == nil) {
			[NSBundle loadNibNamed:@"SMLPreferencesGeneral.nib" owner:self];
		}
		[preferencesToolbar setSelectedItemIdentifier:@"GeneralPreferencesToolbarItem"];
		if ([SMLDefaults valueForKey:@"PreferencesGeneralViewSavedFrame"] == nil) {
			[preferencesWindow setFrame:[self getRectForView:generalView] display:YES animate:NO];
		} else { // It sometimes get the frame wrong after it has been resized so use the own saved version
			NSRect temporaryRect = NSRectFromString([SMLDefaults valueForKey:@"PreferencesGeneralViewSavedFrame"]);
			[preferencesWindow setFrame:NSMakeRect(temporaryRect.origin.x, temporaryRect.origin.y, temporaryRect.size.width * [preferencesWindow userSpaceScaleFactor], temporaryRect.size.height * [preferencesWindow userSpaceScaleFactor]) display:YES animate:NO];
		}
		[[preferencesWindow contentView] addSubview:generalView];
		currentView = generalView;
		
		[preferencesWindow setDelegate:self]; // So that it catches the changeFont action
	}
	
	[preferencesWindow makeKeyAndOrderFront:self];
}


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:@"GeneralPreferencesToolbarItem",
		@"AppearancePreferencesToolbarItem",
		@"SyntaxColoursPreferencesToolbarItem",
		@"SyntaxDefinitionsPreferencesToolbarItem",
		@"OpenSavePreferencesToolbarItem",
		@"AdvancedPreferencesToolbarItem",
		nil];
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar  
{      
    return [NSArray arrayWithObjects:@"GeneralPreferencesToolbarItem",
		@"AppearancePreferencesToolbarItem",
		@"SyntaxColoursPreferencesToolbarItem",
		@"SyntaxDefinitionsPreferencesToolbarItem",
		@"OpenSavePreferencesToolbarItem",
		@"AdvancedPreferencesToolbarItem",
		nil];

} 


- (NSArray *)toolbarSelectableItemIdentifiers: (NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:@"GeneralPreferencesToolbarItem",
		@"AppearancePreferencesToolbarItem",
		@"SyntaxColoursPreferencesToolbarItem",
		@"SyntaxDefinitionsPreferencesToolbarItem",
		@"OpenSavePreferencesToolbarItem",
		@"AdvancedPreferencesToolbarItem",
		nil];	
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)willBeInserted
{
    if ([itemIdentifier isEqualToString:@"GeneralPreferencesToolbarItem"]) {
        
		NSImage *generalImage = [NSImage imageNamed:NSImageNamePreferencesGeneral];
		[generalImage setSize:NSMakeSize(32.0, 32.0)];
		return [NSToolbarItem createPreferencesToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedString(@"General", @"General preferences toolbar item Label") image:generalImage action:@selector(changeTabInPreferences:) target:self];
	
		
	} else if ([itemIdentifier isEqualToString:@"AppearancePreferencesToolbarItem"]) {
		
		NSImage *appearanceImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SMLAppearanceIcon" ofType:@"pdf" inDirectory:@"Preferences Icons"]];
		[[[appearanceImage representations] objectAtIndex:0] setAlpha:YES];
		return [NSToolbarItem createPreferencesToolbarItemWithIdentifier:itemIdentifier name:NSLocalizedString(@"Appearance", @"Appearance preferences toolbar item Label") image:appearanceImage action:@selector(changeTabInPreferences:) target:self];
	
		
	} else if ([itemIdentifier isEqualToString:@"OpenSavePreferencesToolbarItem"]) {
        
		NSImage *openSaveImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SMLOpenSaveIcon" ofType:@"pdf" inDirectory:@"Preferences Icons"]];
		[[[openSaveImage representations] objectAtIndex:0] setAlpha:YES];
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
			[NSBundle loadNibNamed:@"SMLPreferencesGeneral.nib" owner:self];
		}
		if (currentView == generalView) {
			return;
		}
		[[preferencesWindow contentView] addSubview:generalView];
		[SMLInterface changeViewWithAnimationForWindow:preferencesWindow oldView:currentView newView:generalView newRect:[self getRectForView:generalView]];
		[currentView removeFromSuperviewWithoutNeedingDisplay];
		currentView = generalView;
		
	} else if ([identifier isEqualToString:@"AppearancePreferencesToolbarItem"]) {
		if (appearanceView == nil) {
			[NSBundle loadNibNamed:@"SMLPreferencesAppearance.nib" owner:self];			
		}
		
		NSCalendarDate *now = [NSCalendarDate calendarDate];
		NSMenu *lastSavedFormatMenu = [lastSavedFormatPopUp menu];
		NSInteger index;
		for (index = 0; index < 9; index++) {
			[[lastSavedFormatMenu itemWithTag:index] setTitle:[NSString dateStringForDate:now formatIndex:index]];
		}
		if (currentView == appearanceView) {
			return;
		}
		[[preferencesWindow contentView] addSubview:appearanceView];
		[SMLInterface changeViewWithAnimationForWindow:preferencesWindow oldView:currentView newView:appearanceView newRect:[self getRectForView:appearanceView]];
		[currentView removeFromSuperviewWithoutNeedingDisplay];
		currentView = appearanceView;
		
	} else if ([identifier isEqualToString:@"OpenSavePreferencesToolbarItem"]) {
		if (openSaveView == nil) {
			[NSBundle loadNibNamed:@"SMLPreferencesOpenSave.nib" owner:self];
		}
		if (currentView == openSaveView) {
			return;
		}
		[[preferencesWindow contentView] addSubview:openSaveView];
		[SMLInterface changeViewWithAnimationForWindow:preferencesWindow oldView:currentView newView:openSaveView newRect:[self getRectForView:openSaveView]];
		[currentView removeFromSuperviewWithoutNeedingDisplay];
		currentView = openSaveView;
		
	} else if ([identifier isEqualToString:@"AdvancedPreferencesToolbarItem"]) {
		if (advancedView == nil) {
			[NSBundle loadNibNamed:@"SMLPreferencesAdvanced.nib" owner:self];
		}
		if (currentView == advancedView) {
			return;
		}
		if (hasPreparedAdvancedInterface == NO) {
			[SMLBasic removeAllItemsFromMenu:[encodingsPopUp menu]];
			
			[self buildEncodingsMenu];
			
			// Build syntax definitions menu		
			[SMLBasic removeAllItemsFromMenu:[syntaxColouringPopUp menu]];

			NSEnumerator *enumerator = [[SMLBasic fetchAll:@"SyntaxDefinitionSortKeySortOrder"] reverseObjectEnumerator];
			NSMenuItem *menuItem;
			for (id item in enumerator) {
				menuItem = [[NSMenuItem alloc] initWithTitle:[item valueForKey:@"name"] action:nil keyEquivalent:@""];
				[[syntaxColouringPopUp menu] insertItem:menuItem atIndex:0];
			}
			
			// Bind values here rather than in IB because otherwise there is no menu yet
			[encodingsPopUp bind:@"selectedTag" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.EncodingsPopUp" options:nil];
			[syntaxColouringPopUp bind:@"selectedValue" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.SyntaxColouringPopUpString" options:nil];
			
			NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
			[encodingsArrayController setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
			
			sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES];
			[syntaxDefinitionsArrayController setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
			
			hasPreparedAdvancedInterface = YES;
		}
		
		[[preferencesWindow contentView] addSubview:advancedView];
		[SMLInterface changeViewWithAnimationForWindow:preferencesWindow oldView:currentView newView:advancedView newRect:[self getRectForView:advancedView]];
		[currentView removeFromSuperviewWithoutNeedingDisplay];
		currentView = advancedView;
	}

	[preferencesToolbar setSelectedItemIdentifier:identifier]; // Needed to make the selection "stick" in the toolbar
	NSRect generalViewFrame = [self getRectForView:generalView];
	[SMLDefaults setValue:NSStringFromRect(NSMakeRect(generalViewFrame.origin.x, generalViewFrame.origin.y, (generalViewFrame.size.width / [preferencesWindow userSpaceScaleFactor]), (generalViewFrame.size.height / [preferencesWindow userSpaceScaleFactor]))) forKey:@"PreferencesGeneralViewSavedFrame"]; // It sometimes get the frame wrong after it has been resized so save a version to be used when displayed the next time

}


- (NSRect)getRectForView:(NSView *)view
{
	NSPoint windowOrigin = [preferencesWindow frame].origin;
	NSSize windowSize = [preferencesWindow frame].size;
	NSSize viewSize = [view bounds].size;
	CGFloat newY = windowOrigin.y + (windowSize.height - viewSize.height - [self toolbarHeight]);
	
	NSRect rectWithoutTitleBar = NSMakeRect(windowOrigin.x, newY, viewSize.width, viewSize.height);
	NSRect rectWithTitleBar = [NSWindow frameRectForContentRect:rectWithoutTitleBar styleMask:NSTitledWindowMask];
	
	CGFloat titleBarHeight = rectWithTitleBar.size.height - rectWithoutTitleBar.size.height;
	
	return NSMakeRect(windowOrigin.x, newY - titleBarHeight, viewSize.width * [preferencesWindow userSpaceScaleFactor], (viewSize.height + [self toolbarHeight] + titleBarHeight));
}


- (CGFloat)toolbarHeight
{
	CGFloat toolbarHeight = 0.0;
	NSRect windowFrame;
	
	if (preferencesToolbar && [preferencesToolbar isVisible]) {
		windowFrame = [NSWindow contentRectForFrameRect:[preferencesWindow frame] styleMask:[preferencesWindow styleMask]];
		toolbarHeight = NSHeight(windowFrame) - NSHeight([[preferencesWindow contentView] frame]);
	}
	
	return toolbarHeight * [[NSScreen mainScreen] userSpaceScaleFactor];
}


- (IBAction)setFontAction:(id)sender
{
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	[fontManager setSelectedFont:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:@"TextFont"]] isMultiple:NO];
	[fontManager orderFrontFontPanel:nil];
}


- (void)changeFont:(id)sender
{
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSFont *panelFont = [fontManager convertFont:[fontManager selectedFont]];
	[SMLDefaults setValue:[NSArchiver archivedDataWithRootObject:panelFont] forKey:@"TextFont"];
}


- (IBAction)revertToStandardSettingsAction:(id)sender
{
	[[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValues:nil];
	[SMLDefaults setValue:nil forKey:@"ChangedSyntaxDefinitions"];
	[SMLDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"HasImportedFromVersion2"];
	[SMLBasic removeAllObjectsForEntity:@"SyntaxDefinition"];
	[SMLVarious insertSyntaxDefinitions];
}


- (void)buildEncodingsMenu
{
	[SMLBasic removeAllItemsFromMenu:[encodingsPopUp menu]];
	
	NSEnumerator *enumerator = [[SMLBasic fetchAll:@"EncodingSortKeyName"] reverseObjectEnumerator];
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
	[openPanel beginSheetForDirectory:NSHomeDirectory()
								 file:nil
								types:nil
					   modalForWindow:preferencesWindow
						modalDelegate:self
					   didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
}


- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton) {						
		[SMLDefaults setValue:[[sheet filename] stringByAbbreviatingWithTildeInPath] forKey:@"OpenAlwaysUseTextField"];
	}
}


- (IBAction)saveAsSetFolderAction:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel beginSheetForDirectory:NSHomeDirectory()
								 file:nil
								types:nil
					   modalForWindow:preferencesWindow
						modalDelegate:self
					   didEndSelector:@selector(saveAsPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
}


- (void)saveAsPanelDidEnd:(NSOpenPanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton) {						
		[SMLDefaults setValue:[[sheet filename] stringByAbbreviatingWithTildeInPath] forKey:@"SaveAsAlwaysUseTextField"];
	}
}


- (NSManagedObjectContext *)managedObjectContext
{
	return SMLManagedObjectContext;
}

@end
