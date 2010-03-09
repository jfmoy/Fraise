/*
Smultron version 3.7a1, 2009-09-12
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Smultron

Copyright 2004-2009 Peter Borg - 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "SMLStandardHeader.h"

#import "SMLEncodingManagedObject.h"
#import "SMLApplicationDelegate.h"
#import "SMLTextMenuController.h"
#import "SMLPreferencesController.h"

@implementation SMLEncodingManagedObject


- (void)didChangeValueForKey:(NSString *)key
{	
	[super didChangeValueForKey:key];
	
	if ([[SMLApplicationDelegate sharedInstance] hasFinishedLaunching] == NO) {
		return;
	}
	
	NSMutableArray *activeEncodings = [NSMutableArray arrayWithArray:[SMLDefaults valueForKey:@"ActiveEncodings"]];
	if ([[self valueForKey:@"active"] boolValue] == YES) {
		[activeEncodings addObject:[self valueForKey:@"encoding"]];
	} else {
		[activeEncodings removeObject:[self valueForKey:@"encoding"]];
	}
	[SMLDefaults setValue:activeEncodings forKey:@"ActiveEncodings"];

	[[SMLTextMenuController sharedInstance] buildEncodingsMenus];
	NSUInteger selectedTag = [[[[SMLPreferencesController sharedInstance] encodingsPopUp] selectedItem] tag];
	[[SMLPreferencesController sharedInstance] buildEncodingsMenu];
	[[[SMLPreferencesController sharedInstance] encodingsPopUp] selectItemWithTag:selectedTag];
}
		
		

@end
