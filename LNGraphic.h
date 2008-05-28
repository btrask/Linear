#import <Cocoa/Cocoa.h>

// Inherits from
#import "LNDocumentObject.h"

extern NSString *const LNGraphicWillChangeNotification;
extern NSString *const LNGraphicDidChangeNotification;

@interface LNGraphic : LNDocumentObject <NSCoding, NSCopying>
{
	@private
	NSColor *_color;
}

+ (NSBezierPath *)highlightStyleBezierPath:(NSBezierPath *)path;

- (NSColor *)color;
- (void)setColor:(NSColor *)aColor;

@end

@interface LNGraphic (LNGraphicSubclassResponsibility)

- (NSBezierPath *)bezierPath;
- (NSRect)frame;
- (void)draw;
- (BOOL)shouldFlattenHighlight;
- (NSString *)displayString;

@end
