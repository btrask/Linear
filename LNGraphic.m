#import "LNGraphic.h"

// Categories
#import "NSObjectAdditions.h"

NSString *const LNGraphicWillChangeNotification = @"LNGraphicWillChange";
NSString *const LNGraphicDidChangeNotification  = @"LNGraphicDidChange";

@implementation LNGraphic

#pragma mark Class Methods

+ (NSBezierPath *)highlightStyleBezierPath:(NSBezierPath *)path
{
	NSBezierPath *const highlightPath = path ? path : [NSBezierPath bezierPath];
	[highlightPath setLineWidth:9];
	[highlightPath setLineCapStyle:NSRoundLineCapStyle];
	[highlightPath setLineJoinStyle:NSRoundLineJoinStyle];
	return highlightPath;
}

#pragma mark Instance Methods

- (NSColor *)color
{
	return [[_color retain] autorelease];
}
- (void)setColor:(NSColor *)aColor
{
	if(aColor == _color || [aColor isEqual:_color]) return;
	[self AE_postNotificationName:LNGraphicWillChangeNotification];
	[[self LN_undo] setColor:_color];
	[_color release];
	_color = [aColor copy];
	[self AE_postNotificationName:LNGraphicDidChangeNotification];
}

#pragma mark NSCoding Protocol

- (id)initWithCoder:(NSCoder *)aCoder
{
	if((self = [super init])) {
		[self setColor:[aCoder decodeObjectForKey:@"Color"]];
	}
	return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:_color forKey:@"Color"];
}

#pragma mark NSCopying Protocol

- (id)copyWithZone:(NSZone *)aZone
{
	id const dupe = [[[self class] allocWithZone:aZone] init];
	[dupe setColor:[self color]];
	return dupe;
}

#pragma mark NSObject

- (void)dealloc
{
	[_color release];
	[super dealloc];
}

@end
