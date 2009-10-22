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

// Categories
#import "NSObjectAdditions.h"

NSString *const LNCanvasViewSelectionDidChangeNotification = @"LNCanvasViewSelectionDidChange";

// Pasteboard Types
static NSString *const LNCanvasGraphicsPboardType = @"LNCanvasGraphics";

@interface LNCanvasView (Private)

- (void)_setSelectionLine:(LNLine *)line;

@end

@implementation LNCanvasView

#pragma mark Class Methods

+ (void)initialize
{
	[NSColor setIgnoresAlpha:NO];
}

#pragma mark Instance Methods

/*- (IBAction)copy:(id)sender
{
	// FIXME: -[LNCanvasStorage graphicsInSet:]?
	if(![[self selection] count]) return NSBeep();
	NSPasteboard *const pboard = [NSPasteboard generalPasteboard];
	[pboard declareTypes:[NSArray arrayWithObject:LNCanvasGraphicsPboardType] owner:nil];
	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:[self selection]] forType:LNCanvasGraphicsPboardType];
}*/
/*- (IBAction)paste:(id)sender
{
	// FIXME: -[LNCanvasStorage addGraphics:]?
	NSPasteboard *const pboard = [NSPasteboard generalPasteboard];
	if(![[pboard types] containsObject:LNCanvasGraphicsPboardType]) return NSBeep();
	NSSet *const graphics = [NSKeyedUnarchiver unarchiveObjectWithData:[pboard dataForType:LNCanvasGraphicsPboardType]];
	if(![graphics count]) return;
	[[[self canvasStorage] LN_undoManager] beginUndoGrouping];
	[[self canvasStorage] addGraphics:[graphics allObjects]];
	[self deselectAll:self];
	[self select:graphics];
	[self moveSelectionBy:NSMakeSize(15, -15)];
	[[[self canvasStorage] LN_undoManager] endUndoGrouping];
}*/
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
	LNLine *const line = [self primarySelection];
	if(![line isKindOfClass:[LNLine class]]) return NSBeep();
	NSSet *const dividedLines = [line linesByDividingAtLines:[self selection]];
	[[self canvasStorage] removeGraphics:[NSSet setWithObject:line]];
	[[self canvasStorage] addGraphics:dividedLines];
	[self deselectAll:self];
}
- (IBAction)divideByPrimary:(id)sender
{
	LNLine *const line = [self primarySelection];
	if(![line isKindOfClass:[LNLine class]]) return NSBeep();
	NSMutableSet *const selection = [[[self selection] mutableCopy] autorelease];
	[selection removeObject:line];
	NSSet *const dividedLines = [line linesByDividingLines:selection];
	[[self canvasStorage] removeGraphics:selection];
	[[self canvasStorage] addGraphics:dividedLines];
	[self deselectAll:self];
}
- (IBAction)extend:(id)sender
{
	LNLine *const line = [self primarySelection];
	if(![line isKindOfClass:[LNLine class]]) return NSBeep();
	[line extendToClosestLineInSet:[self selection]];
}
- (IBAction)makeShapeWithSelection:(id)sender
{
	NSMutableSet *const selectedLines = [NSMutableSet set];
	id graphic;
	NSEnumerator *const selectionEnum = [[self selection] objectEnumerator];
	while((graphic = [selectionEnum nextObject])) if([graphic isKindOfClass:[LNLine class]]) [selectedLines addObject:graphic];
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
	[_canvasStorage AE_removeObserver:self name:LNCanvasStorageDidChangeGraphicsNotification];
	[_canvasStorage AE_removeObserver:self name:LNCanvasStorageGraphicWillChangeNotification];
	[_canvasStorage AE_removeObserver:self name:LNCanvasStorageGraphicDidChangeNotification];
	[_canvasStorage release];
	_canvasStorage = [storage retain];
	[self setNeedsDisplay:YES];
	[_canvasStorage AE_addObserver:self selector:@selector(storageDidChangeGraphics:) name:LNCanvasStorageDidChangeGraphicsNotification];
	[_canvasStorage AE_addObserver:self selector:@selector(storageGraphicWillChange:) name:LNCanvasStorageGraphicWillChangeNotification];
	[_canvasStorage AE_addObserver:self selector:@selector(storageGraphicDidChange:) name:LNCanvasStorageGraphicDidChangeNotification];
}

#pragma mark -

