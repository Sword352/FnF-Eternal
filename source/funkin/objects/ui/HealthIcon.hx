package funkin.objects.ui;

import flixel.graphics.FlxGraphic;

class HealthIcon extends OffsetSprite {
    public static final animations:Array<String> = ["neutral", "losing", "winning"];

    public var state(default, set):String = "neutral";
    public var healthAnim:Bool = true;

    public var bopping:Bool = false;
    public var bopSpeed:Float = 13;
    public var bopIntensity:Float = 0.2;

    public var defaultScaleX:Float;
    public var defaultScaleY:Float;
    
    public function new(x:Float = 0, y:Float = 0, icon:String = "face") {
        super(x, y);
        changeIcon(icon);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);
        
        if (healthAnim) {
            if (health > 20) {
                if (health > 80 && state != "winning")
                    state = "winning";
                else if (health < 80 && state != "neutral")
                    state = "neutral";
            }
            else if (state != "losing")
                state = "losing";
        }
        
        if (bopping) {
            scale.set(Tools.lerp(scale.x, defaultScaleX, bopSpeed), Tools.lerp(scale.y, defaultScaleY, bopSpeed));
            updateHitbox();
        }
    }

    public function changeIcon(icon:String):Void {
        var newGraphic:FlxGraphic = Assets.image('icons/${icon}');
        if (newGraphic == null)
            newGraphic = Assets.image('icons/face');

        var size:Int = findSize(icon);
        loadGraphic(newGraphic, true, Std.int(newGraphic.width / size), newGraphic.height);
        
        for (i in 0...size)
            animation.add(animations[i], [i], 0);

        animation.play("neutral", true);
        defaultScaleX = scale.x;
        defaultScaleY = scale.y;
    }

    public function bop():Void {
        if (bopping)
            scale.add(bopIntensity, bopIntensity);
    }

    override function destroy():Void {
        super.destroy();
        state = null;
    }

    function set_state(v:String):String {
        if (v != null && exists && animation.exists(v) && animation.curAnim.name != v)
            animation.play(v, true);

        return state = v;
    }

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