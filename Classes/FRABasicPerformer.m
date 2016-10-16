/*
Fraise version 3.7 - Based on Smultron by Peter Borg
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Fraise

Copyright 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "FRABasicPerformer.h"
#import "FRAApplicationDelegate.h"

@implementation FRABasicPerformer

static id sharedInstance = nil;

+ (FRABasicPerformer *)sharedInstance
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
		
		thousandFormatter = [[NSNumberFormatter alloc] init];
		[thousandFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[thousandFormatter setFormat:@"#,##0"];	
    }
    return sharedInstance;
}


- (void)insertFetchRequests
{
	NSManagedObjectContext *managedObjectContext = FRAManagedObjectContext;
	NSEntityDescription *entityDescription;
	NSFetchRequest *request;
	NSSortDescriptor *sortDescriptor;
	fetchRequests = [[NSMutableDictionary alloc] init];
	
	entityDescription = [NSEntityDescription entityForName:@"Command" inManagedObjectContext:managedObjectContext];
	request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	[fetchRequests setValue:request forKey:@"Command"];
	
	entityDescription = [NSEntityDescription entityForName:@"CommandCollection" inManagedObjectContext:managedObjectContext];
	request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	[fetchRequests setValue:request forKey:@"CommandCollection"];
	
	entityDescription = [NSEntityDescription entityForName:@"CommandCollection" inManagedObjectContext:managedObjectContext];
	request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	[request setSortDescriptors:@[sortDescriptor]];
	[fetchRequests setValue:request forKey:@"CommandCollectionSortKeyName"];
	
	entityDescription = [NSEntityDescription entityForName:@"Document" inManagedObjectContext:managedObjectContext];
	request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	[fetchRequests setValue:request forKey:@"Document"];
	
	entityDescription = [NSEntityDescription entityForName:@"Document" inManagedObjectContext:managedObjectContext];
	request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	[request setSortDescriptors:@[sortDescriptor]];
	[fetchRequests setValue:request forKey:@"DocumentSortKeyName"];	
	
	entityDescription = [NSEntityDescription entityForName:@"Encoding" inManagedObjectContext:managedObjectContext];
	request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	[fetchRequests setValue:request forKey:@"Encoding"];

	entityDescription = [NSEntityDescription entityForName:@"Encoding" inManagedObjectContext:managedObjectContext];
	request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	[request setSortDescriptors:@[sortDescriptor]];
	[fetchRequests setValue:request forKey:@"EncodingSortKeyName"];

	entityDescription = [NSEntityDescription entityForName:@"Project" inManagedObjectContext:managedObjectContext];
	request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	[fetchRequests setValue:request forKey:@"Project"];
	
	entityDescription = [NSEntityDescription entityForName:@"Snippet" inManagedObjectContext:managedObjectContext];
	request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	[fetchRequests setValue:request forKey:@"Snippet"];
	
	entityDescription = [NSEntityDescription entityForName:@"SnippetCollection" inManagedObjectContext:managedObjectContext];
	request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	[fetchRequests setValue:request forKey:@"SnippetCollection"];
	
	entityDescription = [NSEntityDescription entityForName:@"SnippetCollection" inManagedObjectContext:managedObjectContext];
	request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	[request setSortDescriptors:@[sortDescriptor]];
	[fetchRequests setValue:request forKey:@"SnippetCollectionSortKeyName"];
	
	entityDescription = [NSEntityDescription entityForName:@"SyntaxDefinition" inManagedObjectContext:managedObjectContext];
	request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	[fetchRequests setValue:request forKey:@"SyntaxDefinition"];
	
	entityDescription = [NSEntityDescription entityForName:@"SyntaxDefinition" inManagedObjectContext:managedObjectContext];
	request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES];
	[request setSortDescriptors:@[sortDescriptor]];
	[fetchRequests setValue:request forKey:@"SyntaxDefinitionSortKeySortOrder"];
}


- (NSArray *)fetchAll:(NSString *)key
{
	return [FRAManagedObjectContext executeFetchRequest:[fetchRequests valueForKey:key] error:nil];
}


- (NSFetchRequest *)fetchRequest:(NSString *)key
{
	return [fetchRequests valueForKey:key];
}


- (id)createNewObjectForEntity:(NSString *)entity
{
	NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:entity inManagedObjectContext:FRAManagedObjectContext];
	
	return object;
}


- (void)removeAllObjectsForEntity:(NSString *)entity
{
	NSArray *array = [self fetchAll:entity];
	for (id item in array) {
		[FRAManagedObjectContext deleteObject:item];
	}
}


- (NSURL *)uriFromObject:(id)object
{
	if ([[object objectID] isTemporaryID] == YES) {
		[[FRAApplicationDelegate sharedInstance] saveAction:nil];
	}
	
	return [[object objectID] URIRepresentation];
}


- (id)objectFromURI:(NSURL *)uri
{
	NSManagedObjectContext *managedObjectContext = FRAManagedObjectContext;
	NSManagedObjectID *objectID = [[managedObjectContext persistentStoreCoordinator]
    managedObjectIDForURIRepresentation:uri];
	
	
	return [managedObjectContext objectWithID:objectID];	
}


- (void)removeAllItemsFromMenu:(NSMenu *)menu
{
	NSArray *array = [menu itemArray];
	for (id item in array) {
		[menu removeItem:item];
	}
}


- (NSString *)createUUID
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);

    return (__bridge NSString *)uuidString;
}


- (void)insertSortOrderNumbersForArrayController:(NSArrayController *)arrayController
{
	NSArray *array = [arrayController arrangedObjects];
	NSInteger index = 0;
	for (id item in array) {
		[item setValue:@(index) forKey:@"sortOrder"];
		index++;
	}
}


- (NSString *)genererateTemporaryPath
{
	NSInteger sequenceNumber = 0;
	NSString *temporaryPath;
	do {
		sequenceNumber++;
		temporaryPath = [NSString stringWithFormat:@"%d-%ld-%ld.%@", [[NSProcessInfo processInfo] processIdentifier], (NSInteger)[NSDate timeIntervalSinceReferenceDate], sequenceNumber, @"Fraise"];
		temporaryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:temporaryPath];
	} while ([[NSFileManager defaultManager] fileExistsAtPath:temporaryPath]);
	
	return temporaryPath;
}


- (NSString *)thousandFormatedStringFromNumber:(NSNumber *)number
{
	return [thousandFormatter stringFromNumber:number];
}


- (NSString *)resolveAliasInPath:(NSString *)path
{
	NSString *resolvedPath = nil;
	CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef)path, kCFURLPOSIXPathStyle, NO);
	
	if (url != NULL) {
		FSRef fsRef;
		if (CFURLGetFSRef(url, &fsRef)) {
			Boolean targetIsFolder, wasAliased;
			if (FSResolveAliasFile (&fsRef, true, &targetIsFolder, &wasAliased) == noErr && wasAliased) {
				CFURLRef resolvedURL = CFURLCreateFromFSRef(NULL, &fsRef);
				if (resolvedURL != NULL) {
					resolvedPath = (NSString*)CFBridgingRelease(CFURLCopyFileSystemPath(resolvedURL, kCFURLPOSIXPathStyle));
				}
			}
		}
	}
	
	if (resolvedPath==nil) {
		return path;
	}
	
	return resolvedPath;
}

@end
