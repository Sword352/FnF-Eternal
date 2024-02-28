package funkin.states.options;

import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

class KeybindSubState extends MusicBeatSubState {
    var itemGroup:FlxTypedGroup<KeybindItem>;

    var horizontalSelection:Int = 1;
    var currentSelection:Int = 0;

    var allowInputs:Bool = true;
    var changing:Bool = false;

    #if ENGINE_SCRIPTING
    var overrideCode:Bool = false;
    #end

    override function create():Void {
        super.create();

        #if ENGINE_SCRIPTING
        initStateScript();
        hxsCall("onCreate");

        if (overrideCode) {
            hxsCall("onCreatePost");
            return;
        }
        #end

        itemGroup = new FlxTypedGroup<KeybindItem>();
        add(itemGroup);

        for (i in 0...Controls.keybindOrder.length) {
            var item = new KeybindItem(Controls.keybindOrder[i]);
            item.ID = i;
            itemGroup.add(item);
        }

        changeSelection();

        #if ENGINE_SCRIPTING
        hxsCall("onCreatePost");
        #end
    }

    override function update(elapsed:Float):Void {
        #if ENGINE_SCRIPTING
        hxsCall("onUpdate", [elapsed]);
        super.update(elapsed);

        if (overrideCode) {
            hxsCall("onUpdatePost", [elapsed]);
            return;
        }
        #else
        super.update(elapsed);
        #end

        if (allowInputs) {
            if (controls.anyJustPressed(["up", "down"]))
                changeSelection(controls.lastAction == "up" ? -1 : 1);

            if (controls.anyJustPressed(["left", "right"])) {
                horizontalSelection = FlxMath.wrap(horizontalSelection + (controls.lastAction == "left" ? -1 : 1), 0, 2);
                FlxG.sound.play(Assets.sound("scrollMenu"));
                changeSelection();
            }

            if (controls.justPressed("accept") && horizontalSelection != 1) {
                allowInputs = false;
                changing = true;

                itemGroup.forEach((t) -> {
                    if (t.ID != currentSelection)
                        t.alpha = 0;
                    else
                        (horizontalSelection == 0 ? t.secondKeybind : t.firstKeybind).alpha = 0;
                });

                #if ENGINE_SCRIPTING
                hxsCall("onUpdatePost", [elapsed]);
                #end

                // we're returning here so it does not instantly detect the keybind
                return;
            }
        }

        if (controls.justPressed("back")) {
            if (changing) {
                changing = false;
                allowInputs = true;
                changeSelection();
            } else close();
        }

        if (!changing) {
            #if ENGINE_SCRIPTING
            hxsCall("onUpdatePost", [elapsed]);
            #end
            return;
        }

        var targetItem:KeybindItem = itemGroup.members[currentSelection];

        var possibleKey:Int = FlxG.keys.firstJustPressed();
        var gotFromGamepad:Bool = false;

        if (possibleKey < 0 && FlxG.gamepads.lastActive != null) {
            possibleKey = FlxG.gamepads.lastActive.firstJustPressedID();
            gotFromGamepad = true;
        }

        if (possibleKey >= 0) {
            var gamepad:Int = (gotFromGamepad) ? 1 : 0;
            var keyIndex:Int = (horizontalSelection == 2) ? 1 : 0;
            var reverseIndex:Int = (keyIndex == 0) ? 1 : 0;
            var array:Array<Array<Int>> = controls.keybinds[targetItem.keybind];

            if (array[gamepad][keyIndex] == possibleKey || array[gamepad][reverseIndex] == possibleKey)
                possibleKey = NONE;

            controls.keybinds[targetItem.keybind][gamepad][keyIndex] = possibleKey;

            if (controls.keybinds[targetItem.keybind][gamepad][keyIndex] < 0
                && controls.keybinds[targetItem.keybind][gamepad][reverseIndex] < 0)
                controls.keybinds[targetItem.keybind][gamepad] = Controls.defaultKeybinds[targetItem.keybind][gamepad].copy();

            targetItem.updateText(gotFromGamepad);
        }

        #if ENGINE_SCRIPTING
        hxsCall("onUpdatePost", [elapsed]);
        #end
    }

    private function changeSelection(i:Int = 0):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onSelectionChange", [i]))
            return;
        #end

        currentSelection = FlxMath.wrap(currentSelection + i, 0, itemGroup.length - 1);

        for (item in itemGroup) {
            var selected:Bool = item.ID == currentSelection;

            item.target = itemGroup.members.indexOf(item) - currentSelection;
            item.alpha = (selected && horizontalSelection == 1) ? 1 : 0.6;

            item.firstKeybind.alpha = (selected && horizontalSelection == 0) ? 1 : 0.6;
            item.secondKeybind.alpha = (selected && horizontalSelection == 2) ? 1 : 0.6;
        }

        if (i != 0)
            FlxG.sound.play(Assets.sound("scrollMenu"));

        #if ENGINE_SCRIPTING
        hxsCall("onSelectionChangePost", [i]);
        #end
    }

    override function close():Void {
        controls.saveControls();
        Controls.reloadVolumeKeys();
        super.close();
    }
}

class KeybindItem extends FlxText {
    public var firstKeybind:FlxText;
    public var secondKeybind:FlxText;

    public var target:Float = 0;
    public var keybind:String;

