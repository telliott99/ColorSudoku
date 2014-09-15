#import "MyView.h"

@implementation MyView
@synthesize currentPuzzleID;

NSPoint o;
int n;
double side_len;
double inset;

NSRect rect_array [81];        // inset rects
NSRect frame_rect_array [81];  // larger rects
NSColor *color_array [10];

NSMutableArray *ma;            // used repeatedly

// two arrays run in parallel, used for undo
NSMutableArray *squareList;  // holds the old value for a square
NSMutableArray *indexList;   // holds the index where it was

// for breakpoints
NSMutableArray *breakpointList;

- (void)awakeFromNib{
    ds = [[DataSource alloc] init];
    [ds loadBundleData];
    NSLog(@"awake, data source: %@", [ds description]);
    
    // values for UI squares, hard coded
    o = NSMakePoint(20.0,20.0);
    n = 9;
    side_len = 34.0;
    inset = 4.0;
    
    [self makeRects];
    [self makeColors];
    
    // for undo
    squareList = [[NSMutableArray alloc] init];
    indexList = [[NSMutableArray alloc] init];
    breakpointList = [[NSMutableArray alloc] init];
}

- (BOOL)acceptsFirstResponder{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [[NSColor whiteColor] set];
    NSRectFill([self bounds]);
    NSLog(@"drawRect self.ds %p", ds);
    
    NSColor *ca[81];
    for (int i = 0; i < 81; i++) {
        NSArray *data = [[ds getDataArray]objectAtIndex:i];
        if (data.count == 1) {
            int n = [[data objectAtIndex:0] intValue];
            NSColor *c = color_array[n];
            ca[i] = c;
        }
        else {
            // we will draw the small squares later
            ca[i] = [NSColor whiteColor];
        }
    }
    // draw them all at once, supposed to be efficient
    NSRectFillListWithColors(rect_array, ca, 81);
    [self drawSmallRects];
    [self drawLines];
}

- (void)drawLines {
    double start = o.x;
    double one_third = start + 3*side_len;
    double two_thirds = one_third + 3*side_len;
    double finish = two_thirds + 3*side_len;
    
    // do the gray lines by stroking the frame rects
    [NSBezierPath setDefaultLineWidth:0.5];
    [[NSColor lightGrayColor] set];
    for (int i = 0; i < 81; i++) {
        NSRect r = frame_rect_array[i];
        [NSBezierPath strokeRect:r];
    }
    
    // do the blue lines
    [NSBezierPath setDefaultLineWidth:1.5];
    [[NSColor blueColor] set];
    NSBezierPath *p = [NSBezierPath bezierPath];
    
    double pts[4] = {start,one_third,two_thirds,finish};
    double coord;
    for (int i = 0; i < 4; i++) {
        coord = pts[i];
        [p moveToPoint:NSMakePoint(coord,start)];
        [p lineToPoint:NSMakePoint(coord,finish)];
        [p stroke];
        [p moveToPoint:NSMakePoint(start,coord)];
        [p lineToPoint:NSMakePoint(finish,coord)];
        [p stroke];
    }
}
    
    /*
    [p moveToPoint:NSMakePoint(start,start)];
    [p lineToPoint:NSMakePoint(all,start)];
    [p stroke];
    [p moveToPoint:NSMakePoint(start,one_third)];
    [p lineToPoint:NSMakePoint(all,one_third)];
    [p stroke];
    [p moveToPoint:NSMakePoint(start,two_thirds)];
    [p lineToPoint:NSMakePoint(all,two_thirds)];
    [p stroke];
    [p moveToPoint:NSMakePoint(start,all)];
    [p lineToPoint:NSMakePoint(all,all)];
    [p stroke];
    [p moveToPoint:NSMakePoint(start,start)];
    [p lineToPoint:NSMakePoint(start,all)];
    [p stroke];
    [p moveToPoint:NSMakePoint(one_third,start)];
    [p lineToPoint:NSMakePoint(one_third,all)];
    [p stroke];
    [p moveToPoint:NSMakePoint(two_thirds,start)];
    [p lineToPoint:NSMakePoint(two_thirds,all)];
    [p stroke];
    [p moveToPoint:NSMakePoint(all,start)];
    [p lineToPoint:NSMakePoint(all,all)];
    [p stroke];
     */


// doesn't need sorted data
- (void)drawSmallRects{
    NSArray *ds_data = [ds getDataArray];
    for (int i = 0; i < 81; i++) {
        NSArray *data = [ds_data objectAtIndex:i];
        if (data.count > 1) {
            NSRect rect = rect_array[i];
            double sq_side = (side_len - 2*inset)/3;
            for (NSNumber *n in data) {
                int j = [n intValue];
                double x = rect.origin.x + sq_side*((j-1)%3);
                double y = rect.origin.y + sq_side*((j-1)/3);
                NSRect r = NSMakeRect(x,y,sq_side,sq_side);
                NSColor *c = color_array[j];
                [c set];
                NSRectFill(r);
            }
        }
    }
}

- (void)makeRects{
    NSRect r;
    for (int i = 0; i < 81; i++) {
        int row = i % 9;
        int col = i / 9;
        double row_d = (double)row;
        double col_d = (double)col;
        r = NSMakeRect(side_len*row_d + o.x,
                       side_len*col_d + o.y,
                       side_len,
                       side_len );
        //rect_array[i] = r;
        frame_rect_array[i] = r;
        rect_array[i] = NSInsetRect(r, inset, inset);
    }
}

