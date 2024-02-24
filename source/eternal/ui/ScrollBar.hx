package eternal.ui;

import flixel.group.FlxSpriteGroup;

class ScrollBar extends FlxSpriteGroup {
    public var percent(get, set):Float;
    public var onPercentChange:Float->Void = null;

    var background:FlxSprite;
    var bar:FlxSprite;

    public function new(x:Float = 0, width:Float = 50, height:Float = 360):Void {
        super(x);

        background = new FlxSprite();
        background.makeRect(width, height);
        add(background);

        bar = new FlxSprite();
        bar.makeRect(width * 0.75, height * 0.25, FlxColor.WHITE);
        bar.color = FlxColor.GRAY;
        add(bar);

        bar.centerToObject(background, X);
        screenCenter(Y);

        percent = 0;
    }

    override function update(elapsed:Float):Void {
        if (FlxG.mouse.overlaps(bar, camera))
            handleDrag(FlxG.mouse.deltaY);
        else
            bar.color = FlxColor.GRAY;
    }

    inline function handleDrag(value:Float):Void {
        bar.color = 0xFF595959;
        if (!FlxG.mouse.pressed || !FlxG.mouse.justMoved)
            return;

        bar.y = FlxMath.bound(bar.y + value, background.y + 10, background.y + (background.height - bar.height - 10));
        callback(percent);
    }

    inline function callback(value:Float):Void {
        if (onPercentChange != null)
            onPercentChange(value);
    }

    override function destroy():Void {
        onPercentChange = null;
        super.destroy();
    }

    inline function set_percent(v:Float):Float {
        v = FlxMath.bound(v, 0, 1);
        callback(v);

        bar.y = (background.y + 10) + ((background.height - bar.height - 20) * v);
        return v;
    }

    inline function get_percent():Float {
        return (bar.y - background.y - 10) / (background.height - bar.height - 20);
    }
}