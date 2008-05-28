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
	[_canvasStorage setDocument:self];
	[self AE_postNotificationName:LNDocumentCanvasStorageDidChangeNotification];
	return _canvasStorage != nil;
}

#pragma mark NSObject

- (id)init
{
	if((self = [super init])) {
		_canvasStorage = [[LNCanvasStorage alloc] init];
		[_canvasStorage setDocument:self];
	}
	return self;
}
- (void)dealloc
{
	[_canvasStorage release];
	[super dealloc];
}

@end
