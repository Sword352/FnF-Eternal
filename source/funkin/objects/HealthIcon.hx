package funkin.objects;

import flixel.graphics.FlxGraphic;
import funkin.objects.OffsetSprite;

class HealthIcon extends OffsetSprite {
    public static final DEFAULT_ICON:String = "face";

    public var state(default, set):HealthState = "neutral";
    public var character(get, set):String;

    public var healthAnim:Bool = true;
    public var bopping:Bool = false;

    public var bopIntensity:Float = 0.2;
    public var bopSpeed:Float = 15;
    
    var _character:String;

    public function new(x:Float = 0, y:Float = 0, icon:String = "face") {
        super(x, y);

        changeIcon(icon);
        moves = false;
    }

    override function update(elapsed:Float):Void {
        if (healthAnim) {
            if (health > 20) {
                if (health > 80 && state != WINNING) state = WINNING;
                else if (health < 80 && state != NEUTRAL) state = NEUTRAL;
            }
            else if (state != LOSING) state = LOSING;
        }

        if (bopping) {
            scale.set(Tools.lerp(scale.x, 1, bopSpeed), Tools.lerp(scale.y, 1, bopSpeed));
            offset.x = 50 * _facingHorizontalMult * (scale.x - 1);
            offset.y = -height * ((scale.y - 1) * 0.35);
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
        loadGraphic(newGraphic, true, Math.floor(newGraphic.width / size), newGraphic.height);

        for (i in 0...size) animation.add([NEUTRAL, LOSING, WINNING][i], [i], 0);
        animation.play("neutral", true);
    }

    public inline function bop():Void {
        if (bopping)
            scale.add(bopIntensity, bopIntensity);
    }

    override function destroy():Void {
        _character = null;
        state = null;

        super.destroy();
    }

    inline function set_state(v:HealthState):HealthState {
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
        if (!FileTools.exists(path)) return 2;

        var value:Null<Int> = Std.parseInt(FileTools.getContent(path).trim());
        if (value == null || Math.isNaN(value)) return 2;

        return value;
    }
}

enum abstract HealthState(String) from String to String {
    var NEUTRAL = "neutral";
    var LOSING = "losing";
    var WINNING = "winning";
}