## TODO list

- Finish the scripting backend rework
  - Implement global modules
  - Implement back overridable states
  - Implement reloadable modules (?)
  - Implement script priorities
  - Allow more states and subStates to be scripted (LoadingScreen, Transition, ChartEditor...)
  - Change most string enum abstracts to int once enums are supported in hscript
    - IDEA: perhaps make a universal enum macro so that enums are converted into static values for now?
  - Implement `Constants` singleton to be able to modify common values
  - Add more events and expand the current ones (if possible)
  - Make scripts initialization automatic in scriptable states (automatic `initStateScripts` call), along with calling `onCreate`/`onCreatePost`/`onUpdate`/`onUpdatePost`
  - Fix issues with events dispatched by the `StrumLine` class (more details there)
  - Fix some events being repeatedly dispatched, such as `onGameOver`
  - Perhaps rename `onCreate`/`onCreatePost`/`onUpdate`/`onUpdatePost` to `create`/`createPost`/`update`/`updatePost`?
  - Allow for a more class-based scripting api?

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
  - Rework the asset tree (asset structures) system
  - Implement back mod options
  - Implement back the "mods not found" screen
  - Make a better mods overlay
  - Perhaps implement more modding tools?
  - Implement zip mod support

- Perhaps rework the `Controls` class?
- Tweak the gameplay aspect

- Make `Conductor` beats consistent
  - Implement a stronger, more synced beat system
  - Make it framerate independant

- Rework a bit the chart format
- Add support for VSlice charts
- Do a huge overhaul on softcodable data (characters, noteskins, stages...)
- Implement dialogue cutscenes
- Add support for VSlice softcoded data

- Implement texture atlas support
- Implement multi-atlas features
- Implement automatic atlas type finding everywhere
- Implement tools for shaders

- `HealthIcon` changes
  - Implement more animation states
  - Make it not use `health` as it is deprecated

- Finish support for controller inputs
- Finish support for the visual offset option
- Finish the Friday Night Funkin' modpack
- Finish the chart editor

- Perform a major code cleanup
- Complete all remaining TODOs from the code
- Restore back HTML5 support
- Rewrite the crash handler

- Remake most of the menus
- Add a result screen

- Add modding documentation
- Add API documentation
