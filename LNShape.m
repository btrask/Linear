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
#import "LNShape.h"

// Models
#import "LNCanvasStorage.h"
#import "LNLine.h"

// Other Sources
#import "LNFoundationAdditions.h"

@interface LNShape(Private)

- (void)_init;

@end

@implementation LNShape

#pragma mark -LNShape

- (id)initWithSides:(NSSet *)aSet
{
	if((self = [self init])) {
		_sides = [[LNLine chainOfConnectingLines:aSet] copy];
		if(![_sides count]) {
			[self release];
			return nil;
		}
		[self _init];
		[self setColor:[NSColor colorWithDeviceWhite:0.5f alpha:1.0f]];
	}
	return self;
}
- (NSMutableArray *)sides
{
	return [[_sides retain] autorelease];
}
- (NSArray *)points
{
	if(!_cachedPoints) {
		NSMutableArray *const points = [[NSMutableArray alloc] init];
		_cachedPoints = points;
		LNLine *side, *previousSide = [_sides lastObject];
		NSEnumerator *const sideEnum = [_sides objectEnumerator];
		for(; (side = [sideEnum nextObject]); previousSide = side) {
			NSPoint intersection;
			if(![previousSide getIntersection:&intersection withLine:side]) {
				[_cachedPoints release];
				_cachedPoints = [[NSArray alloc] init];
				break;
			}
			[points addObject:[NSValue valueWithPoint:intersection]];
		}
	}
	return [[_cachedPoints retain] autorelease];
}

#pragma mark -

- (void)recache
{
	[_cachedPoints release];
	_cachedPoints = nil;
	[_cachedPath release];
	_cachedPath = nil;
}

#pragma mark -

- (void)sideWillChange:(NSNotification *)aNotif
{
	[self LN_postNotificationName:LNGraphicWillChangeNotification];
}
- (void)sideDidChange:(NSNotification *)aNotif
{
	[self recache];
	[self LN_postNotificationName:LNGraphicDidChangeNotification];
}

#pragma mark -LNShape(Private)

- (void)_init
{
	for(LNLine *const line in _sides) {
		[line LN_addObserver:self selector:@selector(sideWillChange:) name:LNGraphicWillChangeNotification];
		[line LN_addObserver:self selector:@selector(sideDidChange:) name:LNGraphicDidChangeNotification];
	}
}

#pragma mark -LNGraphic(LNGraphicSubclassResponsibility)

- (NSBezierPath *)bezierPath
{
	if(!_cachedPath) {
		_cachedPath = [[NSBezierPath alloc] init];
		NSEnumerator *const pointEnum = [[self points] objectEnumerator];
		NSValue *point = [pointEnum nextObject];
		if(point) [_cachedPath moveToPoint:[point pointValue]];
		while((point = [pointEnum nextObject])) [_cachedPath lineToPoint:[point pointValue]];
		[_cachedPath closePath];
	}
	return [[_cachedPath retain] autorelease];
}
- (NSRect)frame
{
	return [[self bezierPath] isEmpty] ? NSZeroRect : [[self bezierPath] bounds];
}
- (void)draw
{
	[[self color] set];
	[[self bezierPath] fill];
}
- (BOOL)shouldFlattenHighlight
{
	return NO;
}
- (NSString *)displayString
{
	unsigned const c = [_sides count];
	return c == 1 ? NSLocalizedString(@"Shape with 1 side", @"Shape display string for shapes with only 1 side.") : [NSString stringWithFormat:NSLocalizedString(@"Shape with %u sides", @"Shape display string for shapes with any number of sides besides 1. %u is replaced with the number."), c];
}

#pragma mark -NSObject

- (id)init
{
	return [self initWithSides:[NSSet set]];
}
- (void)dealloc
{
	[self LN_removeObserver];
	[_sides release];
	[_cachedPoints release];
	[_cachedPath release];
	[super dealloc];
}

#pragma mark -

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p: %u sides>", [self class], self, [_sides count]];
}

#pragma mark -<NSCoding>

- (id)initWithCoder:(NSCoder *)aCoder
{
	if((self = [super initWithCoder:aCoder])) {
		id const sides = [aCoder decodeObjectForKey:@"Sides"];
		if([sides isKindOfClass:[NSSet class]]) _sides = [[LNLine chainOfConnectingLines:sides] copy];
		else _sides = [sides retain];
		[self _init];
	}
	return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:_sides forKey:@"Sides"];
}

#pragma mark -<NSCopying>

- (id)copyWithZone:(NSZone *)aZone
{
	return [self retain];
}

@end
