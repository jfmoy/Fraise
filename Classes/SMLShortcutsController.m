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

#import "SMLShortcutsController.h"
#import "SMLCommandsController.h"
#import "SMLSnippetsController.H"

@implementation SMLShortcutsController

static id sharedInstance = nil;

+ (SMLShortcutsController *)sharedInstance
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


- (void)registerSnippetShortcutWithEvent:(NSEvent *)event
{
	id snippet = [[[[SMLSnippetsController sharedInstance] snippetsArrayController] selectedObjects] objectAtIndex:0];	
	[snippet setValue:[NSNumber numberWithUnsignedInteger:[event modifierFlags]] forKey:@"shortcutModifier"];
	[snippet setValue:[self menuItemKeyStringFromEvent:event] forKey:@"shortcutMenuItemKeyString"];
	[snippet setValue:[[self plainModifierStringFromEvent:event] stringByAppendingString:[self plainKeyStringFromEvent:event]] forKey:@"shortcutDisplayString"];
}


- (void)unregisterSelectedSnippetShortcut
{
	id snippet = [[[[SMLSnippetsController sharedInstance] snippetsArrayController] selectedObjects] objectAtIndex:0];	
	
	[snippet setValue:nil forKey:@"shortcutModifier"];
	[snippet setValue:nil forKey:@"shortcutMenuItemKeyString"];
	[snippet setValue:nil forKey:@"shortcutDisplayString"];
}


- (void)registerCommandShortcutWithEvent:(NSEvent *)event
{
	id command = [[[[SMLCommandsController sharedInstance] commandsArrayController] selectedObjects] objectAtIndex:0];	
	[command setValue:[NSNumber numberWithUnsignedInteger:[event modifierFlags]] forKey:@"shortcutModifier"];
	[command setValue:[self menuItemKeyStringFromEvent:event] forKey:@"shortcutMenuItemKeyString"];
	[command setValue:[[self plainModifierStringFromEvent:event] stringByAppendingString:[self plainKeyStringFromEvent:event]] forKey:@"shortcutDisplayString"];
}


- (void)unregisterSelectedCommandShortcut
{
	id command = [[[[SMLCommandsController sharedInstance] commandsArrayController] selectedObjects] objectAtIndex:0];	
	
	[command setValue:nil forKey:@"shortcutModifier"];
	[command setValue:nil forKey:@"shortcutMenuItemKeyString"];
	[command setValue:nil forKey:@"shortcutDisplayString"];
}


- (NSString *)menuItemKeyStringFromEvent:(NSEvent *)event
{
	NSString *returnString;
	unichar character[1];
	NSInteger keyCode = [event keyCode];
	
	if (keyCode == 0x7A) {
		character[0] = NSF1FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x78) {
		character[0] = NSF2FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x63) {
		character[0] = NSF3FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x76) {
		character[0] = NSF4FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x60) {
		character[0] = NSF5FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x61) {
		character[0] = NSF6FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x62) {
		character[0] = NSF7FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x64) {
		character[0] = NSF8FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x65) {
		character[0] = NSF9FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x6D) {
		character[0] = NSF10FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x67) {
		character[0] = NSF11FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x6F) {
		character[0] = NSF12FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x69) {
		character[0] = NSF13FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x6B) {
		character[0] = NSF14FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x71) {
		character[0] = NSF15FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x6A) {
		character[0] = NSF16FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x40) {
		character[0] = NSF17FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x4F) {
		character[0] = NSF18FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	} else if (keyCode == 0x50) {
		character[0] = NSF19FunctionKey;
		returnString = [NSString stringWithCharacters:character length:1];
	}
	
	else if (keyCode == 0x34) returnString = [NSString stringWithFormat:@"%C", 0x2324]; // enter
	else if (keyCode == 0x24) returnString = [NSString stringWithFormat:@"%C", 0x21B5]; // return
	else if (keyCode == 0x35) returnString = [NSString stringWithFormat:@"%C", 0x238B]; // escape
	else if (keyCode == 0x30) returnString = [NSString stringWithFormat:@"%C", 0x21E5]; // tab
	else if (keyCode == 0x33) returnString = [NSString stringWithFormat:@"%C", 0x232B]; // backwards delete
	else if (keyCode == 0x31) returnString = [NSString stringWithFormat:@"%C", 0x2423]; // space
	else if (keyCode == 0x47) returnString = [NSString stringWithFormat:@"%C", 0x2327]; // clear key
	else if (keyCode == 0x4D) returnString = [NSString stringWithFormat:@"%C", 0x2191]; // up arrow
	else if (keyCode == 0x7D) returnString = [NSString stringWithFormat:@"%C", 0x2193]; // down arrow
	else if (keyCode == 0x7B) returnString = [NSString stringWithFormat:@"%C", 0x2190]; // left arrow
	else if (keyCode == 0x7C) returnString = [NSString stringWithFormat:@"%C", 0x2192]; // right arrow
	else if (keyCode == 0x75) returnString = [NSString stringWithFormat:@"%C", 0x2326]; // forward delete
	else if (keyCode == 0x73) returnString = [NSString stringWithFormat:@"%C", 0x2196]; // home
	else if (keyCode == 0x77) returnString = [NSString stringWithFormat:@"%C", 0x2198]; // end
	else if (keyCode == 0x74) returnString = [NSString stringWithFormat:@"%C", 0x21DE]; // page up
	else if (keyCode == 0x79) returnString = [NSString stringWithFormat:@"%C", 0x21DF]; // page down
	else if (keyCode == 0x72) returnString = [NSString stringWithString:@"?"]; // help
	
	else {
		if ([event modifierFlags] & NSShiftKeyMask) { // If Shift is pressed, get the character this way so the "correct" character will be displayed, e.g. 3 and not #
			OSStatus err;
			
			static UInt32 deadKeyState = 0;
			UniCharCount maxStringLength = 4;
			UniCharCount actualStringLength;
			UniChar unicodeString[4];
			
			TISInputSourceRef kbInputSourceRef = (TISInputSourceRef) TISCopyCurrentKeyboardLayoutInputSource();
			
			CFDataRef uchrDataRef = (CFDataRef)TISGetInputSourceProperty(kbInputSourceRef, kTISPropertyUnicodeKeyLayoutData);
				
			err = UCKeyTranslate((const UCKeyboardLayout *)CFDataGetBytePtr(uchrDataRef), keyCode, kUCKeyActionDown, [self carbonModifierFromCocoaModifier:[event modifierFlags]], LMGetKbdType(), kUCKeyTranslateNoDeadKeysMask, &deadKeyState, maxStringLength, &actualStringLength, unicodeString);
			returnString = [NSString stringWithCharacters:unicodeString length:1];
	
			if (err != noErr) {
				returnString = [NSString stringWithString:[event charactersIgnoringModifiers]];
			}
			
			
		} else {
			returnString = [NSString stringWithString:[event charactersIgnoringModifiers]];
		}
	}
	
	return returnString;
}


