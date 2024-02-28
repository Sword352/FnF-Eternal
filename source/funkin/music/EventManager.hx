package funkin.music;

import flixel.FlxBasic;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase.EaseFunction;

import funkin.states.PlayState;
import funkin.objects.Character;

#if ENGINE_SCRIPTING
import eternal.core.scripting.HScript;
#end
import eternal.ChartFormat.ChartEvent;

// TODO: switch character int values to strings (0 -> "opponent", etc)
class EventManager extends FlxBasic {
    public static final defaultEvents:Array<EventDetails> = [
        {
            name: "play hey anim",
            display: "Play Hey Anim",
            description: "Make a character play the \"hey\" animation",
            arguments: [
                {name: "Whos", type: "Int", defaultValue: 0},
                {name: "Beat Duration", type: "Float", defaultValue: 1}
            ]
        },
        {
            name: "change character",
            display: "Change Character",
            description: "Change a character to another",
            arguments: [
                {name: "Whos", type: "Int", defaultValue: 0},
                {name: "To", type: "String", defaultValue: "?"}
            ]
        },
        {
            name: "change scroll speed",
            display: "Change Scroll Speed",
            description: "Change the strumlines note scroll speed to another",
            arguments: [
                {name: "New Speed", type: "Float", defaultValue: 1},
                {name: "Ease Duration", type: "Float", defaultValue: null},
                {name: "Ease", type: "String", defaultValue: null}
            ]
        },
        {
            name: "change camera target",
            display: "Change Camera Target",
            description: "Change the character that the camera focus on",
            arguments: [{name: "Whos", type: "Int", defaultValue: 0}]
        },
        {
            name: "change bpm",
            display: "Change BPM",
            description: "Change the song's beat per minutes",
            arguments: [{name: "New BPM", type: "Float", defaultValue: 100}]
        },
        {
            name: "change time signature",
            display: "Change Time Signature",
            description: "Change the song's time signature",
            arguments: [{name: "Steps per beat", type: "Int", defaultValue: 4}]
        }
    ];

    public var events:Array<ChartEvent>;

    #if ENGINE_SCRIPTING
    var scriptsMap:Map<String, HScript> = [for (event in defaultEvents) event.name => null];
    #end

    var charactersMap:Map<String, Character> = [];

    var game(get, never):PlayState;
    inline function get_game():PlayState
        return PlayState.current;

    var lastBpmChange:Float = 0;
    var bpmOffset:Float = 0;

    var stepOffset:Float = 0;
    var beatOffset:Float = 0;
    var lastTS:Float = 0;

    public function new():Void {
        super();
        visible = false;
    }

    override function update(elapsed:Float):Void {
        while (events.length > 0 && Conductor.time >= events[0].time)
            runEvent(events.shift());
    }

    public inline function loadEvents(events:Array<ChartEvent>):Void {
        this.events = events.copy();
        this.events.sort((e1, e2) -> Std.int(e1.time - e2.time));

        var i:Int = 0;
        while (i < this.events.length)
            runPreload(this.events[i++]);
    }

    public function runEvent(event:ChartEvent):Void {
        game.stage.onEventTrigger(event);

        #if ENGINE_SCRIPTING
        game.hxsCall("onEventTrigger", [event]);
        #end

        switch (event.event.toLowerCase().trim()) {
            case "play hey anim":
                var character:Character = getCharacter(event.arguments[0]);
                if (character == null)
                    return;

                var beatDuration:Float = event.arguments[1] ?? 1;

                character.playAnimation("hey", true);
                character.animEndTime = (Conductor.crochet / 1000) * beatDuration;
            case "change character":
                var character:Character = getCharacter(event.arguments[0]);
                if (character == null)
                    return;

                var newCharacter:Character = charactersMap.get(event.arguments[1]);
                var oldAnim:String = character.animation.curAnim.name;

                character.setup(newCharacter.data);
                character.data = newCharacter.data;
                character.animationOffsets = newCharacter.animationOffsets;
                character.playAnimation(oldAnim);
            case "change scroll speed":
                var newSpeed:Float = event.arguments[0];
                var duration:Null<Float> = event.arguments[1];

                for (strumline in game.strumLines) {
                    if (duration != null && duration > 0)
                        FlxTween.tween(strumline, {scrollSpeed: newSpeed}, duration, {ease: getEaseFromString(event.arguments[2])});
                    else
                        strumline.scrollSpeed = newSpeed;
                }
            case "change camera target":
                game.changeCamTarget(event.arguments[0]);
            case "change bpm":
                bpmOffset += ((event.time - lastBpmChange) / Conductor.stepCrochet);
                lastBpmChange = event.time;

                Conductor.beatOffset.time = event.time;
                Conductor.beatOffset.step = bpmOffset;
                Conductor.bpm = event.arguments[0];
            case "change time signature":
                /*
                    stepOffset += ((event.time - lastTS) / Conductor.stepCrochet);
                    beatOffset += ((event.time - lastTS) / Conductor.crochet);
                    lastTS = event.time;

                    Conductor.beatOffset.step = stepOffset;
                    Conductor.beatOffset.beat = beatOffset;
                    Conductor.beatOffset.time = lastTS;

                    Conductor.stepsPerBeat = event.arguments[0];
                 */
            default:
                #if ENGINE_SCRIPTING
                // scripted event
                var script:HScript = scriptsMap.get(event.event);
                if (script != null) {
                    script.set("lastEvent", event);
                    script.set("triggered", true);
                    script.call("onEvent", event.arguments);
                }
                #end
        }

        #if ENGINE_SCRIPTING
        game.hxsCall("onEventTriggerPost", [event]);
        #end
    }

