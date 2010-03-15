/*
Smultron version 3.7a1, 2009-09-12
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Smultron

Copyright 2004-2009 Peter Borg - 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import <SystemConfiguration/SCNetworkReachability.h>

#import "SMLStandardHeader.h"

#import "SMLMainController.h"
#import "SMLPreferencesController.h"
#import "SMLTextMenuController.h"
#import "SMLBasicPerformer.h"
#import "SMLVariousPerformer.h"
#import "SMLFontTransformer.h"

#define THISVERSION 3.71

@implementation SMLMainController

@synthesize isInFullScreenMode, singleDocumentWindowWasOpenBeforeEnteringFullScreen, operationQueue;


static id sharedInstance = nil;

+ (SMLMainController *)sharedInstance
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
		
		operationQueue = [[NSOperationQueue alloc] init];
    }
    return sharedInstance;
}


+ (void)initialize
{
	SInt32 systemVersion;
	if (Gestalt(gestaltSystemVersion, &systemVersion) == noErr) {
		if (systemVersion < 0x1050) {
			[NSApp activateIgnoringOtherApps:YES];
			[SMLVarious alertWithMessage:[NSString stringWithFormat:NSLocalizedStringFromTable(@"You need %@ or later to run this version of Smultron", @"Localizable3", @"You need %@ or later to run this version of Smultron"), @"Mac OS X 10.5 Leopard"] informativeText:NSLocalizedStringFromTable(@"Go to the web site (http://smultron.sourceforge.net) to download another version for an earlier Mac OS X system", @"Localizable3", @"Go to the web site (http://smultron.sourceforge.net) to download another version for an earlier Mac OS X system") defaultButton:OK_BUTTON alternateButton:nil otherButton:nil];
			
			[NSApp terminate:nil];
		}
	}
	
	[SMLBasic insertFetchRequests];
	
	[[SMLPreferencesController sharedInstance] setDefaults];	
	
	NSValueTransformer *fontTransformer = [[SMLFontTransformer alloc] init];
    [NSValueTransformer setValueTransformer:fontTransformer forName:@"FontTransformer"];
	
	
}


- (void)awakeFromNib
{
	// If the application crashed so these weren't removed, remove them now
	[SMLBasic removeAllObjectsForEntity:@"Document"];
	[SMLBasic removeAllObjectsForEntity:@"Encoding"];
	[SMLBasic removeAllObjectsForEntity:@"SyntaxDefinition"];
	[SMLBasic removeAllObjectsForEntity:@"Project"];
	
	[SMLVarious insertTextEncodings];
	[SMLVarious insertSyntaxDefinitions];
	[SMLVarious insertDefaultSnippets];
	[SMLVarious insertDefaultCommands];
	
	[[SMLTextMenuController sharedInstance] buildSyntaxDefinitionsMenu];
	[[SMLTextMenuController sharedInstance] buildEncodingsMenus];
	
	isInFullScreenMode = NO;
	
	[SMLVarious updateCheckIfAnotherApplicationHasChangedDocumentsTimer];
	
	// Verify check update period and program the update check if necessary.
	if ([[SMLDefaults valueForKey:@"CheckForUpdatesInterval"] integerValue] != SMLCheckForUpdatesNever) {
		BOOL checkForUpdates = NO;
		if ([SMLDefaults valueForKey:@"LastCheckForUpdateDate"] == nil) {
			checkForUpdates = YES;
		} else { 
			NSDate *lastCheckDate = [NSUnarchiver unarchiveObjectWithData:[SMLDefaults valueForKey:@"LastCheckForUpdateDate"]];

			if ([[SMLDefaults valueForKey:@"CheckForUpdatesInterval"] integerValue] == SMLCheckForUpdatesDaily) {
				if ([[NSDate dateWithTimeInterval:(60 * 60 * 24) sinceDate:lastCheckDate] compare:[NSDate date]] == NSOrderedAscending) {
					checkForUpdates = YES;
				}
			} else if ([[SMLDefaults valueForKey:@"CheckForUpdatesInterval"] integerValue] == SMLCheckForUpdatesWeekly) {
				if ([[NSDate dateWithTimeInterval:(60 * 60 * 24 * 7) sinceDate:lastCheckDate] compare:[NSDate date]] == NSOrderedAscending) {
					checkForUpdates = YES;
				}
			} else if ([[SMLDefaults valueForKey:@"CheckForUpdatesInterval"] integerValue] == SMLCheckForUpdatesMonthly) {
				if ([[NSDate dateWithTimeInterval:(60 * 60 * 24 * 30) sinceDate:lastCheckDate] compare:[NSDate date]] == NSOrderedAscending) {
					checkForUpdates = YES;
				}
			}
		}

		
		if (checkForUpdates == YES) {
			checkForUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(checkForUpdate) userInfo:nil repeats:NO];
		}									
	}
}


- (void)checkForUpdate
{	
	if (checkForUpdateTimer != nil) {
		[checkForUpdateTimer invalidate];
		checkForUpdateTimer = nil;
	}
	
	[NSThread detachNewThreadSelector:@selector(checkForUpdateInSeparateThread) toTarget:self withObject:nil];
}


/**
 * This method connects to the smultron website and download a property file which contains the latest version number.
 * If the version number is > to the actual version number, we notify the user.
 */
