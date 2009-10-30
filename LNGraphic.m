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
#import "LNGraphic.h"

// Other Sources
#import "LNFoundationAdditions.h"

NSString *const LNGraphicWillChangeNotification = @"LNGraphicWillChange";
NSString *const LNGraphicDidChangeNotification  = @"LNGraphicDidChange";

@implementation LNGraphic

#pragma mark +LNGraphic

+ (NSBezierPath *)highlightStyleBezierPath:(NSBezierPath *)path
{
	NSBezierPath *const highlightPath = path ? path : [NSBezierPath bezierPath];
	[highlightPath setLineWidth:9];
	[highlightPath setLineCapStyle:NSRoundLineCapStyle];
	[highlightPath setLineJoinStyle:NSRoundLineJoinStyle];
	return highlightPath;
}

#pragma mark -LNGraphic

- (NSColor *)color
{
	return [[_color retain] autorelease];
}
- (void)setColor:(NSColor *)aColor
{
	if(aColor == _color || [aColor isEqual:_color]) return;
	[self LN_postNotificationName:LNGraphicWillChangeNotification];
	[_color release];
	_color = [aColor copy];
	[self LN_postNotificationName:LNGraphicDidChangeNotification];
}

#pragma mark -NSObject

- (void)dealloc
{
	[_color release];
	[super dealloc];
}

#pragma mark -<NSCoding>

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

#pragma mark -<NSCopying>

- (id)copyWithZone:(NSZone *)aZone
{
	id const dupe = [[[self class] allocWithZone:aZone] init];
	[dupe setColor:[self color]];
	return dupe;
}

@end
