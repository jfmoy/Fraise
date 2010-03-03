/*
Smultron version 3.6b1, 2009-09-12
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://smultron.sourceforge.net

Copyright 2004-2009 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "SMLStandardHeader.h"

#import "SMLDummyView.h"

@implementation SMLDummyView

- (id)initWithFrame:(NSRect)frame
{
	if (self = [super initWithFrame:frame]) {
        
		gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.12 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.38 alpha:1.0]];
		
		smultronImage = [NSImage imageNamed:@"SMLMainIcon.icns"];
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		[smultronImage setSize:NSMakeSize(128.0, 128.0)];
		[[smultronImage bestRepresentationForRect:NSMakeRect(0.0, 0.0, 128.0, 128.0) context:nil hints:nil] setSize:NSMakeSize(128.0, 128.0)];

		attributes = [[NSMutableDictionary alloc] init];
		[attributes setValue:[NSFont boldSystemFontOfSize:20] forKey:NSFontAttributeName];
		[attributes setValue:[NSColor colorWithCalibratedWhite:0.0 alpha:0.80] forKey:@"NSColor"];
		
		whiteAttributes = [[NSMutableDictionary alloc] init];
		[whiteAttributes setValue:[NSFont boldSystemFontOfSize:20] forKey:NSFontAttributeName];
		[whiteAttributes setValue:[NSColor colorWithCalibratedWhite:1.0 alpha:0.40] forKey:@"NSColor"];
		
		attributedString = [[NSAttributedString alloc] initWithString:NO_DOCUMENT_SELECTED_STRING attributes:attributes];
		whiteAttributedString = [[NSAttributedString alloc] initWithString:NO_DOCUMENT_SELECTED_STRING attributes:whiteAttributes];
		
		attributedStringSize = [attributedString size];
		
		backgroundColour = [NSColor colorWithDeviceWhite:0.91 alpha:1.0];
		
        return self;
    }
	
    return nil;
}


- (void)drawRect:(NSRect)rect
{
	NSRect bounds = [self bounds];
	NSDrawLightBezel(bounds, bounds);
	
	[gradient drawInRect:bounds angle:90.0];
	
	if (bounds.size.height < 240) {
		[whiteAttributedString drawAtPoint:NSMakePoint(((attributedStringSize.width / -2) + bounds.size.width / 2), (attributedStringSize.height / -2) + (bounds.size.height / 2) - 1)];
		[attributedString drawAtPoint:NSMakePoint(((attributedStringSize.width / -2) + bounds.size.width / 2), (attributedStringSize.height / -2) + (bounds.size.height / 2))];
		
		
	} else {
		[whiteAttributedString drawAtPoint:NSMakePoint(((attributedStringSize.width / -2) + bounds.size.width / 2), (attributedStringSize.height / -2) + (bounds.size.height / 2) - 39)];
		[attributedString drawAtPoint:NSMakePoint(((attributedStringSize.width / -2) + bounds.size.width / 2), (attributedStringSize.height / -2) + (bounds.size.height / 2) - 38)];
		
		NSRect centeredRect = rect;
		centeredRect.size = [smultronImage size];
		centeredRect.origin.x += ((rect.size.width - centeredRect.size.width) / 2.0);
		centeredRect.origin.y = ((rect.size.height - centeredRect.size.height) / 2.0) + 48;
		
		[smultronImage drawInRect:centeredRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.80];
	}
}


- (BOOL)isOpaque
{
	return YES;
}
@end