- (NSString *)plainKeyStringFromEvent:(NSEvent *)event
{
	NSString *returnString;
	NSInteger keyCode = [event keyCode];
	
	if (keyCode == 0x7A) returnString = [NSString stringWithString:@"F1"];
	else if (keyCode == 0x78) returnString = [NSString stringWithString:@"F2"];
	else if (keyCode == 0x63) returnString = [NSString stringWithString:@"F3"];
	else if (keyCode == 0x76) returnString = [NSString stringWithString:@"F4"];
	else if (keyCode == 0x60) returnString = [NSString stringWithString:@"F5"];
	else if (keyCode == 0x61) returnString = [NSString stringWithString:@"F6"];
	else if (keyCode == 0x62) returnString = [NSString stringWithString:@"F7"];
	else if (keyCode == 0x64) returnString = [NSString stringWithString:@"F8"];
	else if (keyCode == 0x65) returnString = [NSString stringWithString:@"F9"];
	else if (keyCode == 0x6D) returnString = [NSString stringWithString:@"F10"];
	else if (keyCode == 0x67) returnString = [NSString stringWithString:@"F11"];
	else if (keyCode == 0x6F) returnString = [NSString stringWithString:@"F12"];
	else if (keyCode == 0x69) returnString = [NSString stringWithString:@"F13"];
	else if (keyCode == 0x6B) returnString = [NSString stringWithString:@"F14"];
	else if (keyCode == 0x71) returnString = [NSString stringWithString:@"F15"];
	else if (keyCode == 0x6A) returnString = [NSString stringWithString:@"F16"];
	else if (keyCode == 0x40) returnString = [NSString stringWithString:@"F17"];
	else if (keyCode == 0x4F) returnString = [NSString stringWithString:@"F18"];
	else if (keyCode == 0x50) returnString = [NSString stringWithString:@"F19"];
	else
		returnString = [self menuItemKeyStringFromEvent:event];
	
	return [returnString uppercaseString];
}


- (NSString *)plainModifierStringFromEvent:(NSEvent *)event
{
	NSMutableString *returnString = [NSMutableString stringWithString:@""];
	NSInteger modifier = [event modifierFlags];
	
	if (modifier & NSCommandKeyMask) {
		[returnString appendString:[NSString stringWithFormat:@"%C", 0x2318]];
	}
	
	if (modifier & NSAlternateKeyMask) {
		[returnString appendString:[NSString stringWithFormat:@"%C", 0x2325]];
	}
	
	if (modifier & NSControlKeyMask) {
		[returnString appendString:[NSString stringWithFormat:@"%C", 0x2303]];
	}
	
	if (modifier & NSShiftKeyMask) {
		[returnString appendString:[NSString stringWithFormat:@"%C", 0x21E7]];
	}	
	
	return returnString;
}


- (NSUInteger)carbonModifierFromCocoaModifier:(NSUInteger)cocoaModifier
{
	NSUInteger carbonModifier = 0;
	if (cocoaModifier & NSShiftKeyMask) carbonModifier |= shiftKey;
	if (cocoaModifier & NSControlKeyMask) carbonModifier |= controlKey;
	if (cocoaModifier & NSCommandKeyMask) carbonModifier |= cmdKey;
	if (cocoaModifier & NSAlternateKeyMask) carbonModifier |= optionKey;
	
	return carbonModifier;
}


@end