- (void)getGraphic:(out id *)outGraphic
        linePart:(out LNLinePart *)outPart
	atPoint:(NSPoint)aPoint
{
	id graphic = [self primarySelection];
	if([graphic isKindOfClass:[LNLine class]]) {
		if(LNPointDistance([graphic end], aPoint) <= 4) {
			if(outGraphic) *outGraphic = graphic;
			if(outPart) *outPart = LNEndPart;
			return;
		} else if(LNPointDistance([(LNLine *)graphic start], aPoint) <= 4) {
			if(outGraphic) *outGraphic = graphic;
			if(outPart) *outPart = LNStartPart;
			return;
		}
	}
	NSEnumerator *const graphicEnum = [[[self canvasStorage] graphics] reverseObjectEnumerator];
	while((graphic = [graphicEnum nextObject])) {
		if([graphic isKindOfClass:[LNLine class]]) {
			if([graphic distanceToPoint:aPoint] > 4) continue;
		} else if([graphic isKindOfClass:[LNShape class]]) {
			if(![[graphic bezierPath] containsPoint:aPoint]) continue;
		} else continue;
		if(outGraphic) *outGraphic = graphic;
		if(outPart) *outPart = LNBodyPart;
		return;
	}
	if(outGraphic) *outGraphic = nil;
	if(outPart) *outPart = LNNoPart;
}
- (float)getDistanceToEnd:(out LNLineEnd *)outEnd
         ofLine:(out LNLine **)outLine
	 closestToPoint:(NSPoint)aPoint
	 excluding:(NSSet *)excludedSet
{
	float dist = FLT_MAX;
	if(outLine) *outLine = nil;
	id graphic;
	NSEnumerator *const graphicEnum = [[[self canvasStorage] graphics] objectEnumerator];
	while((graphic = [graphicEnum nextObject])) {
		if(![graphic isKindOfClass:[LNLine class]] || [excludedSet containsObject:graphic]) continue;
		float const startDist = LNPointDistance([(LNLine *)graphic start], aPoint);
		float const endDist = LNPointDistance([graphic end], aPoint);
		if(startDist < dist) {
			dist = startDist;
			if(outEnd) *outEnd = LNStartEnd;
			if(outLine) *outLine = graphic;
		}
		if(endDist < dist) {
			dist = endDist;
			if(outEnd) *outEnd = LNEndEnd;
			if(outLine) *outLine = graphic;
		}
	}
	return dist;
}
- (BOOL)needsToDrawGraphic:(LNGraphic *)graphic
        selected:(BOOL)flag
{
	NSRect frame = [graphic frame];
	if(NSIsEmptyRect(frame)) return NO;
	if(flag) frame = NSInsetRect(frame, -5, -5);
	return [self needsToDrawRect:frame];
}

#pragma mark -

