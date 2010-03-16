/*
Smultron version 3.7
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Smultron

Copyright 2004-2009 Peter Borg - 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "SMLStandardHeader.h"

#import "SMLSingleDocumentWindowDelegate.h"
#import "SMLBasicPerformer.h"
#import "SMLSyntaxColouring.h"
#import "SMLLineNumbers.h"

@implementation SMLSingleDocumentWindowDelegate

static id sharedInstance = nil;

+ (SMLSingleDocumentWindowDelegate *)sharedInstance
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


- (void)windowDidResize:(NSNotification *)aNotification
{
	NSWindow *window = [aNotification object];
	NSArray *array = [SMLBasic fetchAll:@"Document"];
	id document;
	for (document in array) {
		if ([document valueForKey:@"singleDocumentWindow"] == window) {
			break;
		}
	}
	
	if (document == nil) {
		return;
	}
	
	array = [[window contentView] subviews];
	for (id view in array) {
		if (view == [document valueForKey:@"thirdTextScrollView"]) {
			[[document valueForKey:@"lineNumbers"] updateLineNumbersForClipView:[view contentView] checkWidth:NO recolour:YES];
		}
	}
	
	[SMLDefaults setValue:NSStringFromRect([window frame]) forKey:@"SingleDocumentWindow"];
}


- (BOOL)windowShouldClose:(id)sender
{
	NSArray *array = [SMLBasic fetchAll:@"Document"];
	for (id item in array) {
		if ([item valueForKey:@"singleDocumentWindow"] == sender) {
			[item setValue:nil forKey:@"singleDocumentWindow"];
			[item setValue:nil forKey:@"singleDocumentWindow"];
			[item setValue:nil forKey:@"thirdTextView"];
			[[item valueForKey:@"syntaxColouring"] setThirdLayoutManager:nil];
			break;
		}
	}
	
	[SMLDefaults setValue:NSStringFromRect([sender frame]) forKey:@"SingleDocumentWindow"];
	
	return YES;
}

@end
