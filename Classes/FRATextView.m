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

#import "FRATextView.h"
#import "FRALayoutManager.h"
#import "FRATextMenuController.h"
#import "FRAProjectsController.h"
#import "FRABasicPerformer.h"
#import "FRAToolsMenuController.h"
#import "FRAFileMenuController.h"
#import "FRALineNumbers.h"


@implementation FRATextView

@synthesize colouredIBeamCursor;

- (id)initWithFrame:(NSRect)frame
{
	if (self = [super initWithFrame:frame]) {
		FRALayoutManager *layoutManager = [[FRALayoutManager alloc] init];
		[[self textContainer] replaceLayoutManager:layoutManager];
		
		[self setDefaults];		
	}
	return self;
}


- (void)setDefaults
{
	[self setTabWidth];
	
	[self setVerticallyResizable:YES];
	[self setMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
	[self setAutoresizingMask:NSViewWidthSizable];
	[self setAllowsUndo:YES];
	[self setUsesFindPanel:YES];
	[self setAllowsDocumentBackgroundColorChange:NO];
	[self setRichText:NO];
	[self setImportsGraphics:NO];
	[self setUsesFontPanel:NO];
	
	[self setContinuousSpellCheckingEnabled:[[FRADefaults valueForKey:@"AutoSpellCheck"] boolValue]];
	[self setGrammarCheckingEnabled:[[FRADefaults valueForKey:@"AutoGrammarCheck"] boolValue]];
	
	[self setSmartInsertDeleteEnabled:[[FRADefaults valueForKey:@"SmartInsertDelete"] boolValue]];
	[self setAutomaticLinkDetectionEnabled:[[FRADefaults valueForKey:@"AutomaticLinkDetection"] boolValue]];
	[self setAutomaticQuoteSubstitutionEnabled:[[FRADefaults valueForKey:@"AutomaticQuoteSubstitution"] boolValue]];
	
	[self setFont:[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]]];
	[self setTextColor:[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextColourWell"]]];
	[self setInsertionPointColor:[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextColourWell"]]];
	[self setBackgroundColor:[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"BackgroundColourWell"]]];
	
	[self setAutomaticDataDetectionEnabled:YES];
	[self setAutomaticTextReplacementEnabled:YES];
	
	[self setPageGuideValues];
	
	[self updateIBeamCursor];	
	NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:[self frame] options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveWhenFirstResponder) owner:self userInfo:nil];
	[self addTrackingArea:trackingArea];
	
	NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	[defaultsController addObserver:self forKeyPath:@"values.TextFont" options:NSKeyValueObservingOptionNew context:@"TextFontChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.TextColourWell" options:NSKeyValueObservingOptionNew context:@"TextColourChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.BackgroundColourWell" options:NSKeyValueObservingOptionNew context:@"BackgroundColourChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.SmartInsertDelete" options:NSKeyValueObservingOptionNew context:@"SmartInsertDeleteChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.TabWidth" options:NSKeyValueObservingOptionNew context:@"TabWidthChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.ShowPageGuide" options:NSKeyValueObservingOptionNew context:@"PageGuideChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.ShowPageGuideAtColumn" options:NSKeyValueObservingOptionNew context:@"PageGuideChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.SmartInsertDelete" options:NSKeyValueObservingOptionNew context:@"SmartInsertDeleteChanged"];
	
	lineHeight = [[[self textContainer] layoutManager] defaultLineHeightForFont:[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]]];
}


