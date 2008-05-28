#import <Cocoa/Cocoa.h>

// Models
@class LNCanvasStorage;
@class LNGraphic;
#import "LNLine.h"
@class LNShape;

enum {
	LNLineTool   = 0,
	LNSelectTool = 1,
	LNExtendTool = 2,
	LNRotateTool = 3
};
typedef int LNCanvasTool;

extern NSString *const LNCanvasViewSelectionDidChangeNotification;

@interface LNCanvasView : NSView
{
	@private
	LNCanvasStorage *_canvasStorage;
	NSMutableSet    *_selection;
	id               _primarySelection;
	LNCanvasTool     _tool;
	LNLine          *_selectionLine;
}

/*- (IBAction)copy:(id)sender;
- (IBAction)paste:(id)sender;*/
- (IBAction)selectAll:(id)sender;
- (IBAction)deselectAll:(id)sender;

- (IBAction)dividePrimary:(id)sender;
- (IBAction)divideByPrimary:(id)sender;
- (IBAction)extend:(id)sender;
- (IBAction)makeShapeWithSelection:(id)sender;

- (IBAction)orderFrontColorPanel:(id)sender;

- (LNCanvasStorage *)canvasStorage;
- (void)setCanvasStorage:(LNCanvasStorage *)storage;

- (void)getGraphic:(out id *)outGraphic linePart:(out LNLinePart *)outPart atPoint:(NSPoint)aPoint;
- (float)getDistanceToEnd:(out LNLineEnd *)outEnd ofLine:(out LNLine **)outLine closestToPoint:(NSPoint)aPoint excluding:(NSSet *)excludedSet;
- (BOOL)needsToDrawGraphic:(LNGraphic *)graphic selected:(BOOL)flag;

- (NSSet *)selection;
- (void)select:(NSSet *)aSet byExtendingSelection:(BOOL)flag;
- (void)deselect:(NSSet *)aSet;
- (void)invertSelect:(NSSet *)aSet; // Selects unselected and deselects selected objects in aSet.
- (id)primarySelection;
- (void)setPrimarySelection:(id)aGraphic;

- (void)moveSelectionBy:(NSSize)aSize;

- (LNCanvasTool)tool;
- (void)setTool:(LNCanvasTool)tool;

- (void)storageDidChangeGraphics:(NSNotification *)aNotif;
- (void)storageGraphicWillChange:(NSNotification *)aNotif;
- (void)storageGraphicDidChange:(NSNotification *)aNotif;
- (void)graphicWillChange:(NSNotification *)aNotif;
- (void)graphicDidChange:(NSNotification *)aNotif;
- (void)windowWillChangeKey:(NSNotification *)aNotif;

@end
