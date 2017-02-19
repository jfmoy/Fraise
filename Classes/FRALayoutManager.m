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

#import "FRALayoutManager.h"

@implementation FRALayoutManager

@synthesize showsInvisibleChars;

- (id)init
{
	if (self = [super init]) {
		
		attributes = @{NSFontAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]], NSForegroundColorAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"InvisibleCharactersColourWell"]]};
        unichar spaceUnichar = 0x02FD;
        spaceCharacter = [[NSString alloc] initWithCharacters:&spaceUnichar length:1];
		unichar tabUnichar = 0x2192;
		tabCharacter = [[NSString alloc] initWithCharacters:&tabUnichar length:1];
		unichar newLineUnichar = 0x00B6;
		newLineCharacter = [[NSString alloc] initWithCharacters:&newLineUnichar length:1];
		
		self.showsInvisibleChars = [[FRADefaults valueForKey:@"ShowInvisibleCharacters"] boolValue];
		[self setAllowsNonContiguousLayout:YES]; // Setting this to YES sometimes causes "an extra toolbar" and other graphical glitches to sometimes appear in the text view when one sets a temporary attribute, reported as ID #5832329 to Apple
		
		NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
		[defaultsController addObserver:self forKeyPath:@"values.TextFont" options:NSKeyValueObservingOptionNew context:@"FontOrColourValueChanged"];
		[defaultsController addObserver:self forKeyPath:@"values.InvisibleCharactersColourWell" options:NSKeyValueObservingOptionNew context:@"FontOrColourValueChanged"];

	}
	return self;
}


- (void) dealloc
{
    NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    [defaultsController removeObserver:self forKeyPath:@"values.TextFont"];
    [defaultsController removeObserver:self forKeyPath:@"values.InvisibleCharactersColourWell"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([(__bridge NSString *)context isEqualToString:@"FontOrColourValueChanged"]) {
		attributes = @{NSFontAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]], NSForegroundColorAttributeName: [NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"InvisibleCharactersColourWell"]]};
		[[self firstTextView] setNeedsDisplay:YES];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


- (void)drawGlyphsForGlyphRange:(NSRange)glyphRange atPoint:(NSPoint)containerOrigin
{
    if (self.showsInvisibleChars) {
        NSString *completeString = [[self textStorage] string];
		NSInteger lengthToRedraw = NSMaxRange(glyphRange);
		
        for (NSInteger index = glyphRange.location; index < lengthToRedraw; index++) {
			unichar characterToCheck = [completeString characterAtIndex:index];

            NSString *character = nil;
            if (characterToCheck == ' ') {
                character = spaceCharacter;
            } else if (characterToCheck == '\t') {
                character = tabCharacter;
            } else if (characterToCheck == '\n' || characterToCheck == '\r') {
                character = newLineCharacter;
            }

            if (character != nil) {
                NSPoint pointToDrawAt = [self locationForGlyphAtIndex:index];
                NSRect glyphFragment = [self lineFragmentRectForGlyphAtIndex:index effectiveRange:NULL];
                
                pointToDrawAt.x += glyphFragment.origin.x;

                CGFloat yOffset = 0;
                if (characterToCheck == '\t') {
                    yOffset = glyphFragment.size.height / 4;
                }
                pointToDrawAt.y = glyphFragment.origin.y - yOffset;
                
                [character drawAtPoint:pointToDrawAt withAttributes:attributes];
            }
		}
    } 

    [super drawGlyphsForGlyphRange:glyphRange atPoint:containerOrigin];
}

@end
