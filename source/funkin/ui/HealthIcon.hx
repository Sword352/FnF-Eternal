package funkin.ui;

import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import funkin.objects.OffsetSprite;

class HealthIcon extends OffsetSprite {
    public static final DEFAULT_ICON:String = "face";

    public var state(default, set):HealthState = "neutral";
    public var character(get, set):String;

    public var size:FlxPoint = FlxPoint.get(150, 150);
    public var globalOffsets:FlxPoint = FlxPoint.get();
    public var healthAnim:Bool = true;

    public var bopSize:Float = 25;
    public var bopDuration:Float = 2;
    public var bopStep:Int = -1;
    
    var _character:String;

    public function new(x:Float = 0, y:Float = 0, icon:String = "face") {
        super(x, y);

        changeIcon(icon);
        moves = false;
    }

    override function update(elapsed:Float):Void {
        if (healthAnim)
            updateState();

        if (bopStep != -1) {
            var ratio:Float = FlxEase.sineOut(Math.min(Conductor.self.decStep - bopStep, bopDuration) / bopDuration);
            setGraphicSize(FlxMath.lerp(size.x + bopSize, size.x, ratio));
            updateHitbox();
        }

        super.update(elapsed);
    }

    function updateState():Void {
        var currentState:HealthState = state;

        switch (state) {
            case WINNING:
                if (health < 80)
                    state = NEUTRAL;
            case NEUTRAL:
                if (health > 80)
                    state = WINNING;
                else if (health < 20)
                    state = LOSING;
            case LOSING:
                if (health > 20)
                    state = NEUTRAL;
        }

        if (currentState != state) {
            // recursively calls this method to find the proper state
            updateState();
        }
    }

    public inline function bop():Void {
        bopStep = Conductor.self.step;
    }

    public function resetBop():Void {
        setGraphicSize(size.x, size.y);
        updateHitbox();
        bopStep = -1;
    }

    override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint {
        return super.getScreenPosition(result, camera).subtractPoint(globalOffsets);
    }

    override function destroy():Void {
        globalOffsets = FlxDestroyUtil.put(globalOffsets);
        size = FlxDestroyUtil.put(size);

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
        size.set(width, height);
    }

    function changeAdvanced(config:HealthIconConfig):Void {
        var possibleFrames:FlxAtlasFrames = Assets.findFrames('icons/${character}');

        if (possibleFrames != null)
            frames = possibleFrames;
        else {
            var newGraphic:FlxGraphic = Assets.image('icons/${character}');
            if (newGraphic == null) newGraphic = Assets.image('icons/${DEFAULT_ICON}');
            loadGraphic(newGraphic, true, Math.floor(newGraphic.width / (config.frames ?? Math.floor(newGraphic.width / newGraphic.height))), newGraphic.height);
        }

        resetValues();

        Tools.addYamlAnimations(this, config.animations);
        scale.set(config.scale == null ? 1 : (config.scale[0] ?? 1), config.scale == null ? 1 : (config.scale[1] ?? 1));
        updateHitbox();

        var offsetX:Float = (config.globalOffsets != null ? (config.globalOffsets[0] ?? 0) : 0);
        var offsetY:Float = (config.globalOffsets != null ? (config.globalOffsets[1] ?? 0) : 0);
        globalOffsets.set(offsetX, offsetY);

        antialiasing = config.antialiasing ?? FlxSprite.defaultAntialiasing;
    }

    function changeSimple(icon:String):Void {
        var newGraphic:FlxGraphic = Assets.image('icons/${icon}');
        if (newGraphic == null) {
            newGraphic = Assets.image('icons/${DEFAULT_ICON}');
            _character = DEFAULT_ICON;
        }

        var size:Int = Math.floor(newGraphic.width / newGraphic.height);
        loadGraphic(newGraphic, true, Math.floor(newGraphic.width / size), newGraphic.height);
        for (i in 0...size) animation.add([NEUTRAL, LOSING, WINNING][i], [i], 0);

        scale.set(1, 1);
        updateHitbox();
        resetValues();
    }

    function resetValues():Void {
        antialiasing = FlxSprite.defaultAntialiasing;
        globalOffsets.set();
        offsets.clear();
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
}

typedef HealthIconConfig = {
    var ?frames:Int;
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
