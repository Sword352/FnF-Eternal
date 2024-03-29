### High Priority
- Dialogue cutscenes implementation
- Add unlockable freeplay songs support

- Song Metadata rework (implement `SongMeta`)
- Finish the built-in events
- Finish controller input support
- Finish the audio offset support
- Finish the FNF modpack port

### Medium Priority
- Allow difficulties to be changed in the pause menu (freeplay only)
- Allow multi-events (2 or more events having the same time value)
- Gameplay UI tweaks

- Finish the chart editor
- Finish the crash handler rework
- Finish the key formatting in `KeybindItem#formatKey`

- Do all of the TODO stuff that can be found in the code

### Low Priority
- Add a multi-atlas feature for all softcoded sprites
- Rework most of the menus + add credits menu
- FlxAnimate support
- Zip mod support

- Better error handling for the story menu, ModState and ModSubState
- Replace the placeholders BF and GF story menu character spritesheets
- Continue README and wiki stuff, add git wiki

### After GB Release
- Add note colors support
- Playback rate feature (freeplay only)
- Extended shader support/tools
- Add the possibility to enable multiple mods (at the cost of getting some features disabled, like overridable states)

  **Future plans**
- Add modchart tools?
- Lua scripting implementation?

- "Debug Mode" option?
  * Possibility to hot reload ModState and ModSubState
  * In-game traces overlay

### Bugs/Issues to Fix
- Fix freezes happening due to GC clearing sessions