    public function runPreload(event:ChartEvent):Void {
        game.stage.onEventPreload(event);

        #if ENGINE_SCRIPTING
        game.hxsCall("onEventPreload", [event]);
        #end

        switch (event.event.toLowerCase().trim()) {
            case "change character":
                var whose:Int = event.arguments[0];
                var newCharacter:String = event.arguments[1];
                // preloading
                if (!charactersMap.exists(newCharacter))
                    charactersMap.set(newCharacter, new Character(0, 0, newCharacter, (whose == 2) ? PLAYER : DEFAULT));
            default:
                #if ENGINE_SCRIPTING
                if (!scriptsMap.exists(event.event)) {
                    var path:String = Assets.getPath('data/events/${event.event}', SCRIPT);
                    if (FileTools.exists(path)) {
                        var script:HScript = new HScript(path);
                        scriptsMap.set(event.event, script);
                        game.addScript(script);

                        script.set("triggered", false);
                        script.call("onPreload", event.arguments);
                    }
                    else {
                        // no warning since you can code events outside of event scripts
                        // trace('Failed loading event script "${event.event}"!');
                        scriptsMap.set(event.event, null);
                    }
                }
                #end
        }

        #if ENGINE_SCRIPTING
        game.hxsCall("onEventPreloadPost", [event]);
        #end
    }

    override function destroy():Void {
        if (charactersMap != null) {
            for (i in charactersMap)
                i.destroy();
            charactersMap = null;
        }

        events = null;

        #if ENGINE_SCRIPTING scriptsMap = null; #end

        super.destroy();
    }

    private static function getCharacter(index:Int):Character {
        return switch (index) {
            case 1: PlayState.current.spectator;
            case 2: PlayState.current.player;
            default: PlayState.current.opponent;
        }
    }

    private static function getEaseFromString(ease:String):EaseFunction {
        if (ease == null)
            return FlxEase.linear;

        return switch (ease.toLowerCase().trim()) {
            case 'backin': return FlxEase.backIn;
            case 'backinout': return FlxEase.backInOut;
            case 'backout': return FlxEase.backOut;
            case 'bouncein': return FlxEase.bounceIn;
            case 'bounceinout': return FlxEase.bounceInOut;
            case 'bounceout': return FlxEase.bounceOut;
            case 'circin': return FlxEase.circIn;
            case 'circinout': return FlxEase.circInOut;
            case 'circout': return FlxEase.circOut;
            case 'cubein': return FlxEase.cubeIn;
            case 'cubeinout': return FlxEase.cubeInOut;
            case 'cubeout': return FlxEase.cubeOut;
            case 'elasticin': return FlxEase.elasticIn;
            case 'elasticinout': return FlxEase.elasticInOut;
            case 'elasticout': return FlxEase.elasticOut;
            case 'expoin': return FlxEase.expoIn;
            case 'expoinout': return FlxEase.expoInOut;
            case 'expoout': return FlxEase.expoOut;
            case 'quadin': return FlxEase.quadIn;
            case 'quadinout': return FlxEase.quadInOut;
            case 'quadout': return FlxEase.quadOut;
            case 'quartin': return FlxEase.quartIn;
            case 'quartinout': return FlxEase.quartInOut;
            case 'quartout': return FlxEase.quartOut;
            case 'quintin': return FlxEase.quintIn;
            case 'quintinout': return FlxEase.quintInOut;
            case 'quintout': return FlxEase.quintOut;
            case 'sinein': return FlxEase.sineIn;
            case 'sineinout': return FlxEase.sineInOut;
            case 'sineout': return FlxEase.sineOut;
            case 'smoothstepin': return FlxEase.smoothStepIn;
            case 'smoothstepinout': return FlxEase.smoothStepInOut;
            case 'smoothstepout': return FlxEase.smoothStepInOut;
            case 'smootherstepin': return FlxEase.smootherStepIn;
            case 'smootherstepinout': return FlxEase.smootherStepInOut;
            case 'smootherstepout': return FlxEase.smootherStepOut;
            default: FlxEase.linear;
        };
    }

    public static function getEventList():Map<String, EventDetails> {
        var path:String = Assets.getPath("data/events", NONE);
        var exts:Array<String> = JSON.getExtensions();

        var list:Array<EventDetails> = defaultEvents.copy();

        if (FileTools.exists(path)) {
            for (file in FileTools.readDirectory(path)) {
                if (exts.contains(file.substring(file.indexOf("."))))
                    list.push(haxe.Json.parse(FileTools.getContent(path + "/" + file)));
            }
        }

        return [for (ev in list) (ev.display ?? ev.name) => ev];
    }
}

typedef EventDetails = {
    var name:String;
    var ?display:String;
    var ?description:String;
    var ?arguments:Array<{
        name:String,
        type:String,
        defaultValue:Dynamic,
        ?valueList:Array<String>
    }>;
}
