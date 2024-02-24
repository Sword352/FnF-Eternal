### High Priority
- Dialogue cutscenes implementation
- Add unlockable weeks/songs support
- Finish the Alphabet

- Finish the built-in events
- Finish the audio offset support
- Finish the FNF modpack port

### Medium Priority
- Test/Fix controller inputs
- Add support for custom hscript classes
- Allow difficulties to be changed in the pause menu (freeplay only)
- Allow multi-events (2 or more events having the same time value)
- Gameplay UI tweaks

- Finish the chart editor
- Finish the crash handler rework
- Finish the key formatting in `KeybindItem#formatKey`

- Do all of the TODO stuff that can be found in the code

### Low Priority
- Add a multi-atlas feature for all softcoded sprites
- Add softcoded notetypes support
- Add a credits menu

- Better error handling for the story and freeplay menus + on week/song load fail error handling
- ModState and ModSubState error handling

- Replace the placeholders BF and GF story menu character spritesheets
- Continue README.md, complete the wiki stuff and move it to proper git wiki

### After GB Release
- Add note colors support
- Playback rate feature (freeplay only)
- Extended shader support/tools
- Add the possibility to enable multiple mods (at the cost of getting some features disabled, like overridable states)

  **Future plans**
- FlxAnimate support?
- Add modchart tools?
- Lua scripting implementation?

- "Debug Mode" option?
  * Possibility to hot reload ModState and ModSubState
  * In-game traces overlay

### Bugs/Issues to Fix
- Fix sustain rendering bugs/issues
  - Make the sustain tails visible when the sustain height is small
  - Fix slightly innacurate upscroll texture scrolling (?)

- Fix the press enter sprite's frames on the title screen
- Fix freezes happening due to GC clearing sessions