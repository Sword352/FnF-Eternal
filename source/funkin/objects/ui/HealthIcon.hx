package funkin.objects.ui;

import flixel.graphics.FlxGraphic;
import funkin.objects.sprites.OffsetSprite;

class HealthIcon extends OffsetSprite {
    public static final animations:Array<String> = ["neutral", "losing", "winning"];
    public static final DEFAULT_ICON:String = "face";

    public var state(default, set):String = "neutral";
    public var healthAnim:Bool = true;

    public var bopping:Bool = false;
    public var bopIntensity:Float = 0.2;
    public var bopSpeed:Float = 10;

    public var defaultScaleX:Float = 1;
    public var defaultScaleY:Float = 1;

    public var character(get, set):String;
    var _character:String;

    public function new(x:Float = 0, y:Float = 0, icon:String = "face") {
        super(x, y);

        changeIcon(icon);
        moves = false;
    }

    override function update(elapsed:Float):Void {
        if (healthAnim) {
            if (health > 20) {
                if (health > 80 && state != "winning")
                    state = "winning";
                else if (health < 80 && state != "neutral")
                    state = "neutral";
            } else if (state != "losing")
                state = "losing";
        }

        if (bopping) {
            scale.set(Tools.lerp(scale.x, defaultScaleX, bopSpeed), Tools.lerp(scale.y, defaultScaleY, bopSpeed));
            centerOrigin();
        }

        super.update(elapsed);
    }

    public function changeIcon(icon:String):Void {
        var newGraphic:FlxGraphic = Assets.image('icons/${icon}');
        _character = icon;

        if (newGraphic == null) {
            newGraphic = Assets.image('icons/${DEFAULT_ICON}');
            _character = DEFAULT_ICON;
        }

        var size:Int = findSize(icon);
        loadGraphic(newGraphic, true, Std.int(newGraphic.width / size), newGraphic.height);

        for (i in 0...size)
            animation.add(animations[i], [i], 0);

        animation.play("neutral", true);
    }

    public function bop():Void {
        if (bopping)
            scale.add(bopIntensity, bopIntensity);
    }

    override function destroy():Void {
        _character = null;
        state = null;

        super.destroy();
    }

    inline function set_state(v:String):String {
        if (v != null && exists && animation.exists(v) && animation.curAnim.name != v)
            animation.play(v, true);

        return state = v;
    }

    inline function set_character(v:String):String {
        changeIcon(v);
        return v;
    }

    inline function get_character():String
        return _character;

    inline static function findSize(icon:String):Int {
        var path:String = Assets.txt('images/icons/${icon}');
        if (!FileTools.exists(path))
            return 2;

        var value:Null<Int> = Std.parseInt(FileTools.getContent(path).trim());
        if (value == null || Math.isNaN(value))
            return 2;

        return value;
    }
}
