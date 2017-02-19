//
//  PSMTabDragAssistant.m
//  PSMTabBarControl
//
//  Created by John Pannell on 4/10/06.
//  Copyright 2006 Positive Spin Media. All rights reserved.
//

#import "PSMTabDragAssistant.h"
#import "PSMTabBarCell.h"
#import "PSMTabStyle.h"
#import "PSMRolloverButton.h"
#import "PSMOverflowPopUpButton.h"
#import "FRAProjectsController.h"
#import "FRAProject.h"
#import "FRAProject+DocumentViewsController.h"

@implementation PSMTabDragAssistant

static PSMTabDragAssistant *sharedDragAssistant = nil;

#pragma mark -
#pragma mark Creation/Destruction

+ (PSMTabDragAssistant *)sharedDragAssistant
{
    if (!sharedDragAssistant){
        sharedDragAssistant = [[PSMTabDragAssistant alloc] init];
    }
    
    return sharedDragAssistant;
}

- (id)init
{
    if(self = [super init]){
        _sourceTabBar = nil;
        _destinationTabBar = nil;
        _participatingTabBars = [[NSMutableSet alloc] init];
        _draggedCell = nil;
        _animationTimer = nil;
        _sineCurveWidths = [[NSMutableArray alloc] initWithCapacity:kPSMTabDragAnimationSteps];
        _targetCell = nil;
        _isDragging = NO;
    }
    
    return self;
}


#pragma mark -
#pragma mark Accessors

- (PSMTabBarControl *)sourceTabBar
{
    return _sourceTabBar;
}

- (void)setSourceTabBar:(PSMTabBarControl *)tabBar
{
    _sourceTabBar = tabBar;
}

- (PSMTabBarControl *)destinationTabBar
{
    return _destinationTabBar;
}

- (void)setDestinationTabBar:(PSMTabBarControl *)tabBar
{
    _destinationTabBar = tabBar;
}

- (PSMTabBarCell *)draggedCell
{
    return _draggedCell;
}

- (void)setDraggedCell:(PSMTabBarCell *)cell
{
    _draggedCell = cell;
}

- (NSInteger)draggedCellIndex
{
    return _draggedCellIndex;
}

- (void)setDraggedCellIndex:(NSInteger)value
{
    _draggedCellIndex = value;
}

- (BOOL)isDragging
{
    return _isDragging;
}

- (void)setIsDragging:(BOOL)value
{
    _isDragging = value;
}

- (NSPoint)currentMouseLoc
{
    return _currentMouseLoc;
}

- (void)setCurrentMouseLoc:(NSPoint)point
{
    _currentMouseLoc = point;
}

- (PSMTabBarCell *)targetCell
{
    return _targetCell;
}

- (void)setTargetCell:(PSMTabBarCell *)cell
{
    _targetCell = cell;
}

#pragma mark -
#pragma mark Functionality

- (void)startDraggingCell:(PSMTabBarCell *)cell fromTabBar:(PSMTabBarControl *)control withMouseDownEvent:(NSEvent *)event
{
    [self setIsDragging:YES];
    [self setSourceTabBar:control];
    [self setDestinationTabBar:control];
    [_participatingTabBars addObject:control];
    [self setDraggedCell:cell];
    [self setDraggedCellIndex:[[control cells] indexOfObject:cell]];
    
    NSRect cellFrame = [cell frame];
    // list of widths for animation
    NSInteger i;
    CGFloat cellWidth = cellFrame.size.width;
    for(i = 0; i < kPSMTabDragAnimationSteps; i++){
        NSInteger thisWidth;
        thisWidth = (NSInteger)(cellWidth - ((cellWidth/2.0) + ((sin((PI/2.0) + ((CGFloat)i/(CGFloat)kPSMTabDragAnimationSteps)*PI) * cellWidth) / 2.0)));
        [_sineCurveWidths addObject:@(thisWidth)];
    }
    
    // hide UI buttons
    [[control overflowPopUpButton] setHidden:YES];
    [[control addTabButton] setHidden:YES];
    
    [[NSCursor closedHandCursor] set];
    
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    NSImage *dragImage = [cell dragImageForRect:cellFrame];
    [[cell indicator] removeFromSuperview];
    [self distributePlaceholdersInTabBar:control withDraggedCell:cell];

    if([control isFlipped]){
        cellFrame.origin.y += cellFrame.size.height;
    }
    [cell setHighlighted:NO];
    NSSize offset = NSZeroSize;
    [pboard declareTypes:@[@"PSMTabBarControlItemPBType"] owner: nil];
    [pboard setString:[ @([[control cells] indexOfObject:cell]) stringValue] forType:@"PSMTabBarControlItemPBType"];
    _animationTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0/30.0) target:self selector:@selector(animateDrag:) userInfo:nil repeats:YES];
    [control dragImage:dragImage at:cellFrame.origin offset:offset event:event pasteboard:pboard source:control slideBack:YES];
}

