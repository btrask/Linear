#import <Cocoa/Cocoa.h>

// Inherits from
#import "LNGraphic.h"

// Models
@class LNCanvasStorage;

enum {
	LNNoPart     = 0,
	LNBodyPart   = 1,
	LNStartPart  = 2,
	LNEndPart    = 3
};
typedef int LNLinePart;

enum {
	LNEndEnd   = NO,
	LNStartEnd = YES
};
typedef BOOL LNLineEnd; // You can use logical operations on LNLineEnd, like ! to get the opposite. Note that all non-zero values mean LNStartEnd.

float LNRadiansToDegrees(float rad);
float LNDegreesToRadians(float deg);
float LNPointAngle(NSPoint p1, NSPoint p2);
float LNPointDistance(NSPoint p1, NSPoint p2);

@interface LNLine : LNGraphic <NSCoding, NSCopying>
{
	@private
	NSPoint _p1;
	NSPoint _p2;
}

+ (id)line;
+ (id)lineWithPoint:(NSPoint)aPoint;
+ (NSArray *)chainOfConnectingLines:(NSSet *)aSet;

- (id)initWithStart:(NSPoint)start end:(NSPoint)end;

- (NSPoint)start;
- (void)setStart:(NSPoint)aPoint;
- (NSPoint)end;
- (void)setEnd:(NSPoint)aPoint;
- (void)offsetBy:(NSSize)aSize;

- (float)angle;
- (void)setAngle:(float)aFloat ofEnd:(LNLineEnd)anEnd; // Moves anEnd.
- (float)length;
- (void)setLength:(float)aFloat ofEnd:(LNLineEnd)anEnd; // Moves anEnd.
- (NSPoint)locationOfEnd:(LNLineEnd)anEnd;
- (void)setLocation:(NSPoint)aPoint ofEnd:(LNLineEnd)anEnd;

- (BOOL)isEqualToLine:(LNLine *)line; // Compares start and end points. -isEqual: compares addresses.

- (void)getClosestPoint:(out NSPoint *)outPoint part:(out LNLinePart *)outPart toPoint:(NSPoint)aPoint;
- (float)distanceToPoint:(NSPoint)aPoint;
- (BOOL)getIntersection:(out NSPoint *)outPoint withLine:(LNLine *)line;

- (NSSet *)linesByDividingAtLine:(LNLine *)line;
- (NSSet *)linesByDividingLines:(NSSet *)lines;
- (NSSet *)linesByDividingAtLines:(NSSet *)lines;
- (void)extendToClosestLineInSet:(NSSet *)lines;

@end
