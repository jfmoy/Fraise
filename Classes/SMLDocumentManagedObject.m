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

#import "SMLDocumentManagedObject.h"

@implementation SMLDocumentManagedObject

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	
//	NSImage *defaultDocumentIcon = [SMLInterface documentIcon];
//	[defaultDocumentIcon setDataRetained:NO];
//	[defaultDocumentIcon setScalesWhenResized:YES];
//	
//	NSImage *defaultUnsavedDocumentIcon = [[NSImage alloc] initWithData:[[SMLVarious unsavedIconFromImage:defaultDocumentIcon] TIFFRepresentation]];
//	[defaultUnsavedDocumentIcon setDataRetained:NO];
//	[defaultUnsavedDocumentIcon setScalesWhenResized:YES];
//	
//	[self setValue:defaultDocumentIcon forKey:@"icon"];	
//	[self setValue:defaultUnsavedDocumentIcon forKey:@"unsavedIcon"];

	[self setValue:[NSNumber numberWithBool:[[SMLDefaults valueForKey:@"SyntaxColourNewDocuments"] boolValue]] forKey:@"isSyntaxColoured"];
	[self setValue:[NSNumber numberWithBool:[[SMLDefaults valueForKey:@"LineWrapNewDocuments"] boolValue]] forKey:@"isLineWrapped"];
	[self setValue:[NSNumber numberWithBool:[[SMLDefaults valueForKey:@"ShowInvisibleCharacters"] boolValue]] forKey:@"showInvisibleCharacters"];
	[self setValue:[NSNumber numberWithBool:[[SMLDefaults valueForKey:@"ShowLineNumberGutter"] boolValue]] forKey:@"showLineNumberGutter"];
	[self setValue:[NSNumber numberWithInteger:[[SMLDefaults valueForKey:@"GutterWidth"] integerValue]] forKey:@"gutterWidth"];
	[self setValue:[NSNumber numberWithInteger:[[SMLDefaults valueForKey:@"EncodingsPopUp"] integerValue]] forKey:@"encoding"];
}



@end
