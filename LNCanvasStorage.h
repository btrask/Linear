#import <Cocoa/Cocoa.h>

// Inherits from
#import "LNDocumentObject.h"

// Models
@class LNGraphic;
@class LNLine;
@class LNShape;

// Other Sources
@class LNMutableArray;

extern NSString *const LNCanvasStorageDidChangeGraphicsNotification;
extern NSString *const LNCanvasStorageGraphicsAddedKey;
extern NSString *const LNCanvasStorageGraphicsRemovedKey;

extern NSString *const LNCanvasStorageGraphicWillChangeNotification;
extern NSString *const LNCanvasStorageGraphicDidChangeNotification;
extern NSString *const LNCanvasStorageGraphicKey;

@interface LNCanvasStorage : LNDocumentObject <NSCoding>
{
	@private
	LNMutableArray *_lines;
	LNMutableArray *_shapes;
}

- (NSMutableArray *)lines;
- (NSMutableArray *)shapes;

- (NSArray *)graphics;
- (void)addGraphics:(NSArray *)anArray;
- (void)removeGraphics:(NSSet *)aSet;

- (void)graphicWillChange:(NSNotification *)aNotif;
- (void)graphicDidChange:(NSNotification *)aNotif;

@end
