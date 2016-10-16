/*
Fraise version 3.7 - Based on Smultron by Peter Borg
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Fraise

Copyright 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/


#import "FRASplitView.h"
#import "FRAProjectsController.h"
#import "FRAproject.h"

@implementation FRASplitView

- (void)awakeFromNib
{	
	dividerGradient = [[NSGradient alloc] initWithColorsAndLocations:[NSColor colorWithDeviceWhite:0.80 alpha:1.0], 0.0, [NSColor colorWithDeviceWhite:0.84 alpha:1.0], 0.2, [NSColor colorWithDeviceWhite:0.90 alpha:1.0], 0.50, [NSColor colorWithDeviceWhite:0.84 alpha:1.0], 0.8, [NSColor colorWithDeviceWhite:0.74 alpha:1.0], 1.0, nil];
}


- (void)drawDividerInRect:(NSRect)aRect
{
	if ([self isVertical]) {
		[dividerGradient drawInRect:aRect angle:0];
	} else {
		[dividerGradient drawInRect:aRect angle:90];
	}
	
	[super drawDividerInRect:aRect];
}


- (CGFloat)dividerThickness
{
	if ([[self autosaveName] isEqualToString:@"ProjectSplitView"]) {
		return 1.0;
	} else if ([[self autosaveName] isEqualToString:@"ContentSplitView"] && ([self isSubviewCollapsed:[FRACurrentProject secondContentView]] || ![NSApp isActive])) {
		return 0.0;
	} else if ([[self autosaveName] isEqualToString:@"ContentSplitView"]) {
		return 7.0;
	} else {
		return 5.0;
	}
}



@end
