#import <Cocoa/Cocoa.h>

// Models
@class LNDocument;

@interface LNDocumentObject : NSObject
{
	@private
	LNDocument *_document;
}

- (LNDocument *)document;
- (void)setDocument:(LNDocument *)aDoc;

- (NSUndoManager *)LN_undoManager;
- (id)LN_undo;

@end
