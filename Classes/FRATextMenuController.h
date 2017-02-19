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

#import <Cocoa/Cocoa.h>

@interface FRATextMenuController : NSObject
{
	IBOutlet NSMenu *textEncodingMenu;
	IBOutlet NSMenu *reloadTextWithEncodingMenu;	
	IBOutlet NSMenu *syntaxDefinitionMenu;
}

+ (FRATextMenuController *)sharedInstance;

- (void)buildEncodingsMenus;
- (void)buildSyntaxDefinitionsMenu;

- (void)changeEncodingAction:(id)sender;

- (IBAction)removeNeedlessWhitespaceAction:(id)sender;
- (IBAction)detabAction:(id)sender;
- (IBAction)entabAction:(id)sender;
- (void)performEntab;
- (void)performDetab;
- (IBAction)shiftLeftAction:(id)sender;
- (IBAction)shiftRightAction:(id)sender;
- (IBAction)toLowercaseAction:(id)sender;
- (IBAction)toUppercaseAction:(id)sender;
- (IBAction)capitaliseAction:(id)sender;
- (IBAction)goToLineAction:(id)sender;
- (void)performGoToLine:(NSInteger)lineToGoTo;
- (IBAction)closeTagAction:(id)sender;
- (IBAction)commentOrUncommentAction:(id)sender;
- (IBAction)emptyDummyAction:(id)sender;
- (IBAction)removeLineEndingsAction:(id)sender;
- (IBAction)changeLineEndingsAction:(id)sender;
- (IBAction)interchangeAdjacentCharactersAction:(id)sender;
- (IBAction)prepareForXMLAction:(id)sender;
- (IBAction)duplicateLineAction:(id)sender;

- (IBAction)changeSyntaxDefinitionAction:(id)sender;
@end
