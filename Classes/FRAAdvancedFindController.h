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


@interface FRAAdvancedFindController : NSObject <NSOutlineViewDelegate>
{
    IBOutlet NSWindow *__unsafe_unretained advancedFindWindow;
    IBOutlet NSSearchField *findSearchField;
    IBOutlet NSSearchField *replaceSearchField;
    IBOutlet NSTextField *findResultTextField;
    IBOutlet NSOutlineView *__unsafe_unretained findResultsOutlineView;
	IBOutlet NSView *resultDocumentContentView;
	IBOutlet NSTreeController *findResultsTreeController;
	
	IBOutlet NSSplitView *advancedFindSplitView;
	
	IBOutlet NSButton *currentDocumentScope;
	IBOutlet NSButton *currentProjectScope;
	IBOutlet NSButton *allDocumentsScope;
	IBOutlet NSButton *parentDirectoryScope;
}

@property (unsafe_unretained) id currentlyDisplayedDocumentInAdvancedFind;
@property (unsafe_unretained, readonly) IBOutlet NSWindow *advancedFindWindow;
@property (unsafe_unretained, readonly) IBOutlet NSOutlineView *findResultsOutlineView;

+ (FRAAdvancedFindController *)sharedInstance;

- (IBAction)findAction:(id)sender;
- (IBAction)replaceAction:(id)sender;

- (void)performNumberOfReplaces:(NSInteger)numberOfReplaces;

- (void)showAdvancedFindWindow;

- (NSEnumerator *)scopeEnumerator;

- (void)removeCurrentlyDisplayedDocumentInAdvancedFind;

- (NSView *)resultDocumentContentView;

- (NSManagedObjectContext *)managedObjectContext;

- (NSMutableDictionary *)preparedResultDictionaryFromString:(NSString *)completeString searchStringLength:(NSInteger)searchStringLength range:(NSRange)foundRange lineNumber:(NSInteger)lineNumber document:(id)document;

- (void)alertThatThisIsNotAValidRegularExpression:(NSString *)string;

- (void)searchScopeChanged:(id)sender;

- (NSEnumerator *)documentsInFolderEnumerator;

- (IBAction)showRegularExpressionsHelpPanelAction:(id)sender;

@end
