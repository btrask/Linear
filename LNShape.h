#import <Cocoa/Cocoa.h>

// Inherits from
#import "LNGraphic.h"

// Models
@class LNCanvasStorage;
@class LNLine;

@interface LNShape : LNGraphic <NSCoding, NSCopying>
{
	NSMutableArray *_sides;
	NSArray        *_cachedPoints;
	NSBezierPath   *_cachedPath;
}

- (id)initWithSides:(NSSet *)aSet;

- (NSMutableArray *)sides;

- (void)recache;
- (NSArray *)points;

- (void)sideWillChange:(NSNotification *)aNotif;
- (void)sideDidChange:(NSNotification *)aNotif;

@end
