/*
Fraise version 3.7 - Based on Smultron by Peter Borg
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Fraise

Copyright 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "FRAStandardHeader.h"

#import "FRAPrintTextView.h"
#import "FRAProjectsController.h"
#import "FRAProject.h"
#import "FRALayoutManager.h"
#import "FRASyntaxColouring.h"

@implementation FRAPrintTextView

- (id)initWithFrame:(NSRect)frame
{
	if (self = [super initWithFrame:frame]) {
		[self setupView];
	}
	return self;
}


- (NSString *)printJobTitle
{
	return [FRACurrentDocument valueForKey:@"name"];
}

- (void)drawPageBorderWithSize:(NSSize)borderSize
{	
	NSPrintInfo *printInfo = [FRACurrentProject printInfo];
	if ([printInfo topMargin] != [printInfo bottomMargin]) { // We should print a header
		NSString *headerString = [NSString stringWithFormat:@"%ld   %C   %@   %C   %@   %C   %@", [[NSPrintOperation currentOperation] currentPage], 0x00B7, [FRACurrentDocument valueForKey:@"name"], 0x00B7, [[NSDate date] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M" timeZone:nil locale:nil], 0x00B7, NSFullUserName()];
		
		NSRect savedTextRect = [self frame];	
		[self setFrame:NSMakeRect(0, 0, borderSize.width, borderSize.height)];
		[self setFrameOrigin:NSMakePoint(0.0, 0.0)]; // It seems one needs to set this twice otherwise only the first header is visible
		[self setFrameSize:borderSize];
		
		[self lockFocus];
		[headerString drawAtPoint:NSMakePoint([printInfo leftMargin], [[FRADefaults valueForKey:@"MarginsMin"] integerValue]) withAttributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:10.0] forKey:NSFontAttributeName]];
		[NSBezierPath setDefaultLineWidth:1.0];
		[NSBezierPath strokeLineFromPoint:NSMakePoint([printInfo leftMargin], [[FRADefaults valueForKey:@"MarginsMin"] integerValue] + 14) toPoint:NSMakePoint([printInfo paperSize].width - [printInfo leftMargin], [[FRADefaults valueForKey:@"MarginsMin"] integerValue] + 14)];
		[self unlockFocus];
		
		[self setFrame:savedTextRect];
	}
}


- (BOOL)isFlipped
{
	return YES;
}


- (BOOL)isOpaque
{
	return YES;
}

/**
 * Setup the view used for printing regarding current application settings specified by the
 * user.
 **/
- (void)setupView
{
	NSPrintInfo *printInfo = [FRACurrentProject printInfo];
	
	[self setFrame:NSMakeRect([printInfo leftMargin], [printInfo bottomMargin], [printInfo paperSize].width - [printInfo leftMargin] - [printInfo rightMargin], [printInfo paperSize].height - [printInfo topMargin] - [printInfo bottomMargin])];
	
	
	// Set the tabs
	NSMutableString *sizeString = [NSMutableString string];
	NSUInteger numberOfSpaces = [[FRADefaults valueForKey:@"TabWidth"] integerValue];
	while (numberOfSpaces--) {
		[sizeString appendString:@" "];
	}
	NSDictionary *sizeAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"PrintFont"]], NSFontAttributeName, nil];
	CGFloat sizeOfTab = [sizeString sizeWithAttributes:sizeAttribute].width;
	
	NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	NSArray *array = [style tabStops];
	for (id item in array) {
		[style removeTabStop:item];
	}
	
	[style setDefaultTabInterval:sizeOfTab];
	NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:style, NSParagraphStyleAttributeName, nil];
	[self setTypingAttributes:attributes];
	
	BOOL printOnlySelection = NO;
	NSInteger selectionLocation = 0;
	
	if ([FRACurrentProject areThereAnyDocuments]) {
		if ([[FRADefaults valueForKey:@"OnlyPrintSelection"] boolValue] == YES && [FRACurrentTextView selectedRange].length > 0) {
			[self setString:[FRACurrentText substringWithRange:[FRACurrentTextView selectedRange]]];
			printOnlySelection = YES;
			selectionLocation = [FRACurrentTextView selectedRange].location;
		} else {
			[self setString:FRACurrentText];
		}
		
		if ([[FRACurrentDocument valueForKey:@"isSyntaxColoured"] boolValue] == YES && [[FRADefaults valueForKey:@"PrintSyntaxColours"] boolValue] == YES) {
			FRATextView *textView = [FRACurrentDocument valueForKey:@"firstTextView"];
			FRALayoutManager *layoutManager = (FRALayoutManager *)[textView layoutManager];
			NSTextStorage *textStorage = [self textStorage];
			NSInteger lastCharacter = [[textView string] length];
			[layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0, lastCharacter)];
			NSInteger index = 0;
			if (printOnlySelection == YES) {
				index = [FRACurrentTextView selectedRange].location;
				lastCharacter = NSMaxRange([FRACurrentTextView selectedRange]);
				[[FRACurrentDocument valueForKey:@"syntaxColouring"] recolourRange:[FRACurrentTextView selectedRange]];
			} else {
				[[FRACurrentDocument valueForKey:@"syntaxColouring"] recolourRange:NSMakeRange(0, lastCharacter)];
			}
			NSRange range;
			NSDictionary *attributes;
			NSInteger rangeLength = 0;
			while (index < lastCharacter) {
				attributes = [layoutManager temporaryAttributesAtCharacterIndex:index effectiveRange:&range];
				rangeLength = range.length;
				if ([attributes count] != 0) {
					if (printOnlySelection == YES) {
						[textStorage setAttributes:attributes range:NSMakeRange(range.location - selectionLocation, rangeLength)];
					} else {
						[textStorage setAttributes:attributes range:range];
					}
				}
				if (rangeLength != 0) {
					index = index + rangeLength;
				} else {
					index++;
				}
			}
		}
	}
	
	[self setFont:[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"PrintFont"]]];
	
}

@end
