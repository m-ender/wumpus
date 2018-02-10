# Wumpus

Wumpus is a recreational, two-dimensional programming language, where the instruction pointer moves on a [triangular grid](https://en.wikipedia.org/wiki/Triangular_tiling) (and to the best of the author's knowledge, the first such language). It's a language of the [Fungeoid variety](http://esolangs.org/wiki/Fungeoid), in that it is primarily stack-based, allows the source code to be modified at runtime and takes several inspirations from Fungeoids that came before it, primarily [Befunge](http://esolangs.org/wiki/Befunge) itself and [><>](http://esolangs.org/wiki/Fish). However, Wumpus also brings a number of new features to the table (in addition to the triangular grid), such as 20 registers which are arranged around the faces of an [icosahedron](https://en.wikipedia.org/wiki/Regular_icosahedron).

The name is, of course, a reference to [*Hunt the Wumpus*](https://en.wikipedia.org/wiki/Hunt_the_Wumpus), a classic computer game with an icosahedral dungeon map. *Hunt the Wumpus* also has historical significance for 2D programming languages, thanks to [Wim Rijnders's famous implementation in Befunge](http://catseye.tc/view/befunge-93/eg/wumpus.bf).

## Source code and the grid

The language's grid is triangular where each triangle either points north or south (as opposed to pointing either east or west). The triangle in the northwestern corner of the grid always points north. Such a grid can easily be mapped to ASCII characters, by alternatingly specifying an upward and a downward triangle. Consider the following grid:

[![Grid][grid]][grid]

The corresponding ASCII representation would be:

    "dlroW ol
           el
    @No&l{"H 

And this is exactly how source files for Wumpus are interpreted. If not all lines of the source files have the same length, the shorter lines are padded to the maximum length with spaces (so the space after the `H` in the above program could have been omitted). We'll call the number of lines in the program the **height** and the maximum line length the **width**. These are fixed throughout the program (while it's possible to modify the grid at runtime, it can never shrink or grow).

The grid actually stores signed arbitrary-precision integers, and will initially hold the code points of the characters in the source code.

We will occasionally need to refer to individual cells or vertices between cells by their coordinates. Cells and vertices have separate coordinate systems. This the cell coordinate system:

[![Cell coordinates][cell-coordinates]][cell-coordinates]

These are just the normal (0-based) 2D coordinates you'd expect for the characters in the source file. For vertices, only vertices which are surrounded by six cells have coordinates, and they're assigned as follows:

[![Vertex coordinates][vertex-coordinates]][vertex-coordinates]

So **x**-coordinates still increase to the right and **y**-coordinates increase downward, but every other row is offset a bit, and horizontally there's only one vertex for every other cell.

  [grid]: https://github.com/m-ender/wumpus/blob/master/img/grid.png
  [cell-coordinates]: https://github.com/m-ender/wumpus/blob/master/img/cell-coordinates.png
  [vertex-coordinates]: https://github.com/m-ender/wumpus/blob/master/img/vertex-coordinates.png

## Basic control flow

Wumpus has a single **instruction pointer (IP)** which always moves parallel to the edges of the grid. The six directions it can move in will be referred to as E, NE, NW, W, SW and SE. The IP always starts in the top-left corner of the grid (coordinates (0, 0)), moving east. The IP will alternate between visiting upward and downward triangles. In most other Fungeoids, the grid wraps around the edges. Not so in Wumpus: instead, the IP will reflect off the boundaries of the program. A simple diagram should make clear how exactly this reflection works:

[![IP movement][ip-movement]][ip-movement]

These reflections do not cause the current cell to be evaluated again. That means the bottom-left cell (coordinates (0, 3)) is only executed once in the above example. However, the cell at (1, 3) would be executed twice, because it's entered both before and after the bottom-left cell.

Note that when the IP moves along a diagonal, its path in the source code actually has the shape of a staircase.

It's possible to set the **strafing flag** with the `,` command. This causes the the IP to take the next step **orthogonally** to its current direction. Whether this movement goes left or right from the IP's perspective depends on the orientation of the current grid cell (because the IP can only ever move across edges). Here is an example of movement through a grid which contains three `,`s:

[![Strafing][strafing]][strafing]

The dashed lines indicate strafing steps. If the strafing step would cause the IP to go out of bounds, the IP will take a regular step instead. Either way, the strafing flag is set back to false after every step (so using `,` when strafing is impossible due to the grid boundaries, the command will not be stored up for a later step).

There are several other commands to redirect the IP at runtime, but these should be self-explanatory.

  [ip-movement]: https://github.com/m-ender/wumpus/blob/master/img/ip-movement.png
  [strafing]: https://github.com/m-ender/wumpus/blob/master/img/strafing.png

## Memory model

Wumpus's memory model consists of two parts: the **stack**, and the **icosahedron**. Both store signed arbitrary-precision integers. You can also think of the grid as a third part of the memory model, which doubles as the program code.

The stack is the primary data storage. Most commands pop their arguments from the stack and push the result back onto the stack. The stack is initially empty. Trying to pop from an empty stack results in a **0** instead. There are enough stack manipulation commands in the language that you never need to use the icosahedron if you don't want to (unless you need to generate random numbers).

The icosahedron is a collection of 20 registers, each of which has an index from **1** to **20** and is associated with one face of the icosahedron. This document will generally refer to the registers *as* "faces". There are many possible icosahedron nets, but for the purposes of this document, we'll use the following two (these are just different unfoldings of the same icosahedron):

[![Net 1][net-1]][net-1] [![Net 2][net-2]][net-2]

If you can get your hands on a [Magic: the Gathering](https://en.wikipedia.org/wiki/Magic:_The_Gathering) spin-down die, it's strongly recommended to have it on your desk while trying to work with Wumpus's icosahedron, as they use the same face labelling.

It's possible to rotate the icosehedron arbitrarily, but the relative positions of the faces will always remain the same. There's an **active face**, which is the register you can directly interact with – initially, this is face **1**. There's also an **orientation** to the icosahedron, which determines which neighbour of the active face rests where.

You should think of the icosahedron as resting on a table *on its active face*, such that the triangle points north. The initial orientation of the icosahedron is such that face **8** is south of the active face. Note that the two nets above are looking at the active face *from below*, which means east and west are flipped compared to the directions when looking down onto the icosahedron. For example, face **2** is initially the north**western** neighbour of the active face.

There are commands to place the icosahedron onto the triangular grid, in either **get** or **set mode** (you should think of the icosahedron faces as having the same size as the grid cells). If the relevant cell points upward, the icosahedron simply gets placed there in its current orientation. If the relevant cell points downward, the icosahedron is rotated by 180 degrees. The icosahedron can then be rolled around the grid by tipping it from edge to edge: *the active face and icosahedron orientation will change accordingly*. It's still possible to rotate the icosahedron regularly while it's on the grid, which will not change its position on the grid.

While the icosahedron is in *get* mode, the current grid cell value will be copied into the active face of the icosahedron. While the icosahedron is in *set* mode, the active face will be copied into the current grid cell. This happens both when moving the icosahedron around the grid *and* implicitly each time the icosahedron is modified (either by writing to the active face, or by rotating the icosahedron in place).

  [net-1]: https://github.com/m-ender/wumpus/blob/master/img/net-1.png
  [net-2]: https://github.com/m-ender/wumpus/blob/master/img/net-2.png

## Command list

This section is a complete reference of all commands available in Wumpus, grouped into several categories of commands. Remember that the grid actually stores the characters' code points, so each of the characters listed here actually represents its code point. Any character (or code point) that isn't listed here is a no-op (i.e. does nothing).

### General commands

- `@`: Terminate the program.
- `"`: Toggle string mode. While in string mode, each grid cell is pushed directly to the stack (instead of being treated as a command).
- `` ` ``: No-op. This is a special debug marker, whose exact effect is left up to the implementation. The reference implementation prints a readable ASCII representation of the entire program state to the standard error stream.

### Control flow

- `,`: Toggles the *strafing flag*, so that the next step is orthgonal to the current IP direction if possible. Remember that the flag gets automatically reset at the end of the next IP movement.
- `_`, `|`, `/`, `\` are mirrors. They reflect the IP in the direction you'd generally expect. `_`, `/` and `\` are essentially equivalent to a grid boundary in the same direction. For completeness, the following table shows how they deflect an incoming IP. The top row corresponds to the current direction of the IP, the left column to the mirror, and the table cell shows the outgoing direction of the IP:
 
      cmd   E SE SW  W NW NE

       /   NW  W SW SE  E NE
       \   SW SE  E NE NW  W
       _    E NE NW  W SW SE
       |    W SW SE  E NE NW

- `{`: Turn left by 60°. For example, if the IP is currently moving NE, its direction would be changed to NW.
- `}`: Turn right by 60°. For example, if the IP is currently moving NE, its direction would be changed to E.
- `^`: Conditional turn. Pop **n**. If **n** is positive this acts like `}`, otherwise acts like `{`.
- `&`: Pop **n**. The next cell is executed **n** times. This does not stack in any way: if you apply `&` to another `&`, the second one will pop **n** values and the *last* one will be used to determine how many times the next cell is executed.
- `$`: Skip the next cell. This is equivalent to `0&`.
- `?`: Conditional skip. Pop **n**. Skip the next cell only if **n = 0**.
- `.`: Jump. Pop **y**. Pop **x**. The next step will go to **(x % w, y % h)**, where **w** and **h** are the grid's width and height, respectively, and **%** is the modulo operation. Note that this step will replace the normal step between cells, so that the command in the target cell will be executed next.

### Arithmetic

- `#`: Pushes a **0** onto the stack and activates **int mode**. Int mode ends automatically when the IP enters a cell that doesn't contain a digit. While in int mode, large numbers can be written out digit by digit, instead of having to construct them from smaller numbers by arithmetic.
- `0-9`: Let's call the actual digit **d**. If int mode is active (see `#`), pop **n**, push **10n + d** (this appends **d** to the current number on top of the stack). If int mode is not active, simply push **d**.
- `(`: Decrement. Pop **n**. Push **n-1**.
- `)`: Decrement. Pop **n**. Push **n+1**.
- `!`: Logical NOT. Pop **n**. If **n = 0**, push **1**, otherwise push **0**.
- `'`: Negate. Pop **n**. Push **-n**.
- `+`: Add. Pop **b**. Pop **a**. Push **a + b**.
- `-`: Subtract. Pop **b**. Pop **a**. Push **a - b**.
- `*`: Multiply. Pop **b**. Pop **a**. Push **a * b**.
- `:`: Divide. Pop **b**. Pop **a**. Push **a / b**, rounded towards negative infinity.
- `%`: Modulo. Pop **b**. Pop **a**. Push **a % b**. The sign of the result matches the sign of **b**.
- `n`: Bitwise NOT. Pop **n**. Push **~n**.
- `a`: Bitwise AND. Pop **b**. Pop **a**. Push **a & b**.
- `v`: Bitwise OR. Pop **b**. Pop **a**. Push **a | b**.
- `x`: Bitwise XOR. Pop **b**. Pop **a**. Push **a ^ b**.

### I/O

- `i`: Read a byte from the standard input stream and push it to the stack.
- `o`: Pop **n**. Print the byte **n % 256** to the standard output stream.
- `I`: Scan the standard input stream for the next decimal integer and push its value to the stack.
- `O`: Pop **n**. Print its decimal representation to the standard output stream.
- `N`: Print a linefeed (0x0A) to the standard output stream.

### Stack manipulation

- `;`: Pop and discard one value.
- `=`: Duplicate. Pop **n**. Push **n** twice.
- `~`: Swap. Pop **b**. Pop **a**. Push **b**. Push **a**.
- `l`: Push the current stack depth.
- `r`: Reverse the stack.
- `[`: If the stack isn't empty, rotate it "left", i.e. remove the bottom element and push it on top.
- `]`: If the stack isn't empty, rotate it "right", i.e. pop the top element and insert it at the bottom.

### Icosahedron manipulation

Remember that the icosahedron should be pictured as resting on its active face, with the face pointing north. Each fixed rotation is accompanied by the permutation it applies to the faces. If the **i**th face of the permutation is **k<sub>i</sub>**, that means applying this rotation to the *initial* icosahedron orientation will move face **k<sub>i</sub>** to where face **i** used to be. Any references to specific faces refer to their initial position. I.e. "face 1" refers to the active face (regardless of its actual index), "face 2" refers to the active face's northwestern neighbour, etc.

- `A`: **{2, 1, 8, 9, 10, 11, 12, 3, 4, 5, 6, 7, 17, 18, 19, 20, 13, 14, 15, 16}**: Tip onto northwestern neighbouring face (then rotate 180°). This can also be thought of as a 180° rotation of the edge between faces **1** and **2**.
- `B`: **{5, 6, 7, 8, 1, 2, 3, 4, 14, 15, 16, 17, 18, 9, 10, 11, 12, 13, 20, 19}**: Tip onto northeastern neighbouring face (then rotate 180°). This can also be thought of as a 180° rotation of the edge between faces **1** and **5**.
- `C`: **{8, 7, 17, 18, 9, 10, 2, 1, 5, 6, 15, 16, 20, 19, 11, 12, 3, 4, 14, 13}**: Tip onto southern neighbouring face (then rotate 180°). This can also be thought of as a 180° rotation of the edge between faces **1** and **8**.
- `P`: **{12, 3, 2, 10, 11, 19, 20, 13, 14, 4, 5, 1, 8, 9, 18, 17, 16, 15, 6, 7}**: Tip onto northwestern neighbouring face, tip onto northern edge, rotate 180°, undo tippings. This can also be thought of as a 180° rotation of the edge between faces **2** and **3**.
- `Q`: **{15, 16, 17, 7, 6, 5, 4, 14, 13, 20, 19, 18, 9, 8, 1, 2, 3, 12, 11, 10}**: Tip onto northeastern neighbouring face, tip onto southeastern edge, rotate 180°, undo tippings. This can also be thought of as a 180° rotation of the edge between faces **5** and **6**.
- `R`: **{18, 17, 16, 20, 19, 11, 10, 9, 8, 7, 6, 15, 14, 13, 12, 3, 2, 1, 5, 4}**: Tip onto southern neighbouring face, tip onto southwestern edge, rotate 180°, undo tippings. This can also be thought of as a 180° rotation of the edge between faces **8** and **9**.
- `V`: **{20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1}**: 180° rotation about the central west-east axis. I.e. put the icosahedron onto the face that is currently facing away from the table.
- `W`: **{1, 5, 6, 7, 8, 9, 10, 2, 3, 4, 14, 15, 16, 17, 18, 19, 11, 12, 13, 20}**: Rotate the icosahedron 120° counterclockwise (while the active face remains flat on the table).
- `X`: **{2, 3, 4, 5, 1, 8, 9, 10, 11, 12, 13, 14, 15, 6, 7, 17, 18, 19, 20, 16}**: Tip onto northern corner, rotate by one face (72°) counterclockwise, then tip back.
- `Y`: **{5, 4, 14, 15, 6, 7, 8, 1, 2, 3, 12, 13, 20, 16, 17, 18, 9, 10, 11, 19}**: Tip onto southeastern corner, rotate by one face (72°) counterclockwise, then tip back.
- `Z`: **{8, 1, 5, 6, 7, 17, 18, 9, 10, 2, 3, 4, 14, 15, 16, 20, 19, 11, 12, 13}**: Tip onto southwestern corner, rotate by one face (72°) counterclockwise, then tip back.

Rotations `A`, `B`, `C`, `P`, `Q` and `R` are all rotations about an edge and and `X`, `Y`, `Z` are rotations about a corner. The following diagrams indicate which edge or corner they rotate about, assuming that the grey face is the active face. Remember that the net looks at the icosahedron *from below*, so east and west are swapped relative to the descriptions above.

[![Net 1 rotations][net-1-rotations-unlabeled]][net-1-rotations-unlabeled] [![Net 2 rotations][net-2-rotations-unlabeled]][net-2-rotations-unlabeled]

There are also a few non-fixed permutations:

- `D`: "Roll the d20". This puts the icosahedron into a uniformly random orientation. I.e. each of the 20 faces is equally likely to become the active face and each of its three neighbours is equally likely to become the active face's southern neighbour. In practice, this is done by doing `X` 0-4 times, `W` 0-2 times, `P` 0-1 time and then `Q` 0-1 time (where each of those choices is independent and uniformly random).
- `U`: Random tip. This chooses randomly (uniformly) between `A`, `B` and `C`, tipping the icosahedron onto a random neighbour of the active face (and then rotating 180°).
- `T`: Conditional tip. Pop **n**. If **n < 0**, do `A`, if **n > 0**, do `B`, if **n = 0**, do `C`.

Finally, there a few commands that let the icosahedron interact with the stack:

- `S`: Store. Pop **n**, write **n** to the active face.
- `L`: Load. Push the active face's value to the stack.
- `F`: Push the active face's *index* to the stack (this lets you determine where the icosahedron ended up after a random rotation).

  [net-1-rotations-unlabeled]: https://github.com/m-ender/wumpus/blob/master/img/net-1-rotations-unlabeled.png
  [net-2-rotations-unlabeled]: https://github.com/m-ender/wumpus/blob/master/img/net-2-rotations-unlabeled.png

### Grid manipulation

- `g`: Get. Pop **y**. Pop **x**. Place the icosahedron onto cell **(x % w, y % h)**, where **w** and **h** are the grid's width and height, respectively. Activates *get mode*, where the current grid cell will be copied into the active face.
- `s`: Set. Pop **y**. Pop **x**. Place the icosahedron onto cell **(x % w, y % h)**, where **w** and **h** are the grid's width and height, respectively. Activates *set mode*, where the current grid cell will be copied into the active face.
- `e`: End. Removes the icosahedron from grid, ending either *get* or *set mode*.
- `<`, `>`, `b`, `d`, `p`, `q`: Move icosahedron. These tip the icosahedron onto the grid cell west, east, northwest, northeast, southwest or southeast, respectively, of the current cell. These directions should be treated the same as IP directions, so for any given cell these only point at three different cells. If this movement would make the icosehedron go out of the grid's bounds, the command is ignored. Note that tipping the icosahedron also changes the active face, so that this movement is accompanied by an implicit rotation via one of `A`, `B`, `C`. Which rotation happens depends on whether the current cell points upward or downward. The following table lists the implicit permutation for every possible configuration:

           cmd   <  >  b  d  p  q
                                 
        upward   A  B  A  B  C  C
      downward   B  A  C  C  B  A

There's also one grid manipulation command which doesn't involve the icosahedron:

- `G`: Pop **y**. Pop **x**. Pop **n**. Find the *vertex* at coordinates **(x, y)**. Rotate the six cells around this vertex **n** steps counterclockwise. If **n** is negative, the cells are rotated **-n** steps clockwise. If **(x, y)** doesn't refer to a vertex with six surrounding cells, nothing happens. If the IP or the icosahedron are currently on one of the six affected cells, their positions are *not* changed (so the grid rotates underneath them).

## Reference implementation

To run a program, invoke the interpreter with the source code's file name as a command-line argument, e.g.

    $ ruby ./wumpus.rb ./examples/hello-world.wumpus

The implementation-defined debug command `` ` `` will print a readable ASCII representation of the current program state, including the two icosahedron nets. The interpreter also has a verbose mode, which can be activated with the `-D` flag:

    $ ruby ./wumpus.rb -D ./examples/hello-world.wumpus

With this flag set, the interpreter will print the debug information before *every* command.