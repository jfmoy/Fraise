/*
Fraise version 3.7 - Based on Smultron by Peter Borg
Written by Jean-François Moy - jeanfrancois.moy@gmail.com
Find the latest version at http://github.com/jfmoy/Fraise

Copyright 2010 Jean-François Moy
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "FRAPreviewController.h"
#import "FRAProjectsController.h"
#import "FRABasicPerformer.h"
#import "FRAProject.h"

@implementation FRAPreviewController

@synthesize previewWindow;

static id sharedInstance = nil;

+ (FRAPreviewController *)sharedInstance
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
	
    [[NSBundle mainBundle] loadNibNamed:@"FRAPreview" owner:self topLevelObjects:nil]; // Otherwise [webView mainFrame] return nil the second time the window loads
		
	[webView setResourceLoadDelegate:self];
	[webView setFrameLoadDelegate:self];
	[previewWindow makeKeyAndOrderFront:self];

	[self reload];
}


- (void)reload
{
	if ([FRACurrentProject areThereAnyDocuments]) {
		
		scrollPoint = [[[[[[webView mainFrame] frameView] documentView] enclosingScrollView] contentView] bounds].origin;
			
		[[NSURLCache sharedURLCache] removeAllCachedResponses];

		NSURL *baseURL;
		if ([[FRADefaults valueForKey:@"BaseURL"] isEqualToString:@""]) { // If no base URL is supplied use the document path
			if ([[FRACurrentDocument valueForKey:@"isNewDocument"] boolValue] == NO) {
				NSString *path = [NSString stringWithString:[FRACurrentDocument valueForKey:@"path"]];
				baseURL = [NSURL fileURLWithPath:path];
			} else {
				baseURL = [NSURL URLWithString:@""];
			}
		} else {
			baseURL = [NSURL URLWithString:[[FRADefaults valueForKey:@"BaseURL"] stringByAppendingPathComponent:[FRACurrentDocument valueForKey:@"name"]]];
		}
		
		if ([FRACurrentDocument valueForKey:@"path"] != nil) {
			NSString *path;
			if ([[FRACurrentDocument valueForKey:@"fromExternal"] boolValue] == NO) {
				path = [FRACurrentDocument valueForKey:@"path"];
			} else {
				path = [FRACurrentDocument valueForKey:@"externalPath"];
			}
			[previewWindow setTitle:[NSString stringWithFormat:@"%@ - %@", path, PREVIEW_STRING]];
		} else {
			[previewWindow setTitle:[NSString stringWithFormat:@"%@ - %@", [FRACurrentDocument valueForKey:@"name"], PREVIEW_STRING]];
		}
		
		NSData *data;
		if ([[FRADefaults valueForKey:@"PreviewParser"] integerValue] == FRAPreviewHTML) {
			data = [FRACurrentText dataUsingEncoding:NSUTF8StringEncoding];
		} else {
			NSString *temporaryPathMarkdown = [FRABasic genererateTemporaryPath];
			[FRACurrentText writeToFile:temporaryPathMarkdown atomically:YES encoding:[[FRACurrentDocument valueForKey:@"encoding"] integerValue] error:nil];
			NSString *temporaryPathHTML = [FRABasic genererateTemporaryPath];
			NSString *htmlString;
			if ([[NSFileManager defaultManager] fileExistsAtPath:temporaryPathMarkdown]) {
				if ([[FRADefaults valueForKey:@"PreviewParser"] integerValue] == FRAPreviewMarkdown) {
					system([[NSString stringWithFormat:@"/usr/bin/perl %@ %@ > %@", [[NSBundle mainBundle] pathForResource:@"Markdown" ofType:@"pl"], temporaryPathMarkdown, temporaryPathHTML] UTF8String]);
				} else {
					system([[NSString stringWithFormat:@"/usr/bin/perl %@ %@ > %@", [[NSBundle mainBundle] pathForResource:@"MultiMarkdown" ofType:@"pl"], temporaryPathMarkdown, temporaryPathHTML] UTF8String]);
				}
				if ([[NSFileManager defaultManager] fileExistsAtPath:temporaryPathMarkdown]) {
					htmlString = [NSString stringWithContentsOfFile:temporaryPathHTML encoding:[[FRACurrentDocument valueForKey:@"encoding"] integerValue] error:nil];
					[[NSFileManager defaultManager] removeItemAtPath:temporaryPathHTML error:nil];
				} else {
					htmlString = FRACurrentText;
				}
				[[NSFileManager defaultManager] removeItemAtPath:temporaryPathMarkdown error:nil];
			} else {
				htmlString = FRACurrentText;
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
	if ([[FRADefaults valueForKey:@"PreviewParser"] integerValue] == FRAPreviewHTML) {
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
