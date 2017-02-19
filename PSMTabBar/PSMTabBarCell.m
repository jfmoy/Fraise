//
//  PSMTabBarCell.m
//  PSMTabBarControl
//
//  Created by John Pannell on 10/13/05.
//  Copyright 2005 Positive Spin Media. All rights reserved.
//

#import "PSMTabBarCell.h"
#import "PSMTabBarControl.h"
#import "PSMTabStyle.h"

#import "PSMTabDragAssistant.h"


@implementation PSMTabBarCell

#pragma mark -
#pragma mark Creation/Destruction
- (id)initWithControlView:(PSMTabBarControl *)controlView
{
    self = [super init];
    if(self){
        _controlView = controlView;
        _closeButtonTrackingTag = 0;
        _cellTrackingTag = 0;
        _closeButtonOver = NO;
        _closeButtonPressed = NO;
        _indicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0.0,0.0,kPSMTabBarIndicatorWidth,kPSMTabBarIndicatorWidth)];
        [_indicator setStyle:NSProgressIndicatorSpinningStyle];
        [_indicator setAutoresizingMask:NSViewMinYMargin];
        _hasCloseButton = YES;
        _isCloseButtonSuppressed = NO;
        _count = 0;
        _isPlaceholder = NO;
    }
    return self;
}

- (id)initPlaceholderWithFrame:(NSRect)frame expanded:(BOOL)value inControlView:(PSMTabBarControl *)controlView
{
    self = [super init];
    if(self){
        _controlView = controlView;
        _isPlaceholder = YES;
        if(!value)
            frame.size.width = 0.0;
        [self setFrame:frame];
        _closeButtonTrackingTag = 0;
        _cellTrackingTag = 0;
        _closeButtonOver = NO;
        _closeButtonPressed = NO;
        _indicator = nil;
        _hasCloseButton = YES;
        _isCloseButtonSuppressed = NO;
        _count = 0;
        
        if(value){
            [self setCurrentStep:(kPSMTabDragAnimationSteps - 1)];
        } else {
            [self setCurrentStep:0];
        }
        
    }
    
    return self;
}


#pragma mark -
#pragma mark Accessors

- (id)controlView
{
    return _controlView;
}

- (void)setControlView:(id)view
{
    // no retain release pattern, as this simply switches a tab to another view.
    _controlView = view;
}

- (NSTrackingRectTag)closeButtonTrackingTag
{
    return _closeButtonTrackingTag;
}

- (void)setCloseButtonTrackingTag:(NSTrackingRectTag)tag
{
    _closeButtonTrackingTag = tag;
}

- (NSTrackingRectTag)cellTrackingTag
{
    return _cellTrackingTag;
}

- (void)setCellTrackingTag:(NSTrackingRectTag)tag
{
    _cellTrackingTag = tag;
}

- (CGFloat)width
{
    return _frame.size.width;
}

- (NSRect)frame
{
    return _frame;
}

- (void)setFrame:(NSRect)rect
{
    _frame = rect;
}

- (void)setStringValue:(NSString *)aString
{
    [super setStringValue:aString];
    _stringSize = [[self attributedStringValue] size];
    // need to redisplay now - binding observation was too quick.
    [_controlView update];
}

- (NSSize)stringSize
{
    return _stringSize;
}

- (NSAttributedString *)attributedStringValue
{
    return [[(PSMTabBarControl *)_controlView style] attributedStringValueForTabCell:self];
}

- (NSInteger)tabState
{
    return _tabState;
}

- (void)setTabState:(NSInteger)state
{
    _tabState = state;
}

- (NSProgressIndicator *)indicator
{ 
    return _indicator;
}

- (BOOL)isInOverflowMenu
{
    return _isInOverflowMenu;
}

- (void)setIsInOverflowMenu:(BOOL)value
{
    _isInOverflowMenu = value;
}

- (BOOL)closeButtonPressed
{
    return _closeButtonPressed;
}

- (void)setCloseButtonPressed:(BOOL)value
{
    _closeButtonPressed = value;
}

- (BOOL)closeButtonOver
{
    return _closeButtonOver;
}

- (void)setCloseButtonOver:(BOOL)value
{
    _closeButtonOver = value;
}

- (BOOL)hasCloseButton
{
    return _hasCloseButton;
}

- (void)setHasCloseButton:(BOOL)set;
{
    _hasCloseButton = set;
}

- (void)setCloseButtonSuppressed:(BOOL)suppress;
{
    _isCloseButtonSuppressed = suppress;
}

- (BOOL)isCloseButtonSuppressed;
{
    return _isCloseButtonSuppressed;
}

- (BOOL)hasIcon
{
    return _hasIcon;
}

- (void)setHasIcon:(BOOL)value
{
    _hasIcon = value;
    [_controlView update]; // binding notice is too fast
}

- (NSInteger)count
{
    return _count;
}

- (void)setCount:(NSInteger)value
{
    _count = value;
    [_controlView update]; // binding notice is too fast
}

- (BOOL)isPlaceholder
{
    return _isPlaceholder;
}

- (void)setIsPlaceholder:(BOOL)value;
{
    _isPlaceholder = value;
}

- (NSInteger)currentStep
{
    return _currentStep;
}

- (void)setCurrentStep:(NSInteger)value
{
    if(value < 0)
        value = 0;
    
    if(value > (kPSMTabDragAnimationSteps - 1))
        value = (kPSMTabDragAnimationSteps - 1);
    
    _currentStep = value;
}

#pragma mark -
#pragma mark Component Attributes

- (NSRect)indicatorRectForFrame:(NSRect)cellFrame
{
    return [[(PSMTabBarControl *)_controlView style] indicatorRectForTabCell:self];
}

