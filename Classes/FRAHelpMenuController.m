/*
Fraise version 3.7 - Based on Smultron by Peter Borg
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Fraise

Copyright 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "FRAStandardHeader.h"

#import "FRAHelpMenuController.h"
#import "FRAProjectsController.h"
#import "FRAAuthenticationController.h"

@implementation FRAHelpMenuController

- (IBAction)installCommandLineUtilityAction:(id)sender
{
	if ([FRACurrentWindow attachedSheet] != nil) {
		[[FRACurrentWindow attachedSheet] close];
	}
	
	NSBeginAlertSheet(NSLocalizedString(@"Are you sure you want to install the command-line utility?", @"Ask if they are sure they want to install the command-line utility in Install-command-line-utility sheet"),
					  NSLocalizedString(@"Install", @"Install-button in Install-command-line-utility sheet"),
					  NSLocalizedString(@"Put On Desktop", @"Put On Desktop-button in Install-command-line-utility sheet"),
					  CANCEL_BUTTON,
					  FRACurrentWindow,
					  self,
					  @selector(installCommandLineUtiltiySheetDidEnd:returnCode:contextInfo:),
					  nil,
					  nil,
					  NSLocalizedString(@"If you choose Install fraise will be installed in /usr/bin and its man page in /usr/share/man/man1 and you can use it directly in the Terminal (you may need to authenticate twice with an administrators username and password). Otherwise you can choose to place all the files you need on the Desktop and install it manually.", @"Indicate that if you choose Install fraise will be installed in /usr/bin and its man page in /usr/share/man/man1 and you can use it directly in the Terminal (you may need to authenticate twice with an administrators username and password). Otherwise you can choose to place all the files you need on the desktop and install it manually. in Install-command-line-utility sheet"));
}


- (void)installCommandLineUtiltiySheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn) {
		[[FRAAuthenticationController sharedInstance] installCommandLineUtility];
	} else if (returnCode == NSAlertAlternateReturn) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		NSString *pathToFolder = [[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"]
        stringByAppendingPathComponent:@"Fraise command-line utility"];
		[fileManager createDirectoryAtPath:pathToFolder withIntermediateDirectories:YES attributes:nil error:nil];
		
		[workspace performFileOperation:NSWorkspaceCopyOperation source:[[NSBundle mainBundle] resourcePath] destination:pathToFolder files:@[@"fraise", @"fraise.1", @"fraise - installation instructions"] tag:NULL];
	}
}


- (IBAction)fraiseHelp:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"Fraise-Manual" ofType:@"pdf"]];
}

@end
