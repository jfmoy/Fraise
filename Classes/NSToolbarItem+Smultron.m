/*
Smultron version 3.7
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Smultron

Copyright 2004-2009 Peter Borg - 2010 Jean-François Moy

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "NSToolbarItem+Smultron.h"


@implementation NSToolbarItem (NSToolbarItemSmultron)


+ (NSToolbarItem *)createToolbarItemWithIdentifier:(NSString *)itemIdentifier name:(NSString *)name image:(NSImage *)image action:(SEL)selector tag:(NSInteger)tag target:(id)target
{
	NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	
//	[toolbarItem setLabel:name];
//	[toolbarItem setPaletteLabel:name];
//	[toolbarItem setToolTip:name];
//	[toolbarItem setTag:tag];
//	
//	[toolbarItem setImage:image];
//	[toolbarItem setTarget:target];
//	[toolbarItem setAction:selector];
	
	NSRect toolbarItemRect = NSMakeRect(0.0, 0.0, 28.0, 27.0);
	
	NSView *view = [[NSView alloc] initWithFrame:toolbarItemRect];
	NSButton *button = [[NSButton alloc] initWithFrame:toolbarItemRect];
	[button setBezelStyle:NSTexturedRoundedBezelStyle];
	[button setTitle:@""];
	[button setImage:image];
	[button setTarget:target];
	[button setAction:selector];
	[[button cell] setImageScaling:NSImageScaleProportionallyDown];
	[button setImagePosition:NSImageOnly];
	
	[toolbarItem setLabel:name];
	[toolbarItem setPaletteLabel:name];
	[toolbarItem setToolTip:name];
	
	[view addSubview:button];
	
	[toolbarItem setTag:tag];
	[toolbarItem setView:view];
	
	return toolbarItem;
}


+ (NSToolbarItem *)createPreferencesToolbarItemWithIdentifier:(NSString *)itemIdentifier name:(NSString *)name image:(NSImage *)image action:(SEL)selector target:(id)target
{
	NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	
	[toolbarItem setLabel:name];
	[toolbarItem setPaletteLabel:name];
	[toolbarItem setToolTip:name];
	
	[toolbarItem setImage:image];
	[toolbarItem setTarget:target];
	[toolbarItem setAction:selector];
	
	return toolbarItem;
}


+ (NSToolbarItem *)createSeachFieldToolbarItemWithIdentifier:(NSString *)itemIdentifier name:(NSString *)name view:(NSView *)view
{
	NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	[toolbarItem setLabel:name];
	[toolbarItem setToolTip:name];
	[toolbarItem setPaletteLabel:name];
	[toolbarItem setView:view];
	[toolbarItem setMinSize:NSMakeSize(70, 32)];
	[toolbarItem setMaxSize:NSMakeSize(200, 32)];

	return toolbarItem;
}
@end
