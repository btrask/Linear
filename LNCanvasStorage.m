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
#import "LNCanvasStorage.h"

// Models
#import "LNGraphic.h"
#import "LNLine.h"
#import "LNShape.h"

// Other Sources
#import "LNFoundationAdditions.h"

NSString *const LNCanvasStorageDidChangeGraphicsNotification = @"LNCanvasStorageDidChangeGraphics";
NSString *const LNCanvasStorageGraphicsAddedKey              = @"LNCanvasStorageGraphicsAdded";
NSString *const LNCanvasStorageGraphicsRemovedKey            = @"LNCanvasStorageGraphicsRemoved";

NSString *const LNCanvasStorageGraphicWillChangeNotification = @"LNCanvasStorageGraphicWillChange";
NSString *const LNCanvasStorageGraphicDidChangeNotification  = @"LNCanvasStorageGraphicDidChange";
NSString *const LNCanvasStorageGraphicKey                    = @"LNCanvasStorageGraphic";

@implementation LNCanvasStorage

#pragma mark -LNCanvasStorage

@synthesize canvasView = _canvasView;
- (NSMutableArray *)lines
{
	return [[_lines retain] autorelease];
}
- (NSMutableArray *)shapes
{
	return [[_shapes retain] autorelease];
}

#pragma mark -

- (NSArray *)graphics
{
	return [_shapes arrayByAddingObjectsFromArray:_lines];
}
- (void)addGraphics:(id)collection
{
	if(![collection count]) return;
	for(id const graphic in collection) {
		if([graphic isKindOfClass:[LNLine class]]) [_lines addObject:graphic];
		else if([graphic isKindOfClass:[LNShape class]]) [_shapes addObject:graphic];
		else NSAssert(0, @"Invalid graphic.");
		[graphic LN_addObserver:self selector:@selector(graphicWillChange:) name:LNGraphicWillChangeNotification];
		[graphic LN_addObserver:self selector:@selector(graphicDidChange:) name:LNGraphicDidChangeNotification];
	}
	[self LN_postNotificationName:LNCanvasStorageDidChangeGraphicsNotification userInfo:[NSDictionary dictionaryWithObject:collection forKey:LNCanvasStorageGraphicsAddedKey]];
}
- (void)removeGraphics:(NSSet *)aSet
{
	for(id const graphic in aSet) {
		if([graphic isKindOfClass:[LNLine class]]) for(LNShape *const shape in [[_shapes copy] autorelease]) if([[shape sides] indexOfObjectIdenticalTo:graphic] != NSNotFound) [self removeGraphics:[NSSet setWithObject:shape]];
		[graphic LN_removeObserver:self name:LNGraphicWillChangeNotification];
		[graphic LN_removeObserver:self name:LNGraphicDidChangeNotification];
	}
	NSArray *const old = [aSet allObjects];
	[_lines removeObjectsInArray:old];
	[_shapes removeObjectsInArray:old];
	[self LN_postNotificationName:LNCanvasStorageDidChangeGraphicsNotification userInfo:[NSDictionary dictionaryWithObject:aSet forKey:LNCanvasStorageGraphicsRemovedKey]];
}

#pragma mark -

- (void)graphicWillChange:(NSNotification *)aNotif;
{
	NSParameterAssert(aNotif);
	[self LN_postNotificationName:LNCanvasStorageGraphicWillChangeNotification userInfo:[NSDictionary dictionaryWithObject:[aNotif object] forKey:LNCanvasStorageGraphicKey]];
}
- (void)graphicDidChange:(NSNotification *)aNotif;
{
	NSParameterAssert(aNotif);
	[self LN_postNotificationName:LNCanvasStorageGraphicDidChangeNotification userInfo:[NSDictionary dictionaryWithObject:[aNotif object] forKey:LNCanvasStorageGraphicKey]];
}

#pragma mark -NSObject

- (id)init
{
	if((self = [super init])) {
		_lines = [[NSMutableArray alloc] init];
		_shapes = [[NSMutableArray alloc] init];
	}
	return self;
}
- (void)dealloc
{
	[self LN_removeObserver];
	[_lines release];
	[_shapes release];
	[super dealloc];
}

#pragma mark -<NSCoding>

- (id)initWithCoder:(NSCoder *)aCoder
{
	if((self = [self init])) {
		[self addGraphics:[aCoder decodeObjectForKey:@"Graphics"]]; // BC.

		id lines = [aCoder decodeObjectForKey:@"Lines"];
		if([lines isKindOfClass:[NSSet class]]) lines = [lines allObjects]; // Ancient BC.
		[self addGraphics:lines];

		[self addGraphics:[aCoder decodeObjectForKey:@"Shapes"]];
	}
	return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:[[_lines copy] autorelease] forKey:@"Lines"];
	[aCoder encodeObject:[[_shapes copy] autorelease] forKey:@"Shapes"];
}

@end
