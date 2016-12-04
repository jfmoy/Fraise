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


#import <Cocoa/Cocoa.h>

@interface FRAApplicationDelegate : NSObject <NSApplicationDelegate>
{
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
	
	BOOL shouldCreateEmptyDocument;
	BOOL hasFinishedLaunching;
	BOOL isTerminatingApplication;
	
	NSMutableArray *filesToOpenArray;
	NSAppleEventDescriptor *appleEventDescriptor;

}

@property (readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly) NSManagedObjectModel *managedObjectModel;
@property (readonly) NSManagedObjectContext *managedObjectContext;

@property (readonly) BOOL shouldCreateEmptyDocument, hasFinishedLaunching, isTerminatingApplication;

@property (readonly) NSMutableArray *filesToOpenArray;
@property  NSAppleEventDescriptor *appleEventDescriptor;


+ (FRAApplicationDelegate *)sharedInstance;

- (IBAction)saveAction:sender;

- (void)importFromVersion2;

@end
