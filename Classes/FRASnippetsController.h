/*
 Fraise version 3.7 - Based on Smultron by Peter Borg
 
 Current Maintainer (since 2016): 
 Andreas Bentele: abentele.github@icloud.com (https://github.com/abentele/Fraise)
 
 Maintainer before macOS Sierra (2010-2016): 
 Jean-François Moy: jeanfrancois.moy@gmail.com (http://github.com/jfmoy/Fraise)

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import <Cocoa/Cocoa.h>

@interface FRASnippetsController : NSObject <NSToolbarDelegate>
{ 
    IBOutlet NSArrayController * snippetCollectionsArrayController;
    IBOutlet NSTableView * snippetCollectionsTableView;
    IBOutlet NSArrayController * snippetsArrayController;
    IBOutlet NSTableView * snippetsTableView;
    IBOutlet NSWindow * snippetsWindow;
	IBOutlet NSTextView * snippetsTextView;
	IBOutlet NSView *snippetsFilterView;
}

@property (strong, readonly) IBOutlet NSTextView *snippetsTextView;
@property (strong, readonly) IBOutlet NSWindow *snippetsWindow;
@property (strong, readonly) IBOutlet NSArrayController *snippetCollectionsArrayController;
@property (strong, readonly) IBOutlet NSTableView *snippetCollectionsTableView;
@property (strong, readonly) IBOutlet NSArrayController *snippetsArrayController;
@property (strong, readonly) IBOutlet NSTableView *snippetsTableView;

+ (FRASnippetsController *)sharedInstance;

- (void)openSnippetsWindow;

- (IBAction)newCollectionAction:(id)sender;
- (IBAction)newSnippetAction:(id)sender;

- (id)performInsertNewSnippet;

- (void)insertSnippet:(id)snippet;

- (void)performDeleteCollection;

- (void)importSnippets;
- (void)performSnippetsImportWithPath:(NSString *)path;
- (void)exportSnippets;

- (NSManagedObjectContext *)managedObjectContext;


@end
