/*
Fraise version 3.7 - Based on Smultron by Peter Borg
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Fraise

Copyright 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "FRATextMenuController.h"
#import "FRABasicPerformer.h"
#import "FRAProjectsController.h"
#import "FRAInterfacePerformer.h"
#import "FRAVariousPerformer.h"
#import "FRAExtraInterfaceController.h"
#import "FRAFileMenuController.h"
#import "FRATextPerformer.h"
#import "FRALineNumbers.h"
#import "FRASyntaxColouring.h"
#import "FRATextView.h"
#import "FRAProject.h"

@implementation FRATextMenuController

static id sharedInstance = nil;

+ (FRATextMenuController *)sharedInstance
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


- (void)buildEncodingsMenus
{
	[FRABasic removeAllItemsFromMenu:textEncodingMenu];
	[FRABasic removeAllItemsFromMenu:reloadTextWithEncodingMenu];
	
	NSArray *encodingsArray = [FRABasic fetchAll:@"EncodingSortKeyName"];
	NSEnumerator *enumerator = [encodingsArray reverseObjectEnumerator];
	id item;
	NSMenuItem *menuItem;
	for (item in enumerator) {
		if ([[item valueForKey:@"active"] boolValue] == YES) {
			NSUInteger encoding = [[item valueForKey:@"encoding"] unsignedIntegerValue];
			menuItem = [[NSMenuItem alloc] initWithTitle:[NSString localizedNameOfStringEncoding:encoding] action:@selector(changeEncodingAction:) keyEquivalent:@""];
			[menuItem setTag:encoding];
			[menuItem setTarget:self];
			[textEncodingMenu insertItem:menuItem atIndex:0];
		}
	}
	
	enumerator = [encodingsArray reverseObjectEnumerator];
	for (item in enumerator) {
		if ([[item valueForKey:@"active"] boolValue] == YES) {
			NSUInteger encoding = [[item valueForKey:@"encoding"] unsignedIntegerValue];
			menuItem = [[NSMenuItem alloc] initWithTitle:[NSString localizedNameOfStringEncoding:encoding] action:@selector(reloadText:) keyEquivalent:@""];
			[menuItem setTag:encoding];
			[menuItem setTarget:self];
			[reloadTextWithEncodingMenu insertItem:menuItem atIndex:0];
		}
	}
}


- (void)buildSyntaxDefinitionsMenu
{
	NSArray *syntaxDefinitions = [FRABasic fetchAll:@"SyntaxDefinitionSortKeySortOrder"];
	NSEnumerator *enumerator = [syntaxDefinitions reverseObjectEnumerator];
	NSMenuItem *menuItem;
	NSInteger tag = [syntaxDefinitions count] - 1;
	for (id item in enumerator) {
		menuItem = [[NSMenuItem alloc] initWithTitle:[item valueForKey:@"name"] action:@selector(changeSyntaxDefinitionAction:) keyEquivalent:@""];
		[menuItem setTag:tag];
		[menuItem setTarget:self];
		[syntaxDefinitionMenu insertItem:menuItem atIndex:0];
		tag--;
	}
	
}


- (void)changeEncodingAction:(id)sender
{	
	NSUInteger encoding = [sender tag];
	
	id document = FRACurrentDocument;
	
	[[[document valueForKey:@"syntaxColouring"] undoManager] registerUndoWithTarget:self selector:@selector(performUndoChangeEncoding:) object:@[[document valueForKey:@"encoding"]]];
	[[[document valueForKey:@"syntaxColouring"] undoManager] setActionName:NAME_FOR_UNDO_CHANGE_ENCODING];
	
	[document setValue: @(encoding) forKey:@"encoding"];
	[document setValue:[NSString localizedNameOfStringEncoding:encoding] forKey:@"encodingName"];
	
	[FRAInterface updateStatusBar];

}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	BOOL enableMenuItem = YES;
	NSInteger tag = [anItem tag];
	if ([FRACurrentProject areThereAnyDocuments]) {
		if (tag == 101) { // Encodings
			NSArray *subMenuArray = [NSArray arrayWithArray:[[anItem submenu] itemArray]];
			id object;
			for (object in subMenuArray) {
				[object setState:NSOffState];
			}
			[[[anItem submenu] itemWithTag:[[FRACurrentDocument valueForKey:@"encoding"] integerValue]] setState:NSOnState];
		} else if (tag == 104) { // Encodings, reload
			if ([[FRACurrentDocument valueForKey:@"isEdited"] boolValue] == YES || [FRACurrentDocument valueForKey:@"path"] == nil) {
				return NO;
			}			
			
			NSArray *subMenuArray = [NSArray arrayWithArray:[[anItem submenu] itemArray]];
			id object;
			for (object in subMenuArray) {
				[object setState:NSOffState];
			}
			[[[anItem submenu] itemWithTag:[[FRACurrentDocument valueForKey:@"encoding"] integerValue]] setState:NSOnState];
			
		} else if (tag == 102) { // All items who should only be active if something is selected
			if ([FRACurrentTextView selectedRange].length < 1) {
				enableMenuItem = NO;
			}
		} else if (tag == 103) { // Comment Or Uncomment
			if ([[[FRACurrentDocument valueForKey:@"syntaxColouring"] valueForKey:@"firstSingleLineComment"] isEqualToString:@""]) {
				enableMenuItem = NO;
			}
		} else if (tag == 150) { // Line endings
			NSArray *subMenuArray = [NSArray arrayWithArray:[[anItem submenu] itemArray]];
			id object;
			for (object in subMenuArray) {
				[object setState:NSOffState];
			}
			NSInteger lineEndings = [[FRACurrentDocument valueForKey:@"lineEndings"] integerValue];
			if (lineEndings != 0) {
				[[[anItem submenu] itemWithTag:(lineEndings + 150)] setState:NSOnState];
			}
		} else if (tag == 112) { // Syntax Definition
			NSArray *subMenuArray = [NSArray arrayWithArray:[[anItem submenu] itemArray]];
			id document = FRACurrentDocument;
			id item;
			NSString *syntaxDefinition = [document valueForKey:@"syntaxDefinition"];
			for (item in subMenuArray) {
				if ([[item title] isEqualToString:syntaxDefinition]) {
					[item setState:NSOnState];
				} else {
					[item setState:NSOffState];
				}
			}
		}
		
	} else {
		enableMenuItem = NO;
	}
	
	return enableMenuItem;
}


-(void)performUndoChangeEncoding:(id)sender
{
	id document = FRACurrentDocument;
	
	[[[document valueForKey:@"syntaxColouring"] undoManager] registerUndoWithTarget:self selector:@selector(performUndoChangeEncoding:) object:@[[document valueForKey:@"encoding"]]];
	[[[document valueForKey:@"syntaxColouring"] undoManager] setActionName:NAME_FOR_UNDO_CHANGE_ENCODING];
	
	[document setValue:sender[0] forKey:@"encoding"];
	[document setValue:[NSString localizedNameOfStringEncoding:[sender[0] unsignedIntegerValue]] forKey:@"encodingName"];
	
	[FRAInterface updateStatusBar];
}


- (IBAction)shiftLeftAction:(id)sender
{	
	NSTextView *textView = FRACurrentTextView;
	
	NSString *completeString = [textView string];
	if ([completeString length] < 1) {
		return;
	}
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] setReactToChanges:NO];
	NSRange selectedRange;
	
	NSArray *array = [FRACurrentTextView selectedRanges];
	NSInteger sumOfAllCharactersRemoved = 0;
	NSInteger updatedLocation;
	NSMutableArray *updatedSelectionsArray = [NSMutableArray array];
	for (id item in array) {
		selectedRange = NSMakeRange([item rangeValue].location - sumOfAllCharactersRemoved, [item rangeValue].length);
		NSInteger temporaryLocation = selectedRange.location;
		NSInteger maxSelectedRange = NSMaxRange(selectedRange);
		NSInteger numberOfLines = 0;
		NSInteger locationOfFirstLine = [completeString lineRangeForRange:NSMakeRange(temporaryLocation, 0)].location;

		do {
			temporaryLocation = NSMaxRange([completeString lineRangeForRange:NSMakeRange(temporaryLocation, 0)]);
			numberOfLines++;
		} while (temporaryLocation < maxSelectedRange);

		temporaryLocation = selectedRange.location;
		NSInteger index;
		NSInteger charactersRemoved = 0;
		NSInteger charactersRemovedInSelection = 0;
		NSRange rangeOfLine;
		unichar characterToTest;
		NSInteger numberOfSpacesPerTab = [[FRADefaults valueForKey:@"IndentWidth"] integerValue];
		NSInteger numberOfSpacesToDeleteOnFirstLine = -1;
		for (index = 0; index < numberOfLines; index++) {
			rangeOfLine = [completeString lineRangeForRange:NSMakeRange(temporaryLocation, 0)];
			if ([[FRADefaults valueForKey:@"UseTabStops"] boolValue] == YES && [[FRADefaults valueForKey:@"IndentWithSpaces"] boolValue] == YES) {
				NSInteger startOfLine = rangeOfLine.location;
				while (startOfLine < NSMaxRange(rangeOfLine) && [completeString characterAtIndex:startOfLine] == ' ' && rangeOfLine.length > 0) {
					startOfLine++;
				}
				NSInteger numberOfSpacesToDelete = numberOfSpacesPerTab;
				if (numberOfSpacesPerTab != 0) {
					numberOfSpacesToDelete = (startOfLine - rangeOfLine.location) % numberOfSpacesPerTab;
					if (numberOfSpacesToDelete == 0) {
						numberOfSpacesToDelete = numberOfSpacesPerTab;
					}
				}
				if (numberOfSpacesToDeleteOnFirstLine != -1) {
					numberOfSpacesToDeleteOnFirstLine = numberOfSpacesToDelete;
				}
				while (numberOfSpacesToDelete--) {
					characterToTest = [completeString characterAtIndex:rangeOfLine.location];
					if (characterToTest == ' ' || characterToTest == '\t') {
						if ([textView shouldChangeTextInRange:NSMakeRange(rangeOfLine.location, 1) replacementString:@""]) { // Do it this way to mark it as an Undo
							[textView replaceCharactersInRange:NSMakeRange(rangeOfLine.location, 1) withString:@""];
							[textView didChangeText];
						}
						charactersRemoved++;
						if (rangeOfLine.location >= selectedRange.location && rangeOfLine.location < maxSelectedRange) {
							charactersRemovedInSelection++;
						}
						if (characterToTest == '\t') {
							break;
						}
					}
				}
			} else {
				characterToTest = [completeString characterAtIndex:rangeOfLine.location];
				if ((characterToTest == ' ' || characterToTest == '\t') && rangeOfLine.length > 0) {
					if ([textView shouldChangeTextInRange:NSMakeRange(rangeOfLine.location, 1) replacementString:@""]) { // Do it this way to mark it as an Undo
						[textView replaceCharactersInRange:NSMakeRange(rangeOfLine.location, 1) withString:@""];
						[textView didChangeText];
					}			
					charactersRemoved++;
					if (rangeOfLine.location >= selectedRange.location && rangeOfLine.location < maxSelectedRange) {
						charactersRemovedInSelection++;
					}
				}
			}
			if (temporaryLocation < [[textView string] length]) {
				temporaryLocation = NSMaxRange([completeString lineRangeForRange:NSMakeRange(temporaryLocation, 0)]);
			}
		}

		if (selectedRange.length > 0) {
			NSInteger selectedRangeLocation = selectedRange.location; // Make the location into an NSInteger because otherwise the value gets all screwed up when subtracting from it
			NSInteger charactersToCountBackwards = 1;
			if (numberOfSpacesToDeleteOnFirstLine != -1) {
				charactersToCountBackwards = numberOfSpacesToDeleteOnFirstLine;
			}
			if (selectedRangeLocation - charactersToCountBackwards <= locationOfFirstLine) {
				updatedLocation = locationOfFirstLine;
			} else {
				updatedLocation = selectedRangeLocation - charactersToCountBackwards;
			}
			[updatedSelectionsArray addObject:[NSValue valueWithRange:NSMakeRange(updatedLocation, selectedRange.length - charactersRemovedInSelection)]];
		}
		sumOfAllCharactersRemoved = sumOfAllCharactersRemoved + charactersRemoved;
	}
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] setReactToChanges:YES];
	
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] pageRecolour];
	
	if (sumOfAllCharactersRemoved == 0) {
		NSBeep();
	} else {
		if ([[FRACurrentDocument valueForKey:@"isEdited"] boolValue] == NO) {
			[FRAVarious hasChangedDocument:FRACurrentDocument];
		}
		[[FRACurrentDocument valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth:NO recolour:NO];
	}
	
	if ([updatedSelectionsArray count] > 0) {
		[textView setSelectedRanges:updatedSelectionsArray];
	}
}


- (IBAction)shiftRightAction:(id)sender
{
	NSTextView *textView = FRACurrentTextView;
	NSString *completeString = [textView string];
	if ([completeString length] < 1) {
		return;
	}
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] setReactToChanges:NO];
	NSRange selectedRange;
	
	NSMutableString *replacementString;
	if ([[FRADefaults valueForKey:@"IndentWithSpaces"] boolValue] == YES) {
		replacementString = [NSMutableString string];
		NSInteger numberOfSpacesPerTab = [[FRADefaults valueForKey:@"IndentWidth"] integerValue];
		if ([[FRADefaults valueForKey:@"UseTabStops"] boolValue] == YES) {
			NSInteger locationOnLine = [textView selectedRange].location - [[textView string] lineRangeForRange:NSMakeRange([textView selectedRange].location, 0)].location;
			if (numberOfSpacesPerTab != 0) {
				NSInteger numberOfSpacesLess = locationOnLine % numberOfSpacesPerTab;
				numberOfSpacesPerTab = numberOfSpacesPerTab - numberOfSpacesLess;
			}
		}
		while (numberOfSpacesPerTab--) {
			[replacementString appendString:@" "];
		}
	} else {
		replacementString = [NSMutableString stringWithString:@"\t"];
	}
	NSInteger replacementStringLength = [replacementString length];
	
	NSArray *array = [FRACurrentTextView selectedRanges];
	NSInteger sumOfAllCharactersInserted = 0;
	NSInteger updatedLocation;
	NSMutableArray *updatedSelectionsArray = [NSMutableArray array];
	for (id item in array) {
		selectedRange = NSMakeRange([item rangeValue].location + sumOfAllCharactersInserted, [item rangeValue].length);
		NSInteger temporaryLocation = selectedRange.location;
		NSInteger maxSelectedRange = NSMaxRange(selectedRange);
		NSInteger numberOfLines = 0;
		NSInteger locationOfFirstLine = [completeString lineRangeForRange:NSMakeRange(temporaryLocation, 0)].location;
		
		do {
			temporaryLocation = NSMaxRange([completeString lineRangeForRange:NSMakeRange(temporaryLocation, 0)]);
			numberOfLines++;
		} while (temporaryLocation < maxSelectedRange);
		
		temporaryLocation = selectedRange.location;
		NSInteger index;
		NSInteger charactersInserted = 0;
		NSInteger charactersInsertedInSelection = 0;
		NSRange rangeOfLine;
		for (index = 0; index < numberOfLines; index++) {
			rangeOfLine = [completeString lineRangeForRange:NSMakeRange(temporaryLocation, 0)];
			if ([textView shouldChangeTextInRange:NSMakeRange(rangeOfLine.location, 0) replacementString:replacementString]) { // Do it this way to mark it as an Undo
				[textView replaceCharactersInRange:NSMakeRange(rangeOfLine.location, 0) withString:replacementString];
				[textView didChangeText];
			}			
			charactersInserted = charactersInserted + replacementStringLength;
			if (rangeOfLine.location >= selectedRange.location && rangeOfLine.location < maxSelectedRange + charactersInserted) {
				charactersInsertedInSelection = charactersInsertedInSelection + replacementStringLength;
			}
			if (temporaryLocation < [[textView string] length]) {
				temporaryLocation = NSMaxRange([completeString lineRangeForRange:NSMakeRange(temporaryLocation, 0)]);
			}	
		}
		
		if (selectedRange.length > 0) {
			if (selectedRange.location + replacementStringLength >= [[textView string] length]) {
				updatedLocation = locationOfFirstLine;
			} else {
				updatedLocation = selectedRange.location;
			}
			[updatedSelectionsArray addObject:[NSValue valueWithRange:NSMakeRange(updatedLocation, selectedRange.length + charactersInsertedInSelection)]];
		}
		sumOfAllCharactersInserted = sumOfAllCharactersInserted + charactersInserted;

	}
	
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] setReactToChanges:YES];
	
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] pageRecolour];
	
	if ([[FRACurrentDocument valueForKey:@"isEdited"] boolValue] == NO) {
		[FRAVarious hasChangedDocument:FRACurrentDocument];
	}
	
	[[FRACurrentDocument valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth:NO recolour:NO];
	
	if ([updatedSelectionsArray count] > 0) {
		[textView setSelectedRanges:updatedSelectionsArray];
	}
}


- (IBAction)removeNeedlessWhitespaceAction:(id)sender
{
	// First count the number of lines in which to perform the action, as the original range changes when you insert characters, and then perform the action line after line, by removing tabs and spaces after the last non-whitespace characters in every line
	
	NSTextView *textView = FRACurrentTextView;
	NSString *completeString = [textView string];
	if ([completeString length] < 1) {
		return;
	}
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] setReactToChanges:NO];
	NSRange selectedRange;
	
	NSArray *array = [FRACurrentTextView selectedRanges];
	NSInteger sumOfAllCharactersRemoved = 0;
	NSInteger updatedLocation;
	NSMutableArray *updatedSelectionsArray = [NSMutableArray array];
	for (id item in array) {
		selectedRange = NSMakeRange([item rangeValue].location - sumOfAllCharactersRemoved, [item rangeValue].length);
		NSInteger tempLocation = selectedRange.location;
		NSInteger maxSelectedRange = NSMaxRange(selectedRange);
		NSInteger numberOfLines = 0;
		NSInteger locationOfFirstLine = [completeString lineRangeForRange:NSMakeRange(tempLocation, 0)].location;
		
		do {
			tempLocation = NSMaxRange([completeString lineRangeForRange:NSMakeRange(tempLocation, 0)]);
			numberOfLines++;
		} while (tempLocation < maxSelectedRange);
		
		tempLocation = selectedRange.location;
		NSInteger index;
		NSInteger charactersRemoved = 0;
		NSInteger charactersRemovedInSelection = 0;
		NSRange rangeOfLine;
		
		NSUInteger endOfContentsLocation;
		for (index = 0; index < numberOfLines; index++) {
			rangeOfLine = [completeString lineRangeForRange:NSMakeRange(tempLocation, 0)];
			[completeString getLineStart:NULL end:NULL contentsEnd:&endOfContentsLocation forRange:rangeOfLine];
			
			while (endOfContentsLocation != 0 && ([completeString characterAtIndex:endOfContentsLocation - 1] == ' ' || [completeString characterAtIndex:endOfContentsLocation - 1] == '\t')) {
				if ([textView shouldChangeTextInRange:NSMakeRange(endOfContentsLocation - 1, 1) replacementString:@""]) { // Do it this way to mark it as an Undo
					[textView replaceCharactersInRange:NSMakeRange(endOfContentsLocation - 1, 1) withString:@""];
					[textView didChangeText];
				}
				endOfContentsLocation--;
				charactersRemoved++;
				if (rangeOfLine.location >= selectedRange.location && rangeOfLine.location < maxSelectedRange) {
					charactersRemovedInSelection++;
				}
			}
			tempLocation = NSMaxRange([completeString lineRangeForRange:NSMakeRange(tempLocation, 0)]);		
		}
		
		if (selectedRange.length > 0) {
			NSInteger selectedRangeLocation = selectedRange.location; // Make the location into an NSInteger because otherwise the value gets all screwed up when subtracting from it
			if (selectedRangeLocation - 1 <= locationOfFirstLine) {
				updatedLocation = locationOfFirstLine;
			} else {
				updatedLocation = selectedRangeLocation - 1;
			}
			[updatedSelectionsArray addObject:[NSValue valueWithRange:NSMakeRange(updatedLocation, selectedRange.length - charactersRemoved)]];
		}
		sumOfAllCharactersRemoved = sumOfAllCharactersRemoved + charactersRemoved;
	}
	
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] setReactToChanges:YES];
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] pageRecolour];
	
	if (sumOfAllCharactersRemoved == 0) {
		NSBeep();
	} else {
		if ([[FRACurrentDocument valueForKey:@"isEdited"] boolValue] == NO) {
			[FRAVarious hasChangedDocument:FRACurrentDocument];
		}
		[[FRACurrentDocument valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth:NO recolour:NO];
	}
	
	if ([updatedSelectionsArray count] > 0) {
		[textView setSelectedRanges:updatedSelectionsArray];
	}
}


- (IBAction)toLowercaseAction:(id)sender
{
	NSTextView *textView = FRACurrentTextView;
	NSArray *array = [textView selectedRanges];
	for (id item in array) {
		NSRange selectedRange = [item rangeValue];
		NSString *originalString = [FRACurrentText substringWithRange:selectedRange];
		NSString *newString = [NSString stringWithString:[originalString lowercaseString]];
		[textView setSelectedRange:selectedRange];
		[textView insertText:newString replacementRange:[textView selectedRange]];
	}
}


- (IBAction)toUppercaseAction:(id)sender
{
	NSTextView *textView = FRACurrentTextView;
	NSArray *array = [textView selectedRanges];
	for (id item in array) {
		NSRange selectedRange = [item rangeValue];
		NSString *originalString = [FRACurrentText substringWithRange:selectedRange];
		NSString *newString = [NSString stringWithString:[originalString uppercaseString]];
		[textView setSelectedRange:selectedRange];
		[textView insertText:newString replacementRange:[textView selectedRange]];
	}
}


- (IBAction)capitaliseAction:(id)sender
{
	NSTextView *textView = FRACurrentTextView;
	NSArray *array = [textView selectedRanges];
	for (id item in array) {
		NSRange selectedRange = [item rangeValue];
		NSString *originalString = [FRACurrentText substringWithRange:selectedRange];
		NSString *newString = [NSString stringWithString:[originalString capitalizedString]];
		[textView setSelectedRange:selectedRange];
		[textView insertText:newString replacementRange:[textView selectedRange]];
	}
}


- (IBAction)entabAction:(id)sender
{
	[[FRAExtraInterfaceController sharedInstance] displayEntab];
}


- (IBAction)detabAction:(id)sender
{
	[[FRAExtraInterfaceController sharedInstance] displayDetab];
}


- (void)performEntab
{	
	NSTextView *textView = FRACurrentTextView;
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] setReactToChanges:NO];
	NSRange selectedRange;
	NSRange savedRange = [textView selectedRange];
	
	NSArray *array = [FRACurrentTextView selectedRanges];
	NSMutableString *searchString = [NSMutableString string];
	NSInteger numberOfSpaces = [[FRADefaults valueForKey:@"SpacesPerTabEntabDetab"] integerValue];
	while (numberOfSpaces--) {
		[searchString appendString:@" "];
	}
	NSMutableString *completeString = [NSMutableString stringWithString:[textView string]];
	NSInteger sumOfRemovedCharacters = 0;
	for (id item in array) {
		selectedRange = NSMakeRange([item rangeValue].location - sumOfRemovedCharacters, [item rangeValue].length);
	
		sumOfRemovedCharacters = sumOfRemovedCharacters + ([completeString replaceOccurrencesOfString:searchString withString:@"\t" options:NSLiteralSearch range:selectedRange] * ([searchString length] - 1));
		
		if ([textView shouldChangeTextInRange:NSMakeRange(0, [[textView string] length]) replacementString:completeString]) { // Do it this way to mark it as an Undo
			[textView replaceCharactersInRange:NSMakeRange(0, [[textView string] length]) withString:completeString];
			[textView didChangeText];
		}

	}
	
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] setReactToChanges:YES];
	
	if ([[FRACurrentDocument valueForKey:@"isEdited"] boolValue] == NO) {
		[FRAVarious hasChangedDocument:FRACurrentDocument];
	}
	
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] pageRecolour]; 

	[textView setSelectedRange:NSMakeRange(savedRange.location, 0)];
}


- (void)performDetab
{	
	NSTextView *textView = FRACurrentTextView;
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] setReactToChanges:NO];
	NSRange selectedRange;
	NSRange savedRange = [textView selectedRange];
	
	NSArray *array = [FRACurrentTextView selectedRanges];
	NSMutableString *replacementString = [NSMutableString string];
	NSInteger numberOfSpaces = [[FRADefaults valueForKey:@"SpacesPerTabEntabDetab"] integerValue];
	while (numberOfSpaces--) {
		[replacementString appendString:@" "];
	}
	NSMutableString *completeString = [NSMutableString stringWithString:[textView string]];
	NSInteger sumOfInsertedCharacters = 0;
	for (id item in array) {
		selectedRange = NSMakeRange([item rangeValue].location + sumOfInsertedCharacters, [item rangeValue].length);
		
		sumOfInsertedCharacters = sumOfInsertedCharacters + ([completeString replaceOccurrencesOfString:@"\t" withString:replacementString options:NSLiteralSearch range:selectedRange] * ([replacementString length] - 1));
		
		if ([textView shouldChangeTextInRange:NSMakeRange(0, [[textView string] length]) replacementString:completeString]) { // Do it this way to mark it as an Undo
			[textView replaceCharactersInRange:NSMakeRange(0, [[textView string] length]) withString:completeString];
			[textView didChangeText];
		}
		
	}
	
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] setReactToChanges:YES];
	
	if ([[FRACurrentDocument valueForKey:@"isEdited"] boolValue] == NO) {
		[FRAVarious hasChangedDocument:FRACurrentDocument];
	}
	
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] pageRecolour]; 
	[textView setSelectedRange:NSMakeRange(savedRange.location, 0)];
}


- (IBAction)goToLineAction:(id)sender
{
	[[FRAExtraInterfaceController sharedInstance] displayGoToLine];
}


- (void)performGoToLine:(NSInteger)lineToGoTo
{
	NSInteger lineNumber;
	NSInteger index;
	NSString *completeString = FRACurrentText;
	NSInteger completeStringLength = [completeString length];
	NSInteger numberOfLinesInDocument;
	for (index = 0, numberOfLinesInDocument = 1; index < completeStringLength; numberOfLinesInDocument++) {
		index = NSMaxRange([completeString lineRangeForRange:NSMakeRange(index, 0)]);
	}
	if (lineToGoTo > numberOfLinesInDocument) {
		NSBeep();
		return;
	}
	
	for (index = 0, lineNumber = 1; lineNumber < lineToGoTo; lineNumber++) {
		index = NSMaxRange([completeString lineRangeForRange:NSMakeRange(index, 0)]);
	}
	
	[FRACurrentTextView setSelectedRange:[completeString lineRangeForRange:NSMakeRange(index, 0)]];
	[FRACurrentTextView scrollRangeToVisible:[completeString lineRangeForRange:NSMakeRange(index, 0)]];
}


- (IBAction)closeTagAction:(id)sender
{
	NSTextView *textView = FRACurrentTextView;
	
	NSRange selectedRange = [textView selectedRange];
	if (selectedRange.length > 0) {
		NSBeep();
		return;
	}
	
	NSInteger location = selectedRange.location;
	NSString *completeString = [textView string];
	BOOL foundClosingBrace = NO;
	BOOL foundOpeningBrace = NO;
	
	while (location--) { // First check that there is a closing c i.e. >
		if ([completeString characterAtIndex:location] == '>') {
			foundClosingBrace = YES;
			break;
		}
	}
	
	if (!foundClosingBrace) {
		NSBeep();
		return;
	}
	
	NSInteger locationOfClosingBrace = location;
	NSInteger numberOfClosingTags = 0;
	
	while (location--) { // Then check for the opening brace i.e. <
		if ([completeString characterAtIndex:location] == '<') {
			// Divide into four checks as otherwise it will miss to skip the tag if it comes absolutely last in the document  
			if (location + 4 <= [completeString length]) { // Check that the tag is not one of the tags that aren't closed e.g. <br> or any of their variants
				NSString *checkString = [completeString substringWithRange:NSMakeRange(location, 4)];
				NSRange searchRange = NSMakeRange(0, [checkString length]);
				if ([checkString rangeOfString:@"<br>" options:NSCaseInsensitiveSearch range:searchRange].location != NSNotFound) {
					continue;
				} else if ([checkString rangeOfString:@"<hr>" options:NSCaseInsensitiveSearch range:searchRange].location != NSNotFound) {
					continue;
				} else if ([checkString rangeOfString:@"<!--" options:NSCaseInsensitiveSearch range:searchRange].location != NSNotFound) {
					continue;
				} else if ([checkString rangeOfString:@"<?" options:NSCaseInsensitiveSearch range:searchRange].location != NSNotFound) {
					continue;
				} else if ([checkString rangeOfString:@"<%" options:NSCaseInsensitiveSearch range:searchRange].location != NSNotFound) {
					continue;
				}
			}
			
			if (location + 5 <= [completeString length]) { // Check that the tag is not one of the tags that aren't closed e.g. <br> or any of their variants
				NSString *checkString = [completeString substringWithRange:NSMakeRange(location, 5)];
				NSRange searchRange = NSMakeRange(0, [checkString length]);
				if ([checkString rangeOfString:@"<img " options:NSCaseInsensitiveSearch range:searchRange].location != NSNotFound) {
					continue;
				} else if ([checkString rangeOfString:@"<br/>" options:NSCaseInsensitiveSearch range:searchRange].location != NSNotFound) {
					continue;
				}
			}
			
			if (location + 6 <= [completeString length]) { // Check that the tag is not one of the tags that aren't closed e.g. <br> or any of their variants
				NSString *checkString = [completeString substringWithRange:NSMakeRange(location, 6)];
				NSRange searchRange = NSMakeRange(0, [checkString length]);
				if ([checkString rangeOfString:@"<br />" options:NSCaseInsensitiveSearch range:searchRange].location != NSNotFound) {
					continue;
				} else if ([checkString rangeOfString:@"<hr />" options:NSCaseInsensitiveSearch range:searchRange].location != NSNotFound) {
					continue;
				} else if ([checkString rangeOfString:@"<area " options:NSCaseInsensitiveSearch range:searchRange].location != NSNotFound) {
					continue;
				} else if ([checkString rangeOfString:@"<base " options:NSCaseInsensitiveSearch range:searchRange].location != NSNotFound) {
					continue;
				} else if ([checkString rangeOfString:@"<link " options:NSCaseInsensitiveSearch range:searchRange].location != NSNotFound) {
					continue;
				} else if ([checkString rangeOfString:@"<meta " options:NSCaseInsensitiveSearch range:searchRange].location != NSNotFound) {
					continue;
				}
			}
			
			if (location + 7 < [completeString length]) { // check that the tag is not one of the tags that aren't closed e.g. <br> and their variants
				NSString *checkString = [completeString substringWithRange:NSMakeRange(location, 7)];
				NSRange searchRange = NSMakeRange(0, [checkString length]);
				if ([checkString rangeOfString:@"<frame " options:NSCaseInsensitiveSearch range:searchRange].location != NSNotFound) {
					continue;
				} else if ([checkString rangeOfString:@"<input " options:NSCaseInsensitiveSearch range:searchRange].location != NSNotFound) {
					continue;
				} else if ([checkString rangeOfString:@"<param " options:NSCaseInsensitiveSearch range:searchRange].location != NSNotFound) {
					continue;
				}
			}
			
			NSScanner *selfClosingScanner = [NSScanner scannerWithString:[completeString substringWithRange:NSMakeRange(location, locationOfClosingBrace - location)]];
			[selfClosingScanner setCharactersToBeSkipped:nil];
			NSString *selfClosingScanString = [NSString string];
			[selfClosingScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@">"] intoString:&selfClosingScanString]; 
			
			if ([selfClosingScanString length] != 0) {
				if ([selfClosingScanString characterAtIndex:([selfClosingScanString length] - 1)] == '/') {
					continue;
				}
			}
			
			if ([completeString characterAtIndex:location + 1] == '/') { // If it's a closing tag (e.g. </a>) continue the search
				numberOfClosingTags++; 
				continue;
			} else {				
				if (numberOfClosingTags) { // Try to find the "correct" tag to close by counting the number of closing tags and when they match up insert the created closing tag; if they don't write balanced code - well, tough luck...
					numberOfClosingTags--;
				} else {
					foundOpeningBrace = YES;
					break;
				}
			}
		}
	}
	
	if (foundOpeningBrace == NO) {
		NSBeep();
		return;
	}
	
	NSScanner *scanner = [NSScanner scannerWithString:[completeString substringWithRange:NSMakeRange(location, locationOfClosingBrace - location)]];
	[scanner setCharactersToBeSkipped:nil];
	NSString *scanString = [NSString string];
	[scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" >/"] intoString:&scanString]; // Set the string to everything up to any of the characters (space),> or / so that it will catch things like <a href... as well as <br>
	
	NSMutableString *tagString = [NSMutableString stringWithString:scanString];
	NSInteger tagStringLength = [tagString length];
	if (tagStringLength == 0) {
		NSBeep();
		return;
	}
	
	[tagString insertString:@"/" atIndex:1];
	[tagString insertString:@">" atIndex:tagStringLength + 1];
	
	if ([textView shouldChangeTextInRange:selectedRange replacementString:tagString]) { // Do it this way to mark it as an Undo
		[textView replaceCharactersInRange:selectedRange withString:tagString];
		[textView didChangeText];
	}
}


- (IBAction)commentOrUncommentAction:(id)sender
{
	NSTextView *textView = FRACurrentTextView;
	NSString *completeString = [textView string];
	NSString *commentString = [[FRACurrentDocument valueForKey:@"syntaxColouring"] valueForKey:@"firstSingleLineComment"];
	NSInteger commentStringLength = [commentString length];
	if ([commentString isEqualToString:@""] || [completeString length] < commentStringLength) {
		NSBeep();
		return;
	}
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] setReactToChanges:NO];	
	
	NSArray *array = [textView selectedRanges];
	NSRange selectedRange;
	NSInteger sumOfChangedCharacters = 0;
	NSMutableArray *updatedSelectionsArray = [NSMutableArray array];
	for (id item in array) {
		selectedRange = NSMakeRange([item rangeValue].location + sumOfChangedCharacters, [item rangeValue].length);
	
		NSInteger tempLocation = selectedRange.location;
		NSInteger maxSelectedRange = NSMaxRange(selectedRange);
		NSInteger numberOfLines = 0;
		NSInteger locationOfFirstLine = [completeString lineRangeForRange:NSMakeRange(tempLocation, 0)].location;
		
		BOOL shouldUncomment = NO;
		NSInteger searchLength = commentStringLength;
		if ((tempLocation + commentStringLength) > [completeString length]) {
			searchLength = 0;
		}
		
		if ([completeString rangeOfString:commentString options:NSCaseInsensitiveSearch range:NSMakeRange(tempLocation, searchLength)].location != NSNotFound) {
			shouldUncomment = YES; // The first line of the selection is already commented and thus we should uncomment
		} else if ([completeString rangeOfString:commentString options:NSCaseInsensitiveSearch range:NSMakeRange(locationOfFirstLine, searchLength)].location != NSNotFound) {
			shouldUncomment = YES; // Check the beginning of the line too
		} else { // Also check the first character after the whitespace
			NSInteger firstCharacterOfFirstLine = locationOfFirstLine;
			while ([completeString characterAtIndex:firstCharacterOfFirstLine] == ' ' || [completeString characterAtIndex:firstCharacterOfFirstLine] == '\t') {
				firstCharacterOfFirstLine++;
			}
			if ([completeString rangeOfString:commentString options:NSCaseInsensitiveSearch range:NSMakeRange(firstCharacterOfFirstLine, searchLength)].location != NSNotFound) {
				shouldUncomment = YES;
			}
		}
		
		do {
			tempLocation = NSMaxRange([completeString lineRangeForRange:NSMakeRange(tempLocation, 0)]);
			numberOfLines++;
		} while (tempLocation < maxSelectedRange);
		NSInteger locationOfLastLine = tempLocation;
		
		tempLocation = selectedRange.location;
		NSInteger index;
		NSInteger charactersInserted = 0;
		NSRange rangeOfLine;
		NSInteger firstCharacterOfLine;
		
		for (index = 0; index < numberOfLines; index++) {
			rangeOfLine = [completeString lineRangeForRange:NSMakeRange(tempLocation, 0)];
			if (shouldUncomment == NO) {
				if ([textView shouldChangeTextInRange:NSMakeRange(rangeOfLine.location, 0) replacementString:commentString]) { // Do it this way to mark it as an Undo
					[textView replaceCharactersInRange:NSMakeRange(rangeOfLine.location, 0) withString:commentString];
					[textView didChangeText];
				}			
				charactersInserted = charactersInserted + commentStringLength;
			} else {
				firstCharacterOfLine = rangeOfLine.location;
				while ([completeString characterAtIndex:firstCharacterOfLine] == ' ' || [completeString characterAtIndex:firstCharacterOfLine] == '\t') {
					firstCharacterOfLine++;
				}
				if ([completeString rangeOfString:commentString options:NSCaseInsensitiveSearch range:NSMakeRange(firstCharacterOfLine, [commentString length])].location != NSNotFound) {
					if ([textView shouldChangeTextInRange:NSMakeRange(firstCharacterOfLine, commentStringLength) replacementString:@""]) { // Do it this way to mark it as an Undo
						[textView replaceCharactersInRange:NSMakeRange(firstCharacterOfLine, commentStringLength) withString:@""];
						[textView didChangeText];
					}		
					charactersInserted = charactersInserted - commentStringLength;
				}
			}
			tempLocation = NSMaxRange([completeString lineRangeForRange:NSMakeRange(tempLocation, 0)]);
		}
		sumOfChangedCharacters = sumOfChangedCharacters + charactersInserted;
		[updatedSelectionsArray addObject:[NSValue valueWithRange:NSMakeRange(locationOfFirstLine, locationOfLastLine - locationOfFirstLine + charactersInserted)]];
	}
	
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] setReactToChanges:YES];
	
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] pageRecolour];
	
	if ([[FRACurrentDocument valueForKey:@"isEdited"] boolValue] == NO) {
		[FRAVarious hasChangedDocument:FRACurrentDocument];
	}
	
	[[FRACurrentDocument valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth:NO recolour:NO];
	
	if (selectedRange.length > 0) {
		[textView setSelectedRanges:updatedSelectionsArray];
	}

}


- (IBAction)emptyDummyAction:(id)sender
{
	// An easy way to enable menu items with submenus without setting an action which actually does something
}


- (void)reloadText:(id)sender
{
	id document = FRACurrentDocument;
	[document setValue: @([sender tag]) forKey:@"encoding"];
	[document setValue:[NSString localizedNameOfStringEncoding:[sender tag]] forKey:@"encodingName"];
	[[FRAFileMenuController sharedInstance] performRevertOfDocument:document];
}


- (IBAction)removeLineEndingsAction:(id)sender
{
	NSTextView *textView = FRACurrentTextView;
	NSString *text = [textView string];
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] setReactToChanges:NO];	
	NSArray *array = [textView selectedRanges];
	NSInteger sumOfDeletedLineEndings = 0;
	NSMutableArray *updatedSelectionsArray = [NSMutableArray array];
	for (id item in array) {
		NSRange selectedRange = NSMakeRange([item rangeValue].location - sumOfDeletedLineEndings, [item rangeValue].length);
		NSString *stringToRemoveLineEndingsFrom = [text substringWithRange:selectedRange];
		NSInteger originalLength = [stringToRemoveLineEndingsFrom length];
		NSString *stringWithNoLineEndings = [FRAText removeAllLineEndingsInString:stringToRemoveLineEndingsFrom];
		NSInteger newLength = [stringWithNoLineEndings length];
		if ([textView shouldChangeTextInRange:NSMakeRange(selectedRange.location, originalLength) replacementString:stringWithNoLineEndings]) { // Do it this way to mark it as an Undo
			[textView replaceCharactersInRange:NSMakeRange(selectedRange.location, originalLength) withString:stringWithNoLineEndings];
			[textView didChangeText];
		}			
		sumOfDeletedLineEndings = sumOfDeletedLineEndings + (originalLength - newLength);
		
		[updatedSelectionsArray addObject:[NSValue valueWithRange:NSMakeRange(selectedRange.location, newLength)]];
	}
	
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] setReactToChanges:YES];
	
	if ([[FRACurrentDocument valueForKey:@"isEdited"] boolValue] == NO) {
		[FRAVarious hasChangedDocument:FRACurrentDocument];
	}
	
	[[FRACurrentDocument valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth:YES recolour:YES];
	
	if ([updatedSelectionsArray count] > 0) {
		[textView setSelectedRanges:updatedSelectionsArray];
	}
}


- (IBAction)changeLineEndingsAction:(id)sender
{
	id document = FRACurrentDocument;
	
	[[[document valueForKey:@"syntaxColouring"] undoManager] registerUndoWithTarget:self selector:@selector(performUndoChangeLineEndings:) object:@[[document valueForKey:@"lineEndings"]]];
	[[[document valueForKey:@"syntaxColouring"] undoManager] setActionName:NAME_FOR_UNDO_CHANGE_LINE_ENDINGS];
	
	[document setValue:@([sender tag] - 150) forKey:@"lineEndings"];
	
	NSTextView *textView = FRACurrentTextView;
	NSRange selectedRange = [textView selectedRange];
	NSString *text = [textView string];
	NSString *convertedString = [FRAText convertLineEndings:text inDocument:document];
	[textView replaceCharactersInRange:NSMakeRange(0, [text length]) withString:convertedString];
	[textView setSelectedRange:selectedRange];
	
	[[document valueForKey:@"syntaxColouring"] pageRecolour];
	
	[FRAVarious hasChangedDocument:document];
}


- (void)performUndoChangeLineEndings:(id)sender
{
	id document = FRACurrentDocument;
	
	[[[document valueForKey:@"syntaxColouring"] undoManager] registerUndoWithTarget:self selector:@selector(performUndoChangeLineEndings:) object:@[[document valueForKey:@"lineEndings"]]];
	[[[document valueForKey:@"syntaxColouring"] undoManager] setActionName:NAME_FOR_UNDO_CHANGE_LINE_ENDINGS];
	
	[document setValue:sender[0] forKey:@"lineEndings"];
	
	NSTextView *textView = FRACurrentTextView;
	NSRange selectedRange = [textView selectedRange];
	NSString *text = [textView string];
	NSString *convertedString = [FRAText convertLineEndings:text inDocument:document];
	[textView replaceCharactersInRange:NSMakeRange(0, [text length]) withString:convertedString];
	[textView setSelectedRange:selectedRange];
	
	[[document valueForKey:@"syntaxColouring"] pageRecolour];
	
	[FRAVarious hasChangedDocument:document];
}


- (IBAction)interchangeAdjacentCharactersAction:(id)sender
{
	NSTextView *textView = FRACurrentTextView;
	[textView transpose:nil];
}


- (IBAction)prepareForXMLAction:(id)sender
{
	NSTextView *textView = FRACurrentTextView;
	NSRange selectedRange = [textView selectedRange];
	NSMutableString *stringToConvert = [NSMutableString stringWithString:[[textView string] substringWithRange:selectedRange]];
	[stringToConvert replaceOccurrencesOfString:@"&amp;" withString:@"&" options:NSLiteralSearch range:NSMakeRange(0, [stringToConvert length])];
	[stringToConvert replaceOccurrencesOfString:@"&" withString:@"&amp;" options:NSLiteralSearch range:NSMakeRange(0, [stringToConvert length])];
	[stringToConvert replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:NSMakeRange(0, [stringToConvert length])];
	[stringToConvert replaceOccurrencesOfString:@">" withString:@"&gt;" options:NSLiteralSearch range:NSMakeRange(0, [stringToConvert length])];
	if ([textView shouldChangeTextInRange:selectedRange replacementString:stringToConvert]) { // Do it this way to mark it as an Undo
		[textView replaceCharactersInRange:selectedRange withString:stringToConvert];
		[textView didChangeText];
	}	
}

/**
 * This method duplicates the current line.
 */
