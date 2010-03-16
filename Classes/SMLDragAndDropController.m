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

#import "SMLDragAndDropController.h"
#import "SMLOpenSavePerformer.h"
#import "SMLProjectsController.h"
#import "SMLTableView.h"
#import "SMLTextPerformer.h"
#import "SMLCommandsController.h"
#import "SMLBasicPerformer.h"
#import "SMLSnippetsController.h"
#import "SMLVariousPerformer.h"
#import "SMLProject.h"

@implementation SMLDragAndDropController

static id sharedInstance = nil;

+ (SMLDragAndDropController *)sharedInstance
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
		
		movedDocumentType = @"SMLMovedDocumentType";
		movedSnippetType = @"SMLMovedSnippetType";
		movedCommandType = @"SMLMovedCommandType";
    }
    return sharedInstance;
}


- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	NSArray *typesArray;
	if (aTableView == [SMLCurrentProject documentsTableView]) {		
		typesArray = [NSArray arrayWithObjects:movedDocumentType, nil];
		
		NSMutableArray *uriArray = [NSMutableArray array];
		NSArray *arrangedObjects = [[SMLCurrentProject documentsArrayController] arrangedObjects];
		NSInteger currentIndex = [rowIndexes firstIndex];
		while (currentIndex != NSNotFound) {
			[uriArray addObject:[SMLBasic uriFromObject:[arrangedObjects objectAtIndex:currentIndex]]];
			currentIndex = [rowIndexes indexGreaterThanIndex:currentIndex];
		}
		
		[pboard declareTypes:typesArray owner:self];
		[pboard setData:[NSArchiver archivedDataWithRootObject:[NSArray arrayWithObjects:rowIndexes, uriArray, nil]] forType:movedDocumentType];
		
		return YES;
		
	} else if (aTableView == [[SMLSnippetsController sharedInstance] snippetsTableView]) {
		typesArray = [NSArray arrayWithObjects:NSStringPboardType, movedSnippetType, nil];
		
		NSMutableString *string = [NSMutableString stringWithString:@""];
		NSMutableArray *uriArray = [NSMutableArray array];
		NSArray *arrangedObjects = [[[SMLSnippetsController sharedInstance] snippetsArrayController] arrangedObjects];
		NSInteger currentIndex = [rowIndexes firstIndex];
		while (currentIndex != NSNotFound) {
			NSRange selectedRange = [SMLCurrentTextView selectedRange];
			NSString *selectedText = [[SMLCurrentTextView string] substringWithRange:selectedRange];
			if (selectedText == nil) {
				selectedText = @"";
			}
			NSMutableString *insertString = [NSMutableString stringWithString:[[arrangedObjects objectAtIndex:currentIndex] valueForKey:@"text"]];
			[insertString replaceOccurrencesOfString:@"%%s" withString:selectedText options:NSLiteralSearch range:NSMakeRange(0, [insertString length])];
			
			[string appendString:insertString];
			[uriArray addObject:[SMLBasic uriFromObject:[arrangedObjects objectAtIndex:currentIndex]]];
			currentIndex = [rowIndexes indexGreaterThanIndex:currentIndex];
		}
		
		[pboard declareTypes:typesArray owner:self];
		[pboard setString:string forType:NSStringPboardType];
		[pboard setData:[NSArchiver archivedDataWithRootObject:[NSArray arrayWithObjects:rowIndexes, uriArray, nil]] forType:movedSnippetType];
		
		return YES;
		
	} else if (aTableView == [[SMLCommandsController sharedInstance] commandsTableView]) {
		typesArray = [NSArray arrayWithObjects:NSStringPboardType, movedCommandType, nil];
		
		NSMutableString *string = [NSMutableString stringWithString:@""];
		NSMutableArray *uriArray = [NSMutableArray array];
		NSArray *arrangedObjects = [[[SMLCommandsController sharedInstance] commandsArrayController] arrangedObjects];
		NSInteger currentIndex = [rowIndexes firstIndex];
		while (currentIndex != NSNotFound) {
			NSRange selectedRange = [SMLCurrentTextView selectedRange];
			NSString *selectedText = [[SMLCurrentTextView string] substringWithRange:selectedRange];
			if (selectedText == nil) {
				selectedText = @"";
			}
			NSMutableString *insertString = [NSMutableString stringWithString:[[arrangedObjects objectAtIndex:currentIndex] valueForKey:@"text"]];
			[insertString replaceOccurrencesOfString:@"%%s" withString:selectedText options:NSLiteralSearch range:NSMakeRange(0, [insertString length])];
			
			[string appendString:insertString];
			[uriArray addObject:[SMLBasic uriFromObject:[arrangedObjects objectAtIndex:currentIndex]]];
			currentIndex = [rowIndexes indexGreaterThanIndex:currentIndex];
		}
		
		[pboard declareTypes:typesArray owner:self];
		[pboard setString:string forType:NSStringPboardType];
		[pboard setData:[NSArchiver archivedDataWithRootObject:[NSArray arrayWithObjects:rowIndexes, uriArray, nil]] forType:movedCommandType];
		
		return YES;
		
	} else {
		return NO;
	}
}


- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	if (aTableView == [SMLCurrentProject documentsTableView]) {
		if ([info draggingSource] == [SMLCurrentProject documentsTableView]) {
			[aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
			return NSDragOperationMove;
		} else {
			[aTableView setDropRow:[[[SMLCurrentProject documentsArrayController] arrangedObjects] count] dropOperation:NSTableViewDropAbove];
			return NSDragOperationCopy;
		}
		
	} else if (aTableView == [[SMLSnippetsController sharedInstance] snippetsTableView]) {
		[aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
	 	return NSDragOperationCopy;
		
	} else if (aTableView == [[SMLSnippetsController sharedInstance] snippetCollectionsTableView]) {
		if ([info draggingSource] == [[SMLSnippetsController sharedInstance] snippetsTableView]) {
			[aTableView setDropRow:row dropOperation:NSTableViewDropOn];
			return NSDragOperationMove;
		} else {
			[aTableView setDropRow:[[[[SMLSnippetsController sharedInstance] snippetCollectionsArrayController] arrangedObjects] count] dropOperation:NSTableViewDropAbove];
			return NSDragOperationCopy;
		}
		return NSDragOperationCopy;
		
	} else if (aTableView == [[SMLCommandsController sharedInstance] commandsTableView]) {
		[aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
	 	return NSDragOperationCopy;
		
	} else if (aTableView == [[SMLCommandsController sharedInstance] commandCollectionsTableView]) {
		if ([info draggingSource] == [[SMLCommandsController sharedInstance] commandsTableView]) {
			[aTableView setDropRow:row dropOperation:NSTableViewDropOn];
			return NSDragOperationMove;
		} else {
			[aTableView setDropRow:[[[[SMLCommandsController sharedInstance] commandCollectionsArrayController] arrangedObjects] count] dropOperation:NSTableViewDropAbove];
			return NSDragOperationCopy;
		}
		return NSDragOperationCopy;
		
	} else if ([aTableView isKindOfClass:[SMLTableView class]]) {		
		[aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
		return NSDragOperationMove;
	}
	
	return NSDragOperationNone;
}


- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
	if (row < 0) {
		row = 0;
	}

    // Documents list
	if (aTableView == [SMLCurrentProject documentsTableView]) {
		if ([info draggingSource] == [SMLCurrentProject documentsTableView]) {
			if (![[[info draggingPasteboard] types] containsObject:movedDocumentType]) {
				return NO;
			}
			NSArrayController *arrayController = [SMLCurrentProject documentsArrayController];
			
			NSArray *pasteboardData = [NSUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:movedDocumentType]];
			NSIndexSet *rowIndexes = [pasteboardData objectAtIndex:0];
			NSArray *uriArray = [pasteboardData objectAtIndex:1];
			[self moveObjects:uriArray inArrayController:arrayController fromIndexes:rowIndexes toIndex:row];
			
			[SMLCurrentProject documentsListHasUpdated];
			
			return YES;
			
		}

		NSArray *filesToImport = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
		if (filesToImport != nil && aTableView == [SMLCurrentProject documentsTableView]) {
			[SMLOpenSave openAllTheseFiles:filesToImport];
			return YES;
		}
		
		NSString *textToImport = (NSString *)[[info draggingPasteboard] stringForType:NSStringPboardType];
		if (textToImport != nil && aTableView == [SMLCurrentProject documentsTableView]) {
			[SMLCurrentProject createNewDocumentWithContents:textToImport];
			return YES;
		}
		
	// Snippets
	} else if (aTableView == [[SMLSnippetsController sharedInstance] snippetsTableView]) {
		
		NSString *textToImport = (NSString *)[[info draggingPasteboard] stringForType:NSStringPboardType];
		if (textToImport != nil) {
			
			id item = [[SMLSnippetsController sharedInstance] performInsertNewSnippet];
			
			[item setValue:textToImport forKey:@"text"];
			if ([textToImport length] > SNIPPET_NAME_LENGTH) {
				[item setValue:[SMLText replaceAllNewLineCharactersWithSymbolInString:[textToImport substringWithRange:NSMakeRange(0, SNIPPET_NAME_LENGTH)]] forKey:@"name"];
			} else {
				[item setValue:textToImport forKey:@"name"];
			}
			
			return YES;
		} else {
			return NO;
		}		
	
	// Snippet collections
	} else if (aTableView == [[SMLSnippetsController sharedInstance] snippetCollectionsTableView]) {
		NSArray *filesToImport = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
		
		if (filesToImport != nil) {
			[SMLOpenSave openAllTheseFiles:filesToImport];
			return YES;
		}
		
		if ([info draggingSource] == [[SMLSnippetsController sharedInstance] snippetsTableView]) {
			if (![[[info draggingPasteboard] types] containsObject:movedSnippetType]) {
				return NO;
			}
			
			NSArray *pasteboardData = [NSUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:movedSnippetType]];
			NSArray *uriArray = [pasteboardData objectAtIndex:1];
			
			id collection = [[[[SMLSnippetsController sharedInstance] snippetCollectionsArrayController] arrangedObjects] objectAtIndex:row];
			
			id item;
			for (item in uriArray) {
				[[collection mutableSetValueForKey:@"snippets"] addObject:[SMLBasic objectFromURI:item]];
			}
			
			[[[SMLSnippetsController sharedInstance] snippetsArrayController] rearrangeObjects];

			return YES;
		}
		
		
	// Commands
	} else if (aTableView == [[SMLCommandsController sharedInstance] commandsTableView]) {
		
		NSString *textToImport = (NSString *)[[info draggingPasteboard] stringForType:NSStringPboardType];
		if (textToImport != nil) {
			
			id item = [[SMLCommandsController sharedInstance] performInsertNewCommand];
			
			[item setValue:textToImport forKey:@"text"];
			if ([textToImport length] > SNIPPET_NAME_LENGTH) {
				[item setValue:[SMLText replaceAllNewLineCharactersWithSymbolInString:[textToImport substringWithRange:NSMakeRange(0, SNIPPET_NAME_LENGTH)]] forKey:@"name"];
			} else {
				[item setValue:textToImport forKey:@"name"];
			}
			
			return YES;
		} else {
			return NO;
		}		
		
	// Command collections
	} else if (aTableView == [[SMLCommandsController sharedInstance] commandCollectionsTableView]) {

		NSArray *filesToImport = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
		
		if (filesToImport != nil) {
			[SMLOpenSave openAllTheseFiles:filesToImport];
			return YES;
		}
		
		if ([info draggingSource] == [[SMLCommandsController sharedInstance] commandsTableView]) {
			if (![[[info draggingPasteboard] types] containsObject:movedCommandType]) {
				return NO;
			}
			
			NSArray *pasteboardData = [NSUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:movedCommandType]];
			NSArray *uriArray = [pasteboardData objectAtIndex:1];
			
			id collection = [[[[SMLCommandsController sharedInstance] commandCollectionsArrayController] arrangedObjects] objectAtIndex:row];
			
			id item;
			for (item in uriArray) {
				[[collection mutableSetValueForKey:@"commands"] addObject:[SMLBasic objectFromURI:item]];
			}
			
			[[[SMLCommandsController sharedInstance] commandsArrayController] rearrangeObjects];
			
			return YES;
		}
		
	// From another project
	} else if ([[info draggingSource] isKindOfClass:[SMLTableView class]]) {
		if (![[[info draggingPasteboard] types] containsObject:movedDocumentType]) {
			return NO;
		}
		
		NSArray *array = [[SMLProjectsController sharedDocumentController] documents];
		id destinationProject;
		for (destinationProject in array) {
			if (aTableView == [destinationProject documentsTableView]) {
				break;
			}
		}
		
		if (destinationProject == nil) {
			return NO;
		}
		
		NSArrayController *destinationArrayController = [destinationProject documentsArrayController];
		NSArray *pasteboardData = [NSUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:movedDocumentType]];
		NSArray *uriArray = [pasteboardData objectAtIndex:1];
		id document = [SMLBasic objectFromURI:[uriArray objectAtIndex:0]];
		[(NSMutableSet *)[destinationProject documents] addObject:document];
		[document setValue:[NSNumber numberWithInteger:row] forKey:@"sortOrder"];
		[SMLVarious fixSortOrderNumbersForArrayController:destinationArrayController overIndex:row];
		[destinationArrayController rearrangeObjects];
		[destinationProject selectDocument:document];
		[destinationProject documentsListHasUpdated];
		[SMLCurrentProject documentsListHasUpdated];
		
		return YES;	
		
	
	// To a table view which is not active
	} else if ([aTableView isKindOfClass:[SMLTableView class]]) {
		
		NSArray *filesToImport = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
		
		if (filesToImport != nil) {
			[[aTableView window] makeMainWindow];
			NSArray *array = [[SMLProjectsController sharedDocumentController] documents];
			for (id item in array) {
				if (aTableView == [item documentsTableView]) {
					[[SMLProjectsController sharedDocumentController] setCurrentProject:item];
					break;
				}
			}
			
			if (SMLCurrentProject != nil) {
				[SMLOpenSave openAllTheseFiles:filesToImport];
				[[SMLProjectsController sharedDocumentController] setCurrentProject:nil];
				return YES;
			}
		}
		
		return NO;
	}
	
	
    return NO;
}


- (void)moveObjects:(NSArray *)objects inArrayController:(NSArrayController *)arrayController fromIndexes:(NSIndexSet *)rowIndexes toIndex:(NSInteger)insertIndex
{
	NSMutableArray *arrangedObjects = [NSMutableArray arrayWithArray:[arrayController arrangedObjects]]; 
	
	if (arrangedObjects == nil || objects == nil) {
		return; 
	} 
	
	NSUInteger currentIndex = [rowIndexes firstIndex];
	while (currentIndex != NSNotFound) {
		[arrangedObjects replaceObjectAtIndex:currentIndex withObject:[NSNull null]]; 
		currentIndex = [rowIndexes indexGreaterThanIndex:currentIndex];
	}
	
	NSEnumerator *enumerator = [objects reverseObjectEnumerator]; 
	id item;
	for (item in enumerator) {
		[arrangedObjects insertObject:[SMLBasic objectFromURI:item] atIndex:insertIndex];
	}

	[arrangedObjects removeObject:[NSNull null]];
	
	NSInteger index = 0;
	for (item in arrangedObjects) {
		[item setValue:[NSNumber numberWithInteger:index] forKey:@"sortOrder"];
		index++;
	}
	
	[arrayController setContent:arrangedObjects];
}

@end
