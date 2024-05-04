package objects;

import flixel.math.FlxPoint;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;

class HealthIcon extends OffsetSprite {
    public static final DEFAULT_ICON:String = "face";

    public var state(default, set):HealthState = "neutral";
    public var character(get, set):String;

    public var healthAnim:Bool = true;
    public var bopping:Bool = false;

    public var bopIntensity:Float = 0.2;
    public var bopSpeed:Float = 15;
    
    var storedScale:FlxPoint = FlxPoint.get(1, 1);
    var storedOffsets:FlxPoint = FlxPoint.get();
    var animOffsets:FlxPoint = FlxPoint.get();
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
            scale.set(Tools.lerp(scale.x, storedScale.x, bopSpeed), Tools.lerp(scale.y, storedScale.y, bopSpeed));
            offset.x = 50 * _facingHorizontalMult * (scale.x - storedScale.x);
            offset.y = -height * ((scale.y - storedScale.x) * 0.35);
            offset.addPoint(storedOffsets);
            offset.addPoint(animOffsets);
        }

        super.update(elapsed);
    }

    public inline function bop():Void {
        if (bopping)
            scale.add(bopIntensity, bopIntensity);
    }

    override function destroy():Void {
        storedOffsets = FlxDestroyUtil.put(storedOffsets);
        animOffsets = FlxDestroyUtil.put(animOffsets);
        storedScale = FlxDestroyUtil.put(storedScale);

        _character = null;
        state = null;

        super.destroy();
    }

    public function changeIcon(icon:String):Void {
        var configPath:String = Assets.yaml('images/icons/${icon}');
        _character = icon;

        if (!FileTools.exists(configPath))
            changeSimple(icon);
        else
            changeAdvanced(Tools.parseYAML(FileTools.getContent(configPath)));

        playAnimation("neutral", true);
    }

    function changeAdvanced(config:HealthIconConfig):Void {
        var possibleFrames:FlxAtlasFrames = Assets.findFrames('icons/${character}');

        if (possibleFrames != null)
            frames = possibleFrames;
        else {
            var newGraphic:FlxGraphic = Assets.image('icons/${character}');
            if (newGraphic == null) newGraphic = Assets.image('icons/${DEFAULT_ICON}');
            loadGraphic(newGraphic, true, Math.floor(newGraphic.width / (config.size ?? 2)), newGraphic.height);
        }

        resetValues();

        Tools.addYamlAnimations(this, config.animations);
        scale.set(config.scale == null ? 1 : (config.scale[0] ?? 1), config.scale == null ? 1 : (config.scale[1] ?? 1));
        updateHitbox();

        var offsetX:Float = -(config.globalOffsets != null ? (config.globalOffsets[0] ?? 0) : 0);
        var offsetY:Float = -(config.globalOffsets != null ? (config.globalOffsets[1] ?? 0) : 0);
        offset.add(offsetX, offsetY);

        antialiasing = config.antialiasing ?? FlxSprite.defaultAntialiasing;
        storedOffsets.set(offset.x, offset.y);
        storedScale.set(scale.x, scale.y);
    }

    function changeSimple(icon:String):Void {
        var newGraphic:FlxGraphic = Assets.image('icons/${icon}');
        if (newGraphic == null) {
            newGraphic = Assets.image('icons/${DEFAULT_ICON}');
            _character = DEFAULT_ICON;
        }

        var size:Int = findSize(icon);
        loadGraphic(newGraphic, true, Math.floor(newGraphic.width / size), newGraphic.height);
        for (i in 0...size) animation.add([NEUTRAL, LOSING, WINNING][i], [i], 0);

        scale.set(1, 1);
        updateHitbox();
        resetValues();
    }

    function resetValues():Void {
        antialiasing = FlxSprite.defaultAntialiasing;
        animationOffsets.clear();
        storedScale.set(1, 1);
        storedOffsets.set();
        animOffsets.set();
    }

    override function playAnimation(name:String, force:Bool = false, reversed:Bool = false, frame:Int = 0) {
        super.playAnimation(name, force, reversed, frame);
        animOffsets.set(offset.x, offset.y);
        offset.addPoint(storedOffsets);
    }

    function set_state(v:HealthState):HealthState {
        if (v != null && exists && animation.exists(v) && animation.curAnim.name != v)
            playAnimation(v, true);

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

typedef HealthIconConfig = {
    var ?size:Int;
    var ?animations:Array<YAMLAnimation>;
    var ?globalOffsets:Array<Float>;

    var ?scale:Array<Float>;
    var ?antialiasing:Bool;
}

enum abstract HealthState(String) from String to String {
    var NEUTRAL = "neutral";
    var WINNING = "winning";
    var LOSING = "losing";
}