- (void)draggingEnteredTabBar:(PSMTabBarControl *)control atPoint:(NSPoint)mouseLoc
{
    [self setDestinationTabBar:control];
    [self setCurrentMouseLoc:mouseLoc];
    // hide UI buttons
    [[control overflowPopUpButton] setHidden:YES];
    [[control addTabButton] setHidden:YES];
    if(![[control cells][0] isPlaceholder])
        [self distributePlaceholdersInTabBar:control];
    [_participatingTabBars addObject:control];
}

- (void)draggingUpdatedInTabBar:(PSMTabBarControl *)control atPoint:(NSPoint)mouseLoc
{
    if([self destinationTabBar] != control)
        [self setDestinationTabBar:control];
    [self setCurrentMouseLoc:mouseLoc];
}

- (void)draggingExitedTabBar:(PSMTabBarControl *)control
{
    [self setDestinationTabBar:nil];
    [self setCurrentMouseLoc:NSMakePoint(-1.0, -1.0)];

}

- (void)performDragOperation
{
    // move cell
    [[self destinationTabBar] cells][[[[self destinationTabBar] cells] indexOfObject:[self targetCell]]] = [self draggedCell];
    [[self draggedCell] setControlView:[self destinationTabBar]];
    // move actual NSTabViewItem
    if([self sourceTabBar] != [self destinationTabBar]){
        [[[self sourceTabBar] tabView] removeTabViewItem:[[self draggedCell] representedObject]];
        [[[self destinationTabBar] tabView] addTabViewItem:[[self draggedCell] representedObject]];
		
		NSArray *array = [[FRAProjectsController sharedDocumentController] documents];
		id destinationProject = nil;
		for (destinationProject in array) {
			if ([self destinationTabBar] == [destinationProject tabBarControl]) {
				break;
			}
		}
		
		if (destinationProject != nil) {
			id document = [[[self draggedCell] representedObject] identifier];
			[(NSMutableSet *)[destinationProject documents] addObject:document];
			[destinationProject updateDocumentOrderFromCells:[[self destinationTabBar] cells]];
			[destinationProject selectDocument:document];
		}
		
		array = [[FRAProjectsController sharedDocumentController] documents];
		id sourceProject = nil;
		for (sourceProject in array) {
			if ([self sourceTabBar] == [sourceProject tabBarControl]) {
				
				break;
			}
		}
		
		if (sourceProject != nil) {
			[sourceProject selectionDidChange];
		}
		
    } else {
		[FRACurrentProject updateDocumentOrderFromCells:[[self destinationTabBar] cells]]; 
	}
	
    [self finishDrag];
}

- (void)draggedImageEndedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
    if([self isDragging]){  // means there was not a successful drop (performDragOperation)
        // put cell back
        [[[self sourceTabBar] cells] insertObject:[self draggedCell] atIndex:[self draggedCellIndex]];
        [self finishDrag];
    }

}

- (void)finishDrag
{
    [self setIsDragging:NO];
    [self removeAllPlaceholdersFromTabBar:[self sourceTabBar]];
    [self setSourceTabBar:nil];
    [self setDestinationTabBar:nil];
    PSMTabBarControl *tabBar;
	NSArray *array = [NSArray arrayWithArray:[_participatingTabBars allObjects]];
    for(tabBar in array){
        [self removeAllPlaceholdersFromTabBar:tabBar];
    }
    [_participatingTabBars removeAllObjects];
    [self setDraggedCell:nil];
    [_animationTimer invalidate];
    _animationTimer = nil;
    [_sineCurveWidths removeAllObjects];
    [self setTargetCell:nil];
}

#pragma mark -
#pragma mark Animation

- (void)animateDrag:(NSTimer *)timer
{
    PSMTabBarControl *tabBar;
	NSArray *array = [NSArray arrayWithArray:[_participatingTabBars allObjects]];
    for(tabBar in array){
        [self calculateDragAnimationForTabBar:tabBar];
        [[NSRunLoop currentRunLoop] performSelector:@selector(display) target:tabBar argument:nil order:1 modes:@[@"NSEventTrackingRunLoopMode", @"NSDefaultRunLoopMode"]];
    }
}

