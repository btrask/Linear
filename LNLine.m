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
#import "LNLine.h"

// Models
#import "LNCanvasStorage.h"

// Other Sources
#import "LNFoundationAdditions.h"

float LNRadiansToDegrees(float rad)
{
	return rad / pi * 180.0;
}
float LNDegreesToRadians(float deg)
{
	return deg / 180.0 * pi;
}
float LNPointAngle(NSPoint p1, NSPoint p2)
{
	return LNRadiansToDegrees(atan2f(p2.y - p1.y, p2.x - p1.x));
}
float LNPointDistance(NSPoint p1, NSPoint p2)
{
	return hypotf(p1.x - p2.x, p1.y - p2.y);
}

@interface LNLine (Private)

- (void)_setStart:(NSPoint)start end:(NSPoint)end;
- (NSArray *)_chainOfConnectingLines:(NSSet *)aSet endWith:(LNLine *)lastLine;

@end

@implementation LNLine

#pragma mark +LNLine

+ (id)line
{
	return [[[self alloc] init] autorelease];
}
+ (id)lineWithPoint:(NSPoint)aPoint
{
	return [[[self alloc] initWithStart:aPoint end:aPoint] autorelease];
}

#pragma mark -

+ (NSArray *)chainOfConnectingLines:(NSSet *)aSet
{
	LNLine *const line = [aSet anyObject];
	return [line _chainOfConnectingLines:aSet endWith:line];
}

#pragma mark -LNLine

- (id)initWithStart:(NSPoint)start end:(NSPoint)end
{
	if((self = [self init])) {
		_p1 = start;
		_p2 = end;
	}
	return self;
}
- (NSPoint)start
{
	return _p1;
}
- (void)setStart:(NSPoint)aPoint
{
	[self _setStart:aPoint end:_p2];
}
- (NSPoint)end
{
	return _p2;
}
- (void)setEnd:(NSPoint)aPoint
{
	[self _setStart:_p1 end:aPoint];
}

#pragma mark -

- (void)offsetBy:(NSSize)aSize
{
	[self _setStart:NSMakePoint(_p1.x + aSize.width, _p1.y + aSize.height) end:NSMakePoint(_p2.x + aSize.width, _p2.y + aSize.height)];
}

#pragma mark -

- (float)angle
{
	return LNPointAngle(_p1, _p2);
}
- (void)setAngle:(float)aFloat ofEnd:(LNLineEnd)anEnd
{
	float const l = [self length];
	if(LNEndEnd == anEnd) [self _setStart:_p1 end:NSMakePoint(_p1.x + cosf(LNDegreesToRadians(aFloat)) * l, _p1.y + sinf(LNDegreesToRadians(aFloat)) * l)];
	else [self _setStart:NSMakePoint(_p2.x + cosf(LNDegreesToRadians(aFloat)) * l, _p2.y + sinf(LNDegreesToRadians(aFloat)) * l) end:_p2];
}
- (float)length
{
	return LNPointDistance(_p1, _p2);
}
- (void)setLength:(float)aFloat ofEnd:(LNLineEnd)anEnd
{
	float const a = atan2f(_p2.y - _p1.y, _p2.x - _p1.x);
	if(LNEndEnd == anEnd) [self _setStart:_p1 end:NSMakePoint(_p1.x + cosf(a) * aFloat, _p1.y + sinf(a) * aFloat)];
	else [self _setStart:NSMakePoint(_p2.x + cosf(a + pi) * aFloat, _p2.y + sinf(a + pi) * aFloat) end:_p2];
}
- (NSPoint)locationOfEnd:(LNLineEnd)anEnd
{
	if(LNEndEnd == anEnd) return _p2;
	return _p1;
}
- (void)setLocation:(NSPoint)aPoint ofEnd:(LNLineEnd)anEnd
{
	if(LNEndEnd == anEnd) [self setEnd:aPoint];
	else [self setStart:aPoint];
}

#pragma mark -

- (BOOL)isEqualToLine:(LNLine *)line
{
	return NSEqualPoints([self start], [line start]) && NSEqualPoints([self end], [line end]);
}

#pragma mark -

