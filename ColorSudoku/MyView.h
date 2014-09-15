#import <Cocoa/Cocoa.h>
#import "DataSource.h"

@interface MyView : NSView
{
    DataSource *ds;
}

@property int currentPuzzleID;

- (void)makeRects;
- (void)makeColors;
- (void)drawSmallRects;
- (void)drawLines;

- (void)editData:(int)i
        forPoint:(NSPoint)p
            rect:(NSRect)r
             opt:(BOOL)cmd;

- (IBAction)cleanRows:(id) sender;
- (IBAction)cleanCols:(id) sender;
- (IBAction)cleanBoxes:(id) sender;
- (IBAction)cleanAll:(id) sender;
- (void)resetUndoStacks;

@end
