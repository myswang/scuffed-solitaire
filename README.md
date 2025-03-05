# Scuffed Solitaire
*a stupid solitaire clone in Lua/Love2D*

## Quick Start

[Install Love2D first.](https://love2d.org/)

```bash
git clone https://github.com/myswang/scuffed-solitaire.git
love scuffed-solitaire
```

## Controls

- U: Undo most recent move
- R: Redo move
- Enter: Start new game
- Escape: Exit game

## Game Configuration

`constants.lua` contains some basic game settings. Tweak these at your own risk!

## TODO

- Undo/New game buttons
- ~Three card deals~ (Done, implemented with `constants.THREE_CARD_HAND`)
- ~Double-click to automatically place cards in the foundation~ (Done)
- Further optimizations (WIP)

## Credits

The playing card texture atlas was sourced here: https://www.spriters-resource.com/pc_computer/solitaire/sheet/107016/