- (void)calculateDragAnimationForTabBar:(PSMTabBarControl *)control
{
    BOOL removeFlag = YES;
    NSMutableArray *cells = [control cells];
    CGFloat xPos = [[control style] leftMarginForTabBarControl];
    
    // identify target cell
    // mouse at beginning of tabs
    NSPoint mouseLoc = [self currentMouseLoc];
    if([self destinationTabBar] == control){
        removeFlag = NO;
        if(mouseLoc.x < [[control style] leftMarginForTabBarControl]){
            [self setTargetCell:cells[0]];
            goto layout;
        }
        
        NSRect overCellRect;
        PSMTabBarCell *overCell = [control cellForPoint:mouseLoc cellFrame:&overCellRect];
        if(overCell){
            // mouse among cells - placeholder
            if([overCell isPlaceholder]){
                [self setTargetCell:overCell];
                goto layout;
            }
            
            // non-placeholders
            if(mouseLoc.x < (overCellRect.origin.x + (overCellRect.size.width / 2.0))){
                // mouse on left side of cell
                [self setTargetCell:cells[([cells indexOfObject:overCell] - 1)]];
                goto layout;
            } else {
                // mouse on right side of cell
                [self setTargetCell:cells[([cells indexOfObject:overCell] + 1)]];
                goto layout;
            }
        } else {
            // out at end - must find proper cell (could be more in overflow menu)
            [self setTargetCell:[control lastVisibleTab]];
            goto layout;
        }
    } else {
        [self setTargetCell:nil];
    }
    
layout: 
    for(PSMTabBarCell *cell in cells){
        NSRect newRect = [cell frame];
        if(![cell isInOverflowMenu]){
            if([cell isPlaceholder]){
                if(cell == [self targetCell]){
                    [cell setCurrentStep:([cell currentStep] + 1)];
                } else {
                    [cell setCurrentStep:([cell currentStep] - 1)];
                    if([cell currentStep] > 0){
                        removeFlag = NO;
                    }
                }
                newRect.size.width = [_sineCurveWidths[[cell currentStep]] integerValue];
            }
        } else {
            break;
        }
        newRect.origin.x = xPos;
        [cell setFrame:newRect];
        if([cell indicator])
            [[cell indicator] setFrame:[[control style] indicatorRectForTabCell:cell]];
        xPos += newRect.size.width;
    }
    if(removeFlag){
        [_participatingTabBars removeObject:control];
        [self removeAllPlaceholdersFromTabBar:control];
    }
}

#pragma mark -
#pragma mark Placeholders

- (void)distributePlaceholdersInTabBar:(PSMTabBarControl *)control withDraggedCell:(PSMTabBarCell *)cell
{
    // called upon first drag - must distribute placeholders
    [self distributePlaceholdersInTabBar:control];
    // replace dragged cell with a placeholder, and clean up surrounding cells
    NSInteger cellIndex = [[control cells] indexOfObject:cell];
    PSMTabBarCell *pc = [[PSMTabBarCell alloc] initPlaceholderWithFrame:[[self draggedCell] frame] expanded:YES inControlView:control];
    [control cells][cellIndex] = pc;
    [[control cells] removeObjectAtIndex:(cellIndex + 1)];
    [[control cells] removeObjectAtIndex:(cellIndex - 1)];
    return;
}

- (void)distributePlaceholdersInTabBar:(PSMTabBarControl *)control
{
    NSInteger i, numVisibleTabs = [control numberOfVisibleTabs];
    for(i = 0; i < numVisibleTabs; i++){
        PSMTabBarCell *pc = [[PSMTabBarCell alloc] initPlaceholderWithFrame:[[self draggedCell] frame] expanded:NO inControlView:control]; 
        [[control cells] insertObject:pc atIndex:(2 * i)];
    }
    if(numVisibleTabs > 0){
        PSMTabBarCell *pc = [[PSMTabBarCell alloc] initPlaceholderWithFrame:[[self draggedCell] frame] expanded:NO inControlView:control];
        if([[control cells] count] > (2 * numVisibleTabs)){
            [[control cells] insertObject:pc atIndex:(2 * numVisibleTabs)];
        } else {
            [[control cells] addObject:pc];
        }
    }
}

- (void)removeAllPlaceholdersFromTabBar:(PSMTabBarControl *)control
{
    NSInteger i, cellCount = [[control cells] count];
    for(i = (cellCount - 1); i >= 0; i--){
        PSMTabBarCell *cell = [control cells][i];
        if([cell isPlaceholder])
            [[control cells] removeObject:cell];
    }
    // redraw
    [[NSRunLoop currentRunLoop] performSelector:@selector(update) target:control argument:nil order:1 modes:@[@"NSEventTrackingRunLoopMode", @"NSDefaultRunLoopMode"]];
    [[NSRunLoop currentRunLoop] performSelector:@selector(display) target:control argument:nil order:1 modes:@[@"NSEventTrackingRunLoopMode", @"NSDefaultRunLoopMode"]];
}


@end
