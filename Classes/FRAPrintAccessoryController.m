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

#import "FRAPrintAccessoryController.h"

@implementation FRAPrintAccessoryController

@synthesize dummyValue;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:@"FRAPrintAccessoryView" bundle:nibBundleOrNil];
}


- (void) updateMargins {
    NSPrintInfo *printInfo = [self representedObject];
    CGFloat marginsMin = [[FRADefaults valueForKey:@"MarginsMin"] doubleValue];
    if ([[FRADefaults valueForKey:@"PrintHeader"] boolValue] == YES) {
        [printInfo setBottomMargin:(marginsMin + 22)];
    } else {
        [printInfo setBottomMargin:marginsMin];
    }
    [printInfo setLeftMargin:marginsMin];
    [printInfo setRightMargin:marginsMin];
    [printInfo setTopMargin:marginsMin];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    [self updateMargins];
}


- (void)awakeFromNib
{
	NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];

	[defaultsController addObserver:self forKeyPath:@"values.PrintHeader" options:NSKeyValueObservingOptionNew context:@"PrinterSettingsChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.PrintSyntaxColours" options:NSKeyValueObservingOptionNew context:@"PrinterSettingsChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.OnlyPrintSelection" options:NSKeyValueObservingOptionNew context:@"PrinterSettingsChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.MarginsMin" options:NSKeyValueObservingOptionNew context:@"PrinterSettingsChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.PrintFont" options:NSKeyValueObservingOptionNew context:@"PrinterSettingsChanged"];
}


- (void) dealloc
{
    NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    [defaultsController removeObserver:self forKeyPath:@"values.PrintHeader"];
    [defaultsController removeObserver:self forKeyPath:@"values.PrintSyntaxColours"];
    [defaultsController removeObserver:self forKeyPath:@"values.OnlyPrintSelection"];
    [defaultsController removeObserver:self forKeyPath:@"values.MarginsMin"];
    [defaultsController removeObserver:self forKeyPath:@"values.PrintFont"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([(__bridge NSString *)context isEqualToString:@"PrinterSettingsChanged"]) {
        // update the margins because they depend on the settings in this view
        [self updateMargins];
        
		[self setDummyValue:!dummyValue];

	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


- (NSSet *)keyPathsForValuesAffectingPreview
{
	return [NSSet setWithObject:@"dummyValue"];
}


- (NSArray *)localizedSummaryItems
{    
	return nil;
}


- (IBAction)setPrintFontAction:(id)sender
{
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	[fontManager setSelectedFont:[NSUnarchiver unarchiveObjectWithData:[FRADefaults valueForKey:@"PrintFont"]] isMultiple:NO];
	[fontManager orderFrontFontPanel:nil];
}

@end
