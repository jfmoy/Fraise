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

#import "SMLPrintTextView.h"
#import "SMLProjectsController.h"
#import "SMLProject.h"
#import "SMLLayoutManager.h"
#import "SMLSyntaxColouring.h"

@implementation SMLPrintTextView

- (id)initWithFrame:(NSRect)frame
{
	if (self = [super initWithFrame:frame]) {
		//[self setupView];
	}
	return self;
}


- (NSString *)printJobTitle
{
	return [SMLCurrentDocument valueForKey:@"name"];
}


- (void)drawRect:(NSRect)rect
{
	[self setupView];
	
	[super drawRect:rect];
	
}



- (void)drawPageBorderWithSize:(NSSize)borderSize
{	
	NSPrintInfo *printInfo = [SMLCurrentProject printInfo];
	if ([printInfo topMargin] != [printInfo bottomMargin]) { // We should print a header
		NSString *headerString = [NSString stringWithFormat:@"%ld   %C   %@   %C   %@   %C   %@", [[NSPrintOperation currentOperation] currentPage], 0x00B7, [SMLCurrentDocument valueForKey:@"name"], 0x00B7, [[NSDate date] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M" timeZone:nil locale:nil], 0x00B7, NSFullUserName()];
		
		NSRect savedTextRect = [self frame];	
		[self setFrame:NSMakeRect(0, 0, borderSize.width, borderSize.height)];
		[self setFrameOrigin:NSMakePoint(0.0, 0.0)]; // It seems one needs to set this twice otherwise only the first header is visible
		[self setFrameSize:borderSize];
		
		[self lockFocus];
		[headerString drawAtPoint:NSMakePoint([printInfo leftMargin], [[SMLDefaults valueForKey:@"MarginsMin"] integerValue]) withAttributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:10.0] forKey:NSFontAttributeName]];
		[NSBezierPath setDefaultLineWidth:1.0];
		[NSBezierPath strokeLineFromPoint:NSMakePoint([printInfo leftMargin], [[SMLDefaults valueForKey:@"MarginsMin"] integerValue] + 14) toPoint:NSMakePoint([printInfo paperSize].width - [printInfo leftMargin], [[SMLDefaults valueForKey:@"MarginsMin"] integerValue] + 14)];
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


- (void)setupView
{
	NSPrintInfo *printInfo = [SMLCurrentProject printInfo];
	
	[self setFrame:NSMakeRect([printInfo leftMargin], [printInfo bottomMargin], [printInfo paperSize].width - [printInfo leftMargin] - [printInfo rightMargin], [printInfo paperSize].height - [printInfo topMargin] - [printInfo bottomMargin])];
	
	
	// Set the tabs
	NSMutableString *sizeString = [NSMutableString string];
	NSUInteger numberOfSpaces = [[SMLDefaults valueForKey:@"TabWidth"] integerValue];
	while (numberOfSpaces--) {
		[sizeString appendString:@" "];
	}
	NSDictionary *sizeAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:@"PrintFont"]], NSFontAttributeName, nil];
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
	
	if ([SMLCurrentProject areThereAnyDocuments]) {
		if ([[SMLDefaults valueForKey:@"OnlyPrintSelection"] boolValue] == YES && [SMLCurrentTextView selectedRange].length > 0) {
			[self setString:[SMLCurrentText substringWithRange:[SMLCurrentTextView selectedRange]]];
			printOnlySelection = YES;
			selectionLocation = [SMLCurrentTextView selectedRange].location;
		} else {
			[self setString:SMLCurrentText];
		}
		
		if ([[SMLCurrentDocument valueForKey:@"isSyntaxColoured"] boolValue] == YES && [[SMLDefaults valueForKey:@"PrintSyntaxColours"] boolValue] == YES) {
			SMLTextView *textView = [SMLCurrentDocument valueForKey:@"firstTextView"];
			SMLLayoutManager *layoutManager = (SMLLayoutManager *)[textView layoutManager];
			NSTextStorage *textStorage = [self textStorage];
			NSInteger lastCharacter = [[textView string] length];
			[layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0, lastCharacter)];
			NSInteger index = 0;
			if (printOnlySelection == YES) {
				index = [SMLCurrentTextView selectedRange].location;
				lastCharacter = NSMaxRange([SMLCurrentTextView selectedRange]);
				[[SMLCurrentDocument valueForKey:@"syntaxColouring"] recolourRange:[SMLCurrentTextView selectedRange]];
			} else {
				[[SMLCurrentDocument valueForKey:@"syntaxColouring"] recolourRange:NSMakeRange(0, lastCharacter)];
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
	
	[self setFont:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:@"PrintFont"]]];
	
}

@end
