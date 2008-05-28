#import <Cocoa/Cocoa.h>

// Inherits from
#import "LNGraphic.h"

// Models
@class LNCanvasStorage;
@class LNLine;

// Other Sources
@class LNMutableArray;

@interface LNShape : LNGraphic <NSCoding, NSCopying>
{
	LNMutableArray *_sides;
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
