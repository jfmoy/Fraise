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

#import "FRAEditMenuController.h"
#import "FRAProjectsController.h"
#import "FRAAdvancedFindController.h"
#import "FRAProject.h"
#import "FRATextView.h"
#import "FRAProject+ToolbarController.h"

@implementation FRAEditMenuController


- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	BOOL enableMenuItem = YES;
	NSInteger tag = [anItem tag];
	if (tag == 1 || tag == 11 || tag == 111) { // All items that should only be active when there's text to select/delete
		if (FRACurrentTextView == nil) {
			enableMenuItem = NO;
		}
	} else if (tag == 2) { // Live Find
		if ([FRACurrentProject areThereAnyDocuments] == NO) {
			enableMenuItem = NO;
		}
	}
	
	return enableMenuItem;
}


- (IBAction)advancedFindReplaceAction:(id)sender
{
	[[FRAAdvancedFindController sharedInstance] showAdvancedFindWindow];
}


- (IBAction)liveFindAction:(id)sender
{
	id firstResponder = [FRACurrentWindow firstResponder];
	[FRACurrentWindow makeFirstResponder:[FRACurrentProject liveFindSearchField]];
	NSText *fieldEditor = (NSText *)[[[FRACurrentProject liveFindSearchField] window] firstResponder];
	
	if (firstResponder == fieldEditor) {
		[FRACurrentWindow makeFirstResponder:[FRACurrentProject lastTextViewInFocus]]; // If the search field is already in focus switch it back to the text, this allows the user to use the same key command to get to the search field and get back to the selected text after the search is complete
	} else {
		[FRACurrentProject prepareForLiveFind];
	}
}


@end
