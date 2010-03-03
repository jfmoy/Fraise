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

#import "SMLHelpMenuController.h"
#import "SMLProjectsController.h"
#import "SMLAuthenticationController.h"

@implementation SMLHelpMenuController

- (IBAction)installCommandLineUtilityAction:(id)sender
{
	if ([SMLCurrentWindow attachedSheet] != nil) {
		[[SMLCurrentWindow attachedSheet] close];
	}
	
	NSBeginAlertSheet(NSLocalizedString(@"Are you sure you want to install the command-line utility?", @"Ask if they are sure they want to install the command-line utility in Install-command-line-utility sheet"),
					  NSLocalizedString(@"Install", @"Install-button in Install-command-line-utility sheet"),
					  NSLocalizedString(@"Put On Desktop", @"Put On Desktop-button in Install-command-line-utility sheet"),
					  CANCEL_BUTTON,
					  SMLCurrentWindow,
					  self,
					  @selector(installCommandLineUtiltiySheetDidEnd:returnCode:contextInfo:),
					  nil,
					  nil,
					  NSLocalizedString(@"If you choose Install smultron will be installed in /usr/bin and its man page in /usr/share/man/man1 and you can use it directly in the Terminal (you may need to authenticate twice with an administrators username and password). Otherwise you can choose to place all the files you need on the Desktop and install it manually.", @"Indicate that if you choose Install smultron will be installed in /usr/bin and its man page in /usr/share/man/man1 and you can use it directly in the Terminal (you may need to authenticate twice with an administrators username and password). Otherwise you can choose to place all the files you need on the desktop and install it manually. in Install-command-line-utility sheet"));
}


- (void)installCommandLineUtiltiySheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn) {
		[[SMLAuthenticationController sharedInstance] installCommandLineUtility];
	} else if (returnCode == NSAlertAlternateReturn) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		NSString *pathToFolder = [[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"]
        stringByAppendingPathComponent:@"Smultron command-line utility"];
		[fileManager createDirectoryAtPath:pathToFolder withIntermediateDirectories:YES attributes:nil error:nil];
		
		[workspace performFileOperation:NSWorkspaceCopyOperation source:[[NSBundle mainBundle] resourcePath] destination:pathToFolder files:[NSArray arrayWithObjects:@"smultron", @"smultron.1", @"smultron - installation instructions", nil] tag:NULL];
	}
}


- (IBAction)smultronHelp:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"Smultron-Manual" ofType:@"pdf"]];
}

@end
