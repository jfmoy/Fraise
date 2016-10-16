/*
Fraise version 3.7 - Based on Smultron by Peter Borg
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Fraise

Copyright 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "FRAToolsMenuController.h"
#import "FRACommandsController.h"
#import "FRASnippetsController.h"
#import "FRAProjectsController.h"
#import "FRAPreviewController.h"
#import "FRABasicPerformer.h"
#import "FRATextPerformer.h"
#import "FRAInterfacePerformer.h"
#import "FRATextMenuController.h"
#import "FRAInfoController.h"
#import "FRAExtraInterfaceController.h"
#import "FRATextView.h"

#define SNIPPET_TAG		100

@implementation FRAToolsMenuController

static id sharedInstance = nil;

+ (FRAToolsMenuController *)sharedInstance
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
	id item = [[FRASnippetsController sharedInstance] performInsertNewSnippet];
	
	NSRange selectedRange = [FRACurrentTextView selectedRange];
	NSString *text = [[FRACurrentTextView string] substringWithRange:selectedRange];
	if (selectedRange.length == 0 || text == nil || [text isEqualToString:@""]) {
		NSBeep();
		return;
	}

	[item setValue:text forKey:@"text"];
	if ([text length] > SNIPPET_NAME_LENGTH) {
		[item setValue:[FRAText replaceAllNewLineCharactersWithSymbolInString:[text substringWithRange:NSMakeRange(0, SNIPPET_NAME_LENGTH)]] forKey:@"name"];
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
	
	textViewToInsertColourInto = FRACurrentTextView;
	
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
	[[FRAPreviewController sharedInstance] showPreviewWindow];
}


- (IBAction)reloadPreviewAction:(id)sender
{
	[[FRAPreviewController sharedInstance] reload];
}


- (IBAction)showCommandsWindowAction:(id)sender
{
	[[FRACommandsController sharedInstance] openCommandsWindow];
}


- (IBAction)runTextAction:(id)sender
{
	NSString *text = FRACurrentText;
	if (text == nil || [text isEqualToString:@""]) {
		return;
	}
	NSString *textPath = [FRABasic genererateTemporaryPath];
	
	id document = FRACurrentDocument;
	NSData *data = [[NSData alloc] initWithData:[[FRAText convertLineEndings:text inDocument:document] dataUsingEncoding:[[document valueForKey:@"encoding"] integerValue] allowLossyConversion:YES]];
	if ([data writeToFile:textPath atomically:YES]) {
		NSString *result;
		NSString *resultPath = [FRABasic genererateTemporaryPath];
		system([[NSString stringWithFormat:@"%@ %@ > %@", [FRADefaults valueForKey:@"RunText"], textPath, resultPath] UTF8String]);
		if ([[NSFileManager defaultManager] fileExistsAtPath:resultPath]) {
			result = [NSString stringWithContentsOfFile:resultPath encoding:[[document valueForKey:@"encoding"] integerValue] error:nil];
			[[NSFileManager defaultManager] removeItemAtPath:resultPath error:nil];
			[[[FRAExtraInterfaceController sharedInstance] commandResultWindow] makeKeyAndOrderFront:nil];
			[[[FRAExtraInterfaceController sharedInstance] commandResultTextView] setString:result];
		}
		if ([[NSFileManager defaultManager] fileExistsAtPath:textPath]) {
			[[NSFileManager defaultManager] removeItemAtPath:textPath error:nil];
		}
	}
}


- (IBAction)showSnippetsWindowAction:(id)sender
{
	[[FRASnippetsController sharedInstance] openSnippetsWindow];
}


- (void)buildInsertSnippetMenu
{
	[FRABasic removeAllItemsFromMenu:insertSnippetMenu];
	
	NSEnumerator *collectionEnumerator = [[FRABasic fetchAll:@"SnippetCollectionSortKeyName"] reverseObjectEnumerator];
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
			[subMenuItem setTag:SNIPPET_TAG]; // Used for validation
			[subMenu insertItem:subMenuItem atIndex:0];
		}
		
		[menuItem setSubmenu:subMenu];
		[insertSnippetMenu insertItem:menuItem atIndex:0];
	}
}


- (void)snippetShortcutFired:(id)sender
{
	[[FRASnippetsController sharedInstance] insertSnippet:[sender representedObject]];
}


- (void)buildRunCommandMenu
{
	[FRABasic removeAllItemsFromMenu:runCommandMenu];
	
	NSEnumerator *collectionEnumerator = [[FRABasic fetchAll:@"CommandCollectionSortKeyName"] reverseObjectEnumerator];
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
	[[FRACommandsController sharedInstance] runCommand:[sender representedObject]];
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
	if ([[FRADefaults valueForKey:@"UseRGBRatherThanHexWhenInsertingColourValues"] boolValue] == YES) {
		insertString = [NSString stringWithFormat:@"rgb(%lu,%lu,%lu)", red, green, blue];
	} else {
		insertString = [[NSString stringWithFormat:@"#%02lx%02lx%02lx", (unsigned long)red, (unsigned long)green, (unsigned long)blue] uppercaseString];
	}
	
	
	NSRange selectedRange = [textViewToInsertColourInto selectedRange];
	[textViewToInsertColourInto insertText:insertString replacementRange:selectedRange];
	[textViewToInsertColourInto setSelectedRange:NSMakeRange(selectedRange.location, [insertString length])]; // Select the inserted string so it will replace the last colour if more colours are inserted
}


- (IBAction)previousFunctionAction:(id)sender
{
	NSInteger lineNumber = [FRAInterface currentLineNumber];
	NSArray *functions = [FRAInterface allFunctions];
	
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
				[[FRATextMenuController sharedInstance] performGoToLine:previousFunctionLineNumber];
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
	NSInteger lineNumber = [FRAInterface currentLineNumber];
	NSArray *functions = [FRAInterface allFunctions];

	if (lineNumber == 0 || [functions count] == 0) {
		NSBeep();
		return;
	}

	id item;
	BOOL hasFoundNextFunction = NO;
	for (item in functions) {
		NSInteger functionLineNumber = [[item valueForKey:@"lineNumber"] integerValue];
		if (functionLineNumber > lineNumber) {
			[[FRATextMenuController sharedInstance] performGoToLine:functionLineNumber];
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
		if (FRACurrentTextView == nil) {
			enableMenuItem = NO;
		}
	} else if (tag == 2) { // Functions
		[FRABasic removeAllItemsFromMenu:functionsMenu];
		[FRAInterface insertAllFunctionsIntoMenu:functionsMenu];
	} else if (tag == 3) { // Refresh Info
		if ([[[FRAInfoController sharedInstance] infoWindow] isVisible] == NO) {
			enableMenuItem = NO;
		}
	} else if (tag == 4) { // Reload Preview
		if ([[[FRAPreviewController sharedInstance] previewWindow] isVisible] == NO) {
			enableMenuItem = NO;
		}
	} else if (tag == 5) { // Create Snippet From Selection
		if ([FRACurrentTextView selectedRange].length < 1) {
			enableMenuItem = NO;
		}
	} else if (tag == 6) { // Insert Colour
		if (FRACurrentTextView == nil) {
			enableMenuItem = NO;
		}
	} else if (tag == 7) { // Export Snippets
		if ([[[FRASnippetsController sharedInstance] snippetsWindow] isVisible] == NO || [[[[FRASnippetsController sharedInstance] snippetCollectionsArrayController] selectedObjects] count] < 1) {
			enableMenuItem = NO;
		}
	} else if (tag == 8) { // Export Commands
		if ([[[FRACommandsController sharedInstance] commandsWindow] isVisible] == NO || [[[[FRACommandsController sharedInstance] commandCollectionsArrayController] selectedObjects] count] < 1) {
			enableMenuItem = NO;
		}
	} else if (tag == 9) { // Run Selection Inline
		if ([FRACurrentTextView selectedRange].length < 1) {
			enableMenuItem = NO;
		}
	} else if (tag == 10) { // New Snippet, New Snippet Collection
		if ([[[FRASnippetsController sharedInstance] snippetsWindow] isVisible] == NO) {
			enableMenuItem = NO;
		}
	} else if (tag == 11) { // Run Command, New Command, New Command Collection
		if ([[[FRACommandsController sharedInstance] commandsWindow] isVisible] == NO) {
			enableMenuItem = NO;
		}
	} else if (tag == SNIPPET_TAG) {
		if (FRACurrentTextView == nil) {
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
	[[FRAInfoController sharedInstance] openInfoWindow];	
}


- (IBAction)refreshInfoAction:(id)sender
{
	[[FRAInfoController sharedInstance] refreshInfo];
}


- (IBAction)importSnippetsAction:(id)sender
{
	[[FRASnippetsController sharedInstance] importSnippets];
}


- (IBAction)exportSnippetsAction:(id)sender
{
	[[FRASnippetsController sharedInstance] exportSnippets];	
}


- (IBAction)importCommandsAction:(id)sender
{
	[[FRACommandsController sharedInstance] importCommands];
}


- (IBAction)exportCommandsAction:(id)sender
{
	[[FRACommandsController sharedInstance] exportCommands];
}


- (IBAction)showCommandResultWindowAction:(id)sender
{
	[[FRAExtraInterfaceController sharedInstance] showCommandResultWindow];
}


- (IBAction)runSelectionInlineAction:(id)sender
{
	FRATextView *textView = FRACurrentTextView;
	NSRange selectedRange = [textView selectedRange];
	NSString *text = [[textView string] substringWithRange:selectedRange];
	if (selectedRange.length == 0 || text == nil || [text isEqualToString:@""]) {
		NSBeep();
		return;
	}
	NSString *textPath = [FRABasic genererateTemporaryPath];
	
	id document = FRACurrentDocument;
	NSData *data = [[NSData alloc] initWithData:[[FRAText convertLineEndings:text inDocument:document] dataUsingEncoding:[[document valueForKey:@"encoding"] integerValue] allowLossyConversion:YES]];
	if ([data writeToFile:textPath atomically:YES]) {
		NSString *result;
		NSString *resultPath = [FRABasic genererateTemporaryPath];
		system([[NSString stringWithFormat:@"%@ %@ > %@", [FRADefaults valueForKey:@"RunText"], textPath, resultPath] UTF8String]);
		if ([[NSFileManager defaultManager] fileExistsAtPath:resultPath]) {
			result = [NSString stringWithContentsOfFile:resultPath encoding:[[document valueForKey:@"encoding"] integerValue] error:nil];
			[[NSFileManager defaultManager] removeItemAtPath:resultPath error:nil];
			[textView insertText:result replacementRange:[textView selectedRange]];
		}
		if ([[NSFileManager defaultManager] fileExistsAtPath:textPath]) {
			[[NSFileManager defaultManager] removeItemAtPath:textPath error:nil];
		}
	}
}


- (IBAction)runCommandAction:(id)sender
{
	[[FRACommandsController sharedInstance] runAction:sender];
}


- (IBAction)newCommandAction:(id)sender
{
	[[FRACommandsController sharedInstance] newCommandAction:sender];
}


- (IBAction)newCommandCollectionAction:(id)sender
{
	[[FRACommandsController sharedInstance] newCollectionAction:sender];
}


- (IBAction)newSnippetAction:(id)sender
{
	[[FRASnippetsController sharedInstance] newSnippetAction:sender];
}


- (IBAction)newSnippetCollectionAction:(id)sender
{
	[[FRASnippetsController sharedInstance] newCollectionAction:sender];
}

@end
