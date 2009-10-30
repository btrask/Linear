/* Copyright (c) 2007-2009, Ben Trask
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * The names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY BEN TRASK ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL BEN TRASK BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */
#import "LNCanvasView.h"

// Models
#import "LNCanvasStorage.h"
#import "LNGraphic.h"
#import "LNShape.h"

// Other Sources
#import "LNFoundationAdditions.h"

NSString *const LNCanvasViewSelectionDidChangeNotification = @"LNCanvasViewSelectionDidChange";

// Pasteboard Types
static NSString *const LNCanvasGraphicsPboardType = @"LNCanvasGraphics";

@interface LNCanvasView (Private)

- (void)_setSelectionLine:(LNLine *)line;

@end

@implementation LNCanvasView

#pragma mark +NSObject

+ (void)initialize
{
	[NSColor setIgnoresAlpha:NO];
}

#pragma mark -LNCanvasView

- (IBAction)copy:(id)sender
{
	if(![[self selection] count]) return NSBeep();
	NSPasteboard *const pboard = [NSPasteboard generalPasteboard];
	[pboard declareTypes:[NSArray arrayWithObject:LNCanvasGraphicsPboardType] owner:nil];
	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:[self selection]] forType:LNCanvasGraphicsPboardType];
}
- (IBAction)paste:(id)sender
{
	NSPasteboard *const pboard = [NSPasteboard generalPasteboard];
	if(![[pboard types] containsObject:LNCanvasGraphicsPboardType]) return NSBeep();
	NSSet *const graphics = [NSKeyedUnarchiver unarchiveObjectWithData:[pboard dataForType:LNCanvasGraphicsPboardType]];
	if(![graphics count]) return;
	[[self canvasStorage] addGraphics:graphics];
	[self deselectAll:self];
	[self select:graphics byExtendingSelection:NO];
	[self moveSelectionBy:NSMakeSize(15, -15)];
}
- (IBAction)selectAll:(id)sender
{
	[self select:[NSSet setWithArray:[[self canvasStorage] graphics]] byExtendingSelection:NO];
}
- (IBAction)deselectAll:(id)sender
{
	[self deselect:[self selection]];
}

#pragma mark -

- (IBAction)dividePrimary:(id)sender
{
	LNGraphic *const line = [self primarySelection];
	if(![line isKindOfClass:[LNLine class]]) return NSBeep();
	NSSet *const dividedLines = [(LNLine *)line linesByDividingAtLines:[self selection]];
	[[self canvasStorage] removeGraphics:[NSSet setWithObject:line]];
	[[self canvasStorage] addGraphics:dividedLines];
	[self deselectAll:self];
}
- (IBAction)divideByPrimary:(id)sender
{
	LNGraphic *const line = [self primarySelection];
	if(![line isKindOfClass:[LNLine class]]) return NSBeep();
	NSMutableSet *const selection = [[[self selection] mutableCopy] autorelease];
	[selection removeObject:line];
	NSSet *const dividedLines = [(LNLine *)line linesByDividingLines:selection];
	[[self canvasStorage] removeGraphics:selection];
	[[self canvasStorage] addGraphics:dividedLines];
	[self deselectAll:self];
}
- (IBAction)extend:(id)sender
{
	LNGraphic *const line = [self primarySelection];
	if(![line isKindOfClass:[LNLine class]]) return NSBeep();
	[(LNLine *)line extendToClosestLineInSet:[self selection]];
}
- (IBAction)makeShapeWithSelection:(id)sender
{
	NSMutableSet *const selectedLines = [NSMutableSet set];
	for(LNGraphic *const graphic in [self selection]) if([graphic isKindOfClass:[LNLine class]]) [selectedLines addObject:graphic];
	LNShape *const shape = [[[LNShape alloc] initWithSides:selectedLines] autorelease];
	if(!shape) return;
	[[self canvasStorage] addGraphics:[NSSet setWithObject:shape]];
	[self select:[NSSet setWithObject:shape] byExtendingSelection:NO];
}

#pragma mark -

- (IBAction)orderFrontColorPanel:(id)sender
{
	NSColorPanel *const colorPanel = [NSColorPanel sharedColorPanel];
	if([_selection count] == 1) [[NSColorPanel sharedColorPanel] setColor:[[_selection anyObject] color]];
	[colorPanel orderFront:sender];
}

#pragma mark -

