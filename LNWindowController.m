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
#import "LNWindowController.h"

// Models
#import "LNDocument.h"
#import "LNCanvasStorage.h"
#import "LNLine.h"
#import "LNShape.h"

// Other Sources
#import "LNFoundationAdditions.h"

@implementation LNWindowController

#pragma mark -LNWindowController

- (IBAction)changeTool:(id)sender
{
	if(sender == toolsControl) return [canvas setTool:[[toolsControl cell] tagForSegment:[toolsControl selectedSegment]]];
	[canvas setTool:[sender tag]];
	[toolsControl setSelectedSegment:[sender tag]];
}
- (IBAction)delete:(id)sender
{
	[[canvas canvasStorage] removeGraphics:[canvas selection]];
}

#pragma mark -

- (void)documentCanvasStorageDidChange:(NSNotification *)aNotif
{
	LNCanvasStorage *const old = [canvas canvasStorage], *new = [[self document] canvasStorage];
	[old LN_removeObserver:self name:LNCanvasStorageDidChangeGraphicsNotification];
	[old LN_removeObserver:self name:LNCanvasStorageGraphicDidChangeNotification];
	[canvas setCanvasStorage:new];
	[new LN_addObserver:self selector:@selector(storageDidChangeGraphics:) name:LNCanvasStorageDidChangeGraphicsNotification];
	[new LN_addObserver:self selector:@selector(storageGraphicDidChange:) name:LNCanvasStorageGraphicDidChangeNotification];
	[self storageDidChangeGraphics:nil];
}
- (void)storageDidChangeGraphics:(NSNotification *)aNotif
{
	[graphicsOutline reloadData];
}
- (void)storageGraphicDidChange:(NSNotification *)aNotif
{
	[graphicsOutline reloadItem:[[aNotif userInfo] objectForKey:LNCanvasStorageGraphicKey]];
}
- (void)canvasSelectionDidChange:(NSNotification *)aNotif
{
	NSMutableIndexSet *const indexes = [NSMutableIndexSet indexSet];
	id graphic;
	NSEnumerator *const selectedGraphicEnum = [[canvas selection] objectEnumerator];
	while((graphic = [selectedGraphicEnum nextObject])) {
		int const i = [graphicsOutline rowForItem:graphic];
		if(i >= 0) [indexes addIndex:i];
	}
	[graphicsOutline selectRowIndexes:indexes byExtendingSelection:NO];
	if([indexes count]) [graphicsOutline scrollRectToVisible:[graphicsOutline frameOfCellAtColumn:0 row:[indexes lastIndex]]];
}

#pragma mark -NSWindowController

- (void)windowDidLoad
{
	[super windowDidLoad];
	NSToolbar *const toolbar = [[[NSToolbar alloc] initWithIdentifier:@"LNDocumentWindowToolbar"] autorelease];
	[toolbar setSizeMode:NSToolbarSizeModeRegular];
	[toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
	[toolbar setAllowsUserCustomization:NO];
	[toolbar setDelegate:self];
	[[self window] setToolbar:toolbar];
	[[self window] setShowsToolbarButton:NO];
	[graphicsOutline expandItem:[LNLine class]];
	[graphicsOutline expandItem:[LNShape class]];
	[canvas setFrameSize:NSMakeSize(501, 501)];
	[canvas setCanvasStorage:[[self document] canvasStorage]];
	[canvas LN_addObserver:self selector:@selector(canvasSelectionDidChange:) name:LNCanvasViewSelectionDidChangeNotification];
}
- (void)setDocument:(id)aDocument
{
	[[self document] LN_removeObserver:self name:LNDocumentCanvasStorageDidChangeNotification];
	[super setDocument:aDocument];
	[[self document] LN_addObserver:self selector:@selector(documentCanvasStorageDidChange:) name:LNDocumentCanvasStorageDidChangeNotification];
	[self documentCanvasStorageDidChange:nil];
}

#pragma mark -NSResponder

- (void)flagsChanged:(NSEvent *)anEvent
{
	if([anEvent modifierFlags] & NSAlternateKeyMask) {
		if(_optionKeyDown) return;
		_optionKeyDown = YES;
		_primaryTool = [canvas tool];
		[canvas setTool:LNSelectTool];
	} else if(_optionKeyDown) {
		_optionKeyDown = NO;
		[canvas setTool:_primaryTool];
	}
	[toolsControl setSelectedSegment:[canvas tool]];
}

#pragma mark -NSObject

- (id)init
{
	return [super initWithWindowNibName:@"LNDocument"];
}

#pragma mark -NSObject(NSMenuValidation)

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	SEL const action = [anItem action];
	if(@selector(changeTool:) == action) {
		[anItem setState:([anItem tag] == [canvas tool] ? NSOnState : NSOffState)];
		return YES;
	}
	if(![[canvas selection] count]) {
		if(@selector(delete:) == action) return NO;
	}
	return [self respondsToSelector:action];
}

#pragma mark -NSObject(NSOutlineViewNotifications)

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSMutableSet *const selection = [NSMutableSet set];
	NSIndexSet *const indexes = [graphicsOutline selectedRowIndexes];
	unsigned i = [indexes firstIndex];
	for(; i != NSNotFound; i = [indexes indexGreaterThanIndex:i]) {
		id const item = [graphicsOutline itemAtRow:i];
		if([self outlineView:graphicsOutline shouldSelectItem:item]) [selection addObject:item];
	}
	[canvas select:selection byExtendingSelection:NO];
}

#pragma mark -<NSOutlineViewDataSource>

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	if(!item) {
		if(index == 0) return [LNLine class];
		else return [LNShape class];
	}
	if([LNLine class] == item) {
		NSArray *const lines = [[[self document] canvasStorage] lines];
		return [lines objectAtIndex:[lines count] - 1 - index];
	} else if([LNShape class] == item) {
		NSArray *const shapes = [[[self document] canvasStorage] shapes];
		return [shapes objectAtIndex:[shapes count] - 1 - index];
	}
	return nil;
}
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return [item class] == item;
}
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if(!item) return 2;
	if([LNLine class] == item) return [[[[self document] canvasStorage] lines] count];
	if([LNShape class] == item) return [[[[self document] canvasStorage] shapes] count];
	return 0;
}
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if([LNLine class] == item) return NSLocalizedString(@"LINES", @"Outline header for lines group.");
	if([LNShape class] == item) return NSLocalizedString(@"SHAPES", @"Outline header for shapes group.");
	return [item displayString];
}

#pragma mark -<NSOutlineViewDelegate>

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return [LNLine class] != item && [LNShape class] != item;
}

#pragma mark -<NSToolbarDelegate>

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *const item = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
	[item setPaletteLabel:NSLocalizedString(@"Tools", @"Tools toolbar item label.")];
	[item setView:toolsControl];
	return item;
}
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObject:@"LNToolsControlItem"];
}
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return [self toolbarDefaultItemIdentifiers:toolbar];
}

#pragma mark -<NSWindowDelegate>

- (void)windowDidResignKey:(NSNotification *)notification
{
	if(!_optionKeyDown) return;
	_optionKeyDown = NO;
	[canvas setTool:_primaryTool];
	[toolsControl setSelectedSegment:[canvas tool]];
}

@end
