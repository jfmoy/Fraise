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

#import "FRAPrintTextView.h"
#import "FRAProjectsController.h"
#import "FRAProject.h"
#import "FRALayoutManager.h"
#import "FRASyntaxColouring.h"
#import "FRATextView.h"

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
    NSPrintInfo *printInfo = [[NSPrintOperation currentOperation] printInfo];
    
    if ([[FRADefaults valueForKey:@"PrintHeader"] boolValue] == YES) {
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
        NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
        unichar separator = 0x00B7;
        
		NSString *headerString = [NSString stringWithFormat:@"%ld   %C   %@   %C   %@   %C   %@",
                                  [[NSPrintOperation currentOperation] currentPage],
                                  separator,
                                  [FRACurrentDocument valueForKey:@"name"],
                                  separator,
                                  dateString,
                                  separator,
                                  NSFullUserName()];
        
        NSInteger marginsMin = [[FRADefaults valueForKey:@"MarginsMin"] integerValue];
		
		[self lockFocus];
		[headerString drawAtPoint:NSMakePoint([printInfo leftMargin], marginsMin)
                   withAttributes:@{NSFontAttributeName: [NSFont systemFontOfSize:10.0]}];
		[NSBezierPath setDefaultLineWidth:1.0];
		[NSBezierPath strokeLineFromPoint:NSMakePoint([printInfo leftMargin], marginsMin + 14)
                                  toPoint:NSMakePoint([printInfo paperSize].width - [printInfo leftMargin], marginsMin + 14)];
		[self unlockFocus];
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

- (BOOL)knowsPageRange:(NSRangePointer)range {
    NSPrintInfo *printInfo = [[NSPrintOperation currentOperation] printInfo];

    [self setFont:[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"PrintFont"]]];
    
    [self setFrame:NSMakeRect([printInfo leftMargin], [printInfo bottomMargin], [printInfo paperSize].width - [printInfo leftMargin] - [printInfo rightMargin], [printInfo paperSize].height - [printInfo topMargin] - [printInfo bottomMargin])];

    if ([FRACurrentProject areThereAnyDocuments]) {
        bool shouldPrintSelection = [[FRADefaults valueForKey:@"OnlyPrintSelection"] boolValue] && [FRACurrentTextView selectedRange].length > 0;
        bool textInvalid = !initialized || (printSelection != shouldPrintSelection);
        
        bool shouldPrintSyntaxColor = [[FRACurrentDocument valueForKey:@"isSyntaxColoured"] boolValue] == YES && [[FRADefaults valueForKey:@"PrintSyntaxColours"] boolValue] == YES;
        bool printSyntaxColoursInvalid = textInvalid || (printSyntaxColours != shouldPrintSyntaxColor);
        
        if (textInvalid) {
            printSelection = shouldPrintSelection;
            if (printSelection == YES) {
                [self setString:[FRACurrentText substringWithRange:[FRACurrentTextView selectedRange]]];
                selectionLocation = [FRACurrentTextView selectedRange].location;
            } else {
                [self setString:FRACurrentText];
                selectionLocation = 0;
            }
        }
        
        if (printSyntaxColoursInvalid) {
            printSyntaxColours = shouldPrintSyntaxColor;
            
            FRATextView *textView = [FRACurrentDocument valueForKey:@"firstTextView"];
            NSTextStorage *textStorage = [self textStorage];
            [textStorage setAttributes:nil range:NSMakeRange(0, [[self string] length])];
            
            if (printSyntaxColours) {
                FRALayoutManager *layoutManager = (FRALayoutManager *)[textView layoutManager];
                NSInteger lastCharacter = [[textView string] length];
                [layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0, lastCharacter)];
                NSInteger index = 0;
                if (printSelection) {
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
                        if (printSelection) {
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
    }
    
    initialized = true;

    return [super knowsPageRange:range];
}

/**
 * Setup the view used for printing regarding current application settings specified by the
 * user.
 **/
- (void)setupView
{
	// Set the tabs
	NSMutableString *sizeString = [NSMutableString string];
	NSUInteger numberOfSpaces = [[FRADefaults valueForKey:@"TabWidth"] integerValue];
	while (numberOfSpaces--) {
		[sizeString appendString:@" "];
	}
	NSDictionary *sizeAttribute = @{NSFontAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"PrintFont"]]};
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

@end
