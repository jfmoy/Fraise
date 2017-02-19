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

#import "FRALineNumbers.h"
#import "FRASyntaxColouring.h"
#import "FRAProjectsController.h"
#import "FRAProject.h"
#import "FRATextView.h"

@implementation FRALineNumbers

- (id)init
{
	if (!(self = [self initWithDocument:nil])) return nil;
	
	return self;
}


- (id)initWithDocument:(id)theDocument
{
	if (self = [super init]) {
		
		document = theDocument;
		zeroPoint = NSMakePoint(0, 0);
		
		attributes = @{NSFontAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]]};
		NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
		[defaultsController addObserver:self forKeyPath:@"values.TextFont" options:NSKeyValueObservingOptionNew context:@"TextFontChanged"];
	}
	
    return self;
}


- (void) dealloc
{
    NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    [defaultsController removeObserver:self forKeyPath:@"values.TextFont"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([(__bridge NSString *)context isEqualToString:@"TextFontChanged"]) {
		attributes = @{NSFontAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]]};
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


- (void)viewBoundsDidChange:(NSNotification *)notification
{
	if (notification != nil && [notification object] != nil && [[notification object] isKindOfClass:[NSClipView class]]) {
		[self updateLineNumbersForClipView:[notification object] checkWidth:YES recolour:YES];
	}
}


- (void)updateLineNumbersCheckWidth:(BOOL)checkWidth recolour:(BOOL)recolour
{
	[self updateLineNumbersForClipView:[[document valueForKey:@"firstTextScrollView"] contentView] checkWidth:checkWidth recolour:recolour];

	if ([document valueForKey:@"secondTextScrollView"] != nil) {
		[self updateLineNumbersForClipView:[[document valueForKey:@"secondTextScrollView"] contentView] checkWidth:checkWidth recolour:recolour];
	}
	
	if ([document valueForKey:@"singleDocumentWindow"] != nil) {
		[self updateLineNumbersForClipView:[[document valueForKey:@"thirdTextScrollView"] contentView] checkWidth:checkWidth recolour:recolour];
	}
	
	if ([document valueForKey:@"fourthTextScrollView"] != nil) {
		[self updateLineNumbersForClipView:[[document valueForKey:@"fourthTextScrollView"] contentView] checkWidth:checkWidth recolour:recolour];
	}
}


- (void)updateLineNumbersForClipView:(NSClipView *)clipView checkWidth:(BOOL)checkWidth recolour:(BOOL)recolour
{
	textView = [clipView documentView];
	
	if ([[document valueForKey:@"showLineNumberGutter"] boolValue] == NO || textView == nil) {
		if (checkWidth == YES && recolour == YES) {
			[[document valueForKey:@"syntaxColouring"] pageRecolourTextView:textView];
		}
		return;
	}
	
	scrollView = (NSScrollView *)[clipView superview];
	addToScrollPoint = 0;	
	if (scrollView == [document valueForKey:@"firstTextScrollView"]) {
		gutterScrollView = [document valueForKey:@"firstGutterScrollView"];
	} else if (scrollView == [document valueForKey:@"secondTextScrollView"]) {
		gutterScrollView = [document valueForKey:@"secondGutterScrollView"];
		addToScrollPoint = [[FRACurrentProject secondContentViewNavigationBar] bounds].size.height;
	} else if (scrollView == [document valueForKey:@"thirdTextScrollView"]) {
		gutterScrollView = [document valueForKey:@"thirdGutterScrollView"];
	} else if (scrollView == [document valueForKey:@"fourthTextScrollView"]) {
		gutterScrollView = [document valueForKey:@"fourthGutterScrollView"];
	} else {
		return;
	}
	
	layoutManager = [textView layoutManager];
	visibleRect = [[scrollView contentView] documentVisibleRect];
	visibleRange = [layoutManager glyphRangeForBoundingRect:visibleRect inTextContainer:[textView textContainer]];
	textString = [textView string];
    if (visibleRange.location > textString.length) {
        visibleRange.location = textString.length;
    }
    if (visibleRange.location + visibleRange.length > textString.length) {
        visibleRange.length = textString.length - visibleRange.location;
    }
	searchString = [textString substringWithRange:NSMakeRange(0,visibleRange.location)];
	
    for (index = 0, lineNumber = 0; index < visibleRange.location; lineNumber++) {
		index = NSMaxRange([searchString lineRangeForRange:NSMakeRange(index, 0)]);
	}
	
	indexNonWrap = [searchString lineRangeForRange:NSMakeRange(index, 0)].location;
	maxRangeVisibleRange = NSMaxRange([textString lineRangeForRange:NSMakeRange(NSMaxRange(visibleRange), 0)]); // Set it to just after the last glyph on the last visible line
	numberOfGlyphsInTextString = [layoutManager numberOfGlyphs];
	oneMoreTime = NO;
	if (numberOfGlyphsInTextString != 0) {
        if (numberOfGlyphsInTextString <= textString.length) {
            lastGlyph = [textString characterAtIndex:numberOfGlyphsInTextString - 1];
        }
        else {
            lastGlyph = [textString characterAtIndex:textString.length - 1];
        }
		if (lastGlyph == '\n' || lastGlyph == '\r') {
			oneMoreTime = YES; // Continue one more time through the loop if the last glyph isn't newline
		}
	}
	NSMutableString *lineNumbersString = [[NSMutableString alloc] init];
    
	while (indexNonWrap <= maxRangeVisibleRange) {
		if (index == indexNonWrap) {
			lineNumber++;
			[lineNumbersString appendFormat:@"%ld\n", lineNumber];
		} else {
			[lineNumbersString appendFormat:@"%C\n", 0x00B7];
			indexNonWrap = index;
		}
		
		if (index < maxRangeVisibleRange) {
			[layoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&range];
			index = NSMaxRange(range);
			indexNonWrap = NSMaxRange([textString lineRangeForRange:NSMakeRange(indexNonWrap, 0)]);
		} else {
			index++;
			indexNonWrap ++;
		}
		
		if (index == numberOfGlyphsInTextString && !oneMoreTime) {
			break;
		}
	}
	
	if (checkWidth == YES) {
		widthOfStringInGutter = [lineNumbersString sizeWithAttributes:attributes].width;
		
		if (widthOfStringInGutter > ([[document valueForKey:@"gutterWidth"] integerValue] - 14)) { // Check if the gutterTextView has to be resized
			[document setValue:@(widthOfStringInGutter + 20) forKey:@"gutterWidth"]; // Make it bigger than need be so it doesn't have to resized soon again
			if ([[document valueForKey:@"showLineNumberGutter"] boolValue] == YES) {
				gutterWidth = [[document valueForKey:@"gutterWidth"] integerValue];
			} else {
				gutterWidth = 0;
			}
			currentViewBounds = [[gutterScrollView superview] bounds];
			[scrollView setFrame:NSMakeRect(gutterWidth, 0, currentViewBounds.size.width - gutterWidth, currentViewBounds.size.height)];
			
			[gutterScrollView setFrame:NSMakeRect(0, 0, [[document valueForKey:@"gutterWidth"] integerValue], currentViewBounds.size.height)];
		}
	}
	
	if (recolour == YES) {
		[[document valueForKey:@"syntaxColouring"] pageRecolourTextView:textView];
	}
	
	[[gutterScrollView documentView] setString:lineNumbersString];
	
	[[gutterScrollView contentView] setBoundsOrigin:zeroPoint]; // To avert an occasional bug which makes the line numbers disappear
	currentLineHeight = (NSInteger)[textView lineHeight];
	if ((NSInteger)visibleRect.origin.y != 0 && currentLineHeight != 0) {
		[[gutterScrollView contentView] scrollToPoint:NSMakePoint(0, ((NSInteger)visibleRect.origin.y % currentLineHeight) + addToScrollPoint)]; // Move currentGutterScrollView so it aligns with the rows in currentTextView
	}
}
@end
