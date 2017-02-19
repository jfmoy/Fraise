/*
 Fraise version 3.7 - Based on Smultron by Peter Borg
 
 Current Maintainer (since 2016): 
 Andreas Bentele: abentele.github@icloud.com (https://github.com/abentele/Fraise)
 
 Maintainer before macOS Sierra (2010-2016): 
 Jean-François Moy: jeanfrancois.moy@gmail.com (http://github.com/jfmoy/Fraise)

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

#import <Cocoa/Cocoa.h>


@interface FRAExtraInterfaceController : NSObject {

	IBOutlet NSTextField *spacesTextFieldEntabWindow;
	IBOutlet NSTextField *spacesTextFieldDetabWindow;
	IBOutlet NSTextField *lineTextFieldGoToLineWindow;
	IBOutlet NSWindow *entabWindow;
	IBOutlet NSWindow *detabWindow;
	IBOutlet NSWindow *goToLineWindow;
	
	IBOutlet NSView * openPanelAccessoryView;
	IBOutlet NSPopUpButton * openPanelEncodingsPopUp;
	
	IBOutlet NSWindow * commandResultWindow;
	IBOutlet NSTextView * commandResultTextView;
	
	IBOutlet NSWindow * newProjectWindow;
	IBOutlet NSPanel *regularExpressionsHelpPanel;
}


@property (strong, readonly) IBOutlet NSView *openPanelAccessoryView;
@property (strong, readonly) IBOutlet NSPopUpButton *openPanelEncodingsPopUp;
@property (strong, readonly) IBOutlet NSWindow *commandResultWindow;
@property (strong, readonly) IBOutlet NSTextView *commandResultTextView;
@property (strong, readonly) IBOutlet NSWindow *newProjectWindow;

+ (FRAExtraInterfaceController *)sharedInstance;

- (void)displayEntab;
- (void)displayDetab;
- (IBAction)entabButtonEntabWindowAction:(id)sender;
- (IBAction)detabButtonDetabWindowAction:(id)sender;
- (IBAction)cancelButtonEntabDetabGoToLineWindowsAction:(id)sender;
- (void)displayGoToLine;
- (IBAction)goButtonGoToLineWindowAction:(id)sender;

- (NSPopUpButton *)openPanelEncodingsPopUp;
- (NSView *)openPanelAccessoryView;
- (NSWindow *)commandResultWindow;
-(NSTextView *)commandResultTextView;
- (NSWindow *)newProjectWindow;

- (void)showCommandResultWindow;


- (IBAction)createNewProjectAction:(id)sender;

- (void)showRegularExpressionsHelpPanel;

@end
