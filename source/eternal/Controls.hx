package eternal;

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.gamepad.FlxGamepadInputID;

import openfl.ui.Keyboard;
import flixel.util.FlxSignal.FlxTypedSignal;

typedef KeyCall = (Int, String) -> Void;
typedef KeybindSet = Array<Array<Int>>;

class Controls {
   /**
    * This mainly exists because maps are unordered, this is required by the option keybind substate.
    * If you ever add a new keybind make sure to add it in that list as well!
    */
   public static final keybindOrder:Array<String> = [
      "left", "down", "up", "right",
      "accept", "back", "autoplay", "debug", #if ENGINE_MODDING "open mods", #end
      "volume up", "volume down", "volume mute"
   ];

   public static final defaultKeybinds:Map<String, KeybindSet> = [
      "left" => [[LEFT, D], []],
      "down" => [[DOWN, F], []],
      "up" => [[UP, J], []],
      "right" => [[RIGHT, K], []],
      "accept" => [[ENTER], []],
      "back" => [[ESCAPE, BACKSPACE], []],
      "autoplay" => [[SIX], []],
      "debug" => [[SEVEN], []],
      "volume up" => [[PLUS, NUMPADPLUS], []],
      "volume down" => [[MINUS, NUMPADMINUS], []],
      "volume mute" => [[ZERO, NUMPADZERO], []],
      
      #if ENGINE_MODDING
      "open mods" =>  [[TAB], []],
      #end
   ];

   public static var globalControls(default, null):Controls;

   public var saveFile:String;
   public var active:Bool = true;

   public var keybinds(default, null):Map<String, KeybindSet>;
   public var lastAction(default, null):String = null;

   public var onKeyPressed(default, null):FlxTypedSignal<KeyCall> = new FlxTypedSignal<KeyCall>();
   public var onKeyReleased(default, null):FlxTypedSignal<KeyCall> = new FlxTypedSignal<KeyCall>();
   public var onKeyJustPressed(default, null):FlxTypedSignal<KeyCall> = new FlxTypedSignal<KeyCall>();
   public var onKeyJustReleased(default, null):FlxTypedSignal<KeyCall> = new FlxTypedSignal<KeyCall>();

   var heldKeys:Array<Int> = [];

   public static inline function init():Void {
      globalControls = new Controls("main");
      reloadVolumeKeys();
   }

   public function new(saveFile:String):Void {
      this.saveFile = saveFile;
      loadControls();

      FlxG.stage.addEventListener("enterFrame", this.updateGamepadInputs);
      FlxG.stage.application.window.onKeyDown.add(this.onKeyDown);
		FlxG.stage.application.window.onKeyUp.add(this.onKeyUp);
   }

   inline public function pressed(key:String):Bool
      return checkInput(key, PRESSED);
   inline public function justPressed(key:String):Bool
      return checkInput(key, JUST_PRESSED);
   inline public function released(key:String):Bool
      return checkInput(key, RELEASED);
   inline public function justReleased(key:String):Bool
      return checkInput(key, JUST_RELEASED);

   inline public function anyPressed(keys:Array<String>):Bool
      return checkAnyInputs(keys, pressed);
   inline public function anyJustPressed(keys:Array<String>):Bool
      return checkAnyInputs(keys, justPressed);
   inline public function anyReleased(keys:Array<String>):Bool
      return checkAnyInputs(keys, released);
   inline public function anyJustReleased(keys:Array<String>):Bool
      return checkAnyInputs(keys, justReleased);

   function checkInput(key:String, status:FlxInputState):Bool {
      var keybindMap:KeybindSet = keybinds.get(key);
      if (keybindMap == null)
         return false;

      var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
      if (gamepad != null && keybindMap[1] != null) {
         for (button in keybindMap[1]) {
            if (button != NONE && gamepad.checkStatus(button, status)) {
               lastAction = key;
               return true;
            }
         }
      }

      if (keybindMap[0] != null) {
         for (keyInput in keybindMap[0]) {
            if (keyInput != NONE && FlxG.keys.checkStatus(keyInput, status)) {
               lastAction = key;
               return true;
            }
         }
      }

      return false;
   }

   function checkAnyInputs(keys:Array<String>, func:String->Bool):Bool {
      for (key in keys)
         if (func(key))
            return true;

      return false;
   }