- (void) dealloc
{
    NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    [defaultsController removeObserver:self forKeyPath:@"values.TextFont"];
    [defaultsController removeObserver:self forKeyPath:@"values.TextColourWell"];
    [defaultsController removeObserver:self forKeyPath:@"values.BackgroundColourWell"];
    [defaultsController removeObserver:self forKeyPath:@"values.SmartInsertDelete"];
    [defaultsController removeObserver:self forKeyPath:@"values.TabWidth"];
    [defaultsController removeObserver:self forKeyPath:@"values.ShowPageGuide"];
    [defaultsController removeObserver:self forKeyPath:@"values.ShowPageGuideAtColumn"];
    [defaultsController removeObserver:self forKeyPath:@"values.SmartInsertDelete"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([(__bridge NSString *)context isEqualToString:@"TextFontChanged"]) {
		[self setFont:[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]]];
		lineHeight = [[[self textContainer] layoutManager] defaultLineHeightForFont:[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]]];
		[[FRACurrentDocument valueForKey:@"lineNumbers"] updateLineNumbersForClipView:[[self enclosingScrollView] contentView] checkWidth:NO recolour:YES];
		[self setPageGuideValues];
	} else if ([(__bridge NSString *)context isEqualToString:@"TextColourChanged"]) {
		[self setTextColor:[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextColourWell"]]];
		[self setInsertionPointColor:[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextColourWell"]]];
		[self setPageGuideValues];
		[self updateIBeamCursor];
	} else if ([(__bridge NSString *)context isEqualToString:@"BackgroundColourChanged"]) {
		[self setBackgroundColor:[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"BackgroundColourWell"]]];
	} else if ([(__bridge NSString *)context isEqualToString:@"SmartInsertDeleteChanged"]) {
		[self setSmartInsertDeleteEnabled:[[FRADefaults valueForKey:@"SmartInsertDelete"] boolValue]];
	} else if ([(__bridge NSString *)context isEqualToString:@"TabWidthChanged"]) {
		[self setTabWidth];
	} else if ([(__bridge NSString *)context isEqualToString:@"PageGuideChanged"]) {
		[self setPageGuideValues];
	} else if ([(__bridge NSString *)context isEqualToString:@"SmartInsertDeleteChanged"]) {
		[self setSmartInsertDeleteEnabled:[[FRADefaults valueForKey:@"SmartInsertDelete"] boolValue]];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


- (void)insertNewline:(id)sender
{
	[super insertNewline:sender];
	
	// If we should indent automatically, check the previous line and scan all the whitespace at the beginning of the line into a string and insert that string into the new line
	NSString *lastLineString = [[self string] substringWithRange:[[self string] lineRangeForRange:NSMakeRange([self selectedRange].location - 1, 0)]];
	if ([[FRADefaults valueForKey:@"IndentNewLinesAutomatically"] boolValue] == YES) {
		NSString *previousLineWhitespaceString;
		NSScanner *previousLineScanner = [[NSScanner alloc] initWithString:[[self string] substringWithRange:[[self string] lineRangeForRange:NSMakeRange([self selectedRange].location - 1, 0)]]];
		[previousLineScanner setCharactersToBeSkipped:nil];		
		if ([previousLineScanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&previousLineWhitespaceString]) {
            [self insertText:previousLineWhitespaceString replacementRange:[self selectedRange]];
		}
		
		if ([[FRADefaults valueForKey:@"AutomaticallyIndentBraces"] boolValue] == YES) {
			NSCharacterSet *characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
			NSInteger index = [lastLineString length];
			while (index--) {
				if ([characterSet characterIsMember:[lastLineString characterAtIndex:index]]) {
					continue;
				}
				if ([lastLineString characterAtIndex:index] == '{') {
					[self insertTab:nil];
				}
				break;
			}
		}
	}
}


- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity
{
	if (granularity != NSSelectByWord || [[self string] length] == proposedSelRange.location || [[NSApp currentEvent] clickCount] != 2) { // If it's not a double-click return unchanged
		return [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
	}
	
	NSInteger location = [super selectionRangeForProposedRange:proposedSelRange granularity:NSSelectByCharacter].location;
	NSInteger originalLocation = location;

	NSString *completeString = [self string];
	unichar characterToCheck = [completeString characterAtIndex:location];
	NSInteger skipMatchingBrace = 0;
	NSInteger lengthOfString = [completeString length];
	if (lengthOfString == proposedSelRange.location) { // To avoid crash if a double-click occurs after any text
		return [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
	}
	
	BOOL triedToMatchBrace = NO;
	
	if (characterToCheck == ')') {
		triedToMatchBrace = YES;
		while (location--) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '(') {
				if (!skipMatchingBrace) {
					return NSMakeRange(location, originalLocation - location + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == ')') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '}') {
		triedToMatchBrace = YES;
		while (location--) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '{') {
				if (!skipMatchingBrace) {
					return NSMakeRange(location, originalLocation - location + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '}') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == ']') {
		triedToMatchBrace = YES;
		while (location--) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '[') {
				if (!skipMatchingBrace) {
					return NSMakeRange(location, originalLocation - location + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == ']') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '>') {
		triedToMatchBrace = YES;
		while (location--) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '<') {
				if (!skipMatchingBrace) {
					return NSMakeRange(location, originalLocation - location + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '>') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '(') {
		triedToMatchBrace = YES;
		while (++location < lengthOfString) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == ')') {
				if (!skipMatchingBrace) {
					return NSMakeRange(originalLocation, location - originalLocation + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '(') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '{') {
		triedToMatchBrace = YES;
		while (++location < lengthOfString) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '}') {
				if (!skipMatchingBrace) {
					return NSMakeRange(originalLocation, location - originalLocation + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '{') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '[') {
		triedToMatchBrace = YES;
		while (++location < lengthOfString) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == ']') {
				if (!skipMatchingBrace) {
					return NSMakeRange(originalLocation, location - originalLocation + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '[') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	} else if (characterToCheck == '<') {
		triedToMatchBrace = YES;
		while (++location < lengthOfString) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '>') {
				if (!skipMatchingBrace) {
					return NSMakeRange(originalLocation, location - originalLocation + 1);
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '<') {
				skipMatchingBrace++;
			}
		}
		NSBeep();
	}

	// If it has a found a "starting" brace but not found a match, a double-click should only select the "starting" brace and not what it usually would select at a double-click
	if (triedToMatchBrace) {
		return [super selectionRangeForProposedRange:NSMakeRange(proposedSelRange.location, 1) granularity:NSSelectByCharacter];
	} else {
		
		NSInteger startLocation = originalLocation;
		NSInteger stopLocation = originalLocation;
		NSInteger minLocation = [super selectionRangeForProposedRange:proposedSelRange granularity:NSSelectByWord].location;
		NSInteger maxLocation = NSMaxRange([super selectionRangeForProposedRange:proposedSelRange granularity:NSSelectByWord]);
		
		BOOL hasFoundSomething = NO;
		while (--startLocation >= minLocation) {
			if ([completeString characterAtIndex:startLocation] == '.' || [completeString characterAtIndex:startLocation] == ':') {
				hasFoundSomething = YES;
				break;
			}
		}
		
		while (++stopLocation < maxLocation) {
			if ([completeString characterAtIndex:stopLocation] == '.' || [completeString characterAtIndex:stopLocation] == ':') {
				hasFoundSomething = YES;
				break;
			}
		}
		
		if (hasFoundSomething == YES) {
			return NSMakeRange(startLocation + 1, stopLocation - startLocation - 1);
		} else {
			return [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
		}
	}
}


-(BOOL)isOpaque
{
	return YES;
}


- (void)insertTab:(id)sender
{	
	BOOL shouldShiftText = NO;
	
	if ([self selectedRange].length > 0) { // Check to see if the selection is in the text or if it's at the beginning of a line or in whitespace; if one doesn't do this one shifts the line if there's only one suggestion in the auto-complete
		NSRange rangeOfFirstLine = [[self string] lineRangeForRange:NSMakeRange([self selectedRange].location, 0)];
		NSInteger firstCharacterOfFirstLine = rangeOfFirstLine.location;
		while ([[self string] characterAtIndex:firstCharacterOfFirstLine] == ' ' || [[self string] characterAtIndex:firstCharacterOfFirstLine] == '\t') {
			firstCharacterOfFirstLine++;
		}
		if ([self selectedRange].location <= firstCharacterOfFirstLine) {
			shouldShiftText = YES;
		}
	}
	
	if (shouldShiftText) {
		[[FRATextMenuController sharedInstance] shiftRightAction:nil];
	} else if ([[FRADefaults valueForKey:@"IndentWithSpaces"] boolValue] == YES) {
		NSMutableString *spacesString = [NSMutableString string];
		NSInteger numberOfSpacesPerTab = [[FRADefaults valueForKey:@"TabWidth"] integerValue];
		if ([[FRADefaults valueForKey:@"UseTabStops"] boolValue] == YES) {
			NSInteger locationOnLine = [self selectedRange].location - [[self string] lineRangeForRange:[self selectedRange]].location;
			if (numberOfSpacesPerTab != 0) {
				NSInteger numberOfSpacesLess = locationOnLine % numberOfSpacesPerTab;
				numberOfSpacesPerTab = numberOfSpacesPerTab - numberOfSpacesLess;
			}
		}
		while (numberOfSpacesPerTab--) {
			[spacesString appendString:@" "];
		}
		
		[self insertText:spacesString replacementRange:[self selectedRange]];
	} else if ([self selectedRange].length > 0) { // If there's only one word matching in auto-complete there's no list but just the rest of the word inserted and selected; and if you do a normal tab then the text is removed so this will put the cursor at the end of that word
		[self setSelectedRange:NSMakeRange(NSMaxRange([self selectedRange]), 0)];
	} else {
		[super insertTab:sender];
	}
}


- (void)mouseDown:(NSEvent *)theEvent
{
	if (([theEvent modifierFlags] & NSEventModifierFlagOption) && ([theEvent modifierFlags] & NSEventModifierFlagCommand)) { // If the option and command keys are pressed, change the cursor to grab-cursor
		startPoint = [theEvent locationInWindow];
		startOrigin = [[[self enclosingScrollView] contentView] documentVisibleRect].origin;
		[[self enclosingScrollView] setDocumentCursor:[NSCursor openHandCursor]];
	} else {
		[super mouseDown:theEvent];
	}
}


- (void)mouseDragged:(NSEvent *)theEvent
{
    if ([[NSCursor currentCursor] isEqual:[NSCursor openHandCursor]]) {
		[self scrollPoint:NSMakePoint(startOrigin.x - ([theEvent locationInWindow].x - startPoint.x) * 3, startOrigin.y + ([theEvent locationInWindow].y - startPoint.y) * 3)];
	} else {
		[super mouseDragged:theEvent];
	}
}


- (void)mouseUp:(NSEvent *)theEvent
{
	[[self enclosingScrollView] setDocumentCursor:[NSCursor IBeamCursor]];
}


- (NSInteger)lineHeight
{
    return lineHeight;
}


- (void)setTabWidth
{
	// Set the width of every tab by first checking the size of the tab in spaces in the current font and then remove all tabs that sets automatically and then set the default tab stop distance
	NSMutableString *sizeString = [NSMutableString string];
	NSInteger numberOfSpaces = [[FRADefaults valueForKey:@"TabWidth"] integerValue];
	while (numberOfSpaces--) {
		[sizeString appendString:@" "];
	}
	NSDictionary *sizeAttribute = @{NSFontAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]]};
	CGFloat sizeOfTab = [sizeString sizeWithAttributes:sizeAttribute].width;
	
	NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	
	NSArray *array = [style tabStops];
	for (id item in array) {
		[style removeTabStop:item];
	}
	[style setDefaultTabInterval:sizeOfTab];
	NSDictionary *attributes = @{NSParagraphStyleAttributeName: style};
	[self setTypingAttributes:attributes];
}


- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
	
	if (showPageGuide == YES) {
		NSRect bounds = [self bounds]; 
		if ([self needsToDrawRect:NSMakeRect(pageGuideX, 0, 1, bounds.size.height)] == YES) { // So that it doesn't draw the line if only e.g. the cursor updates
			[pageGuideColour set];
			[NSBezierPath strokeRect:NSMakeRect(pageGuideX, 0, 0, bounds.size.height)];
		}
	}
}


- (void)setPageGuideValues
{
	NSDictionary *sizeAttribute = @{NSFontAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]]};
	NSString *sizeString = @" ";
	CGFloat sizeOfCharacter = [sizeString sizeWithAttributes:sizeAttribute].width;
	pageGuideX = (sizeOfCharacter * ([[FRADefaults valueForKey:@"ShowPageGuideAtColumn"] integerValue] + 1)) - 1.5; // -1.5 to put it between the two characters and draw only on one pixel and not two (as the system draws it in a special way), and that's also why the width above is set to zero 
	
	NSColor *color = [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextColourWell"]];
	pageGuideColour = [color colorWithAlphaComponent:([color alphaComponent] / 4)]; // Use the same colour as the text but with more transparency
	
	showPageGuide = [[FRADefaults valueForKey:@"ShowPageGuide"] boolValue];
	
	[self display]; // To reflect the new values in the view
}


- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange
{
	if ([aString isEqualToString:@"}"] && [[FRADefaults valueForKey:@"IndentNewLinesAutomatically"] boolValue] == YES && [[FRADefaults valueForKey:@"AutomaticallyIndentBraces"] boolValue] == YES) {
		unichar characterToCheck;
		NSInteger location = [self selectedRange].location;
		NSString *completeString = [self string];
		NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
		NSRange currentLineRange = [completeString lineRangeForRange:NSMakeRange([self selectedRange].location, 0)];
		NSInteger lineLocation = location;
		NSInteger lineStart = currentLineRange.location;
		while (--lineLocation >= lineStart) { // If there are any characters before } on the line skip indenting
			if ([whitespaceCharacterSet characterIsMember:[completeString characterAtIndex:lineLocation]]) {
				continue;
			}
            [super insertText:aString replacementRange:replacementRange];
			return;
		}
		
		BOOL hasInsertedBrace = NO;
		NSUInteger skipMatchingBrace = 0;
		while (location--) {
			characterToCheck = [completeString characterAtIndex:location];
			if (characterToCheck == '{') {
				if (skipMatchingBrace == 0) { // If we have found the opening brace check first how much space is in front of that line so the same amount can be inserted in front of the new line
					NSString *openingBraceLineWhitespaceString;
					NSScanner *openingLineScanner = [[NSScanner alloc] initWithString:[completeString substringWithRange:[completeString lineRangeForRange:NSMakeRange(location, 0)]]];
					[openingLineScanner setCharactersToBeSkipped:nil];
					BOOL foundOpeningBraceWhitespace = [openingLineScanner scanCharactersFromSet:whitespaceCharacterSet intoString:&openingBraceLineWhitespaceString];
					
					if (foundOpeningBraceWhitespace == YES) {
						NSMutableString *newLineString = [NSMutableString stringWithString:openingBraceLineWhitespaceString];
						[newLineString appendString:@"}"];
						[newLineString appendString:[completeString substringWithRange:NSMakeRange([self selectedRange].location, NSMaxRange(currentLineRange) - [self selectedRange].location)]];
						if ([self shouldChangeTextInRange:currentLineRange replacementString:newLineString]) {
							[self replaceCharactersInRange:currentLineRange withString:newLineString];
							[self didChangeText];
						}
						hasInsertedBrace = YES;
						[self setSelectedRange:NSMakeRange(currentLineRange.location + [openingBraceLineWhitespaceString length] + 1, 0)]; // +1 because we have inserted a character
					} else {
						NSString *restOfLineString = [completeString substringWithRange:NSMakeRange([self selectedRange].location, NSMaxRange(currentLineRange) - [self selectedRange].location)];
						if ([restOfLineString length] != 0) { // To fix a bug where text after the } can be deleted
							NSMutableString *replaceString = [NSMutableString stringWithString:@"}"];
							[replaceString appendString:restOfLineString];
							hasInsertedBrace = YES;
							NSInteger lengthOfWhiteSpace = 0;
							if (foundOpeningBraceWhitespace == YES) {
								lengthOfWhiteSpace = [openingBraceLineWhitespaceString length];
							}
							if ([self shouldChangeTextInRange:currentLineRange replacementString:replaceString]) {
								[self replaceCharactersInRange:[completeString lineRangeForRange:currentLineRange] withString:replaceString];
								[self didChangeText];
							}
							[self setSelectedRange:NSMakeRange(currentLineRange.location + lengthOfWhiteSpace + 1, 0)]; // +1 because we have inserted a character
						} else {
							[self replaceCharactersInRange:[completeString lineRangeForRange:currentLineRange] withString:@""]; // Remove whitespace before }
						}
				
					}
					break;
				} else {
					skipMatchingBrace--;
				}
			} else if (characterToCheck == '}') {
				skipMatchingBrace++;
			}
		}
		if (hasInsertedBrace == NO) {
			[super insertText:aString replacementRange:replacementRange];
		}
	} else if ([aString isEqualToString:@"("] && [[FRADefaults valueForKey:@"AutoInsertAClosingParenthesis"] boolValue] == YES) {
		[super insertText:aString replacementRange:replacementRange];
		NSRange selectedRange = [self selectedRange];
		if ([self shouldChangeTextInRange:selectedRange replacementString:@")"]) {
			[self replaceCharactersInRange:selectedRange withString:@")"];
			[self didChangeText];
			[self setSelectedRange:NSMakeRange(selectedRange.location - 0, 0)];
		}
	} else if ([aString isEqualToString:@"{"] && [[FRADefaults valueForKey:@"AutoInsertAClosingBrace"] boolValue] == YES) {
		[super insertText:aString replacementRange:replacementRange];
		NSRange selectedRange = [self selectedRange];
		if ([self shouldChangeTextInRange:selectedRange replacementString:@"}"]) {
			[self replaceCharactersInRange:selectedRange withString:@"}"];
			[self didChangeText];
			[self setSelectedRange:NSMakeRange(selectedRange.location - 0, 0)];
		}
	} else {
		[super insertText:aString replacementRange:replacementRange];
	}
}


- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSMenu *menu = [super menuForEvent:theEvent];

	NSArray *array = [menu itemArray];
	for (id oldMenuItem in array) {
		if ([oldMenuItem tag] == -123457) {
			[menu removeItem:oldMenuItem];
		}		
	}
	
	[menu insertItem:[NSMenuItem separatorItem] atIndex:0];
	
	NSEnumerator *collectionEnumerator = [[FRABasic fetchAll:@"SnippetCollectionSortKeyName"] reverseObjectEnumerator];
	for (id collection in collectionEnumerator) {
		if ([collection valueForKey:@"name"] == nil) {
			continue;
		}
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[collection valueForKey:@"name"] action:nil keyEquivalent:@""];
		[menuItem setTag:-123457];
		NSMenu *subMenu = [[NSMenu alloc] init];
		
		NSMutableArray *array = [NSMutableArray arrayWithArray:[[collection mutableSetValueForKey:@"snippets"] allObjects]];
		[array sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
		for (id snippet in array) {
			if ([snippet valueForKey:@"name"] == nil) {
				continue;
			}
			NSString *keyString;
			if ([snippet valueForKey:@"shortcutMenuItemKeyString"] != nil) {
				keyString = [snippet valueForKey:@"shortcutMenuItemKeyString"];
			} else {
				keyString = @"";
			}
            NSMenuItem *subMenuItem = [[NSMenuItem alloc] initWithTitle:[snippet valueForKey:@"name"] action:@selector(snippetShortcutFired:) keyEquivalent:@""];
			[subMenuItem setTarget:[FRAToolsMenuController sharedInstance]];			
			[subMenuItem setRepresentedObject:snippet];
			[subMenu insertItem:subMenuItem atIndex:0];
		}
		
		[menuItem setSubmenu:subMenu];
		[menu insertItem:menuItem atIndex:0];
	}
	
	return menu;
	
}


- (IBAction)save:(id)sender
{
	[[FRAFileMenuController sharedInstance] saveAction:nil];
}


- (void)updateIBeamCursor
{
	NSColor *textColour = [[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextColourWell"]] colorUsingColorSpaceName:NSCalibratedWhiteColorSpace];
	
	if (textColour != nil && [textColour whiteComponent] == 0.0 && [textColour alphaComponent] == 1.0) { // Keep the original cursor if it's black
		[self setColouredIBeamCursor:[NSCursor IBeamCursor]];
	} else {
		NSImage *cursorImage = [[NSCursor IBeamCursor] image];
		[cursorImage lockFocus];
		[(NSColor *)[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextColourWell"]] set];
		NSRectFillUsingOperation(NSMakeRect(0, 0, [cursorImage size].width, [cursorImage size].height), NSCompositingOperationSourceAtop);
		[cursorImage unlockFocus];
		[self setColouredIBeamCursor:[[NSCursor alloc] initWithImage:cursorImage hotSpot:[[NSCursor IBeamCursor] hotSpot]]];
	}
}


- (void)cursorUpdate:(NSEvent *)event
{
	[colouredIBeamCursor set];
}
	

- (void)mouseMoved:(NSEvent *)theEvent
{
	if ([NSCursor currentCursor] == [NSCursor IBeamCursor]) {
		[colouredIBeamCursor set];
	}
}


- (void)performFindPanelAction:(id)sender
{
	[super performFindPanelAction:sender];
}

@end
