## TODO list

- Finish song events rework
  - Add event descriptions in the chart editor
  - Allow dropdown items to display a text different than their actual values
  - Make `List` arguments dynamic
  - Find a better workaround to allow default dynamic argument values with the event macro (deprecate `tempValue`)
  - Better character preloading for the `ChangeCharacterEvent`
  - Rename the `ChangeCameraTargetEvent` to `CameraFocusEvent` and make it's "target" argument a string
  - Rename the `ChangeBpmEvent` to `TimingPointEvent` and make it be able to change the time signature
  - Allow 2 events or more to have the same time value

- Finish the modding support rework
  - Clean up code
  - Implement back mod options
  - Implement back the "mods not found" screen
  - Make a better mods overlay
  - Perhaps implement more modding tools?
  - Implement zip mod support?

- Continue tweaking up gameplay
  - Make it so restarting the song/leaving gameover still uses the same PlayState instance
  - Re-use the player character for the gameover screen when possible
  - Make icon bops/measure zooms not happen at the end of the song
  - Make it so toggling on botplay reset the held keys and receptor animations
  - Improve the ui style system so that individual assets can be changed
  - Remove the use of static variables
  - Continue the code cleanup

- `Conductor` changes
  - Implement a better structure for bpm changes
  - Improve support for time signatures
  - Add time signature changes

- Rework the keybind system (and `Controls` class)

- Rework a bit the chart format
- Add support for VSlice charts
- Do a huge overhaul on softcodable data (characters, noteskins, stages...)
- Implement dialogue cutscenes
- Add support for VSlice softcoded data
- Implement animate atlas support?

- Finish support for controller inputs
- Finish support for the visual offset option
- Finish the Friday Night Funkin' modpack
- Finish the chart editor

- Perform a major code cleanup
- Complete all remaining TODOs from the code

- Remake most of the menus
- Implement a nicer transition system
- Add a result screen

- Add modding documentation
- Add API documentation

# Future concerns
- Replace HScript with a faster and more performant scripting engine, if possible
  - Note that it doesn't necessarly needs to run Haxe code. Other scripting languages such as Lua are still options
    (although HScript will have to be kept, otherwise it's a breaking change).
