package funkin.core;

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.FlxInput.FlxInputState;

typedef KeyCall = (Int, String) -> Void;
typedef KeybindSet = Array<Array<Int>>;

class Controls {
    public static final keybindOrder:Array<String> = [
        "left",
        "down",
        "up",
        "right",
        "accept",
        "back",
        "autoplay",
        "debug",
        "open mods",
        "volume up",
        "volume down",
        "volume mute"
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
        "open mods" => [[TAB], []],
    ];

    public static var global(default, null):Controls;

    public var keybinds:Map<String, KeybindSet>;
    public var lastAction(default, null):String = null;
    public var saveFile:String;

    public static function init():Void {
        global = new Controls("main");
        reloadVolumeKeys();
    }

    public function new(saveFile:String):Void {
        this.saveFile = saveFile;
        loadControls();
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
        if (keybindMap == null) return false;

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

    public function listKeys(keybind:String, ?separator:String = ", "):String {
        var list:Array<String> = [];

        for (key in keybinds[keybind][0])
            if (key != NONE && key != ANY)
                list.push(FlxKey.toStringMap.get(key));

        return list.join(separator);
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

    public static function reloadVolumeKeys(enabled:Bool = true):Void {
        var muteKeys:Array<FlxKey> = global.keybinds.get("volume mute")[0].filter((k) -> k != NONE);
        var volumeUpKeys:Array<FlxKey> = global.keybinds.get("volume up")[0].filter((k) -> k != NONE);
        var volumeDownKeys:Array<FlxKey> = global.keybinds.get("volume down")[0].filter((k) -> k != NONE);

        FlxG.sound.muteKeys = (enabled && muteKeys.length > 0) ? muteKeys : null;
        FlxG.sound.volumeUpKeys = (enabled && volumeUpKeys.length > 0) ? volumeUpKeys : null;
        FlxG.sound.volumeDownKeys = (enabled && volumeDownKeys.length > 0) ? volumeDownKeys : null;
    }
}
