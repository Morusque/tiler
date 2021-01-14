# tiler
tool to cut pictures into tiles and regenerate them

The .pde file is meant to be opened with the Processing ide.

rough documentation :

(1) loading zone
(2) tiles
(3) goal
(4) result
(5) buttons

left click on a button increases values
right click on a button decreases values
shift + clicks shift values by greater gaps
ctrl + clicks modifies x and y to keep a square ratio

- dragging and dropping a pictures loads it into the loading zone (1)
- add tiles cuts the loading zone (1) picture and adds the tiles to the pool according to "divide x" and "divide y" values
- "load goal" loads the picture in the loading zone (1) to the goal (3) to reproduce
- "tile size x" and "tile size y" parameters define the size and ratio of the final tiles to match, tiles will be stretched to fit with them
- "process" will use the tiles from the pool (2) to reconstruct the goal (3), and display it as the result (4) ; some buttons trigger this action automatically
- "once only" if set to 1 will use every available tile once before reusing them
- "tile subdiv" defines if only an average color (if set to 1) or several subdivisions of tiles are used during the matching process

press tab to display the result as a bigger picture
click "export" to generate a png in the data folder