    public function new(keybind:String):Void {
        super();

        text = keybind.toUpperCase();
        this.keybind = keybind.toLowerCase();

        setFormat(Assets.font("vcr"), 54, FlxColor.WHITE, CENTER);
        setBorderStyle(OUTLINE, FlxColor.BLACK, 2.5);

        firstKeybind = new FlxText();
        firstKeybind.setFormat(font, 36, FlxColor.WHITE, RIGHT);
        firstKeybind.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        firstKeybind.updateHitbox();

        secondKeybind = new FlxText();
        secondKeybind.setFormat(font, 36, FlxColor.WHITE, LEFT);
        secondKeybind.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        secondKeybind.updateHitbox();

        screenCenter(X);
        updateText(FlxG.gamepads.lastActive != null);

        firstKeybind.x = FlxG.width * 0.35 - firstKeybind.width;
        secondKeybind.x = FlxG.width * 0.65;
    }

    override function update(elapsed:Float):Void {
        for (text in [this, firstKeybind, secondKeybind])
            text.y = Tools.lerp(text.y, (FlxG.height - text.height) * 0.4 + target * 80, 15);

        firstKeybind.x = Tools.lerp(firstKeybind.x, FlxG.width * 0.35 - firstKeybind.width, 15);
    }

    public function updateText(gamepad:Bool = false):Void {
        var arrayToCheck:Array<Int> = Controls.globalControls.keybinds[keybind][gamepad ? 1 : 0];
        if (arrayToCheck == null)
            arrayToCheck = [FlxKey.NONE, FlxKey.NONE];

        while (arrayToCheck.length < 2)
            arrayToCheck.push(FlxKey.NONE);

        firstKeybind.text = formatKey(arrayToCheck[0], gamepad);
        secondKeybind.text = formatKey(arrayToCheck[1], gamepad);
    }

    override function draw():Void {
        firstKeybind.draw();
        super.draw();
        secondKeybind.draw();
    }

    override function set_alpha(v:Float):Float {
        firstKeybind.alpha = secondKeybind.alpha = v;
        return super.set_alpha(v);
    }

    override function destroy():Void {
        firstKeybind = FlxDestroyUtil.destroy(firstKeybind);
        secondKeybind = FlxDestroyUtil.destroy(secondKeybind);
        keybind = null;

        super.destroy();
    }

    private static function formatKey(key:Int, gamepad:Bool = false):String {
        if (key < 0)
            return "NONE";

        if (gamepad) {
            return switch (key) {
                case LEFT_STICK_DIGITAL_LEFT: "L. LEFT";
                case LEFT_STICK_DIGITAL_RIGHT: "L. RIGHT";
                case LEFT_STICK_DIGITAL_UP: "L. UP";
                case LEFT_STICK_DIGITAL_DOWN: "L. DOWN";
                case LEFT_STICK_CLICK: "L. STICK";
                case RIGHT_STICK_DIGITAL_LEFT: "R. LEFT";
                case RIGHT_STICK_DIGITAL_RIGHT: "R. RIGHT";
                case RIGHT_STICK_DIGITAL_UP: "R. UP";
                case RIGHT_STICK_DIGITAL_DOWN: "R. DOWN";
                case RIGHT_STICK_CLICK: "R. STICK";
                case GUIDE: switch (FlxG.gamepads.lastActive.model) {
                        case PS4: "PS";
                        case XINPUT: "XB";
                        default: "HOME";
                    }
                case A: switch (FlxG.gamepads.lastActive.model) {
                        case PS4: "X";
                        default: "A";
                    }
                case B: switch (FlxG.gamepads.lastActive.model) {
                        case PS4: "O";
                        case XINPUT: "A";
                        default: "B";
                    }
                case X: switch (FlxG.gamepads.lastActive.model) {
                        case PS4: "SQUARE";
                        default: "X";
                    }
                case Y: switch (FlxG.gamepads.lastActive.model) {
                        case PS4: "TRIANGLE";
                        default: "Y";
                    }
                default: FlxGamepadInputID.toStringMap.get(key).replace("_", " ");
            }
        }

        return switch (key) {
            case ZERO | NUMPADZERO: "0";
            case ONE | NUMPADONE: "1";
            case TWO | NUMPADTWO: "2";
            case THREE | NUMPADTHREE: "3";
            case FOUR | NUMPADFOUR: "4";
            case FIVE | NUMPADFIVE: "5";
            case SIX | NUMPADSIX: "6";
            case SEVEN | NUMPADSEVEN: "7";
            case EIGHT | NUMPADEIGHT: "8";
            case NINE | NUMPADNINE: "9";
            case MINUS | NUMPADMINUS: "-";
            case PLUS | NUMPADPLUS: "+";
            case PERIOD | NUMPADPERIOD: ".";
            case SLASH | NUMPADSLASH: "/";
            case NUMPADMULTIPLY: "X";
            case PAGEUP: "PGUP";
            case PAGEDOWN: "PGDOWN";
            case CAPSLOCK: "CAPS";
            case CONTROL: "CTRL";
            case PRINTSCREEN: "PRTSCR";
            case LBRACKET: "[";
            case RBRACKET: "]";
            case BACKSLASH: "\\";
            case SCROLL_LOCK: "SCROLL LOCK";
            case SEMICOLON: ";";
            case QUOTE: "'";
            case COMMA: ",";
            default: FlxKey.toStringMap.get(key).replace("_", " ");
        }
    }
}
