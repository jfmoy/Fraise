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

#import "SMLExtraInterfaceController.h"
#import "SMLTextMenuController.h"
#import "SMLProjectsController.h"
#import "SMLInterfacePerformer.h"
#import "SMLProject.h"


@implementation SMLExtraInterfaceController

@synthesize openPanelAccessoryView, openPanelEncodingsPopUp, commandResultWindow, commandResultTextView, newProjectWindow;



static id sharedInstance = nil;

+ (SMLExtraInterfaceController *)sharedInstance
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


- (void)displayEntab
{
	if (entabWindow == nil) {
		[NSBundle loadNibNamed:@"SMLEntab.nib" owner:self];
	}
	
	[NSApp beginSheet:entabWindow modalForWindow:SMLCurrentWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}


- (void)displayDetab
{
	if (detabWindow == nil) {
		[NSBundle loadNibNamed:@"SMLDetab.nib" owner:self];
	}
	
	[NSApp beginSheet:detabWindow modalForWindow:SMLCurrentWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}


- (IBAction)entabButtonEntabWindowAction:(id)sender
{
	[NSApp endSheet:[SMLCurrentWindow attachedSheet]]; 
	[[SMLCurrentWindow attachedSheet] close];
	
	[[SMLTextMenuController sharedInstance] performEntab];
}


- (IBAction)detabButtonDetabWindowAction:(id)sender
{
	[NSApp endSheet:[SMLCurrentWindow attachedSheet]]; 
	[[SMLCurrentWindow attachedSheet] close];
	
	[[SMLTextMenuController sharedInstance] performDetab];
}


- (IBAction)cancelButtonEntabDetabGoToLineWindowsAction:(id)sender
{
	[NSApp endSheet:[SMLCurrentWindow attachedSheet]]; 
	[[SMLCurrentWindow attachedSheet] close];
}


- (void)displayGoToLine
{
	if (goToLineWindow == nil) {
		[NSBundle loadNibNamed:@"SMLGoToLine.nib" owner:self];
	}
	
	[NSApp beginSheet:goToLineWindow modalForWindow:SMLCurrentWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}


- (IBAction)goButtonGoToLineWindowAction:(id)sender
{
	[NSApp endSheet:[SMLCurrentWindow attachedSheet]]; 
	[[SMLCurrentWindow attachedSheet] close];
	
	[[SMLTextMenuController sharedInstance] performGoToLine:[lineTextFieldGoToLineWindow integerValue]];
}


//- (IBAction)setPrintFontAction:(id)sender
//{
//	NSFontManager *fontManager = [NSFontManager sharedFontManager];
//	[fontManager setSelectedFont:[NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:@"PrintFont"]] isMultiple:NO];
//	[fontManager orderFrontFontPanel:nil];
//}


- (NSPopUpButton *)openPanelEncodingsPopUp
{
	if (openPanelEncodingsPopUp == nil) {
		[NSBundle loadNibNamed:@"SMLOpenPanelAccessoryView.nib" owner:self];
	}
	
	return openPanelEncodingsPopUp;
}


- (NSView *)openPanelAccessoryView
{
	if (openPanelAccessoryView == nil) {
		[NSBundle loadNibNamed:@"SMLOpenPanelAccessoryView.nib" owner:self];
	}
	
	return openPanelAccessoryView;
}


//- (NSView *)printAccessoryView
//{
//	if (printAccessoryView == nil) {
//		[NSBundle loadNibNamed:@"SMLPrintAccessoryView.nib" owner:self];
//	}
//	
//	return printAccessoryView;
//}


- (NSWindow *)commandResultWindow
{
    if (commandResultWindow == nil) {
		[NSBundle loadNibNamed:@"SMLCommandResult.nib" owner:self];
		[commandResultWindow setTitle:COMMAND_RESULT_WINDOW_TITLE];
	}
	
	return commandResultWindow;
}


- (NSTextView *)commandResultTextView
{
    if (commandResultTextView == nil) {
		[NSBundle loadNibNamed:@"SMLCommandResult.nib" owner:self];
		[commandResultWindow setTitle:COMMAND_RESULT_WINDOW_TITLE];		
	}
	
	return commandResultTextView; 
}


- (void)showCommandResultWindow
{
	[[self commandResultWindow] makeKeyAndOrderFront:nil];
}



- (NSWindow *)newProjectWindow
{
	if (newProjectWindow == nil) {
		[NSBundle loadNibNamed:@"SMLNewProject.nib" owner:self];
	}
	
	return newProjectWindow;
}


- (IBAction)createNewProjectAction:(id)sender
{
	if ([[SMLDefaults valueForKey:@"WhatKindOfProject"] integerValue] == SMLVirtualProject) {
		[newProjectWindow orderOut:nil]; 
		[[SMLProjectsController sharedDocumentController] newDocument:nil];
		[SMLCurrentProject updateWindowTitleBarForDocument:nil];
		[SMLCurrentProject selectionDidChange];	
	} else {
		NSSavePanel *savePanel = [NSSavePanel savePanel];
		[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"smultronProject"]];
		[savePanel beginSheetForDirectory:[SMLInterface whichDirectoryForSave]
									 file:nil
						   modalForWindow:newProjectWindow
							modalDelegate:self
						   didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
							  contextInfo:nil];
	}	
}


- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[sheet close];
	
	[newProjectWindow orderOut:nil];
	
	if (returnCode == NSOKButton) {
		[[SMLProjectsController sharedDocumentController] newDocument:nil];
		[SMLCurrentProject setFileURL:[NSURL fileURLWithPath:[sheet filename]]];
		[SMLCurrentProject saveToURL:[NSURL fileURLWithPath:[sheet filename]] ofType:@"smultronProject" forSaveOperation:NSSaveOperation error:nil];
		[SMLCurrentProject updateWindowTitleBarForDocument:nil];
		[SMLCurrentProject saveDocument:nil];
	}
}


- (void)showRegularExpressionsHelpPanel
{
	if (regularExpressionsHelpPanel == nil) {
		[NSBundle loadNibNamed:@"SMLRegularExpressionHelp.nib" owner:self];
	}
	
	[regularExpressionsHelpPanel makeKeyAndOrderFront:nil];
}
@end
