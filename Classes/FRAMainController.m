/*
 Fraise version 3.7 - Based on Smultron by Peter Borg
 
 Current Maintainer (2016): 
 Andreas Bentele: abentele.github@icloud.com (https://github.com/abentele/Fraise)
 
 Maintainer before macOS Sierra (2010-2016): 
 Jean-François Moy: jeanfrancois.moy@gmail.com (http://github.com/jfmoy/Fraise)

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

#import <SystemConfiguration/SCNetworkReachability.h>

#import "FRAMainController.h"
#import "FRAPreferencesController.h"
#import "FRATextMenuController.h"
#import "FRABasicPerformer.h"
#import "FRAVariousPerformer.h"
#import "FRAFontTransformer.h"

@implementation FRAMainController

@synthesize operationQueue;


static id sharedInstance = nil;

+ (FRAMainController *)sharedInstance
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
	[FRABasic insertFetchRequests];
	
	[[FRAPreferencesController sharedInstance] setDefaults];	
	
	FRAFontTransformer *fontTransformer = [[FRAFontTransformer alloc] init];
    [NSValueTransformer setValueTransformer: fontTransformer
                                    forName: @"FontTransformer"];
}


- (void)awakeFromNib
{
	// If the application crashed so these weren't removed, remove them now
	[FRABasic removeAllObjectsForEntity:@"Document"];
	[FRABasic removeAllObjectsForEntity:@"Encoding"];
	[FRABasic removeAllObjectsForEntity:@"SyntaxDefinition"];
	[FRABasic removeAllObjectsForEntity:@"Project"];
	
	[FRAVarious insertTextEncodings];
	[FRAVarious insertSyntaxDefinitions];
	[FRAVarious insertDefaultSnippets];
	[FRAVarious insertDefaultCommands];
	
	[[FRATextMenuController sharedInstance] buildSyntaxDefinitionsMenu];
	[[FRATextMenuController sharedInstance] buildEncodingsMenus];
	
	[FRAVarious updateCheckIfAnotherApplicationHasChangedDocumentsTimer];
}

@end
