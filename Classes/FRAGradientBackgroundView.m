/*
 Fraise version 3.7 - Based on Smultron by Peter Borg
 
 Current Maintainer (2016): 
 Andreas Bentele: abentele.github@icloud.com (https://github.com/abentele/Fraise)
 
 Maintainer before macOS Sierra (2010-2016): 
 Jean-François Moy: jeanfrancois.moy@gmail.com (http://github.com/jfmoy/Fraise)

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "FRAGradientBackgroundView.h"

@implementation FRAGradientBackgroundView

- (id)initWithFrame:(NSRect)frame
{
	if (self = [super initWithFrame:frame]) {

		gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceRed:0.812 green:0.812 blue:0.812 alpha:1.0] endingColor:[NSColor colorWithDeviceRed:0.914 green:0.914 blue:0.914 alpha:1.0]];
		
		scaleFactor = [[NSScreen mainScreen] backingScaleFactor];
	}
	return self;
}


- (void)drawRect:(NSRect)rect 
{	
	NSRect gradientRect = [self bounds];
	
	NSDrawGroove(gradientRect, gradientRect);
	[gradient drawInRect:NSMakeRect(gradientRect.origin.x * scaleFactor, gradientRect.origin.y * scaleFactor, gradientRect.size.width * scaleFactor, gradientRect.size.height - 1.0 * scaleFactor) angle:90];
}


- (BOOL)isOpaque {
	return YES;
}


@end