   public function getActionFromKey(key:Int, ?fromKeyboard:Null<Bool>):Null<String> {
      for (id => action in keybinds) {
         if ((fromKeyboard == null || fromKeyboard) && action[0] != null && action[0].contains(key))
            return id;
         if ((fromKeyboard == null || !fromKeyboard) && FlxG.gamepads.lastActive != null && action[1] != null && action[1].contains(key))
            return id;
      }
      return null;
   }

   public function listKeys(keybind:String, ?seperator:String = ", "):String {
      var list:Array<String> = [];

      for (key in keybinds[keybind][0])
         if (key != NONE && key != ANY)
            list.push(FlxKey.toStringMap.get(key));

      return list.join(seperator);
   }

   public function loadControls():Void {
      keybinds = null;

      Tools.invokeTempSave((save) -> {
         var data:Map<String, KeybindSet> = save.data.controls;
         if (data != null) {
            keybinds = [];
            for (key in data.keys()) {
               if (defaultKeybinds.exists(key))
                  keybinds.set(key, data.get(key));
            }
         }
      }, 'controls_${saveFile}');

      if (keybinds != null) {
         // check for keybinds that are not registered into the save file
         for (key in defaultKeybinds.keys())
            if (!keybinds.exists(key))
               keybinds.set(key, defaultKeybinds.get(key));
      }
      else
         keybinds = defaultKeybinds.copy();
   }

   inline public function saveControls():Void {
      Tools.invokeTempSave((save) -> save.data.controls = keybinds, 'controls_${saveFile}');
   }

   public function destroy():Void {
      FlxG.stage.removeEventListener("enterFrame", this.updateGamepadInputs);      
      FlxG.stage.application.window.onKeyDown.remove(this.onKeyDown);
		FlxG.stage.application.window.onKeyUp.remove(this.onKeyUp);

      for (signal in [onKeyPressed, onKeyReleased, onKeyJustPressed, onKeyJustReleased])
         signal?.destroy();

      keybinds?.clear();
      keybinds = null;

      heldKeys = null;

      lastAction = null;
      saveFile = null;
   }

   inline function updateGamepadInputs(_):Void {
      if (!active || FlxG.gamepads.lastActive == null)
         return;
      
      var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
      for (id => keybinds in keybinds) {
         if (keybinds[1] == null)
            continue;
         
         for (key in keybinds[1]) {
            if (key == NONE)
               continue;

            if (gamepad.checkStatus(key, PRESSED))
               onKeyPressed.dispatch(key, id);
            if (gamepad.checkStatus(key, RELEASED))
               onKeyReleased.dispatch(key, id);
            if (gamepad.checkStatus(key, JUST_PRESSED))
               onKeyJustPressed.dispatch(key, id);
            if (gamepad.checkStatus(key, JUST_RELEASED))
               onKeyJustReleased.dispatch(key, id);
         }
      }
   }

   inline function onKeyDown(rawKey:Int, _):Void {
      if (!active || !FlxG.keys.enabled)
         return;

      var keyCode:Int = @:privateAccess Keyboard.__convertKeyCode(rawKey);

      var action:String = getActionFromKey(keyCode, true);
      onKeyPressed.dispatch(keyCode, action);

      if (!heldKeys.contains(keyCode)) {
         onKeyJustPressed.dispatch(keyCode, action);
         heldKeys.push(keyCode);
      }
   }

   inline function onKeyUp(rawKey:Int, _):Void {
      if (!active || !FlxG.keys.enabled)
         return;

      var keyCode:Int = @:privateAccess Keyboard.__convertKeyCode(rawKey);
      
      var action:String = getActionFromKey(keyCode, true);
      onKeyReleased.dispatch(keyCode, action);

      if (heldKeys.contains(keyCode)) {
         onKeyJustReleased.dispatch(keyCode, action);
         heldKeys.remove(keyCode);
      }
   }

   public static function reloadVolumeKeys(enabled:Bool = true):Void {
      var muteKeys:Array<FlxKey> = globalControls.keybinds.get("volume mute")[0].filter((k) -> k != NONE);
      var volumeUpKeys:Array<FlxKey> = globalControls.keybinds.get("volume up")[0].filter((k) -> k != NONE);
      var volumeDownKeys:Array<FlxKey> = globalControls.keybinds.get("volume down")[0].filter((k) -> k != NONE);

      FlxG.sound.muteKeys = (enabled && muteKeys.length > 0) ? muteKeys : null;
      FlxG.sound.volumeUpKeys = (enabled && volumeUpKeys.length > 0) ? volumeUpKeys : null;
      FlxG.sound.volumeDownKeys = (enabled && volumeDownKeys.length > 0) ? volumeDownKeys : null;
   }
}
