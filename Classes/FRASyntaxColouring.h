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
@class FRALayoutManager;
@class ICUPattern;
@class ICUMatcher;

@interface FRASyntaxColouring : NSObject <NSTextStorageDelegate> {
	
	NSUndoManager *undoManager;
	FRALayoutManager *firstLayoutManager, *secondLayoutManager, *thirdLayoutManager, *fourthLayoutManager;
	
	NSTimer *autocompleteWordsTimer;
	NSInteger currentYOfSelectedCharacter, lastYOfSelectedCharacter, currentYOfLastCharacterInLine, lastYOfLastCharacterInLine, currentYOfLastCharacter, lastYOfLastCharacter, lastCursorLocation;
	
	NSCharacterSet *letterCharacterSet, *keywordStartCharacterSet, *keywordEndCharacterSet;
	
	NSDictionary *commandsColour, *commentsColour, *instructionsColour, *keywordsColour, *autocompleteWordsColour, *stringsColour, *variablesColour, *attributesColour, *lineHighlightColour;
	
	NSEnumerator *wordEnumerator;
	NSSet *keywords;
	NSSet *autocompleteWords;
	NSArray *keywordsAndAutocompleteWords;
	BOOL keywordsCaseSensitive;
	BOOL recolourKeywordIfAlreadyColoured;
	NSString *beginCommand;
	NSString *endCommand;
	NSString *beginInstruction;
	NSString *endInstruction;
	NSCharacterSet *beginVariable;
	NSCharacterSet *endVariable;
	NSString *firstString;
	unichar firstStringUnichar;
	NSString *secondString;
	unichar secondStringUnichar;
	NSString *firstSingleLineComment, *secondSingleLineComment, *beginFirstMultiLineComment, *endFirstMultiLineComment, *beginSecondMultiLineComment, *endSecondMultiLineComment, *functionDefinition, *removeFromFunction;
	
	NSString *completeString;
	NSString *searchString;
	NSScanner *scanner;
	NSScanner *completeDocumentScanner;	
	NSInteger beginning, end, endOfLine, index, length, searchStringLength, commandLocation, skipEndCommand, beginLocationInMultiLine, endLocationInMultiLine, searchSyntaxLength, rangeLocation;
	NSRange rangeOfLine;
	NSString *keyword;
	BOOL shouldOnlyColourTillTheEndOfLine;
	unichar commandCharacterTest;
	unichar beginCommandCharacter;
	unichar endCommandCharacter;
	BOOL shouldColourMultiLineStrings;
	BOOL foundMatch;
	NSInteger completeStringLength;
	unichar characterToCheck;
	NSRange editedRange;
	NSInteger cursorLocation;
	NSInteger differenceBetweenLastAndPresent;
	NSInteger skipMatchingBrace;
	NSRect visibleRect;
	NSRange visibleRange;
	NSInteger beginningOfFirstVisibleLine;
	NSInteger endOfLastVisibleLine;
	NSRange selectedRange;;
	NSInteger stringLength;
	NSString *keywordTestString;
	NSString *autocompleteTestString;
	NSRange searchRange;
	NSInteger maxRange;
	
	NSTextContainer *textContainer;
	
	BOOL reactToChanges;
	
	id document;
	
	NSCharacterSet *attributesCharacterSet;
	
	ICUPattern *firstStringPattern;
	ICUPattern *secondStringPattern;
	
	ICUMatcher *firstStringMatcher;
	ICUMatcher *secondStringMatcher;
	
	NSRange foundRange;
	
	NSTimer *liveUpdatePreviewTimer;
	
	NSRange lastLineHighlightRange;
}

//@property ICUPattern *firstStringPattern;
//@property ICUPattern *secondStringPattern;
//
//@property ICUMatcher *firstStringMatcher;
//@property ICUMatcher *secondStringMatcher;

//@property NSSet *keywords;
//@property NSSet *autocompleteWords;
//@property NSArray *keywordsAndAutocompleteWords;
//
//@property BOOL keywordsCaseSensitive;
//@property BOOL recolourKeywordIfAlreadyColoured;
@property BOOL reactToChanges;

//@property NSEnumerator *wordEnumerator;

@property (copy) NSString *functionDefinition;
@property (copy) NSString *removeFromFunction;

@property (assign) FRALayoutManager *secondLayoutManager;
@property (assign) FRALayoutManager *thirdLayoutManager;
@property (assign) FRALayoutManager *fourthLayoutManager;

@property (readonly) NSUndoManager *undoManager;
//@property (readonly) NSDictionary *highlightColour;



- (id)initWithDocument:(id)document;

- (void)setColours;
- (void)setSyntaxDefinition;
- (void)prepareRegularExpressions;
- (void)recolourRange:(NSRange)range;

- (void)removeAllColours;
- (void)removeColoursFromRange:(NSRange)range;

- (NSString *)guessSyntaxDefinitionFromFirstLine:(NSString *)firstLine;

- (void)pageRecolour;
- (void)pageRecolourTextView:(FRATextView *)textView;

- (void)setColour:(NSDictionary *)colour range:(NSRange)range;
- (void)highlightLineRange:(NSRange)lineRange;


@end
