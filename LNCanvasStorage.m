#import "LNCanvasStorage.h"

// Models
#import "LNGraphic.h"
#import "LNLine.h"
#import "LNShape.h"

// Categories
#import "NSObjectAdditions.h"

NSString *const LNCanvasStorageDidChangeGraphicsNotification = @"LNCanvasStorageDidChangeGraphics";
NSString *const LNCanvasStorageGraphicsAddedKey              = @"LNCanvasStorageGraphicsAdded";
NSString *const LNCanvasStorageGraphicsRemovedKey            = @"LNCanvasStorageGraphicsRemoved";

NSString *const LNCanvasStorageGraphicWillChangeNotification = @"LNCanvasStorageGraphicWillChange";
NSString *const LNCanvasStorageGraphicDidChangeNotification  = @"LNCanvasStorageGraphicDidChange";
NSString *const LNCanvasStorageGraphicKey                    = @"LNCanvasStorageGraphic";

@implementation LNCanvasStorage

#pragma mark Instance Methods

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
		[graphic AE_addObserver:self selector:@selector(graphicWillChange:) name:LNGraphicWillChangeNotification];
		[graphic AE_addObserver:self selector:@selector(graphicDidChange:) name:LNGraphicDidChangeNotification];
	}
	[self AE_postNotificationName:LNCanvasStorageDidChangeGraphicsNotification userInfo:[NSDictionary dictionaryWithObject:collection forKey:LNCanvasStorageGraphicsAddedKey]];
}
- (void)removeGraphics:(NSSet *)aSet
{
	for(id const graphic in aSet) {
		if([graphic isKindOfClass:[LNLine class]]) for(LNShape *const shape in [[_shapes copy] autorelease]) if([[shape sides] indexOfObjectIdenticalTo:graphic] != NSNotFound) [self removeGraphics:[NSSet setWithObject:shape]];
		[graphic AE_removeObserver:self name:LNGraphicWillChangeNotification];
		[graphic AE_removeObserver:self name:LNGraphicDidChangeNotification];
	}
	NSArray *const old = [aSet allObjects];
	[_lines removeObjectsInArray:old];
	[_shapes removeObjectsInArray:old];
	[self AE_postNotificationName:LNCanvasStorageDidChangeGraphicsNotification userInfo:[NSDictionary dictionaryWithObject:aSet forKey:LNCanvasStorageGraphicsRemovedKey]];
}

#pragma mark -

- (void)graphicWillChange:(NSNotification *)aNotif;
{
	NSParameterAssert(aNotif);
	[self AE_postNotificationName:LNCanvasStorageGraphicWillChangeNotification userInfo:[NSDictionary dictionaryWithObject:[aNotif object] forKey:LNCanvasStorageGraphicKey]];
}
- (void)graphicDidChange:(NSNotification *)aNotif;
{
	NSParameterAssert(aNotif);
	[self AE_postNotificationName:LNCanvasStorageGraphicDidChangeNotification userInfo:[NSDictionary dictionaryWithObject:[aNotif object] forKey:LNCanvasStorageGraphicKey]];
}

#pragma mark NSCoding Protocol

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

#pragma mark LNDocumentObject

- (void)setDocument:(LNDocument *)aDoc
{
	[super setDocument:aDoc];
	[[self graphics] makeObjectsPerformSelector:@selector(setDocument:) withObject:[self document]];
}

#pragma mark NSObject

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
	[self AE_removeObserver];
	[self setDocument:nil];
	[_lines release];
	[_shapes release];
	[super dealloc];
}

@end
