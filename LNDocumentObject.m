#import "LNDocumentObject.h"

// Models
#import "LNDocument.h"

@implementation LNDocumentObject

#pragma mark Instance Methods

- (LNDocument *)document
{
	return _document;
}
- (void)setDocument:(LNDocument *)aDoc
{
	if(aDoc == _document) return;
	NSParameterAssert(!_document || !aDoc);
	_document = aDoc;
}

#pragma mark -

- (NSUndoManager *)LN_undoManager
{
	return [[self document] undoManager];
}
- (id)LN_undo
{
	return [[self LN_undoManager] prepareWithInvocationTarget:self];
}

@end
