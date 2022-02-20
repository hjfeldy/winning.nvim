# winning.nvim
Convenient, minimal terminal / window management for Neovim

## Demo
![demo](images/demo.gif)

## Functions
- ToggleZoom: Zoom into/out of the current window.
    - "Zoom-in" translates to setting the maximum window width/height.
    - "Zoom-out" means reverting to the most recent un-zoomed window dimensions

- ToggleTerm: Toggle the appearance of your terminal window(s) at the top of the screen
- NextTerm: Attach the next available terminal buffer to the currently focused terminal window (excludes currently attached buffers)
- PrevTerm: Same as NextTerm, but traverse the table of available terminal buffers in the backwards direction
- NewTerm: Create a new terminal buffer. 
    - If no terminal windows are visible, create a new window at the top of the screen.
    - Otherwise, split the terminal windows vertically to contain the new buffer
- RenameTerm: Rename the currently selected window interactively

## Install
Install via packer.nvim
```lua
use "hjfeldy/winning.nvim"
```

## Config
No config file. Open to feature requests

