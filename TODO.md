### High Priority
- Finish the chart editor
- Finish the built-in events
- Finish the audio offset support
- Finish the Alphabet (character offsets + symbols)
- Do all of the TODO stuff that can be found in the code

### Medium Priority
- Test/Fix controller inputs
- Dialogue cutscenes implementation
- Proper noteskins (and asset style?) system
- Finish the key formatting in `KeybindItem#formatKey`

### Low Priority
- Gameplay UI tweaks
- Freeplay UI overhaul
- Replace the placeholders BF and GF story menu character spritesheets

- ModState and ModSubState error handling
- (Better error handling for FreeplayMenu and StoryMenu?)

- Add Credits menu
- Finish the FNF modpack port

- Continue README.me, complete the wiki stuff, move it to proper git wiki and add a "documentation" issue template

### After Release
- Add note colors support
- Add softcoded notetypes support

- Playback rate feature (Freeplay mode only)
- Extended shader support/tools

- (FlxAnimate support?)
- (Add modchart tools?)
- (Add "modules" support?)
- (Lua scripting implementation?)
- (Add support for multiple strumlines/characters within a chart?)

- (Debug Mode, as an option?)
  * Possibility to hot reload ModState and ModSubState
  * In-game traces overlay

### Bugs to Fix
- Fix sustain rendering bugs
  - Fix sustain tail not clipping properly (except on low scroll speeds)
  - Fix sustain scroll texture (?)

- Fix the objects "repositioning" when using a lerped camera zoom value (like in PlayState with camHUD)
- Fix little position snap when calling `obj.centerToObject(base, Y)`, where `base`'s position is get via `FlxMath#lerp` (the snap happens when `base` is in it's intended position)
- Fix the press enter sprite's frames on TitleScreen