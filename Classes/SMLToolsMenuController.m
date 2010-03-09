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

#import "SMLToolsMenuController.h"
#import "SMLCommandsController.h"
#import "SMLSnippetsController.h"
#import "SMLProjectsController.h"
#import "SMLPreviewController.h"
#import "SMLBasicPerformer.h"
#import "SMLTextPerformer.h"
#import "SMLInterfacePerformer.h"
#import "SMLTextMenuController.h"
#import "SMLInfoController.h"
#import "SMLExtraInterfaceController.h"
#import "SMLTextView.h"

@implementation SMLToolsMenuController

static id sharedInstance = nil;

+ (SMLToolsMenuController *)sharedInstance
{ 
	if (sharedInstance == nil) { 
		sharedInstance = [[self alloc] init];
	}
	
	return sharedInstance;
} 


- (id)init 
{
    if (sharedInstance == nil) {
        sharedInstance = [super init];
		
    }
    return sharedInstance;
}


- (IBAction)createSnippetFromSelectionAction:(id)sender
{	
	id item = [[SMLSnippetsController sharedInstance] performInsertNewSnippet];
	
	NSRange selectedRange = [SMLCurrentTextView selectedRange];
	NSString *text = [[SMLCurrentTextView string] substringWithRange:selectedRange];
	if (selectedRange.length == 0 || text == nil || [text isEqualToString:@""]) {
		NSBeep();
		return;
	}

	[item setValue:text forKey:@"text"];
	if ([text length] > SNIPPET_NAME_LENGTH) {
		[item setValue:[SMLText replaceAllNewLineCharactersWithSymbolInString:[text substringWithRange:NSMakeRange(0, SNIPPET_NAME_LENGTH)]] forKey:@"name"];
	} else {
		[item setValue:text forKey:@"name"];
	}
}


- (IBAction)insertColourAction:(id)sender
{
	NSColorPanel *colourPanel = [NSColorPanel sharedColorPanel];
	
	if ([NSApp keyWindow] == colourPanel) {
		[colourPanel orderOut:nil];
		return;
	}
	
	textViewToInsertColourInto = SMLCurrentTextView;
	
	if (textViewToInsertColourInto == nil) {
		NSBeep();
		return;
	}
	
	[colourPanel makeKeyAndOrderFront:self];
	[colourPanel setTarget:self];
	[colourPanel setAction:@selector(insertColour:)];
}


- (IBAction)previewAction:(id)sender
{
	[[SMLPreviewController sharedInstance] showPreviewWindow];
}


- (IBAction)reloadPreviewAction:(id)sender
{
	[[SMLPreviewController sharedInstance] reload];
}


- (IBAction)showCommandsWindowAction:(id)sender
{
	[[SMLCommandsController sharedInstance] openCommandsWindow];
}


- (IBAction)runTextAction:(id)sender
{
	NSString *text = SMLCurrentText;
	if (text == nil || [text isEqualToString:@""]) {
		return;
	}
	NSString *textPath = [SMLBasic genererateTemporaryPath];
	
	id document = SMLCurrentDocument;
	NSData *data = [[NSData alloc] initWithData:[[SMLText convertLineEndings:text inDocument:document] dataUsingEncoding:[[document valueForKey:@"encoding"] integerValue] allowLossyConversion:YES]];
	if ([data writeToFile:textPath atomically:YES]) {
		NSString *result;
		NSString *resultPath = [SMLBasic genererateTemporaryPath];
		system([[NSString stringWithFormat:@"%@ %@ > %@", [SMLDefaults valueForKey:@"RunText"], textPath, resultPath] UTF8String]);
		if ([[NSFileManager defaultManager] fileExistsAtPath:resultPath]) {
			result = [NSString stringWithContentsOfFile:resultPath encoding:[[document valueForKey:@"encoding"] integerValue] error:nil];
			[[NSFileManager defaultManager] removeItemAtPath:resultPath error:nil];
			[[[SMLExtraInterfaceController sharedInstance] commandResultWindow] makeKeyAndOrderFront:nil];
			[[[SMLExtraInterfaceController sharedInstance] commandResultTextView] setString:result];
		}
		if ([[NSFileManager defaultManager] fileExistsAtPath:textPath]) {
			[[NSFileManager defaultManager] removeItemAtPath:textPath error:nil];
		}
	}
}


