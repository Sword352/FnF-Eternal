### High Priority
- Proper noteskins (and asset style?) system
- Finish Alphabet (character offsets + symbols)
- (Move game over properties from CharacterConfig to SongMetadata?)

### Medium Priority
- Finish the key formatting in `KeybindItem#formatKey`
- Finish the built-in events
- Add mod options support
- Dialogue cutscenes implementation

### Low Priority
- Replace the placeholders BF and GF story menu character spritesheets
- (Better error handling for FreeplayMenu and StoryMenu?)

- (Make CrashScreen an openfl.display.Sprite instead of an FlxState, in case when the FlxGame itself crashes?)
- (Add critical error handling? NOTE: critical error handler gets called on YAML parsing warnings)

- Gameplay UI tweaks
- (Use [hxVlc](https://github.com/MAJigsaw77/hxvlc) instead of hxCodec?)

- Add a `close` function to the `HScript` class
- ModState and ModSubState error handling

- Continue README.md and complete the wiki stuff

- Add Credits menu
- Continue the chart editor
- Finish the FNF modpack port

### After Release
- Add a note colors option
- Add notetypes support

- Playback rate feature (Freeplay mode only)
- Extended shader support/tools

- (FlxAnimate support?)
- (Add modchart tools?)
- (Add "modules" support?)
- (Lua scripting implementation?)
- (Add multiple strumlines support?)

- (Debug Mode, as an option?)
  * Possibility to hot reload ModState and ModSubState
  * In-game traces overlay

### Bugs to Fix
- Fix little position snap when calling `obj.centerToObject(base, Y)`, where `base`'s position is get via `FlxMath#lerp` (the snap happens when `base` is in it's intended position)
- Fix the press enter sprite's frames on TitleScreen