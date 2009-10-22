#import <Cocoa/Cocoa.h>

// Models
@class LNDocument;
@class LNCanvasStorage;
@class LNLine;
@class LNShape;

// Views
#import "LNCanvasView.h"

@interface LNWindowController : NSWindowController <NSToolbarDelegate>
{
	@private
	IBOutlet NSSegmentedControl *toolsControl;
	IBOutlet NSOutlineView      *graphicsOutline;
	IBOutlet LNCanvasView       *canvas;
	         BOOL                _optionKeyDown;
		 LNCanvasTool        _primaryTool;
}

- (IBAction)changeTool:(id)sender; // LNCanvasTool from [sender tag].
- (IBAction)delete:(id)sender;

- (void)documentCanvasStorageDidChange:(NSNotification *)aNotif;
- (void)storageDidChangeGraphics:(NSNotification *)aNotif;

@end
