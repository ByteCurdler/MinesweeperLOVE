# MinesweeperLOVE
A small Minesweeper clone made with LÖVE

# Usage
```
<LÖVE2D executable> MinesweeperLOVE/ [<width> [<height> [<scale>]]]
```
where:
- \<width> is the width of the Minesweeper board (default: 8)
- \<height> is the height of same (default: 8)
- \<scale> is the size of a cell in pixels (default: 64)

Uses the [LÖVE2D](https://love2d.org) framework
## Controls:
- Left-click: Reveal the cell under the cursor
- Right-click: Mark there to be a mine under the cursor
- Left+Right/middle click + drag: Hilight the cells around and under the cursor.<br>
  &nbsp;&nbsp;If the cell under the cursor is revealed and has mines around it equal to its number,<br>
  it reveals all unmarked cells, and detonates any unmarked bombs