- (LNCanvasStorage *)canvasStorage
{
	return [[_canvasStorage retain] autorelease];
}
- (void)setCanvasStorage:(LNCanvasStorage *)storage
{
	if(storage == _canvasStorage) return;
	[self deselectAll:self];
	[_canvasStorage LN_removeObserver:self name:LNCanvasStorageDidChangeGraphicsNotification];
	[_canvasStorage LN_removeObserver:self name:LNCanvasStorageGraphicWillChangeNotification];
	[_canvasStorage LN_removeObserver:self name:LNCanvasStorageGraphicDidChangeNotification];
	[_canvasStorage release];
	_canvasStorage = [storage retain];
	_canvasStorage.canvasView = self;
	[self setNeedsDisplay:YES];
	[_canvasStorage LN_addObserver:self selector:@selector(storageDidChangeGraphics:) name:LNCanvasStorageDidChangeGraphicsNotification];
	[_canvasStorage LN_addObserver:self selector:@selector(storageGraphicWillChange:) name:LNCanvasStorageGraphicWillChangeNotification];
	[_canvasStorage LN_addObserver:self selector:@selector(storageGraphicDidChange:) name:LNCanvasStorageGraphicDidChangeNotification];
}
- (NSSet *)selection
{
	return [[_selection copy] autorelease];
}
- (id)primarySelection
{
	return [[_primarySelection retain] autorelease];
}
- (void)setPrimarySelection:(id)aGraphic
{
	if(aGraphic == _primarySelection) return;
	[_primarySelection release];
	_primarySelection = [aGraphic retain];
	if(aGraphic) [self select:[NSSet setWithObject:aGraphic] byExtendingSelection:YES];
}
@synthesize tool = _tool;

#pragma mark -

- (void)getGraphic:(out id *)outGraphic linePart:(out LNLinePart *)outPart atPoint:(NSPoint)aPoint
{
	LNGraphic *graphic = [self primarySelection];
	if([graphic isKindOfClass:[LNLine class]]) {
		if(LNPointDistance([(LNLine *)graphic end], aPoint) <= 4) {
			if(outGraphic) *outGraphic = graphic;
			if(outPart) *outPart = LNEndPart;
			return;
		} else if(LNPointDistance([(LNLine *)graphic start], aPoint) <= 4) {
			if(outGraphic) *outGraphic = graphic;
			if(outPart) *outPart = LNStartPart;
			return;
		}
	}
	for(graphic in [[self canvasStorage] graphics]) {
		if([graphic isKindOfClass:[LNLine class]]) {
			if([(LNLine *)graphic distanceToPoint:aPoint] > 4) continue;
		} else if([graphic isKindOfClass:[LNShape class]]) {
			if(![[(LNShape *)graphic bezierPath] containsPoint:aPoint]) continue;
		} else continue;
		if(outGraphic) *outGraphic = graphic;
		if(outPart) *outPart = LNBodyPart;
		return;
	}
	if(outGraphic) *outGraphic = nil;
	if(outPart) *outPart = LNNoPart;
}
- (float)getDistanceToEnd:(out LNLineEnd *)outEnd ofLine:(out LNLine **)outLine closestToPoint:(NSPoint)aPoint excluding:(NSSet *)excludedSet
{
	float dist = FLT_MAX;
	if(outLine) *outLine = nil;
	for(LNGraphic *const graphic in [[self canvasStorage] graphics]) {
		if(![graphic isKindOfClass:[LNLine class]] || [excludedSet containsObject:graphic]) continue;
		float const startDist = LNPointDistance([(LNLine *)graphic start], aPoint);
		float const endDist = LNPointDistance([(LNLine *)graphic end], aPoint);
		if(startDist < dist) {
			dist = startDist;
			if(outEnd) *outEnd = NO;
			if(outLine) *outLine = (LNLine *)graphic;
		}
		if(endDist < dist) {
			dist = endDist;
			if(outEnd) *outEnd = YES;
			if(outLine) *outLine = (LNLine *)graphic;
		}
	}
	return dist;
}
- (BOOL)needsToDrawGraphic:(LNGraphic *)graphic selected:(BOOL)flag
{
	NSRect frame = [graphic frame];
	if(NSIsEmptyRect(frame)) return NO;
	if(flag) frame = NSInsetRect(frame, -5, -5);
	return [self needsToDrawRect:frame];
}

#pragma mark -

