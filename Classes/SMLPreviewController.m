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

#import "SMLPreviewController.h"
#import "SMLProjectsController.h"
#import "SMLBasicPerformer.h"
#import "SMLProject.h"

@implementation SMLPreviewController

@synthesize previewWindow;

static id sharedInstance = nil;

+ (SMLPreviewController *)sharedInstance
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


- (void)showPreviewWindow
{	
	if (previewWindow != nil) {
		[previewWindow close];
	}
	
	[NSBundle loadNibNamed:@"SMLPreview.nib" owner:self]; // Otherwise [webView mainFrame] return nil the second time the window loads
		
	[webView setResourceLoadDelegate:self];
	[webView setFrameLoadDelegate:self];
	[previewWindow makeKeyAndOrderFront:self];

	[self reload];
}


- (void)reload
{
	if ([SMLCurrentProject areThereAnyDocuments]) {
		
		scrollPoint = [[[[[[webView mainFrame] frameView] documentView] enclosingScrollView] contentView] bounds].origin;
			
		[[NSURLCache sharedURLCache] removeAllCachedResponses];

		NSURL *baseURL;
		if ([[SMLDefaults valueForKey:@"BaseURL"] isEqualToString:@""]) { // If no base URL is supplied use the document path
			if ([[SMLCurrentDocument valueForKey:@"isNewDocument"] boolValue] == NO) {
				NSString *path = [NSString stringWithString:[SMLCurrentDocument valueForKey:@"path"]];
				baseURL = [NSURL fileURLWithPath:path];
			} else {
				baseURL = [NSURL URLWithString:@""];
			}
		} else {
			baseURL = [NSURL URLWithString:[[SMLDefaults valueForKey:@"BaseURL"] stringByAppendingPathComponent:[SMLCurrentDocument valueForKey:@"name"]]];
		}
		
		if ([SMLCurrentDocument valueForKey:@"path"] != nil) {
			NSString *path;
			if ([[SMLCurrentDocument valueForKey:@"fromExternal"] boolValue] == NO) {
				path = [SMLCurrentDocument valueForKey:@"path"];
			} else {
				path = [SMLCurrentDocument valueForKey:@"externalPath"];
			}
			[previewWindow setTitle:[NSString stringWithFormat:@"%@ - %@", path, PREVIEW_STRING]];
		} else {
			[previewWindow setTitle:[NSString stringWithFormat:@"%@ - %@", [SMLCurrentDocument valueForKey:@"name"], PREVIEW_STRING]];
		}
		
		NSData *data;
		if ([[SMLDefaults valueForKey:@"PreviewParser"] integerValue] == SMLPreviewHTML) {
			data = [SMLCurrentText dataUsingEncoding:NSUTF8StringEncoding];
		} else {
			NSString *temporaryPathMarkdown = [SMLBasic genererateTemporaryPath];
			[SMLCurrentText writeToFile:temporaryPathMarkdown atomically:YES encoding:[[SMLCurrentDocument valueForKey:@"encoding"] integerValue] error:nil];
			NSString *temporaryPathHTML = [SMLBasic genererateTemporaryPath];
			NSString *htmlString;
			if ([[NSFileManager defaultManager] fileExistsAtPath:temporaryPathMarkdown]) {
				if ([[SMLDefaults valueForKey:@"PreviewParser"] integerValue] == SMLPreviewMarkdown) {
					system([[NSString stringWithFormat:@"/usr/bin/perl %@ %@ > %@", [[NSBundle mainBundle] pathForResource:@"Markdown" ofType:@"pl"], temporaryPathMarkdown, temporaryPathHTML] UTF8String]);
				} else {
					system([[NSString stringWithFormat:@"/usr/bin/perl %@ %@ > %@", [[NSBundle mainBundle] pathForResource:@"MultiMarkdown" ofType:@"pl"], temporaryPathMarkdown, temporaryPathHTML] UTF8String]);
				}
				if ([[NSFileManager defaultManager] fileExistsAtPath:temporaryPathMarkdown]) {
					htmlString = [NSString stringWithContentsOfFile:temporaryPathHTML encoding:[[SMLCurrentDocument valueForKey:@"encoding"] integerValue] error:nil];
					[[NSFileManager defaultManager] removeItemAtPath:temporaryPathHTML error:nil];
				} else {
					htmlString = SMLCurrentText;
				}
				[[NSFileManager defaultManager] removeItemAtPath:temporaryPathMarkdown error:nil];
			} else {
				htmlString = SMLCurrentText;
			}
			data = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
		}
		
		[[webView mainFrame] loadData:data MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:baseURL];
	} else {
		[[webView mainFrame] loadHTMLString:@"" baseURL:[NSURL URLWithString:@""]];
		[previewWindow setTitle:PREVIEW_STRING];
	}

}


- (IBAction)reloadAction:(id)sender
{
	[self reload];
}


- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource
{
	if ([[SMLDefaults valueForKey:@"PreviewParser"] integerValue] == SMLPreviewHTML) {
		NSURL *url = [request URL];
		NSURLRequest *noCacheRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:120];
		return noCacheRequest;
	} else {
		return request;
	}
}


- (void)liveUpdate
{
	if (previewWindow != nil && [previewWindow isVisible]) {
		[webView setResourceLoadDelegate:nil];
		[self reload];
		[webView setResourceLoadDelegate:self];
	}
}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	[[[[[[webView mainFrame] frameView] documentView] enclosingScrollView] contentView] scrollPoint:scrollPoint];
}
@end
