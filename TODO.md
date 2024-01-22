### High Priority
- Dialogue cutscenes implementation
- Add unlockable weeks/songs support
- Finish the Alphabet (character offsets + symbols)

- Finish the built-in events
- Finish the audio offset support
- Finish the FNF modpack port

### Medium Priority
- Test/Fix controller inputs
- Gameplay UI tweaks

- Finish the chart editor
- Finish the key formatting in `KeybindItem#formatKey`

- Do all of the TODO stuff that can be found in the code

### Low Priority
- Add a multi-atlas feature for all softcoded sprites
- Add a credits menu

- Better error handling for the story and freeplay menus + on week/song load fail error handling
- ModState and ModSubState error handling

- Replace the placeholders BF and GF story menu character spritesheets
- Continue README.md, complete the wiki stuff and move it to proper git wiki

### After GB Release
- Add note colors support
- Add softcoded notetypes support
- Playback rate feature (freeplay only)
- Extended shader support/tools
- Add the possibility to enable multiple mods (at the cost of getting some features disableed, like overridable states)

  **Future plans**
- FlxAnimate support?
- Add modchart tools?
- Lua scripting implementation?
- Add "modules" support? (Custom HScript classes...)

- "Debug Mode" option?
  * Possibility to hot reload ModState and ModSubState
  * In-game traces overlay

### Bugs to Fix
- Fix sustain rendering bugs/issues
  - Fix sustain tail not clipping properly (except on low scroll speeds)
  - Make the sustain tails visible when the sustain height is small
  - Fix slightly innacurate upscroll texture scrolling (?)
  - Fix the small sustail tail gaps

- Fix the object positions rounding effect when using a lerped camera zoom value (like in PlayState with camHUD)
- Fix little position snap when calling `obj.centerToObject(base, Y)`, where `base`'s position is get via `FlxMath#lerp` (the snap happens when `base` is in it's intended position)
- Fix the press enter sprite's frames on TitleScreen