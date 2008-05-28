#import "LNShape.h"

// Models
#import "LNCanvasStorage.h"
#import "LNLine.h"

// Categories
#import "NSObjectAdditions.h"

// Other Sources
#import "LNMutableArray.h"

@implementation LNShape

#pragma mark Instance Methods

- (id)initWithSides:(NSSet *)aSet
{
	if((self = [self init])) {
		NSArray *const sides = [LNLine chainOfConnectingLines:aSet];
		if(![sides count]) {
			[self release];
			return nil;
		}
		[_sides addObjectsFromArray:sides];
	}
	return self;
}

#pragma mark -

- (NSMutableArray *)sides
{
	return [[_sides retain] autorelease];
}

#pragma mark -

- (void)recache
{
	[_cachedPoints release];
	_cachedPoints = nil;
	[_cachedPath release];
	_cachedPath = nil;
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

- (void)sideWillChange:(NSNotification *)aNotif
{
	[self AE_postNotificationName:LNGraphicWillChangeNotification];
}
- (void)sideDidChange:(NSNotification *)aNotif
{
	[self recache];
	[self AE_postNotificationName:LNGraphicDidChangeNotification];
}

#pragma mark LNMutableArrayDelegate Protocol

- (NSUndoManager *)undoManagerForArray:(LNMutableArray *)sender
{
	return [self LN_undoManager];
}
- (void)array:(LNMutableArray *)sender
        didAddObject:(id)anObject
{
	[anObject AE_addObserver:self selector:@selector(sideWillChange:) name:LNGraphicWillChangeNotification];
	[anObject AE_addObserver:self selector:@selector(sideDidChange:) name:LNGraphicDidChangeNotification];
	[self recache];
	[self AE_postNotificationName:LNGraphicDidChangeNotification];
}
- (void)array:(LNMutableArray *)sender
        didRemoveObject:(id)anObject
{
	[anObject AE_removeObserver:self name:LNGraphicWillChangeNotification];
	[anObject AE_removeObserver:self name:LNGraphicDidChangeNotification];
	[self recache];
	[self AE_postNotificationName:LNGraphicDidChangeNotification];
}

#pragma mark LNGraphicSubclassResponsibility Protocol

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

#pragma mark NSCoding Protocol

- (id)initWithCoder:(NSCoder *)aCoder
{
	if((self = [super initWithCoder:aCoder])) {
		id const sides = [aCoder decodeObjectForKey:@"Sides"];
		if(![sides isKindOfClass:[NSSet class]]) _sides = [sides retain];
	}
	return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:_sides forKey:@"Sides"];
}

#pragma mark NSCopying Protocol

- (id)copyWithZone:(NSZone *)aZone
{
	return [self retain];
}

#pragma mark NSObject

- (id)init
{
	if((self = [super init])) {
		_sides = [[LNMutableArray alloc] init];
		[_sides setDelegate:self];
		[self setColor:[NSColor colorWithDeviceWhite:0.5 alpha:1]];
	}
	return self;
}
- (void)dealloc
{
	[self AE_removeObserver];
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

@end
