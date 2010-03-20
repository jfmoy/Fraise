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

@interface FRALineNumbers : NSObject {

	id document;	
	NSPoint zeroPoint;
	NSDictionary *attributes;
	
	FRATextView *textView;
	NSScrollView *scrollView;
	NSScrollView *gutterScrollView;
	NSLayoutManager *layoutManager;
	NSRect visibleRect;
	NSRange visibleRange;
	NSString *textString;
	NSString *searchString;
	
	NSInteger index;
	NSInteger lineNumber;
	
	NSInteger indexNonWrap;
	NSInteger maxRangeVisibleRange;
	NSInteger numberOfGlyphsInTextString;
	BOOL oneMoreTime;
	unichar lastGlyph;

	NSRange range;
	NSInteger widthOfStringInGutter;
	NSInteger gutterWidth;
	NSRect currentViewBounds;
	NSInteger gutterY;

	NSInteger currentLineHeight;
	
	CGFloat addToScrollPoint;
}

- (id)initWithDocument:(id)theDocument;

- (void)updateLineNumbersCheckWidth:(BOOL)checkWidth recolour:(BOOL)recolour;
- (void)updateLineNumbersForClipView:(NSClipView *)clipView checkWidth:(BOOL)checkWidth recolour:(BOOL)recolour;

@end
