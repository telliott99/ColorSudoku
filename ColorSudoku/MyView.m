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
NSMutableArray *ma;

// two arrays run in parallel, used for undo
NSMutableArray *squareList;  // holds the old value for a square
NSMutableArray *indexList;   // holds the index where it was

- (void)awakeFromNib{
    ds = [[DataSource alloc] init];
    [ds loadBundleData];
    NSLog(@"awake, data source: %@", [ds description]);
    o = NSMakePoint(20.0,20.0);
    n = 9;
    side_len = 34.0;
    inset = 4.0;
    [self makeRects];
    [self makeColors];
    squareList = [[NSMutableArray alloc] init];
    indexList = [[NSMutableArray alloc] init];
}

- (BOOL)acceptsFirstResponder{
    return YES;
}

- (void)viewWillDraw {
    NSLog(@"will draw");
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [[NSColor whiteColor] set];
    NSRectFill([self bounds]);
    NSLog(@"drawRect self.ds %p", ds);
    
    NSColor *ca[81];
    for (int i = 0; i < 81; i++) {
        NSArray *data = [[ds getData]objectAtIndex:i];
        if (data.count == 1) {
            int n = [[data objectAtIndex:0] intValue];
            NSColor *c = color_array[n];
            ca[i] = c;
        }
        else {
            ca[i] = [NSColor whiteColor];
        }
    }
    NSRectFillListWithColors(rect_array, ca, 81);
    [self drawSmallRects];
    [self drawLines];
}

- (void)drawLines {
    double start = o.x;
    double one_third = start + 3*side_len;
    double two_thirds = one_third + 3*side_len;
    double all = two_thirds + 3*side_len;
    [[NSColor lightGrayColor] set];
    for (int i = 0; i < 81; i++) {
        NSRect r = frame_rect_array[i];
        [NSBezierPath strokeRect:r];
    }
    
    [NSBezierPath setDefaultLineWidth:2.0];
    [[NSColor blueColor] set];
    NSBezierPath *p = [NSBezierPath bezierPath];
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
}

// doesn't need sorted data
- (void)drawSmallRects{
    NSArray *ds_data = [ds getData];
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
    
    NSPoint p = [self convertPoint:[e locationInWindow] fromView: nil];
    NSRect r;
    int i;
    for (i = 0; i < 81; i++) {
        r = rect_array[i];
        if (NSPointInRect(p,r)) {
            break;
        }
        if (i == 80) { return; }
    }
    [self editData:i forPoint:p rect:r opt:cmd];
}

// already determined that p is inside r
- (void)editData:(int)i forPoint:(NSPoint)p rect:(NSRect)r opt:(BOOL)cmd {
    NSLog(@"editData self.ds %p", ds);
    ma = [ds getData];
    NSMutableArray *old_square = [ma objectAtIndex:i];
    NSMutableArray *sq = [NSMutableArray arrayWithArray:old_square];
    if (sq.count > 1) {
        // find which small square was clicked
        double dx = p.x - r.origin.x;
        double dy = p.y - r.origin.y;
        double u = (side_len - 2*inset)/3;
        int row = floor(dx/u);
        int col = floor(dy/u);
        NSNumber *n = [NSNumber numberWithInt:col*3 + row + 1];
        // clicked on a small square
        if ([sq containsObject:n]) {
            if (cmd) {
                sq = [NSMutableArray arrayWithArray:@[n]];
            }
            else {
                [sq removeObject:n];
            }
        }
        // clicked on white space where a square used to be
        else {
            [sq addObject:n];
        }
        [squareList addObject:old_square];
        [indexList addObject:[NSNumber numberWithInt:i]];
        [ma replaceObjectAtIndex:i withObject:sq];

    }
    [self setNeedsDisplay:YES];
}


- (void)fakeEditForData:(int) i rect:(NSRect)r{
    NSLog(@"fakeEdit");
    ma = [ds getData];
    NSMutableArray *old_square = [ma objectAtIndex:i];
    NSMutableArray *sq = [NSMutableArray arrayWithArray:old_square];
    NSNumber *n = [sq objectAtIndex:0];
    [sq insertObject:n atIndex:0];
    [ma replaceObjectAtIndex:i withObject:sq];
    [ds setData:ma];
    
    [self setNeedsDisplay:YES];
}


// doesn't draw right away
// but does correct undo after next edit

- (IBAction)undo:(id) sender {
    NSLog(@"undo");
    ma = [ds getData];
    int k = (int)squareList.count;
    if (k == 0) { return; }
    assert (k == indexList.count);
    k -= 1;
    
    NSMutableArray *old_square = [squareList objectAtIndex:k];
    [squareList removeLastObject];
    NSNumber *n = [indexList objectAtIndex:k];
    [indexList removeLastObject];
    int i = (int)[n intValue];
    [ma replaceObjectAtIndex:i withObject:old_square];
    
    // does not have desired effect
    [self setNeedsDisplay:YES];
    return;
}

- (IBAction)cleanRows:(id) sender {
    [ds cleanRows];
    // does not have desired effect
    [self setNeedsDisplay:YES];
    [self fakeEditForData:0 rect:rect_array[0]];
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
- (IBAction)cleanAll:(id) sender {
    [ds cleanRows];
    [ds cleanCols];
    [ds cleanBoxes];
    // does not have desired effect
    [self setNeedsDisplay:YES];
}

- (IBAction)newPuzzle:(id) sender {
    NSLog(@"new");
    int n = (int)[[ds getData] count];
    int i = (int)arc4random_uniform(n);
    [ds loadPuzzleAtIndex:i];
    [self setNeedsDisplay:YES];
}
@end
