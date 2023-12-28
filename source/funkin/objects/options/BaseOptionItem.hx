package funkin.objects.options;

import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup.FlxSpriteGroup;

class BaseOptionItem<T> extends FlxSpriteGroup {
    public var option:String;
    public var target:Int = 0;
    public var onChange:T->Void = null;

    public var title(default, set):String;
    public var description(default, set):String;

    public var inputs:Array<String> = ["left", "right"];

    var background:FlxSprite;
    var separator:FlxSprite;

    var nameText:FlxText;
    var valueText:FlxText;
    var descriptionText:FlxText;

    var inputHoldTime:Float = 0;
    var holdLimitation:Float = 0;

    public function new(option:String):Void {
        super();

        this.option = option;
        this.title = Tools.capitalize(option);

        background = new FlxSprite();
        background.makeRect(FlxG.width - 200, FlxG.height - 500, FlxColor.BLACK);
        background.screenCenter(X);
        background.alpha = 0.6;
        add(background);

        separator = new FlxSprite();
        separator.makeRect(FlxG.width - 250, 15);
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

        if (target != 0)
            return;

        if (Controls.globalControls.anyJustPressed(inputs)) {
            inputHoldTime = 0;
            FlxG.sound.play(Assets.sound("scrollMenu"));
            updateBoth((Controls.globalControls.lastAction == "left") ? -1 : 1);
        }

        if (Controls.globalControls.anyPressed(inputs)) {
            inputHoldTime += 1 * elapsed;
            if (inputHoldTime > 0.75) {
                holdLimitation += 5 * elapsed;
                if (holdLimitation > (FlxG.keys.pressed.SHIFT ? 0.2 : 0.5)) {
                    holdLimitation = 0;
                    updateBoth(Controls.globalControls.lastAction == "left" ? -1 : 1);
                }
            }
        }
    }

    inline function updateBoth(mult:Int):Void {
        updateValue(mult);
        updateText();
    }

    // override those in subclasses!
    private function updateValue(mult:Int):Void {}
    private function updateText():Void {}

    function saveValue(value:Any):Void {
        Settings.settings[option].value = value;

        if (onChange != null)
            onChange(value);
    }

    inline function repositionValueText():Void {
        valueText.x = background.x + background.width - valueText.width - 15;
    }

    override function destroy():Void {
        super.destroy();

        option = null;
        title = null;
        description = null;

        inputs = null;
        onChange = null;
    }

    function set_title(v:String):String {
        if (exists && nameText != null) {
            nameText.text = v;
            nameText.x = background.x + 25;
        }
        return title = v;
    }

    function set_description(v:String):String {
        if (exists)
            descriptionText.text = v;
        return description = v;
    }
}