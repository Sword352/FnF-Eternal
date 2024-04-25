package funkin.states.options;

import flixel.sound.FlxSound;
import funkin.states.options.items.*;

class GeneralOptionSubState extends BaseOptionSubState {
    var boyfriend:FlxSprite;
    var sound:FlxSound;

    override function create():Void {
        var option = new IntOptionItem("framerate");
        option.description = "Defines the framerate cap.";
        option.maxValue = 480;
        option.minValue = 30;
        addOption(option);

        var option = new BoolOptionItem("silent soundtray");
        option.description = "If enabled, increasing/decreasing the volume won't play a sound.";
        addOption(option);

        var option = new BoolOptionItem("show framerate");
        option.description = "If enabled, show the framerate in the framerate overlay.";
        addOption(option);

        var option = new BoolOptionItem("show memory");
        option.description = "If enabled, show the memory usage in the framerate overlay.";
        addOption(option);

        var option = new BoolOptionItem("show overlay background");
        option.description = "If enabled, show an opaque background behind the framerate overlay.";
        addOption(option);

        var option = new BoolOptionItem("auto pause");
        option.description = "Whether to pause the game when the window is unfocused.";
        addOption(option);

        var option = new BoolOptionItem("disable antialiasing");
        option.description = "If enabled, disable antialiasing. Improves performance at the cost of\nsharper visuals.";
        option.onChange = onChangeAntialiasing;
        addOption(option);

        #if ENGINE_DISCORD_RPC
        var option = new BoolOptionItem("disable discord rpc");
        option.title = "Disable Discord RPC";
        option.description = "Whether to disable the Discord Rich Presence.";
        addOption(option);
        #end

        var option = new BoolOptionItem("disable flashing lights");
        option.description = "Whether to disable flashing lights. It is highly recommended to\nenable this option if you are epileptical!";
        addOption(option);

        sound = FlxG.sound.list.recycle(FlxSound);

        boyfriend = new FlxSprite();
        boyfriend.loadGraphic(Assets.image("menus/options/options-bf"));
        boyfriend.scale.set(0.25, 0.25);
        boyfriend.updateHitbox();
        boyfriend.screenCenter().y += 150;

        super.create();
        add(boyfriend);

        Conductor.music = FlxG.sound.music;
        Conductor.resetTime();
    }

    private static var lastSound:Int = -1;

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        boyfriend.scale.set(Tools.lerp(boyfriend.scale.x, 0.25, 12), Tools.lerp(boyfriend.scale.y, 0.25, 12));

        if (boyfriend.visible && FlxG.mouse.overlaps(boyfriend) && FlxG.mouse.justPressed) {
            if (sound.playing)
                sound.stop();

            var selectedSound:Int = FlxG.random.int(1, 8, [lastSound]);
            lastSound = selectedSound;

            sound.loadEmbedded(Assets.sound('options/sound${selectedSound}')).play();
            boyfriend.scale.set(FlxG.random.float(0.3, 0.5), FlxG.random.float(0.3, 0.5));
        }
    }

    function onChangeAntialiasing(i:Bool):Void
        boyfriend.antialiasing = !i;

    override function changeSelection(i:Int = 0) {
        super.changeSelection(i);
        FlxG.mouse.visible = boyfriend.visible = (optionsGroup.members[currentSelection].option == "disable antialiasing");
    }

    override function beatHit(currentBeat:Int):Void {
        if (boyfriend != null)
            boyfriend.angle = (currentBeat % 2 == 0) ? 20 : -20;

        super.beatHit(currentBeat);
    }

    override function close():Void {
        FlxG.sound.list.remove(sound, true);
        sound.destroy();

        Conductor.music = null;
        Conductor.resetTime();

        FlxG.mouse.visible = false;
        super.close();
    }
}
