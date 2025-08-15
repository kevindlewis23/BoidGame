# BoidGame

# How to play
  
Click and drag to move the starting position of the boids (not always allowed)  
Right click and drag to rotate the boids (not always allowed)  
Press start to start the simulation.  You can also press `SPACE` or `ENTER`  
Try to collect all the stars!

## Other controls
Press `r` to reset while the simulation is running  
Press `q` or `ESCAPE` to leave  
Press `e` to show or hide extras (boid paths and previously set positions)  
Press `i` to toggle showing extra information about the level  
Press `Ctrl/Cmd + RIGHT/LEFT` arrows to control simulation speed

# Level creator controls
Right click on empty space to create a new object. You can set the starting place as well as the bounding box for the object, which defines where the player is allowed to move the object.  
Press `t` to test the level (pressing `q` or `ESCAPE` from the level testing will reopen the level creator)  
Press `Ctrl/Cmd + s` to save the level to a json file  
Press `Ctrl/Cmd + l` to load a level into the creator from a json file (changing things will not overwrite the original level)  
Press `q` or `ESCAPE` to go back to the level selector. This will store your current state to a file, so if you reopen the level creator, this level will reopen.  
Press `Ctrl/Cmd + n` to reset the level to a default level (cannot be undone)  
Press `DELETE` to delete the currently selected object  
Press `Ctrl/Cmd + z` to undo the last change  
Press `Ctrl/Cmd + y` to redo the last change

# Coding stuff
This is made with Godot. It's my first time using Godot so please don't make fun of my code lol  

# Tools Used
[Godot](https://godotengine.org/) for game engine
[Font Awesome](https://fontawesome.com) for icons
[LMMS](https://lmms.io/) for sound design

# Current To Do's
 - Add more levels (maybe)
 - Add sprites and make it all look better
 - Better instructions and explanations and stuff
 - Better level selector
 - Sound design
 - This game is almost deterministic, but technically depends on simulation speed. Boid movement is independent of simulation speed, but collisions are checked frame by frame, so collecting stars and stuff could depend on simulation speed.
