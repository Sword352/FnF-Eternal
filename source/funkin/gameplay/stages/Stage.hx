package funkin.gameplay.stages;

import flixel.FlxBasic;
import funkin.states.PlayState;
import funkin.globals.ChartFormat.ChartEvent;

class Stage extends FlxBasic {
    public var sprites:Array<FlxSprite> = [];
    public var uiStyle:String = "";

    var game(get, never):PlayState;
    inline function get_game():PlayState
        return PlayState.current;

    var opponent(get, never):Character;
    inline function get_opponent():Character
        return game.opponent;

    var player(get, never):Character;
    inline function get_player():Character
        return game.player;

    var spectator(get, never):Character;
    inline function get_spectator():Character
        return game.spectator;

    var camSpeed(get, set):Float;
    inline function get_camSpeed():Float return game.cameraSpeed;
    inline function set_camSpeed(v):Float return game.cameraSpeed = v;

    var camZoom(get, set):Float;
    inline function get_camZoom():Float return game.cameraZoom;
    inline function set_camZoom(v):Float return game.cameraZoom = game.camGame.zoom = v;

    var hudZoom(get, set):Float;
    inline function get_hudZoom():Float return game.hudZoom;
    inline function set_hudZoom(v):Float return game.hudZoom = game.camHUD.zoom = v;

    var camBeatZoom(get, set):Float;
    inline function get_camBeatZoom():Float return game.camBeatZoom;
    inline function set_camBeatZoom(v):Float return game.camBeatZoom = v;

    var hudBeatZoom(get, set):Float;
    inline function get_hudBeatZoom():Float return game.hudBeatZoom;
    inline function set_hudBeatZoom(v):Float return game.hudBeatZoom = v;

    var beatZoomInterval(get, set):Float;
    inline function get_beatZoomInterval():Float return game.beatZoomInterval;
    inline function set_beatZoomInterval(v):Float return game.beatZoomInterval = v;

    public function new():Void {
        super();
        visible = false;

        create();
    }

    public function create():Void {}
    override function update(elapsed:Float):Void {
        super.update(elapsed);
    }

    public function createPost():Void {}
    public function updatePost(elapsed:Float):Void {}

    public function stepHit(currentStep:Int):Void {}
    public function beatHit(currentBeat:Int):Void {}
    public function measureHit(currentMeasure:Int):Void {}

    public function onSongStart():Void {}
    public function onSongEnd():Void {}

    public function onCountdownTick(loop:Int):Void {}
    public function onCamFocusChange(target:Int):Void {}

    public function onEventTrigger(event:ChartEvent):Void {}
    public function onEventPreload(event:ChartEvent):Void {}

    public inline function add(sprite:FlxSprite):FlxSprite {
        sprites.push(sprite);
        game.add(sprite);
        return sprite;
    }

    public inline function insert(pos:Int, sprite:FlxSprite):FlxSprite {
        sprites.insert(pos, sprite);
        game.insert(pos, sprite);
        return sprite;
    }

    public inline function remove(sprite:FlxSprite, splice:Bool = false):FlxSprite {
        game.remove(sprite, splice);
        return sprite;
    }

    public inline function addInFront(sprite:FlxSprite, front:FlxSprite):FlxSprite
        return insert(game.members.indexOf(front) + 1, sprite);

    public inline function addBehind(sprite:FlxSprite, behind:FlxSprite):FlxSprite
        return insert(game.members.indexOf(behind), sprite);

    public inline function forEach(func:FlxSprite->Void, ?validateFunc:FlxSprite->Bool):Void {
        for (sprite in sprites) {
            if (validateFunc == null || validateFunc(sprite))
                func(sprite);
        }
    }

    override function destroy():Void {
        uiStyle = null;
        sprites = null;
        super.destroy();
    }
}