- (NSRect)closeButtonRectForFrame:(NSRect)cellFrame
{
    return [[(PSMTabBarControl *)_controlView style] closeButtonRectForTabCell:self];
}

- (CGFloat)minimumWidthOfCell
{
    return [[(PSMTabBarControl *)_controlView style] minimumWidthOfTabCell:self];
}

- (CGFloat)desiredWidthOfCell
{
    return [[(PSMTabBarControl *)_controlView style] desiredWidthOfTabCell:self];
}  

#pragma mark -
#pragma mark Drawing

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if(_isPlaceholder){
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.2] set];
        NSRectFillUsingOperation(cellFrame, NSCompositingOperationSourceAtop);
        return;
    }
    
    [[(PSMTabBarControl *)_controlView style] drawTabCell:self];	
}

#pragma mark -
#pragma mark Tracking

- (void)mouseEntered:(NSEvent *)theEvent
{
    // check for which tag
    if([theEvent trackingNumber] == _closeButtonTrackingTag){
        _closeButtonOver = YES;
    }
    if([theEvent trackingNumber] == _cellTrackingTag){
        [self setHighlighted:YES];
    }
    [_controlView setNeedsDisplay];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    // check for which tag
    if([theEvent trackingNumber] == _closeButtonTrackingTag){
        _closeButtonOver = NO;
    }
    if([theEvent trackingNumber] == _cellTrackingTag){
        [self setHighlighted:NO];
    }
    [_controlView setNeedsDisplay];
}

#pragma mark -
#pragma mark Drag Support

- (NSImage*)dragImageForRect:(NSRect)cellFrame
{
    if(([self state] == NSOnState) && ([[_controlView styleName] isEqualToString:@"Metal"]))
        cellFrame.size.width += 1.0;
    [_controlView lockFocus];
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:cellFrame];
    [_controlView unlockFocus];
    NSSize size = [rep size];
    
    NSImage *image = [[NSImage alloc] initWithSize: size];
    [image addRepresentation:rep];
    NSImage *returnImage = [[NSImage alloc] initWithSize: size];
    [returnImage lockFocus];
    [image drawAtPoint: NSMakePoint(0.0, 0.0)
              fromRect: NSMakeRect(0, 0, size.width, size.height)
             operation: NSCompositingOperationSourceOver
              fraction: 0.7];

    [returnImage unlockFocus];
    
    if(![[self indicator] isHidden])
    {
        NSImage *pi = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"pi"]];
        [returnImage lockFocus];
        NSPoint indicatorPoint = NSMakePoint([self frame].size.width - MARGIN_X - kPSMTabBarIndicatorWidth, MARGIN_Y);
        if(([self state] == NSOnState) && ([[_controlView styleName] isEqualToString:@"Metal"]))
            indicatorPoint.y += 1.0;
        [pi drawAtPoint:indicatorPoint fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:0.7];
        [returnImage unlockFocus];
    }
    return returnImage;
}

#pragma mark -
#pragma mark Archiving

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    if ([aCoder allowsKeyedCoding]) {
        [aCoder encodeRect:_frame forKey:@"frame"];
        [aCoder encodeSize:_stringSize forKey:@"stringSize"];
        [aCoder encodeInteger:_currentStep forKey:@"currentStep"];
        [aCoder encodeBool:_isPlaceholder forKey:@"isPlaceholder"];
        [aCoder encodeInteger:_tabState forKey:@"tabState"];
        [aCoder encodeInteger:_closeButtonTrackingTag forKey:@"closeButtonTrackingTag"];
        [aCoder encodeInteger:_cellTrackingTag forKey:@"cellTrackingTag"];
        [aCoder encodeBool:_closeButtonOver forKey:@"closeButtonOver"];
        [aCoder encodeBool:_closeButtonPressed forKey:@"closeButtonPressed"];
        [aCoder encodeObject:_indicator forKey:@"indicator"];
        [aCoder encodeBool:_isInOverflowMenu forKey:@"isInOverflowMenu"];
        [aCoder encodeBool:_hasCloseButton forKey:@"hasCloseButton"];
        [aCoder encodeBool:_isCloseButtonSuppressed forKey:@"isCloseButtonSuppressed"];
        [aCoder encodeBool:_hasIcon forKey:@"hasIcon"];
        [aCoder encodeInteger:_count forKey:@"count"];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        if ([aDecoder allowsKeyedCoding]) {
            _frame = [aDecoder decodeRectForKey:@"frame"];
            NSLog(@"decoding cell");
            _stringSize = [aDecoder decodeSizeForKey:@"stringSize"];
            _currentStep = [aDecoder decodeIntegerForKey:@"currentStep"];
            _isPlaceholder = [aDecoder decodeBoolForKey:@"isPlaceholder"];
            _tabState = [aDecoder decodeIntegerForKey:@"tabState"];
            _closeButtonTrackingTag = [aDecoder decodeIntegerForKey:@"closeButtonTrackingTag"];
            _cellTrackingTag = [aDecoder decodeIntegerForKey:@"cellTrackingTag"];
            _closeButtonOver = [aDecoder decodeBoolForKey:@"closeButtonOver"];
            _closeButtonPressed = [aDecoder decodeBoolForKey:@"closeButtonPressed"];
            _indicator = [aDecoder decodeObjectForKey:@"indicator"];
            _isInOverflowMenu = [aDecoder decodeBoolForKey:@"isInOverflowMenu"];
            _hasCloseButton = [aDecoder decodeBoolForKey:@"hasCloseButton"];
            _isCloseButtonSuppressed = [aDecoder decodeBoolForKey:@"isCloseButtonSuppressed"];
            _hasIcon = [aDecoder decodeBoolForKey:@"hasIcon"];
            _count = [aDecoder decodeIntegerForKey:@"count"];
        }
    }
    return self;
}

@end
