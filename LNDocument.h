#import <Cocoa/Cocoa.h>

// Models
@class LNCanvasStorage;

// Controllers
@class LNWindowController;

// Notifications
extern NSString *const LNDocumentCanvasStorageDidChangeNotification;

@interface LNDocument : NSDocument
{
	@private
	LNCanvasStorage *_canvasStorage;
}

- (LNCanvasStorage *)canvasStorage;

@end