- (void)getClosestPoint:(out NSPoint *)outPoint part:(out LNLinePart *)outPart toPoint:(NSPoint)aPoint
{
	float length = [self length];
	if(!length) {
		if(outPoint) *outPoint = _p1;
		if(outPart) *outPart = LNNoPart;
		return;
	}
	float const u = ((aPoint.x - _p1.x) * (_p2.x - _p1.x) + (aPoint.y - _p1.y) * (_p2.y - _p1.y)) / powf(length, 2);
	if(u < 0) {
		if(outPoint) *outPoint = _p1;
		if(outPart) *outPart = LNStartPart;
	} else if(u > 1) {
		if(outPoint) *outPoint = _p2;
		if(outPart) *outPart = LNEndPart;
	} else {
		if(outPoint) *outPoint = NSMakePoint(_p1.x + u * (_p2.x - _p1.x), _p1.y + u * (_p2.y - _p1.y));
		if(outPart) *outPart = LNBodyPart;
	}
}
- (float)distanceToPoint:(NSPoint)aPoint
{
	NSPoint closestPoint;
	[self getClosestPoint:&closestPoint part:NULL toPoint:aPoint];
	return LNPointDistance(closestPoint, aPoint);
}
- (BOOL)getIntersection:(out NSPoint *)outPoint withLine:(LNLine *)line
{
	NSPoint const op1 = [line start], op2 = [line end];
	float const numeA = ((op2.x - op1.x) * (_p1.y - op1.y)) - ((op2.y - op1.y) * (_p1.x - op1.x));
	float const numeB = ((_p2.x - _p1.x) * (_p1.y - op1.y)) - ((_p2.y - _p1.y) * (_p1.x - op1.x));
	float const denom = ((op2.y - op1.y) * (_p2.x - _p1.x)) - ((op2.x - op1.x) * (_p2.y - _p1.y));
	if(!denom) {
		if(numeA || numeB) return NO;
		if(outPoint) *outPoint = NSMakePoint(MAX(MIN(_p1.x, _p2.x), MIN(op1.x, op2.x)), MAX(MIN(_p1.y, _p2.y), MIN(op1.y, op2.y)));
		return YES;
	}
	float const uA = numeA / denom;
	float const uB = numeB / denom;
	if(outPoint) *outPoint = NSMakePoint(_p1.x + uA * (_p2.x - _p1.x), _p1.y + uA * (_p2.y - _p1.y));
	return uA > -0.001 && uA < 1.001 && uB > -0.001 && uB < 1.001;
}

#pragma mark -

- (NSSet *)linesByDividingAtLine:(LNLine *)line
{
	NSPoint intersection;
	if(![self getIntersection:&intersection withLine:line] || [line isEqualToLine:self]) return [NSSet setWithObject:self];
	NSMutableSet *const results = [NSMutableSet set];
	LNLine *const l1 = [[self copy] autorelease];
	[l1 setEnd:intersection];
	if([l1 length] > 0.01) [results addObject:l1];
	LNLine *const l2 = [[self copy] autorelease];
	[l2 setStart:intersection];
	if([l2 length] > 0.01) [results addObject:l2];
	return results;
}
- (NSSet *)linesByDividingLines:(NSSet *)lines
{
	NSMutableSet *const results = [NSMutableSet set];
	for(LNLine *const line in lines) if([line isKindOfClass:[LNLine class]]) [results unionSet:[line linesByDividingAtLine:self]];
	return results;
}
- (NSSet *)linesByDividingAtLines:(NSSet *)lines
{
	NSSet *results = [NSSet setWithObject:self];
	for(LNLine *const denom in lines) if([denom isKindOfClass:[LNLine class]]) results = [denom linesByDividingLines:results];
	return results;
}
- (void)extendToClosestLineInSet:(NSSet *)lines
{
	float dist = FLT_MAX;
	LNLineEnd direction;
	NSPoint closest;
	BOOL foundSomething = NO;
	for(LNLine *const line in lines) {
		NSPoint const op1 = [line start], op2 = [line end];
		float const numeA = ((op2.x - op1.x) * (_p1.y - op1.y)) - ((op2.y - op1.y) * (_p1.x - op1.x));
		float const numeB = ((_p2.x - _p1.x) * (_p1.y - op1.y)) - ((_p2.y - _p1.y) * (_p1.x - op1.x));
		float const denom = ((op2.y - op1.y) * (_p2.x - _p1.x)) - ((op2.x - op1.x) * (_p2.y - _p1.y));
		if(!denom) continue;
		float const uA = numeA / denom;
		float const uB = numeB / denom;
		if(uB < 0 || uB > 1) continue;
		NSPoint const intersection = NSMakePoint(_p1.x + uA * (_p2.x - _p1.x), _p1.y + uA * (_p2.y - _p1.y));
		float newDist;
		float newDirection;
		if(uA < -0.01) { // Insist on moving a little for it to count.
			newDist = LNPointDistance(intersection, _p1);
			newDirection = LNStartEnd;
		} else if(uA > 1.01) {
			newDist = LNPointDistance(intersection, _p2);
			newDirection = LNEndEnd;
		} else continue;
		if(newDist >= dist) continue;
		dist = newDist;
		direction = newDirection;
		closest = intersection;
		foundSomething = YES;
	}
	if(foundSomething) [self setLocation:closest ofEnd:direction];
}