- (void)select:(NSSet *)aSet byExtendingSelection:(BOOL)flag
{
	NSMutableSet *const realSet = [NSMutableSet set];
//	[realSet unionSet:[];
	if([aSet isEqualToSet:_selection]) return;
	if(flag) {
		if(![aSet count]) return;
		[_selection unionSet:aSet];
	} else [_selection setSet:aSet];
	if([_selection count] == 1) [[NSColorPanel sharedColorPanel] setColor:[[_selection anyObject] color]];
	if(![_selection containsObject:[self primarySelection]]) [self setPrimarySelection:nil];
	[self setNeedsDisplay:YES];
	[self LN_postNotificationName:LNCanvasViewSelectionDidChangeNotification];
}
- (void)deselect:(NSSet *)aSet
{
	if(![aSet count]) return;
	[_selection minusSet:aSet];
	if([_selection count] == 1) [[NSColorPanel sharedColorPanel] setColor:[[_selection anyObject] color]];
	if([aSet containsObject:[self primarySelection]]) [self setPrimarySelection:nil];
	[self setNeedsDisplay:YES];
	[self LN_postNotificationName:LNCanvasViewSelectionDidChangeNotification];
}
- (void)invertSelect:(NSSet *)aSet
{
	for(LNGraphic *const graphic in aSet) {
		if([_selection containsObject:graphic]) [_selection removeObject:graphic];
		else [_selection addObject:graphic];
	}
	if(![_selection containsObject:[self primarySelection]]) [self setPrimarySelection:nil];
	[self setNeedsDisplay:YES];
	[self LN_postNotificationName:LNCanvasViewSelectionDidChangeNotification];
}

#pragma mark -

- (void)moveSelectionBy:(NSSize)aSize
{
	for(LNGraphic *const graphic in [self selection]) if([graphic isKindOfClass:[LNLine class]]) [(LNLine *)graphic offsetBy:aSize];
}

#pragma mark -

- (void)storageDidChangeGraphics:(NSNotification *)aNotif
{
	[self deselect:[[aNotif userInfo] objectForKey:LNCanvasStorageGraphicsRemovedKey]];
	[self setNeedsDisplay:YES];
}
- (void)storageGraphicWillChange:(NSNotification *)aNotif
{
}
- (void)storageGraphicDidChange:(NSNotification *)aNotif
{
	[self setNeedsDisplay:YES];
}
- (void)graphicWillChange:(NSNotification *)aNotif
{
}
- (void)graphicDidChange:(NSNotification *)aNotif
{
	[self setNeedsDisplay:YES];
}
- (void)windowWillChangeKey:(NSNotification *)aNotif
{
	if([[self selection] count]) [self setNeedsDisplay:YES];
}

#pragma mark -LNCanvasView(Private)

- (void)_setSelectionLine:(LNLine *)line
{
	if(line == _selectionLine) return;
	[_selectionLine LN_removeObserver:self name:LNGraphicWillChangeNotification];
	[_selectionLine LN_removeObserver:self name:LNGraphicDidChangeNotification];
	[_selectionLine release];
	_selectionLine = [line retain];
	[_selectionLine LN_addObserver:self selector:@selector(graphicWillChange:) name:LNGraphicWillChangeNotification];
	[_selectionLine LN_addObserver:self selector:@selector(graphicDidChange:) name:LNGraphicDidChangeNotification];
	[self setNeedsDisplay:YES];
}

#pragma mark -NSView

- (id)initWithFrame:(NSRect)aRect
{
	if((self = [super initWithFrame:aRect])) {
		_selection = [[NSMutableSet alloc] init];
		[self setBoundsOrigin:NSMakePoint(0.5, 0.5)];
	}
	return self;
}

#pragma mark -

- (BOOL)isFlipped
{
	return NO;
}
- (void)drawRect:(NSRect)aRect
{
	NSAffineTransform *const transform = [NSAffineTransform transform];
	[transform translateXBy:0.5 yBy:-0.5];
	[transform concat];

	for(LNGraphic *const graphic in [[self canvasStorage] graphics]) {
		if([graphic isKindOfClass:[LNShape class]] && [self needsToDrawGraphic:graphic selected:NO]) [graphic draw];
	}

	[[([[self window] firstResponder] == self && [[self window] isKeyWindow] ? [NSColor alternateSelectedControlColor] : [NSColor grayColor]) colorWithAlphaComponent:0.5] set];
	NSBezierPath *const highlightPath = [LNGraphic highlightStyleBezierPath:nil];
	for(LNGraphic *const graphic in [self selection]) {
		if(![self needsToDrawGraphic:graphic selected:YES]) continue;
		if([graphic shouldFlattenHighlight]) [highlightPath appendBezierPath:[graphic bezierPath]];
		else [[LNGraphic highlightStyleBezierPath:[graphic bezierPath]] stroke];
	}
	[highlightPath stroke];
	if(_selectionLine && [self needsToDrawGraphic:_selectionLine selected:YES]) [[LNGraphic highlightStyleBezierPath:[_selectionLine bezierPath]] stroke];

	for(LNGraphic *const graphic in [[self canvasStorage] graphics]) {
		if([graphic isKindOfClass:[LNLine class]] && [self needsToDrawGraphic:graphic selected:NO]) [graphic draw];
	}

	if([_primarySelection isKindOfClass:[LNLine class]]) {
		NSPoint const p1 = [(LNLine *)_primarySelection start];
		NSPoint const p2 = [(LNLine *)_primarySelection end];
		NSBezierPath *const startHandle = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(p1.x - 2.5, p1.y - 2.5, 5, 5)];
		NSBezierPath *const endHandle = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(p2.x - 2.5, p2.y - 2.5, 5, 5)];
		[[NSColor whiteColor] set];
		[startHandle fill];
		[endHandle fill];
		[[NSColor blackColor] set];
		[startHandle stroke];
		[endHandle stroke];
	}

	[transform invert];
	[transform concat];

	[[NSColor lightGrayColor] set];
	NSRect const b = [self bounds];
	NSRectFill(NSMakeRect(NSMinX(b), NSMaxY(b) - 1, NSWidth(b), 1));
	NSRectFill(NSMakeRect(NSMaxX(b) - 1, NSMinY(b), 1, NSHeight(b)));
}

