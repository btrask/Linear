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

@property(retain) LNCanvasStorage *canvasStorage;
@property(readonly) NSSet *selection;
@property(retain) LNGraphic *primarySelection;
@property(assign) LNCanvasTool tool;

- (void)getGraphic:(out id *)outGraphic linePart:(out LNLinePart *)outPart atPoint:(NSPoint)aPoint;
- (float)getDistanceToEnd:(out LNLineEnd *)outEnd ofLine:(out LNLine **)outLine closestToPoint:(NSPoint)aPoint excluding:(NSSet *)excludedSet;
- (BOOL)needsToDrawGraphic:(LNGraphic *)graphic selected:(BOOL)flag;

- (void)select:(NSSet *)aSet byExtendingSelection:(BOOL)flag;
- (void)deselect:(NSSet *)aSet;
- (void)invertSelect:(NSSet *)aSet; // Selects unselected and deselects selected objects in aSet.

- (void)moveSelectionBy:(NSSize)aSize;

- (void)storageDidChangeGraphics:(NSNotification *)aNotif;
- (void)storageGraphicWillChange:(NSNotification *)aNotif;
- (void)storageGraphicDidChange:(NSNotification *)aNotif;
- (void)graphicWillChange:(NSNotification *)aNotif;
- (void)graphicDidChange:(NSNotification *)aNotif;
- (void)windowWillChangeKey:(NSNotification *)aNotif;

@end
