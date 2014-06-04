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

@interface FRASnippetsController : NSObject <NSToolbarDelegate>
{ 
    IBOutlet NSArrayController *__unsafe_unretained snippetCollectionsArrayController;
    IBOutlet NSTableView *__unsafe_unretained snippetCollectionsTableView;
    IBOutlet NSArrayController *__unsafe_unretained snippetsArrayController;
    IBOutlet NSTableView *__unsafe_unretained snippetsTableView;
    IBOutlet NSWindow *__unsafe_unretained snippetsWindow;
	IBOutlet NSTextView *__unsafe_unretained snippetsTextView;
	IBOutlet NSView *snippetsFilterView;
}

@property (unsafe_unretained, readonly) IBOutlet NSTextView *snippetsTextView;
@property (unsafe_unretained, readonly) IBOutlet NSWindow *snippetsWindow;
@property (unsafe_unretained, readonly) IBOutlet NSArrayController *snippetCollectionsArrayController;
@property (unsafe_unretained, readonly) IBOutlet NSTableView *snippetCollectionsTableView;
@property (unsafe_unretained, readonly) IBOutlet NSArrayController *snippetsArrayController;
@property (unsafe_unretained, readonly) IBOutlet NSTableView *snippetsTableView;

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
