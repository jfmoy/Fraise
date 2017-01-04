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

#import "FRAGutterTextView.h"

@implementation FRAGutterTextView

- (id)initWithFrame:(NSRect)frame
{
	if (self = [super initWithFrame:frame]) {

		[self setContinuousSpellCheckingEnabled:NO];
		[self setAllowsUndo:NO];
		[self setAllowsDocumentBackgroundColorChange:NO];
		[self setRichText:NO];
		[self setUsesFindPanel:NO];
		[self setUsesFontPanel:NO];
		[self setAlignment:NSTextAlignmentRight];
		[self setEditable:NO];
		[self setSelectable:NO];
		[[self textContainer] setContainerSize:NSMakeSize([[FRADefaults valueForKey:@"GutterWidth"] integerValue], NSIntegerMax)];
		[self setVerticallyResizable:YES];
		[self setHorizontallyResizable:YES];
		[self setAutoresizingMask:NSViewHeightSizable];
		
		[self setFont:[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]]];
		[self setTextColor:[NSColor textColor]];//[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextColourWell"]]];
		[self setInsertionPointColor:[NSColor textColor]];//[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextColourWell"]]];
		[self setBackgroundColor:[NSColor colorWithCalibratedWhite:0.94 alpha:1.0]];

		NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
		[defaultsController addObserver:self forKeyPath:@"values.TextFont" options:NSKeyValueObservingOptionNew context:@"TextFontChanged"];
	}
	return self;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([(__bridge NSString *)context isEqualToString:@"TextFontChanged"]) {
		[self setFont:[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"TextFont"]]];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
	
	NSRect bounds = [self bounds]; 
	if ([self needsToDrawRect:NSMakeRect(bounds.size.width - 1, 0, 1, bounds.size.height)] == YES) {
		[[NSColor lightGrayColor] set];
		NSBezierPath *dottedLine = [NSBezierPath bezierPathWithRect:NSMakeRect(bounds.size.width, 0, 0, bounds.size.height)];
		CGFloat dash[2];
		dash[0] = 1.0;
		dash[1] = 2.0;
		[dottedLine setLineDash:dash count:2 phase:1.0];
		[dottedLine stroke];
	}
	
}


- (BOOL)isOpaque
{
	return YES;
}

@end