- (void)makeColors{
    color_array[0] = [NSColor whiteColor];
    color_array[1] = [NSColor blackColor];
    color_array[2] = [NSColor magentaColor];
    color_array[3] = [NSColor greenColor];
    color_array[4] = [NSColor cyanColor];
    color_array[5] = [NSColor orangeColor];
    color_array[6] = [NSColor purpleColor];
    color_array[7] = [NSColor redColor];
    color_array[8] = [NSColor blueColor];
    color_array[9] = [NSColor yellowColor];
}

- (void)mouseDown:(NSEvent *) e{
    NSLog(@"flags:  %lu", [e modifierFlags]);
    NSUInteger mask = NSDeviceIndependentModifierFlagsMask;
    NSUInteger flags = [e modifierFlags] & mask;
    BOOL cmd = flags == NSCommandKeyMask;
    
    NSPoint p = [self convertPoint:[e locationInWindow]
                          fromView: nil];
    NSRect r;
    int i;
    for (i = 0; i < 81; i++) {
        r = rect_array[i];
        if (NSPointInRect(p,r)) {
            break;
        }
        // did not find it
        if (i == 80) { return; }
    }
    [self editData:i
          forPoint:p
              rect:r
               opt:cmd];
}

// already determined that p is inside r at index i
- (void)editData:(int)i
        forPoint:(NSPoint)p
            rect:(NSRect)r
             opt:(BOOL)cmd {
    
    NSLog(@"editData self.ds %p", ds);
    ma = [ds getDataArray];
    NSMutableArray *old_square = [ma objectAtIndex:i];
    
    // make a copy of the data we are about to edit
    NSMutableArray *sq =
        [NSMutableArray arrayWithArray:old_square];
    
    // only edit squares that have not made single choice
    if (sq.count > 1) {
        
        // find out which small square was clicked
        double dx = p.x - r.origin.x;
        double dy = p.y - r.origin.y;
        double u = (side_len - 2*inset)/3;
        int row = floor(dx/u);
        int col = floor(dy/u);
        
        // convert index of small square to an integer (1-based)
        NSNumber *n = [NSNumber numberWithInt:col*3 + row + 1];
        
        // so we clicked on a small square
        // case 1:  it is active (present in data)
        if ([sq containsObject:n]) {
            // CMD-click chooses that as the determined value
            if (cmd) {
                sq = [NSMutableArray arrayWithArray:@[n]];
            }
            // otherwise clicking just removes that small square
            else {
                [sq removeObject:n];
            }
            // check whether proposed move is coherent
            // if not, bail
            if (!([ds isLegalMoveForIndex:i editedSquare:sq])) {
                return;
            }
        }
        
        // else, the value we "clicked" on is not in data
        // clicked on a blank spot in the array of small squares
        // so add it
        else {
            [sq addObject:n];
        }
        
        // save the move to the undo arrays
        [squareList addObject:old_square];
        [indexList addObject:[NSNumber numberWithInt:i]];
        
        // save the modified square in the data
        // bad! but works.  propagates to the data source's _data_array
        [ma replaceObjectAtIndex:i withObject:sq];
    }
    [self setNeedsDisplay:YES];
}

// works, but doesn't draw right away
// haven't figured out why

- (IBAction)undo:(id) sender {
    NSLog(@"undo");
    int k = (int)squareList.count;
    if (k == 0) { return; }
    assert (k == indexList.count);
    
    NSMutableArray *old_square = [squareList objectAtIndex:k];
    [squareList removeLastObject];
    NSNumber *n = [indexList objectAtIndex:k];
    [indexList removeLastObject];
    
    ma = [ds getDataArray];
    int i = (int)[n intValue];
    // i is index of square we previously changed
    [ma replaceObjectAtIndex:i withObject:old_square];
    
    // does not have desired effect
    [self setNeedsDisplay:YES];
    return;
}

// buttons in the UI for cleaning up data
// cleaning resets undo stacks

- (IBAction)cleanRows:(id) sender {
    [ds cleanRows];
    // does not have desired effect
    [self setNeedsDisplay:YES];
}
- (IBAction)cleanCols:(id) sender {
    [ds cleanCols];
    // does not have desired effect
    [self setNeedsDisplay:YES];
}
- (IBAction)cleanBoxes:(id) sender {
    [ds cleanBoxes];
    // does not have desired effect
    [self setNeedsDisplay:YES];
}

- (void)resetUndoStacks{
    [squareList removeAllObjects];
    [indexList removeAllObjects];
}

- (IBAction)cleanAll:(id) sender {
    [ds cleanRows];
    [ds cleanCols];
    [ds cleanBoxes];
    // does not have desired effect
    [self setNeedsDisplay:YES];
}

- (IBAction)newPuzzle:(id) sender {
    ma = [ds getPuzzleArray];
    int n = (int)[ma count];
    int i = (int)arc4random_uniform(n);
    [ds loadPuzzleAtIndex:i];
    [self setNeedsDisplay:YES];
}

- (IBAction)reloadPuzzle:(id) sender {
    [ds loadPuzzleAtIndex:[ds getPuzzleIndex]];
    [self resetUndoStacks];
}

// restoreBreakpoint doesn't work
// data looks different

/*
- (IBAction)setBreakpoint:(id) sender {
    ma = [ds getDataArray];
    [breakpointList addObject:ma];
}

- (IBAction)restoreBreakpoint:(id) sender {
    int i = (int)breakpointList.count;
    if (i == 0) { return; }
    i -= 1;
    ma = [breakpointList objectAtIndex:i];
    NSLog(@"restore, before:  %@", [[ds getDataArray] description]);
    [ds setDataArray:ma];
    [breakpointList removeObjectAtIndex:i];
    [self setNeedsDisplay:YES];
    NSLog(@"restore, after :  %@", [[ds getDataArray] description]);
}
*/
@end