- (void)checkForUpdateInSeparateThread
{
	NSAutoreleasePool *checkUpdatePool = [[NSAutoreleasePool alloc] init];	

	// Checking the website availability.
	SCNetworkConnectionFlags status = 0;
	SCNetworkReachabilityRef target = SCNetworkReachabilityCreateWithName(NULL, "github.com");
	
	BOOL success = SCNetworkReachabilityGetFlags(target, &status);
	CFRelease(target);
	
	BOOL connected = success && (status & kSCNetworkFlagsReachable) && !(status & kSCNetworkFlagsConnectionRequired); 
	if (connected) {
		NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:@"http://github.com/downloads/jfmoy/Smultron/checkForUpdate.plist"]];
		if (dictionary) {
				float thisVersion = THISVERSION;
				float latestVersion = [[dictionary valueForKey:@"latestVersion"] floatValue];
				if (latestVersion > thisVersion) {
					[self performSelectorOnMainThread:@selector(updateInterfaceOnMainThreadAfterCheckForUpdateFoundNewUpdate:) withObject:dictionary waitUntilDone:YES];
				} else {
					[self performSelectorOnMainThread:@selector(updateInterfaceOnMainThreadAfterCheckForUpdateFoundNewUpdate:) withObject:nil waitUntilDone:YES];
				}
				
				// Store the last update date.
				[SMLDefaults setValue:[NSArchiver archivedDataWithRootObject:[NSDate date]] forKey:@"LastCheckForUpdateDate"];
		}
	}
	[checkUpdatePool drain];
}

/**
 * This method is used to notify the user (through a dialog box) of a new update and download it if the user accepts it.
 */
- (void)updateInterfaceOnMainThreadAfterCheckForUpdateFoundNewUpdate:(id)sender
{
	if (sender != nil && [sender isKindOfClass:[NSDictionary class]]) {
		NSInteger returnCode = [SMLVarious alertWithMessage:[NSString stringWithFormat:NSLocalizedString(@"A newer version (%@) is available. Do you want to download it?", @"A newer version (%@) is available. Do you want to download it? in checkForUpdate"), [sender valueForKey:@"latestVersionString"]] informativeText:@"" defaultButton:NSLocalizedString(@"Download", @"Download") alternateButton:CANCEL_BUTTON otherButton:nil];
		if (returnCode == NSAlertFirstButtonReturn) {
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[sender valueForKey:@"downloadURL"]]];
		}
		
	} else {
		if ([[[SMLPreferencesController sharedInstance] preferencesWindow] isVisible] == YES) {
			[[[SMLPreferencesController sharedInstance] noUpdateAvailableTextField] setHidden:NO];
			hideNoUpdateAvailableTextFieldTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(hideNoUpdateAvailableTextField) userInfo:nil repeats:NO];
		}
	}
	
}


- (void)hideNoUpdateAvailableTextField
{
	if (hideNoUpdateAvailableTextFieldTimer) {
		[hideNoUpdateAvailableTextFieldTimer invalidate];
		hideNoUpdateAvailableTextFieldTimer = nil;
	}
	
	[[[SMLPreferencesController sharedInstance] noUpdateAvailableTextField] setHidden:YES];
}

@end
