#import <Cocoa/Cocoa.h>

// Inherits from
#import "LNDocumentObject.h"

// Models
@class LNGraphic;
@class LNLine;
@class LNShape;

extern NSString *const LNCanvasStorageDidChangeGraphicsNotification;
extern NSString *const LNCanvasStorageGraphicsAddedKey;
extern NSString *const LNCanvasStorageGraphicsRemovedKey;

extern NSString *const LNCanvasStorageGraphicWillChangeNotification;
extern NSString *const LNCanvasStorageGraphicDidChangeNotification;
extern NSString *const LNCanvasStorageGraphicKey;

@interface LNCanvasStorage : LNDocumentObject <NSCoding>
{
	@private
	NSMutableArray *_lines;
	NSMutableArray *_shapes;
}

- (NSArray *)lines;
- (NSArray *)shapes;

- (NSArray *)graphics;
- (void)addGraphics:(id)collection;
- (void)removeGraphics:(NSSet *)aSet;

- (void)graphicWillChange:(NSNotification *)aNotif;
- (void)graphicDidChange:(NSNotification *)aNotif;

@end
