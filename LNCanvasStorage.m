#import "LNCanvasStorage.h"

// Models
#import "LNGraphic.h"
#import "LNLine.h"
#import "LNShape.h"

// Categories
#import "NSObjectAdditions.h"

// Other Sources
#import "LNMutableArray.h"

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
- (void)addGraphics:(NSArray *)anArray
{
	id graphic;
	NSEnumerator *graphicEnum = [anArray objectEnumerator];
	while((graphic = [graphicEnum nextObject])) {
		if([graphic isKindOfClass:[LNLine class]]) [_lines addObject:graphic];
		else if([graphic isKindOfClass:[LNShape class]]) [_shapes addObject:graphic];
		else NSAssert(0, @"Invalid graphic.");
	}
}
- (void)removeGraphics:(NSSet *)aSet
{
	NSArray *const old = [aSet allObjects];
	[_lines removeObjectsInArray:old];
	[_shapes removeObjectsInArray:old];
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

#pragma mark LNMutableArrayDelegate Protocol

- (NSUndoManager *)undoManagerForArray:(LNMutableArray *)sender
{
	return [self LN_undoManager];
}
- (void)array:(LNMutableArray *)sender
        didAddObject:(id)anObject
{
	[(LNDocumentObject *)anObject setDocument:[self document]];
	[anObject AE_addObserver:self selector:@selector(graphicWillChange:) name:LNGraphicWillChangeNotification];
	[anObject AE_addObserver:self selector:@selector(graphicDidChange:) name:LNGraphicDidChangeNotification];
	[self AE_postNotificationName:LNCanvasStorageDidChangeGraphicsNotification userInfo:[NSDictionary dictionaryWithObject:[NSSet setWithObject:anObject] forKey:LNCanvasStorageGraphicsAddedKey]];
}
- (void)array:(LNMutableArray *)sender
        didRemoveObject:(id)anObject
{
	if([anObject isKindOfClass:[LNLine class]]) {
		LNShape *shape;
		NSEnumerator *shapeEnum = [[[_shapes copy] autorelease] objectEnumerator];
		while((shape = [shapeEnum nextObject])) if([[shape sides] indexOfObjectIdenticalTo:anObject] != NSNotFound) [_shapes removeObjectIdenticalTo:shape];
	}
	[anObject AE_removeObserver:self name:LNGraphicWillChangeNotification];
	[anObject AE_removeObserver:self name:LNGraphicDidChangeNotification];
	[self AE_postNotificationName:LNCanvasStorageDidChangeGraphicsNotification userInfo:[NSDictionary dictionaryWithObject:[NSSet setWithObject:anObject] forKey:LNCanvasStorageGraphicsRemovedKey]];
}

#pragma mark NSCoding Protocol

- (id)initWithCoder:(NSCoder *)aCoder
{
	if((self = [self init])) {
		[self addGraphics:[aCoder decodeObjectForKey:@"Graphics"]]; // BC.

		id lines = [aCoder decodeObjectForKey:@"Lines"];
		if([lines isKindOfClass:[NSSet class]]) lines = [lines allObjects]; // Ancient BC.
		[_lines addObjectsFromArray:lines];

		[_shapes addObjectsFromArray:[aCoder decodeObjectForKey:@"Shapes"]];
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
		_lines = [[LNMutableArray alloc] init];
		[_lines setDelegate:self];
		_shapes = [[LNMutableArray alloc] init];
		[_shapes setDelegate:self];
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