- (IBAction)showSnippetsWindowAction:(id)sender
{
	[[SMLSnippetsController sharedInstance] openSnippetsWindow];
}


- (void)buildInsertSnippetMenu
{
	[SMLBasic removeAllItemsFromMenu:insertSnippetMenu];
	
	NSEnumerator *collectionEnumerator = [[SMLBasic fetchAll:@"SnippetCollectionSortKeyName"] reverseObjectEnumerator];
	for (id collection in collectionEnumerator) {
		if ([collection valueForKey:@"name"] == nil) {
			continue;
		}
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[collection valueForKey:@"name"] action:nil keyEquivalent:@""];
		NSMenu *subMenu = [[NSMenu alloc] init];
		
		NSMutableArray *array = [NSMutableArray arrayWithArray:[[collection mutableSetValueForKey:@"snippets"] allObjects]];
		[array sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
		for (id snippet in array) {
			if ([snippet valueForKey:@"name"] == nil) {
				continue;
			}
			NSString *keyString;
			if ([snippet valueForKey:@"shortcutMenuItemKeyString"] != nil) {
				keyString = [snippet valueForKey:@"shortcutMenuItemKeyString"];
			} else {
				keyString = @"";
			}
			NSMenuItem *subMenuItem = [[NSMenuItem alloc] initWithTitle:[snippet valueForKey:@"name"] action:@selector(snippetShortcutFired:) keyEquivalent:keyString];
			[subMenuItem setKeyEquivalentModifierMask:[[snippet valueForKey:@"shortcutModifier"] integerValue]];
			[subMenuItem setTarget:self];			
			[subMenuItem setRepresentedObject:snippet];
			[subMenu insertItem:subMenuItem atIndex:0];
		}
		
		[menuItem setSubmenu:subMenu];
		[insertSnippetMenu insertItem:menuItem atIndex:0];
	}
}


- (void)snippetShortcutFired:(id)sender
{
	[[SMLSnippetsController sharedInstance] insertSnippet:[sender representedObject]];
}


- (void)buildRunCommandMenu
{
	[SMLBasic removeAllItemsFromMenu:runCommandMenu];
	
	NSEnumerator *collectionEnumerator = [[SMLBasic fetchAll:@"CommandCollectionSortKeyName"] reverseObjectEnumerator];
	for (id collection in collectionEnumerator) {
		if ([collection valueForKey:@"name"] == nil) {
			continue;
		}
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[collection valueForKey:@"name"] action:nil keyEquivalent:@""];
		NSMenu *subMenu = [[NSMenu alloc] init];
		
		NSMutableArray *array = [NSMutableArray arrayWithArray:[[collection mutableSetValueForKey:@"commands"] allObjects]];
		[array sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
		for (id command in array) {
			if ([command valueForKey:@"name"] == nil) {
				continue;
			}
			NSString *keyString;
			if ([command valueForKey:@"shortcutMenuItemKeyString"] != nil) {
				keyString = [command valueForKey:@"shortcutMenuItemKeyString"];
			} else {
				keyString = @"";
			}
			NSMenuItem *subMenuItem = [[NSMenuItem alloc] initWithTitle:[command valueForKey:@"name"] action:@selector(commandShortcutFired:) keyEquivalent:keyString];
			[subMenuItem setKeyEquivalentModifierMask:[[command valueForKey:@"shortcutModifier"] integerValue]];
			[subMenuItem setTarget:self];			
			[subMenuItem setRepresentedObject:command];
			[subMenu insertItem:subMenuItem atIndex:0];
		}
		
		[menuItem setSubmenu:subMenu];
		[runCommandMenu insertItem:menuItem atIndex:0];
	}
	
}


- (void)commandShortcutFired:(id)sender
{
	[[SMLCommandsController sharedInstance] runCommand:[sender representedObject]];
}


