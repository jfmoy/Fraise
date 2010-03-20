/*
Fraise version 3.7 - Based on Smultron by Peter Borg
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Fraise

Copyright 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/


#import <Cocoa/Cocoa.h>

@class FRATextView;
@class FRAProjectManagedObject;
@class FRADocumentManagedObject;
@class FRATableViewDelegate;
@class FRASplitViewDelegate;
@class PSMTabBarControl;

@interface FRAProject : NSDocument <NSTableViewDelegate,NSSplitViewDelegate,NSWindowDelegate,NSToolbarDelegate,NSMenuDelegate>
{
	NSManagedObject *project;
	
	IBOutlet NSTextField *statusBarTextField;
	
	IBOutlet NSView *firstContentView;
	IBOutlet NSView *secondContentView;

	IBOutlet NSView *secondContentViewNavigationBar;
	IBOutlet NSPopUpButton *secondContentViewPopUpButton;
	
	IBOutlet NSSplitView *mainSplitView;
	IBOutlet NSSplitView *contentSplitView;
	
	IBOutlet NSView *leftDocumentsView;
	
	IBOutlet PSMTabBarControl *tabBarControl;
	IBOutlet NSTabView *tabBarTabView;
	
	FRATextView *lastTextViewInFocus;
	
	FRADocumentManagedObject *firstDocument;
	FRADocumentManagedObject *secondDocument;
	
	BOOL shouldWindowClose;
	
	// FRAToolbarController category
	NSToolbarItem *liveFindToolbarItem;
	NSToolbarItem *functionToolbarItem;
	NSToolbarItem *saveToolbarItem;
	NSToolbarItem *advancedFindToolbarItem;
	NSToolbarItem *closeToolbarItem;
	NSToolbarItem *infoToolbarItem;
	NSToolbarItem *previewToolbarItem;
	
	IBOutlet NSSearchField *liveFindSearchField;
	IBOutlet NSButton *functionButton;
	IBOutlet NSPopUpButton *functionPopUpButton;
	
	NSTimer *liveFindSessionTimer;
	NSInteger originalPosition;
	
	NSMenuItem *menuFormRepresentation;
	
	//NSImage *splitWindowImage, *closeSplitImage, *lineWrapImage, *dontLineWrapImage, *saveImage, *openDocumentImage, *newImage, *closeImage, *preferencesImage, *advancedFindImage, *previewImage, *functionImage, *infoImage;
	NSImage *saveImage, *openDocumentImage, *newImage, *closeImage, *advancedFindImage, *previewImage, *functionImage, *infoImage;
	
	// FRADocumentViewsControllerCategory
	IBOutlet NSView *viewSelectionView;
	IBOutlet NSSlider *viewSelectionSizeSlider;
	
	IBOutlet NSView *leftDocumentsTableView;
	IBOutlet NSTableView *documentsTableView;
	IBOutlet NSArrayController *documentsArrayController;
	
}

@property (assign) FRATextView *lastTextViewInFocus;

@property (assign) FRADocumentManagedObject *firstDocument;
@property (assign) FRADocumentManagedObject *secondDocument;

@property (readonly) IBOutlet NSManagedObject *project;
@property (readonly) IBOutlet NSArrayController *documentsArrayController;
@property (readonly) IBOutlet NSTableView *documentsTableView;
@property (readonly) IBOutlet NSView *firstContentView;
@property (readonly) IBOutlet NSView *secondContentView;
@property (readonly) IBOutlet NSTextField *statusBarTextField;

@property (readonly) IBOutlet NSSplitView *mainSplitView;
@property (readonly) IBOutlet NSSplitView *contentSplitView;

@property (readonly) IBOutlet NSView *secondContentViewNavigationBar;
@property (readonly) IBOutlet NSPopUpButton *secondContentViewPopUpButton;

@property (readonly) IBOutlet NSView *leftDocumentsView;
@property (readonly) IBOutlet NSView *leftDocumentsTableView;

@property (readonly) IBOutlet PSMTabBarControl *tabBarControl;
@property (readonly) IBOutlet NSTabView *tabBarTabView;


- (void)setDefaultAppearanceAtStartup;

- (void)selectDocument:(id)document;
- (BOOL)areThereAnyDocuments;
- (void)resizeViewsForDocument:(id)document;
- (void)setLastTextViewInFocus:(FRATextView *)newLastTextViewInFocus;
- (id)createNewDocumentWithContents:(NSString *)textString;
- (id)createNewDocumentWithPath:(NSString *)path andContents:(NSString *)textString;

- (void)updateEditedBlobStatus;
- (void)updateWindowTitleBarForDocument:(id)document;
- (void)checkIfDocumentIsUnsaved:(id)document keepOpen:(BOOL)keepOpen;
- (void)performCloseDocument:(id)document;
- (void)cleanUpDocument:(id)document;


- (NSMutableSet *)documents;

- (NSManagedObjectContext *)managedObjectContext;

- (NSDictionary *)dictionaryOfDocumentsInProject;

- (void)autosave;

- (NSString *)name;

- (void)selectionDidChange;

- (NSWindow *)window;

- (NSToolbar *)projectWindowToolbar;

- (BOOL)areAllDocumentsSaved;

- (void)documentsListHasUpdated;
- (void)buildSecondContentViewNavigationBarMenu;

- (CGFloat)mainSplitViewFraction;
- (void)resizeMainSplitView;
- (void)saveMainSplitViewFraction;

- (void)insertDefaultIconsInDocument:(id)document;


@end


