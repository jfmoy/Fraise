/*
Fraise version 3.7 - Based on Smultron by Peter Borg
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Fraise

Copyright 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "FRAExtraInterfaceController.h"
#import "FRATextMenuController.h"
#import "FRAProjectsController.h"
#import "FRAInterfacePerformer.h"
#import "FRAProject.h"


@implementation FRAExtraInterfaceController

@synthesize openPanelAccessoryView, openPanelEncodingsPopUp, commandResultWindow, commandResultTextView, newProjectWindow;



static id sharedInstance = nil;

+ (FRAExtraInterfaceController *)sharedInstance
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
		[[NSBundle mainBundle] loadNibNamed:@"FRAEntab" owner:self topLevelObjects:nil];
	}
	
    [FRACurrentWindow beginSheet:entabWindow completionHandler:^(NSModalResponse returnCode) {
    }];
}


- (void)displayDetab
{
	if (detabWindow == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"FRADetab" owner:self topLevelObjects:nil];
	}
	
    [FRACurrentWindow beginSheet:detabWindow completionHandler:^(NSModalResponse returnCode) {
    }];
}


- (IBAction)entabButtonEntabWindowAction:(id)sender
{
	[NSApp endSheet:[FRACurrentWindow attachedSheet]]; 
	[[FRACurrentWindow attachedSheet] close];
	
	[[FRATextMenuController sharedInstance] performEntab];
}


- (IBAction)detabButtonDetabWindowAction:(id)sender
{
	[NSApp endSheet:[FRACurrentWindow attachedSheet]]; 
	[[FRACurrentWindow attachedSheet] close];
	
	[[FRATextMenuController sharedInstance] performDetab];
}


- (IBAction)cancelButtonEntabDetabGoToLineWindowsAction:(id)sender
{
	[NSApp endSheet:[FRACurrentWindow attachedSheet]]; 
	[[FRACurrentWindow attachedSheet] close];
}


- (void)displayGoToLine
{
	if (goToLineWindow == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"FRAGoToLine" owner:self topLevelObjects:nil];
	}
	
    [FRACurrentWindow beginSheet:goToLineWindow completionHandler:^(NSModalResponse returnCode) {
    }];
}


- (IBAction)goButtonGoToLineWindowAction:(id)sender
{
	[NSApp endSheet:[FRACurrentWindow attachedSheet]]; 
	[[FRACurrentWindow attachedSheet] close];
	
	[[FRATextMenuController sharedInstance] performGoToLine:[lineTextFieldGoToLineWindow integerValue]];
}


- (NSPopUpButton *)openPanelEncodingsPopUp
{
	if (openPanelEncodingsPopUp == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"FRAOpenPanelAccessoryView" owner:self topLevelObjects:nil];
	}
	
	return openPanelEncodingsPopUp;
}


- (NSView *)openPanelAccessoryView
{
	if (openPanelAccessoryView == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"FRAOpenPanelAccessoryView" owner:self topLevelObjects:nil];
	}
	
	return openPanelAccessoryView;
}


- (NSWindow *)commandResultWindow
{
    if (commandResultWindow == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"FRACommandResult" owner:self topLevelObjects:nil];
		[commandResultWindow setTitle:COMMAND_RESULT_WINDOW_TITLE];
	}
	
	return commandResultWindow;
}


- (NSTextView *)commandResultTextView
{
    if (commandResultTextView == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"FRACommandResult" owner:self topLevelObjects:nil];
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
        [[NSBundle mainBundle] loadNibNamed:@"FRANewProject" owner:self topLevelObjects:nil];
	}
	
	return newProjectWindow;
}


- (IBAction)createNewProjectAction:(id)sender
{
	if ([[FRADefaults valueForKey:@"WhatKindOfProject"] integerValue] == FRAVirtualProject) {
		[newProjectWindow orderOut:nil]; 
		[[FRAProjectsController sharedDocumentController] newDocument:nil];
		[FRACurrentProject updateWindowTitleBarForDocument:nil];
		[FRACurrentProject selectionDidChange];	
	} else
    {
		NSSavePanel *savePanel = [NSSavePanel savePanel];
		[savePanel setAllowedFileTypes:@[@"fraiseProject"]];
        [savePanel setDirectoryURL: [NSURL fileURLWithPath: [FRAInterface whichDirectoryForSave]]];
        
        [savePanel beginSheetModalForWindow: newProjectWindow
                          completionHandler: (^(NSInteger returnCode)
                                              {
                                                  [savePanel close];
                                                  
                                                  [newProjectWindow orderOut:nil];
                                                  
                                                  if (returnCode == NSModalResponseOK)
                                                  {
                                                      NSURL *URL = [savePanel URL];
                                                      [[FRAProjectsController sharedDocumentController] newDocument:nil];
                                                      [FRACurrentProject setFileURL: URL];
                                                      [FRACurrentProject saveToURL: URL
                                                                            ofType: @"fraiseProject"
                                                                  forSaveOperation: NSSaveOperation
                                                                 completionHandler: ^(NSError* error) {
                                                                 }];
                                                      [FRACurrentProject updateWindowTitleBarForDocument:nil];
                                                      [FRACurrentProject saveDocument:nil];
                                                  }
                                              })];
	}
}

- (void)showRegularExpressionsHelpPanel
{
	if (regularExpressionsHelpPanel == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"FRARegularExpressionHelp" owner:self topLevelObjects:nil];
	}
	
	[regularExpressionsHelpPanel makeKeyAndOrderFront:nil];
}
@end
