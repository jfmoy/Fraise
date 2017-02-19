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

// Based on ImageAndTextCell.m by Chuck Pisula (Apple)
// look at https://github.com/jdg/opmlviewer

#import "FRADocumentsListCell.h"

@implementation FRADocumentsListCell

@synthesize image, heightAndWidth;

- (id)copyWithZone:(NSZone *)zone
{
	FRADocumentsListCell *cell = [super copyWithZone:zone];
    cell.image = self.image;
	return cell;
}


- (NSRect)imageFrameForCellFrame:(NSRect)cellFrame 
{
    if (image != nil) {
        NSRect imageFrame;
        imageFrame.size = NSMakeSize(heightAndWidth, heightAndWidth);
        imageFrame.origin = cellFrame.origin;
        imageFrame.origin.x += 3;
        imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        return imageFrame;
    } else {
        return NSZeroRect;
	}
}


- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
    NSRect textFrame = aRect;
	NSSize contentSize = self.cellSize;
    textFrame.origin.y += ceil((textFrame.size.height - contentSize.height) / 2);
    textFrame.size.height = contentSize.height;
    [super editWithFrame:textFrame inView:controlView editor:textObj delegate:anObject event:theEvent];
}


- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
	NSRect textFrame = aRect;
	NSSize contentSize = self.cellSize;
    textFrame.origin.y += ceil((textFrame.size.height - contentSize.height) / 2);
    textFrame.size.height = contentSize.height;
    [super selectWithFrame:textFrame inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}


- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if (image != nil) {
        NSRect imageFrame = NSZeroRect;
        NSSize imageSize = NSMakeSize(heightAndWidth, heightAndWidth);
        NSDivideRect(cellFrame, &imageFrame, &cellFrame, 3 + imageSize.width, NSMinXEdge);
        if (self.drawsBackground) {
            [self.backgroundColor set];
            NSRectFill(imageFrame);
        }
        [image drawInRect:imageFrame fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    }
    NSSize contentSize = self.cellSize;
    cellFrame.origin.y += ceil((cellFrame.size.height - contentSize.height) / 2);
    cellFrame.size.height = contentSize.height;
    if (cellFrame.origin.x < heightAndWidth) {
        // This is to make sure that the text is properly aligned before the icon has been created in a separate thread
        cellFrame.origin.x += heightAndWidth + 3;
    }
    [super drawInteriorWithFrame:cellFrame inView:controlView];
}


- (NSSize)cellSize 
{
    NSSize cellSize = super.cellSize;
    cellSize.width += heightAndWidth + 3;
    return cellSize;
}

@end


