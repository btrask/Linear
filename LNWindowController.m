#import "LNWindowController.h"

// Models
#import "LNDocument.h"
#import "LNCanvasStorage.h"
#import "LNLine.h"
#import "LNShape.h"

// Categories
#import "NSObjectAdditions.h"

@implementation LNWindowController

#pragma mark Instance Methods

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
	[old AE_removeObserver:self name:LNCanvasStorageDidChangeGraphicsNotification];
	[old AE_removeObserver:self name:LNCanvasStorageGraphicDidChangeNotification];
	[canvas setCanvasStorage:new];
	[new AE_addObserver:self selector:@selector(storageDidChangeGraphics:) name:LNCanvasStorageDidChangeGraphicsNotification];
	[new AE_addObserver:self selector:@selector(storageGraphicDidChange:) name:LNCanvasStorageGraphicDidChangeNotification];
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

#pragma mark NSMenuValidation Protocol

- (BOOL)validateMenuItem:(id<NSMenuItem>)anItem
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

#pragma mark NSToolbarDelegate Protocol

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
                   itemForItemIdentifier:(NSString *)itemIdentifier
		   willBeInsertedIntoToolbar:(BOOL)flag
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

#pragma mark NSOutlineViewDataSource Protocol

- (id)outlineView:(NSOutlineView *)outlineView
      child:(int)index
      ofItem:(id)item
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
- (BOOL)outlineView:(NSOutlineView *)outlineView
        isItemExpandable:(id)item
{
	return [item class] == item;
}
- (int)outlineView:(NSOutlineView *)outlineView
       numberOfChildrenOfItem:(id)item
{
	if(!item) return 2;
	if([LNLine class] == item) return [[[[self document] canvasStorage] lines] count];
	if([LNShape class] == item) return [[[[self document] canvasStorage] shapes] count];
	return 0;
}
- (id)outlineView:(NSOutlineView *)outlineView
      objectValueForTableColumn:(NSTableColumn *)tableColumn
      byItem:(id)item
{
	if([LNLine class] == item) return NSLocalizedString(@"LINES", @"Outline header for lines group.");
	if([LNShape class] == item) return NSLocalizedString(@"SHAPES", @"Outline header for shapes group.");
	return [item displayString];
}

#pragma mark NSOutlineViewDelegate Protocol

- (BOOL)outlineView:(NSOutlineView *)outlineView
        shouldSelectItem:(id)item
{
	return [LNLine class] != item && [LNShape class] != item;
}

#pragma mark NSOutlineViewNotifications Protocol

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSMutableSet *const selection = [NSMutableSet set];
	NSIndexSet *const indexes = [graphicsOutline selectedRowIndexes];
	unsigned i = [indexes firstIndex];
	for(; i != NSNotFound; i = [indexes indexGreaterThanIndex:i]) [selection addObject:[graphicsOutline itemAtRow:i]];
	[canvas select:selection byExtendingSelection:NO];
}

#pragma mark NSWindowNotifications Protocol

- (void)windowDidResignKey:(NSNotification *)notification
{
	if(!_optionKeyDown) return;
	_optionKeyDown = NO;
	[canvas setTool:_primaryTool];
	[toolsControl setSelectedSegment:[canvas tool]];
}

#pragma mark NSWindowController

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
	[canvas AE_addObserver:self selector:@selector(canvasSelectionDidChange:) name:LNCanvasViewSelectionDidChangeNotification];
}
- (void)setDocument:(id)aDocument
{
	[[self document] AE_removeObserver:self name:LNDocumentCanvasStorageDidChangeNotification];
	[super setDocument:aDocument];
	[[self document] AE_addObserver:self selector:@selector(documentCanvasStorageDidChange:) name:LNDocumentCanvasStorageDidChangeNotification];
	[self documentCanvasStorageDidChange:nil];
}

#pragma mark NSResponder

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

#pragma mark NSObject

- (id)init
{
	return [super initWithWindowNibName:@"LNDocument"];
}

@end
