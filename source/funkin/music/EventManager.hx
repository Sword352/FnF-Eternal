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
        }
    ];

    public var charactersMap(default, null):Map<String, Character> = [];
    
    #if ENGINE_SCRIPTING
    public var scriptsMap(default, null):Map<String, HScript> = [];
    #end

    public var loadedEvents(default, null):Array<ChartEvent> = [];
    public var game(default, null):PlayState;

    public function new(game:PlayState):Void {
        this.game = game;
        super();
    }

    override function update(elapsed:Float):Void {
        while (loadedEvents.length > 0 && Conductor.position >= loadedEvents[0].time)
            runEvent(loadedEvents.shift());
    }

    public function loadEvents(events:Array<ChartEvent>):Void {
        if (events.length < 1)
            return;
        
        loadedEvents = events.copy();
        loadedEvents.sort((e1, e2) -> FlxSort.byValues(FlxSort.ASCENDING, e1.time, e2.time));

        var i:Int = 0;
        while (i < loadedEvents.length)
            runPreload(loadedEvents[i++]);
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

                game.noteSpawnTime = 1800 / newSpeed;
            case "change camera target":
                game.changeCameraTarget(event.arguments[0]);
            case "change bpm":
                Conductor.bpm = event.arguments[0];
                Conductor.resetPreviousPosition();
            #if ENGINE_SCRIPTING
            case "custom event":
                var name:String = event.arguments[0];
                var args:Array<Any> = event.arguments[1];

                if (!scriptsMap.exists(name))
                    trace('Event script "${name}" was not found!');
                else {
                    var script:HScript = scriptsMap.get(name);
                    script.set("triggered", true);
                    script.call("onEvent", [event, args]);
                }
            #end
            default:
        }

        #if ENGINE_SCRIPTING
        game.hxsCall("onEventTriggerPost", [event]);
        #end
    }

    public function runPreload(event:ChartEvent):Void {
        event.time -= Conductor.offset;

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
            #if ENGINE_SCRIPTING
            case "custom event":
                var name:String = event.arguments[0];
                if (!scriptsMap.exists(name)) {
                    var script:HScript = new HScript(AssetHelper.getPath('data/events/${name}', SCRIPT));
                    if (script.state != ALIVE)
                        trace('Failed loading event script "${name}"!');
                    else {
                        game.addScript(script);
                        scriptsMap.set(name, script);
        
                        script.set("triggered", false);
                        script.call("onPreload", [event.arguments[1]]);   
                    }
                }
            #end
            default:
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

        loadedEvents = null;
        game = null;

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
        var path:String = AssetHelper.getPath("data/events", NONE);
        var exts:Array<String> = JSON.getExtensions();

        var list:Array<EventDetails> = defaultEvents.copy();

        if (FileTools.exists(path)) {
            for (file in FileTools.readDirectory(path)) {
                if (exts.contains(file.substring(file.indexOf("."))))
                    list.push(tjson.TJSON.parse(FileTools.getContent(path + "/" + file)));
            }
        }

        return [for (ev in list) (ev.display ?? ev.name) => ev];
    }
}

typedef EventDetails = {
    var name:String;
    var ?display:String;
    var ?description:String;
    var ?arguments:Array<{name:String, type:String, defaultValue:Dynamic, ?valueList:Array<String>}>;
}