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
#import "LNDocument.h"

// Models
#import "LNCanvasStorage.h"

// Controllers
#import "LNWindowController.h"

// Categories
#import "NSObjectAdditions.h"

// Notifications
NSString *const LNDocumentCanvasStorageDidChangeNotification = @"LNDocumentCanvasStorageDidChange";

@implementation LNDocument

#pragma mark Instance Methods

- (LNCanvasStorage *)canvasStorage
{
	return [[_canvasStorage retain] autorelease];
}

#pragma mark NSDocument

- (void)makeWindowControllers
{
	[self addWindowController:[[[LNWindowController alloc] init] autorelease]];
}

#pragma mark -

- (NSData *)dataRepresentationOfType:(NSString *)type
{
	return [NSKeyedArchiver archivedDataWithRootObject:_canvasStorage];
}
- (BOOL)loadDataRepresentation:(NSData *)data
        ofType:(NSString *)type
{
	[_canvasStorage release];
	_canvasStorage = [[NSKeyedUnarchiver unarchiveObjectWithData:data] retain];
	[self AE_postNotificationName:LNDocumentCanvasStorageDidChangeNotification];
	return _canvasStorage != nil;
}

#pragma mark NSObject

- (id)init
{
	if((self = [super init])) {
		_canvasStorage = [[LNCanvasStorage alloc] init];
	}
	return self;
}
- (void)dealloc
{
	[_canvasStorage release];
	[super dealloc];
}

@end