- (IBAction)duplicateLineAction:(id)sender
{
	NSTextView *textView = FRACurrentTextView;
	NSString *completeString = [textView string];
	
	if ([completeString length] < 1) {
		return;
	}
	
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] setReactToChanges:NO];
	
	NSArray *selectedArray = [FRACurrentTextView selectedRanges];
	
	id selection = selectedArray[0];

	NSRange lineRange = [completeString lineRangeForRange:[selection rangeValue]];
	NSString *lineString = [completeString substringWithRange:lineRange];
	
	NSString *lastSymbol = [lineString substringFromIndex:([lineString length] - 1)];
	NSString *replacementString;
	
	// If the last symbol is a line ending one, we don't have to append one.
	if ([lastSymbol isEqualToString:[FRAText darkSideLineEnding]] 
		|| [lastSymbol isEqualToString:[FRAText unixLineEnding]] 
		|| [lastSymbol isEqualToString:[FRAText macLineEnding]]) {
		replacementString = [NSString stringWithFormat:@"%@%@", lineString, lineString];
	}
	else {
		NSInteger lineEndings;
		if ([[FRACurrentDocument valueForKey:@"lineEndings"] integerValue] == 0) { // It hasn't been changed by the user so use the one from the defaults
			lineEndings = [[FRADefaults valueForKey:@"LineEndingsPopUp"] integerValue] + 1;
		} else {
			lineEndings = [[FRACurrentDocument valueForKey:@"lineEndings"] integerValue];
		}
		
		if (lineEndings == FRADarkSideLineEndings) {
			replacementString = [NSString stringWithFormat:@"%@%@%@", lineString, [FRAText darkSideLineEnding], lineString];
		}
		else if (lineEndings == FRAMacLineEndings) {
			replacementString = [NSString stringWithFormat:@"%@%@%@", lineString, [FRAText macLineEnding], lineString];
		}
		else {
			replacementString = [NSString stringWithFormat:@"%@%@%@", lineString, [FRAText unixLineEnding], lineString];
		}
	}
	
	if ([textView shouldChangeTextInRange:lineRange replacementString:replacementString]) { // Do it this way to mark it as an Undo
		[textView replaceCharactersInRange:lineRange withString:replacementString];
		[textView didChangeText];
	}
	
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] setReactToChanges:YES];
	
	[[FRACurrentDocument valueForKey:@"syntaxColouring"] pageRecolour];
	
	if ([[FRACurrentDocument valueForKey:@"isEdited"] boolValue] == NO) {
		[FRAVarious hasChangedDocument:FRACurrentDocument];
	}
	
	[[FRACurrentDocument valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth:NO recolour:NO];
		
}


- (IBAction)changeSyntaxDefinitionAction:(id)sender
{
	id document = FRACurrentDocument;
	[document setValue:[sender title] forKey:@"syntaxDefinition"];
	[document setValue:@YES forKey:@"hasManuallyChangedSyntaxDefinition"];
	[[document valueForKey:@"syntaxColouring"] setSyntaxDefinition];
	
	[[document valueForKey:@"syntaxColouring"] pageRecolour];
	[FRAInterface updateStatusBar];
}
@end
