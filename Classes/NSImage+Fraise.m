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

#import "NSImage+Fraise.h"
#import "FRAVariousPerformer.h"

@implementation NSImage (NSImageFraise)

+ (NSArray *)iconsForPath:(NSString *)path
{
	NSArray *iconsArray;
	if ([[FRADefaults valueForKey:@"UseQuickLookIcon"] boolValue] == YES) {
		iconsArray = [NSImage quickLookIconForPath:path];
		if (iconsArray != nil && [iconsArray count] > 0)
        {
			return iconsArray;
		}
	}
	
	NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];

	[icon setSize:NSMakeSize(ICON_MAX_SIZE, ICON_MAX_SIZE)]; // This makes sure that unsavedIcon will not get "fuzzy"
	
	NSImage *unsavedIcon = [[NSImage alloc] initWithSize:[icon size]];
	//Log(imageRep);
	CIImage *ciImage = [CIImage imageWithData:[icon TIFFRepresentation]];
	//Log(ciImage);
	[unsavedIcon addRepresentation:[NSCIImageRep imageRepWithCIImage:[NSImage unsavedFilterForCIImage:ciImage]]];
	[unsavedIcon setSize:NSMakeSize(ICON_MAX_SIZE, ICON_MAX_SIZE)];
	iconsArray = @[icon, unsavedIcon];
	
	return iconsArray;
}


+ (NSArray *)quickLookIconForPath:(NSString *)path
{
	// Thanks to Matt Gemmel (http://mattgemmell.com/) for the basics of this code
	
    NSDictionary *options = @{(NSString *)kQLThumbnailOptionIconModeKey: @YES};
    CGImageRef imageRef = QLThumbnailImageCreate(kCFAllocatorDefault, (__bridge CFURLRef)[NSURL fileURLWithPath:path], CGSizeMake(ICON_MAX_SIZE, ICON_MAX_SIZE), (__bridge CFDictionaryRef)options);
    
	if (imageRef != NULL) {
		NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
		
		if (bitmapImageRep != nil) {

			NSSize iconSize = NSMakeSize([bitmapImageRep pixelsWide], [bitmapImageRep pixelsHigh]);
			NSImage *icon = [[NSImage alloc] initWithSize:iconSize];
			
			[icon addRepresentation:bitmapImageRep];
			NSImage *unsavedIcon = [[NSImage alloc] initWithSize:iconSize];
			CIImage *ciImage = [[CIImage alloc] initWithBitmapImageRep:bitmapImageRep];
			[unsavedIcon addRepresentation:[NSCIImageRep imageRepWithCIImage:[NSImage unsavedFilterForCIImage:ciImage]]];
			
			return @[icon, unsavedIcon];
		}
	}
	
    return nil;
}


+ (CIImage *)unsavedFilterForCIImage:(CIImage *)ciImage
{
	CIFilter *filter1 = [CIFilter filterWithName:@"CIColorControls"]; 
	[filter1 setDefaults]; 
	[filter1 setValue:ciImage forKey:@"inputImage"];  
	[filter1 setValue:@-0.1 forKey:@"inputBrightness"];
	
	CIFilter *filter2 = [CIFilter filterWithName:@"CISepiaTone"]; 
	[filter2 setDefaults]; 
	[filter2 setValue:[filter1 valueForKey:@"outputImage"] forKey:@"inputImage"];  
	[filter2 setValue:@0.9 forKey:@"inputIntensity"];
	
	return [filter2 valueForKey:@"outputImage"];
}


@end