#pragma mark -LNLine(Private)

- (void)_setStart:(NSPoint)start end:(NSPoint)end
{
	if(NSEqualPoints(start, _p1) && NSEqualPoints(end, _p2)) return;
	[self LN_postNotificationName:LNGraphicWillChangeNotification];
	_p1 = start;
	_p2 = end;
	[self LN_postNotificationName:LNGraphicDidChangeNotification];
}
- (NSArray *)_chainOfConnectingLines:(NSSet *)aSet
             endWith:(LNLine *)lastLine
{
	NSParameterAssert([aSet count]);
	NSMutableSet *const remainingLines = [[aSet mutableCopy] autorelease];
	[remainingLines removeObject:self];
	if(![remainingLines count]) return [self getIntersection:NULL withLine:lastLine] ? [NSArray arrayWithObject:self] : nil;
	for(LNLine *const line in remainingLines) {
		if(![self getIntersection:NULL withLine:line]) continue;
		NSArray *const chain = [line _chainOfConnectingLines:remainingLines endWith:lastLine];
		if(chain) return [chain arrayByAddingObject:self];
	}
	return nil;
}

#pragma mark -LNGraphic(LNGraphicSubclassResponsibility)

- (NSBezierPath *)bezierPath
{
	NSBezierPath *const path = [NSBezierPath bezierPath];
	[path moveToPoint:_p1];
	[path lineToPoint:_p2];
	return path;
}
- (NSRect)frame
{
	return NSMakeRect(MIN(_p1.x, _p2.x) - 0.5, MIN(_p1.y, _p2.y) - 0.5, MAX(_p1.x - _p2.x, _p2.x - _p1.x) + 0.5, MAX(_p1.y - _p2.y, _p2.y - _p1.y) + 0.5);
}
- (void)draw
{
	[[self color] set];
	[[self bezierPath] stroke];
}
- (BOOL)shouldFlattenHighlight
{
	return YES;
}
- (NSString *)displayString
{
	return [NSString stringWithFormat:NSLocalizedString(@"%.0f, %.0f to %.0f, %.0f", @"Line display string format (%.0f is replaced with the various X and Y coordinates)."), _p1.x, _p1.y, _p2.x, _p2.y];
}

#pragma mark -NSObject

- (id)init
{
	if((self = [super init])) {
		[self setColor:[NSColor blackColor]];
	}
	return self;
}

#pragma mark -

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p: %@ - %@>", [self class], self, NSStringFromPoint(_p1), NSStringFromPoint(_p2)];
}

#pragma mark -<NSCoding>

- (id)initWithCoder:(NSCoder *)aCoder
{
	if((self = [super initWithCoder:aCoder])) {
		[self _setStart:[aCoder decodePointForKey:@"P1"] end:[aCoder decodePointForKey:@"P2"]];
	}
	return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodePoint:_p1 forKey:@"P1"];
	[aCoder encodePoint:_p2 forKey:@"P2"];
}

#pragma mark -<NSCopying>

- (id)copyWithZone:(NSZone *)aZone
{
	id const dupe = [super copyWithZone:aZone];
	[dupe _setStart:_p1 end:_p2];
	return dupe;
}

@end
