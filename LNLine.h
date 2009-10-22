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