#pragma mark -

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	[[self window] LN_removeObserver:self name:NSWindowDidBecomeKeyNotification];
	[[self window] LN_removeObserver:self name:NSWindowDidResignKeyNotification];
	[newWindow LN_addObserver:self selector:@selector(windowWillChangeKey:) name:NSWindowDidBecomeKeyNotification];
	[newWindow LN_addObserver:self selector:@selector(windowWillChangeKey:) name:NSWindowDidResignKeyNotification];
	[self windowWillChangeKey:nil];
}

#pragma mark -NSResponder

- (void)mouseDown:(NSEvent *)firstEvent
{
	BOOL dragging = NO;
	NSPoint const firstPoint = [self convertPoint:[firstEvent locationInWindow] fromView:nil];
	id clickedGraphic;
	LNLinePart clickedPart;
	[self getGraphic:&clickedGraphic linePart:&clickedPart atPoint:firstPoint];
	BOOL const extendingSelection = !!([firstEvent modifierFlags] & (NSCommandKeyMask | NSShiftKeyMask));
	BOOL deselectOnMouseUp = NO;
	if([self tool] == LNSelectTool) {
		if(!extendingSelection) [self deselectAll:self];
	} else if([self tool] == LNLineTool) {
		if(!extendingSelection) {
			if(LNBodyPart != clickedPart || ![[self selection] containsObject:clickedGraphic]) [self deselectAll:self];
			[self setPrimarySelection:clickedGraphic];
		} else if(clickedGraphic) {
			if([[self selection] containsObject:clickedGraphic]) deselectOnMouseUp = YES;
			else if([self primarySelection]) [self select:[NSSet setWithObject:clickedGraphic] byExtendingSelection:YES];
			else [self setPrimarySelection:clickedGraphic];
		}
	} else {
		[self deselectAll:self];
		[self setPrimarySelection:clickedGraphic];
		if(!clickedGraphic) return;
	}
	NSSet *const initialSelection = [self selection];
	id const initialPrimarySelection = [self primarySelection];
	NSMutableArray *const ignoredEvents = [NSMutableArray array];
	NSEvent *latestEvent;
	while((latestEvent = [NSApp nextEventMatchingMask:NSLeftMouseDraggedMask | NSLeftMouseUpMask | NSFlagsChangedMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES]) && [latestEvent type] != NSLeftMouseUp) {
		BOOL caughtFlagsChanged = NO;
		if(!dragging) {
			[[NSCursor crosshairCursor] push];
			dragging = YES;
		}
		NSPoint latestPoint = [self convertPoint:([latestEvent type] == NSLeftMouseDragged ? [latestEvent locationInWindow] : [[self window] mouseLocationOutsideOfEventStream]) fromView:nil];
		switch([self tool]) {
			case LNLineTool:
				if(LNNoPart == clickedPart) {
					clickedGraphic = [LNLine line];
					[clickedGraphic setStart:firstPoint];
					[clickedGraphic setEnd:latestPoint];
					clickedPart = LNEndPart;
					[[self canvasStorage] addGraphics:[NSSet setWithObject:clickedGraphic]];
					[self deselectAll:self];
					[self setPrimarySelection:clickedGraphic];
				} else if(LNBodyPart == clickedPart) {
					if([latestEvent type] == NSLeftMouseDragged) [self moveSelectionBy:NSMakeSize([latestEvent deltaX], -[latestEvent deltaY])];
				} else {
					if(!([latestEvent modifierFlags] & NSShiftKeyMask)) {
						caughtFlagsChanged = YES;
						LNLineEnd closestEnd;
						LNLine *closestLine;
						if([self getDistanceToEnd:&closestEnd ofLine:&closestLine closestToPoint:latestPoint excluding:(clickedGraphic ? [NSSet setWithObject:clickedGraphic] : nil)] < 8 && closestLine) latestPoint = [closestLine locationOfEnd:closestEnd];
					}
					if(LNStartPart == clickedPart) [clickedGraphic setStart:latestPoint];
					else [clickedGraphic setEnd:latestPoint];
				}
				break;
			case LNSelectTool:
				if(_selectionLine) {
					[_selectionLine setEnd:latestPoint];
					NSMutableSet *const selection = [NSMutableSet set];
					for(LNGraphic *const graphic in [[self canvasStorage] graphics]) if([graphic isKindOfClass:[LNLine class]] && [_selectionLine getIntersection:NULL withLine:(LNLine *)graphic]) [selection addObject:graphic];
					[self select:initialSelection byExtendingSelection:NO];
					[self invertSelect:selection];
					if([[self selection] containsObject:initialPrimarySelection]) [self setPrimarySelection:initialPrimarySelection];
				} else {
					[self _setSelectionLine:[LNLine line]];
					[_selectionLine setStart:firstPoint];
					[_selectionLine setEnd:latestPoint];
				}
				break;
			case LNExtendTool:
				if(LNStartPart == clickedPart) [clickedGraphic setLength:MAX(LNPointDistance([clickedGraphic end], latestPoint), 0.01) ofEnd:NO];
				else if(LNEndPart == clickedPart) [clickedGraphic setLength:MAX(LNPointDistance([(LNLine *)clickedGraphic start], latestPoint), 0.01) ofEnd:YES];
				break;
			case LNRotateTool:
				if(LNStartPart == clickedPart) [clickedGraphic setAngle:LNPointAngle([clickedGraphic end], latestPoint) ofEnd:NO];
				else if(LNEndPart == clickedPart) [clickedGraphic setAngle:LNPointAngle([(LNLine *)clickedGraphic start], latestPoint) ofEnd:YES];
				break;
		}
		if([latestEvent type] == NSFlagsChanged && !caughtFlagsChanged) [ignoredEvents addObject:latestEvent];
		[self setNeedsDisplay:YES];
	}
	[[self window] discardEventsMatchingMask:NSAnyEventMask beforeEvent:nil];
	for(NSEvent *const event in ignoredEvents) [NSApp postEvent:event atStart:YES];
	if(dragging) {
		[NSCursor pop];
		[self _setSelectionLine:nil];
	} else if(deselectOnMouseUp) [self deselect:[NSSet setWithObject:clickedGraphic]];
}
- (BOOL)acceptsFirstResponder
{
	return YES;
}
- (BOOL)becomeFirstResponder
{
	[self windowWillChangeKey:nil];
	return YES;
}
- (BOOL)resignFirstResponder
{
	[self windowWillChangeKey:nil];
	return YES;
}
- (void)keyDown:(NSEvent *)anEvent
{
	if(![[NSApp mainMenu] performKeyEquivalent:anEvent]) [super keyDown:anEvent]; // Make sure our one-key menu shortcuts get a shot.
}

#pragma mark -NSObject

- (void)dealloc
{
	[self LN_removeObserver];
	[_canvasStorage release];
	[_selection release];
	[_primarySelection release];
	[_selectionLine release];
	[super dealloc];
}

#pragma mark -NSObject(NSColorPanelResponderMethod)

- (void)changeColor:(id)sender
{
	[[self selection] makeObjectsPerformSelector:@selector(setColor:) withObject:[sender color]];
}

#pragma mark -NSObject(NSMenuValidation)

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	SEL const action = [anItem action];
	if(![[self selection] count]) {
		if(@selector(copy:) == action) return NO;
		if(@selector(deselectAll:) == action) return NO;
	}
	if(@selector(paste:) == action && ![[[NSPasteboard generalPasteboard] types] containsObject:LNCanvasGraphicsPboardType]) return NO;
	if(![self primarySelection] || [[self selection] count] < 2) {
		if(@selector(dividePrimary:) == action) return NO;
		if(@selector(divideByPrimary:) == action) return NO;
		if(@selector(extend:) == action) return NO;
	}
	if([[self selection] count] < 3) {
		if(@selector(makeShapeWithSelection:) == action) return NO;
	}
	return [self respondsToSelector:action];
}

@end
