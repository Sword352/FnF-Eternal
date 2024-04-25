package funkin.gameplay;

import flixel.FlxBasic;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase.EaseFunction;

import funkin.states.PlayState;
import funkin.gameplay.Character;

#if ENGINE_SCRIPTING
import eternal.core.scripting.HScript;
#end
import funkin.globals.ChartFormat.ChartEvent;

// TODO: switch character int values to strings (0 -> "opponent", etc)
class EventManager extends FlxBasic {
    public static final defaultEvents:Array<EventDetails> = [
        {
            name: "Play Hey Anim",
            description: "Make a character play the \"hey\" animation",
            arguments: [
                {name: "Whos", type: INT, value: 0},
                {name: "Beat Duration", type: FLOAT, value: 1}
            ]
        },
        {
            name: "Change Character",
            description: "Change a character to another",
            arguments: [
                {name: "Whos", type: INT, value: 0},
                {name: "To", type: STRING, value: "?"}
            ]
        },
        {
            name: "Change Scroll Speed",
            description: "Change the strumlines note scroll speed to another",
            arguments: [
                {name: "New Speed", type: FLOAT, value: 1},
                {name: "Ease Duration", type: FLOAT, value: null},
                {
                    name: "Ease",
                    type: LIST,
                    value: "linear",
                    list: [
                        for (field in Type.getClassFields(FlxEase))
                            if (Reflect.isFunction(Reflect.field(FlxEase, field)))
                                field
                    ]
                }
            ]
        },
        {
            name: "Change Camera Target",
            description: "Change the character that the camera focus on",
            arguments: [{name: "Whos", type: INT, value: 0}]
        },
        {
            name: "Change BPM",
            description: "Change the song's beat per minutes",
            arguments: [{name: "New BPM", type: FLOAT, value: 100}]
        },
        {
            name: "Change Time Signature",
            description: "Change the song's time signature",
            arguments: [{name: "Steps per beat", type: INT, value: 4}]
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
                        FlxTween.tween(strumline, {scrollSpeed: newSpeed}, duration, {ease: getEase(event.arguments[2])});
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
                    var path:String = Assets.script('data/events/${event.event}');
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

    inline function getEase(ease:String):EaseFunction {
        if (ease == null) return FlxEase.linear;

        var field:Dynamic = Reflect.field(FlxEase, ease.trim());
        return (field == null || !Reflect.isFunction(field)) ? FlxEase.linear : cast field;
    }

    public static function getEventList():Map<String, EventDetails> {
        var path:String = Assets.getPath("data/events", NONE);
        var list:Array<EventDetails> = defaultEvents.copy();

        if (!FileTools.exists(path))
            return [for (ev in list) ev.name => ev];

        var exts:Array<String> = YAML.getExtensions();

        for (file in FileTools.readDirectory(path)) {
            var point:Int = file.indexOf(".");

            if (exts.contains(file.substring(point))) {
                var event:EventDetails = Tools.parseYAML(FileTools.getContent(path + "/" + file));
                if (event.name == null) event.name = file.substring(0, point);
                list.push(event);
            }
        }

        return [for (ev in list) ev.name => ev];
    }
}

typedef EventDetails = {
    var name:String;
    var ?description:String;
    var ?arguments:Array<EventArgument>;
}

typedef EventArgument = {
    var name:String;
    var type:EventValueType;
    var ?value:Dynamic;
    var ?step:Float;
    var ?min:Float;
    var ?max:Float;
    var ?list:Array<String>;
}

enum abstract EventValueType(String) from String to String {
    var STRING = "String";
    var FLOAT = "Float";
    var BOOL = "Bool";
    var INT = "Int";

    // extra types
    var LIST = "String(List)"; // allows you to select a string with whats provided
    var COLOR = "Int(Color)"; // spawns a color picker and returns an int
    var NUMBER = "Number"; // just the float type
}