- (void)insertColour:(id)sender
{
	if (textViewToInsertColourInto == nil) {
		NSBeep();
		return;
	}
	
	NSColor *colour = [[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	
	NSUInteger red = (NSUInteger)([colour redComponent] * 255);
	NSUInteger green = (NSUInteger)([colour greenComponent] * 255);
	NSUInteger blue = (NSUInteger)([colour blueComponent] * 255);
	
	NSString *insertString;
	if ([[SMLDefaults valueForKey:@"UseRGBRatherThanHexWhenInsertingColourValues"] boolValue] == YES) {
		insertString = [NSString stringWithFormat:@"rgb(%lu,%lu,%lu)", red, green, blue];
	} else {
		insertString = [[NSString stringWithFormat:@"#%02x%02x%02x", red, green, blue] uppercaseString];
	}
	
	
	NSRange selectedRange = [textViewToInsertColourInto selectedRange];
	[textViewToInsertColourInto insertText:insertString];
	[textViewToInsertColourInto setSelectedRange:NSMakeRange(selectedRange.location, [insertString length])]; // Select the inserted string so it will replace the last colour if more colours are inserted
}


- (IBAction)previousFunctionAction:(id)sender
{
	NSInteger lineNumber = [SMLInterface currentLineNumber];
	NSArray *functions = [SMLInterface allFunctions];
	
	if (lineNumber == 0 || [functions count] == 0) {
		NSBeep();
		return;
	}
	
	id item;
	NSInteger previousFunctionLineNumber = 0;
	for (item in functions) {
		NSInteger functionLineNumber = [[item valueForKey:@"lineNumber"] integerValue];
		if (functionLineNumber >= lineNumber) {
			if (previousFunctionLineNumber != 0) {
				[[SMLTextMenuController sharedInstance] performGoToLine:previousFunctionLineNumber];
				break;
			} else {
				NSBeep();
				return;
			}
		}
		previousFunctionLineNumber = functionLineNumber;
	}
}


- (IBAction)nextFunctionAction:(id)sender
{
	NSInteger lineNumber = [SMLInterface currentLineNumber];
	NSArray *functions = [SMLInterface allFunctions];

	if (lineNumber == 0 || [functions count] == 0) {
		NSBeep();
		return;
	}

	id item;
	BOOL hasFoundNextFunction = NO;
	for (item in functions) {
		NSInteger functionLineNumber = [[item valueForKey:@"lineNumber"] integerValue];
		if (functionLineNumber > lineNumber) {
			[[SMLTextMenuController sharedInstance] performGoToLine:functionLineNumber];
			hasFoundNextFunction = YES;
			break;
		}
	}
	
	if (hasFoundNextFunction == NO) {
		NSBeep();
	}
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	BOOL enableMenuItem = YES;
	NSInteger tag = [anItem tag];
	if (tag == 1) { // Run Text
		if (SMLCurrentTextView == nil) {
			enableMenuItem = NO;
		}
	} else if (tag == 2) { // Functions
		[SMLBasic removeAllItemsFromMenu:functionsMenu];
		[SMLInterface insertAllFunctionsIntoMenu:functionsMenu];
	} else if (tag == 3) { // Refresh Info
		if ([[[SMLInfoController sharedInstance] infoWindow] isVisible] == NO) {
			enableMenuItem = NO;
		}
	} else if (tag == 4) { // Reload Preview
		if ([[[SMLPreviewController sharedInstance] previewWindow] isVisible] == NO) {
			enableMenuItem = NO;
		}
	} else if (tag == 5) { // Create Snippet From Selection
		if ([SMLCurrentTextView selectedRange].length < 1) {
			enableMenuItem = NO;
		}
	} else if (tag == 6) { // Insert Colour
		if (SMLCurrentTextView == nil) {
			enableMenuItem = NO;
		}
	} else if (tag == 7) { // Export Snippets
		if ([[[SMLSnippetsController sharedInstance] snippetsWindow] isVisible] == NO || [[[[SMLSnippetsController sharedInstance] snippetCollectionsArrayController] selectedObjects] count] < 1) {
			enableMenuItem = NO;
		}
	} else if (tag == 8) { // Export Commands
		if ([[[SMLCommandsController sharedInstance] commandsWindow] isVisible] == NO || [[[[SMLCommandsController sharedInstance] commandCollectionsArrayController] selectedObjects] count] < 1) {
			enableMenuItem = NO;
		}
	} else if (tag == 9) { // Run Selection Inline
		if ([SMLCurrentTextView selectedRange].length < 1) {
			enableMenuItem = NO;
		}
	} else if (tag == 10) { // New Snippet, New Snippet Collection
		if ([[[SMLSnippetsController sharedInstance] snippetsWindow] isVisible] == NO) {
			enableMenuItem = NO;
		}
	} else if (tag == 11) { // Run Command, New Command, New Command Collection
		if ([[[SMLCommandsController sharedInstance] commandsWindow] isVisible] == NO) {
			enableMenuItem = NO;
		}
	}		
	return enableMenuItem;
}


- (IBAction)emptyDummyAction:(id)sender
{
	// An easy way to enable menu items with submenus without setting an action which actually does something
}


- (IBAction)getInfoAction:(id)sender
{
	[[SMLInfoController sharedInstance] openInfoWindow];	
}


- (IBAction)refreshInfoAction:(id)sender
{
	[[SMLInfoController sharedInstance] refreshInfo];
}


- (IBAction)importSnippetsAction:(id)sender
{
	[[SMLSnippetsController sharedInstance] importSnippets];
}


- (IBAction)exportSnippetsAction:(id)sender
{
	[[SMLSnippetsController sharedInstance] exportSnippets];	
}


- (IBAction)importCommandsAction:(id)sender
{
	[[SMLCommandsController sharedInstance] importCommands];
}


- (IBAction)exportCommandsAction:(id)sender
{
	[[SMLCommandsController sharedInstance] exportCommands];
}


- (IBAction)showCommandResultWindowAction:(id)sender
{
	[[SMLExtraInterfaceController sharedInstance] showCommandResultWindow];
}


- (IBAction)runSelectionInlineAction:(id)sender
{
	SMLTextView *textView = SMLCurrentTextView;
	NSRange selectedRange = [textView selectedRange];
	NSString *text = [[textView string] substringWithRange:selectedRange];
	if (selectedRange.length == 0 || text == nil || [text isEqualToString:@""]) {
		NSBeep();
		return;
	}
	NSString *textPath = [SMLBasic genererateTemporaryPath];
	
	id document = SMLCurrentDocument;
	NSData *data = [[NSData alloc] initWithData:[[SMLText convertLineEndings:text inDocument:document] dataUsingEncoding:[[document valueForKey:@"encoding"] integerValue] allowLossyConversion:YES]];
	if ([data writeToFile:textPath atomically:YES]) {
		NSString *result;
		NSString *resultPath = [SMLBasic genererateTemporaryPath];
		system([[NSString stringWithFormat:@"%@ %@ > %@", [SMLDefaults valueForKey:@"RunText"], textPath, resultPath] UTF8String]);
		if ([[NSFileManager defaultManager] fileExistsAtPath:resultPath]) {
			result = [NSString stringWithContentsOfFile:resultPath encoding:[[document valueForKey:@"encoding"] integerValue] error:nil];
			[[NSFileManager defaultManager] removeItemAtPath:resultPath error:nil];
			[textView insertText:result];
		}
		if ([[NSFileManager defaultManager] fileExistsAtPath:textPath]) {
			[[NSFileManager defaultManager] removeItemAtPath:textPath error:nil];
		}
	}
}


- (IBAction)runCommandAction:(id)sender
{
	[[SMLCommandsController sharedInstance] runAction:sender];
}


- (IBAction)newCommandAction:(id)sender
{
	[[SMLCommandsController sharedInstance] newCommandAction:sender];
}


- (IBAction)newCommandCollectionAction:(id)sender
{
	[[SMLCommandsController sharedInstance] newCollectionAction:sender];
}


- (IBAction)newSnippetAction:(id)sender
{
	[[SMLSnippetsController sharedInstance] newSnippetAction:sender];
}


- (IBAction)newSnippetCollectionAction:(id)sender
{
	[[SMLSnippetsController sharedInstance] newCollectionAction:sender];
}

@end
