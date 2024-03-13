package funkin.objects.options;

import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup.FlxSpriteGroup;

class BaseOptionItem<T> extends FlxSpriteGroup {
    public var option:String;
    public var target:Int = 0;

    public var title(default, set):String;
    public var description(default, set):String;
    public var onChange:T->Void = null;

    public var inputs:Array<String> = ["left", "right"];

    var controls(get, never):Controls;
    inline function get_controls():Controls
        return Controls.globalControls;

    var background:FlxSprite;
    var separator:FlxSprite;

    var nameText:FlxText;
    var valueText:FlxText;
    var descriptionText:FlxText;

    var holdTime:Float = 0;

    public function new(option:String):Void {
        super();

        this.option = option;
        this.title = Tools.capitalize(option);

        background = new FlxSprite();
        background.makeRect(FlxG.width - 200, FlxG.height - 500, FlxColor.BLACK, false, "optionmenu_rect");
        background.screenCenter(X);
        background.alpha = 0.6;
        add(background);

        separator = new FlxSprite();
        separator.makeRect(FlxG.width - 250, 15, "optionmenu_sep");
        separator.centerToObject(background);
        add(separator);

        nameText = new FlxText();
        nameText.setFormat(Assets.font("vcr"), 32);
        nameText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        nameText.text = title;
        nameText.x = background.x + 25;
        add(nameText);

        valueText = new FlxText();
        valueText.setFormat(nameText.font, 32);
        valueText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        valueText.text = "null";
        repositionValueText();
        add(valueText);

        descriptionText = new FlxText();
        descriptionText.setFormat(nameText.font, 22);
        descriptionText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        descriptionText.text = "No description provided.";
        descriptionText.x = separator.x;
        add(descriptionText);
    }

    override function update(elapsed:Float):Void {
        background.y = Tools.lerp(background.y, 75 + 240 * target, 10);
        separator.centerToObject(background, Y);

        nameText.y = separator.y - nameText.height - 15;
        valueText.y = separator.y - valueText.height - 15;
        descriptionText.y = separator.y + separator.height + 15;

        super.update(elapsed);
        if (target == 0) handleInputs(elapsed);
    }

    function handleInputs(elapsed:Float):Void {
        if (controls.anyJustPressed(inputs)) {
            updateSetting((controls.lastAction == "left") ? -1 : 1);
            FlxG.sound.play(Assets.sound("scrollMenu"));
            holdTime = 0;
        }

        if (controls.anyPressed(inputs)) {
            var hold:Float = Math.floor(holdTime += elapsed * 1.75) - 0.75;
            if (hold > 0) {
                updateSetting((controls.lastAction == "left") ? -1 : 1);
                holdTime -= (FlxG.keys.pressed.SHIFT ? 0.01 : 0.1);
            }
        }
    }

    inline function updateSetting(mult:Int):Void {
        updateValue(mult);
        updateText();
    }

    // override those in subclasses!
    function updateValue(mult:Int):Void {}
    function updateText():Void {}

    function saveValue(value:Any):Void {
        Settings.settings[option].value = value;
        if (onChange != null) onChange(value);
    }

    inline function repositionValueText():Void {
        valueText.x = background.x + background.width - valueText.width - 15;
    }

    override function destroy():Void {
        option = null;
        title = null;
        description = null;

        inputs = null;
        onChange = null;

        super.destroy();
    }

    function set_title(v:String):String {
        if (v != null && nameText != null) {
            nameText.text = v;
            nameText.x = background.x + 25;
        }

        return title = v;
    }

    function set_description(v:String):String {
        if (v != null)
            descriptionText.text = v;
        return description = v;
    }
}
