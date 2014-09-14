This is an Xcode project written in Objective C.  It is a modified version of Sudoku, in which colored squares replace the digits of the standard form.  I came up with the idea in late 2005, and wrote a PySudoku application in PyObjC.  My early versions are lost, but I have one from May, 2006.

I published the idea on my iDisk pages, and blogged about it [here](http://telliott99.blogspot.com/2008/05/fun-with-sudoku_9172.html).

Various other folks have come up with the same idea in the years since.  I have lost track of the best example, in which hovering the mouse over a square brings up a new panel.  This version works best on a decent sized screen.  That might be fun to attempt.

The todo file lists some issues.  Most important of these is that changes to the data triggered from the view are not updated in the drawing code despite <code>setNeedsDisplay:YES</code>.  I have yet to figure out why this is.  Click on a committed (large square), which won't change its status, but will force the update.

The command key modifies the mouse action to set the clicked square as the user's single choice, otherwise, clicking removes squares.

I originally intended to write this in Swift, but ran into other issues.  This is a pretty rough draft starting at 3 AM today.  We'll see how much love it gets going forward.