- (NSSet *)selection
{
	return [[_selection copy] autorelease];
}
- (LNGraphic *)selectedGraphic
{
	LNGraphic *result = nil, *selected;
	NSEnumerator *const selectedEnum = [_selection objectEnumerator];
	while((selected = [selectedEnum nextObject])) {
		if(![selectedEnum isKindOfClass:[LNGraphic class]]) continue;
		if(result) return nil;
		result = selected;
	}
	return result;
}
- (void)select:(NSSet *)aSet
        byExtendingSelection:(BOOL)flag
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
	[self AE_postNotificationName:LNCanvasViewSelectionDidChangeNotification];
}
- (void)deselect:(NSSet *)aSet
{
	if(![aSet count]) return;
	[_selection minusSet:aSet];
	if([_selection count] == 1) [[NSColorPanel sharedColorPanel] setColor:[[_selection anyObject] color]];
	if([aSet containsObject:[self primarySelection]]) [self setPrimarySelection:nil];
	[self setNeedsDisplay:YES];
	[self AE_postNotificationName:LNCanvasViewSelectionDidChangeNotification];
}
- (void)invertSelect:(NSSet *)aSet
{
	id graphic;
	NSEnumerator *const graphicEnum = [aSet objectEnumerator];
	while((graphic = [graphicEnum nextObject])) {
		if([_selection containsObject:graphic]) [_selection removeObject:graphic];
		else [_selection addObject:graphic];
	}
	if(![_selection containsObject:[self primarySelection]]) [self setPrimarySelection:nil];
	[self setNeedsDisplay:YES];
	[self AE_postNotificationName:LNCanvasViewSelectionDidChangeNotification];
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

#pragma mark -

- (void)moveSelectionBy:(NSSize)aSize
{
	[[[self canvasStorage] LN_undoManager] beginUndoGrouping];
	id graphic;
	NSEnumerator *const graphicEnum = [[self selection] objectEnumerator];
	while((graphic = [graphicEnum nextObject])) if([graphic isKindOfClass:[LNLine class]]) [graphic offsetBy:aSize];
	[[[self canvasStorage] LN_undoManager] endUndoGrouping];
}

#pragma mark -

- (LNCanvasTool)tool
{
	return _tool;
}
- (void)setTool:(LNCanvasTool)tool
{
	_tool = tool;
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

#pragma mark Private Protocol

- (void)_setSelectionLine:(LNLine *)line
{
	if(line == _selectionLine) return;
	[_selectionLine AE_removeObserver:self name:LNGraphicWillChangeNotification];
	[_selectionLine AE_removeObserver:self name:LNGraphicDidChangeNotification];
	[_selectionLine release];
	_selectionLine = [line retain];
	[_selectionLine AE_addObserver:self selector:@selector(graphicWillChange:) name:LNGraphicWillChangeNotification];
	[_selectionLine AE_addObserver:self selector:@selector(graphicDidChange:) name:LNGraphicDidChangeNotification];
	[self setNeedsDisplay:YES];
}

#pragma mark NSColorPanelResponderMethod Protocol

- (void)changeColor:(id)sender
{
	[[self selection] makeObjectsPerformSelector:@selector(setColor:) withObject:[sender color]];
}

#pragma mark NSMenuValidation Protocol

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

#pragma mark NSView

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

	LNGraphic *graphic;
	NSEnumerator *const shapeEnum = [[[self canvasStorage] graphics] objectEnumerator];
	while((graphic = [shapeEnum nextObject])) {
		if([graphic isKindOfClass:[LNShape class]] && [self needsToDrawGraphic:graphic selected:NO]) [graphic draw];
	}

	[[([[self window] firstResponder] == self && [[self window] isKeyWindow] ? [NSColor alternateSelectedControlColor] : [NSColor grayColor]) colorWithAlphaComponent:0.5] set];
	NSBezierPath *const highlightPath = [LNGraphic highlightStyleBezierPath:nil];
	NSEnumerator *const selectedLineEnum = [[self selection] objectEnumerator];
	while((graphic = [selectedLineEnum nextObject])) {
		if(![self needsToDrawGraphic:graphic selected:YES]) continue;
		if([graphic shouldFlattenHighlight]) [highlightPath appendBezierPath:[graphic bezierPath]];
		else [[LNGraphic highlightStyleBezierPath:[graphic bezierPath]] stroke];
	}
	[highlightPath stroke];
	if(_selectionLine && [self needsToDrawGraphic:_selectionLine selected:YES]) [[LNGraphic highlightStyleBezierPath:[_selectionLine bezierPath]] stroke];

	NSEnumerator *const lineEnum = [[[self canvasStorage] graphics] objectEnumerator];
	while((graphic = [lineEnum nextObject])) {
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
	[[self window] AE_removeObserver:self name:NSWindowDidBecomeKeyNotification];
	[[self window] AE_removeObserver:self name:NSWindowDidResignKeyNotification];
	[newWindow AE_addObserver:self selector:@selector(windowWillChangeKey:) name:NSWindowDidBecomeKeyNotification];
	[newWindow AE_addObserver:self selector:@selector(windowWillChangeKey:) name:NSWindowDidResignKeyNotification];
	[self windowWillChangeKey:nil];
}

#pragma mark NSResponder

- (void)mouseDown:(NSEvent *)firstEvent
{
	BOOL beganUndoGroup = NO;
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
		if(!beganUndoGroup && [self tool] != LNSelectTool) {
			[[[self canvasStorage] LN_undoManager] beginUndoGrouping];
			beganUndoGroup = YES;
		}
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
					id graphic;
					NSEnumerator *const graphicEnum = [[[self canvasStorage] graphics] objectEnumerator];
					while((graphic = [graphicEnum nextObject])) if([graphic isKindOfClass:[LNLine class]] && [_selectionLine getIntersection:NULL withLine:graphic]) [selection addObject:graphic];
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
				if(LNStartPart == clickedPart) [clickedGraphic setLength:MAX(LNPointDistance([clickedGraphic end], latestPoint), 0.01) ofEnd:LNStartEnd];
				else if(LNEndPart == clickedPart) [clickedGraphic setLength:MAX(LNPointDistance([(LNLine *)clickedGraphic start], latestPoint), 0.01) ofEnd:LNEndEnd];
				break;
			case LNRotateTool:
				if(LNStartPart == clickedPart) [clickedGraphic setAngle:LNPointAngle([clickedGraphic end], latestPoint) ofEnd:LNStartEnd];
				else if(LNEndPart == clickedPart) [clickedGraphic setAngle:LNPointAngle([(LNLine *)clickedGraphic start], latestPoint) ofEnd:LNEndEnd];
				break;
		}
		if([latestEvent type] == NSFlagsChanged && !caughtFlagsChanged) [ignoredEvents addObject:latestEvent];
		[self setNeedsDisplay:YES];
	}
	[[self window] discardEventsMatchingMask:NSAnyEventMask beforeEvent:nil];
	NSEvent *event;
	NSEnumerator *const eventEnum = [ignoredEvents objectEnumerator];
	while((event = [eventEnum nextObject])) [NSApp postEvent:event atStart:YES];
	if(dragging) {
		[NSCursor pop];
		[self _setSelectionLine:nil];
	} else if(deselectOnMouseUp) [self deselect:[NSSet setWithObject:clickedGraphic]];
	if(beganUndoGroup) [[[self canvasStorage] LN_undoManager] endUndoGrouping];
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

#pragma mark NSObject

- (void)dealloc
{
	[self AE_removeObserver];
	[_canvasStorage release];
	[_selection release];
	[_primarySelection release];
	[_selectionLine release];
	[super dealloc];
}

@end
