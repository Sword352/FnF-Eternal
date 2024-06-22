package states.options;

import flixel.sound.FlxSound;
import states.options.items.*;

class GeneralOptionSubState extends BaseOptionSubState {
    static var lastSound:Int = -1;

    var boyfriend:FlxSprite;
    var sound:FlxSound;

    override function create():Void {
        var option = new IntOptionItem("Framerate");
        option.description = "Defines the framerate cap.";
        option.maxValue = 480;
        option.minValue = 30;
        addOption(option);

        var option = new BoolOptionItem("Silent Soundtray");
        option.description = "If enabled, increasing/decreasing the volume won't play a sound.";
        addOption(option);

        var option = new BoolOptionItem("Show Framerate");
        option.description = "If enabled, show the framerate in the framerate overlay.";
        addOption(option);

        var option = new BoolOptionItem("Show Memory");
        option.description = "If enabled, show the memory usage in the framerate overlay.";
        addOption(option);

        var option = new BoolOptionItem("Show Overlay Background", "showFpsBg");
        option.description = "If enabled, show an opaque background behind the framerate overlay.";
        addOption(option);

        var option = new BoolOptionItem("Auto Pause");
        option.description = "Whether to pause the game when the window is unfocused.";
        addOption(option);

        var option = new BoolOptionItem("Disable Antialiasing", "noAntialiasing");
        option.description = "If enabled, disable antialiasing. Improves performance at the cost of sharper\nvisuals.";
        option.onChange = onChangeAntialiasing;
        addOption(option);

        #if ENGINE_DISCORD_RPC
        var option = new BoolOptionItem("Disable Discord RPC", "noDiscordRpc");
        option.description = "Whether to disable the Discord Rich Presence.";
        addOption(option);
        #end

        var option = new BoolOptionItem("Disable Flashing Lights", "noFlashingLights");
        option.description = "Whether to disable flashing lights. It is highly recommended to enable this\noption if you are epileptical!";
        addOption(option);

        boyfriend = new FlxSprite(0, 0, Assets.image("menus/options/options-bf"));
        boyfriend.scale.set(0.25, 0.25);
        boyfriend.updateHitbox();
        boyfriend.screenCenter();
        boyfriend.y += 150;

        super.create();
        add(boyfriend);

        sound = FlxG.sound.list.recycle(FlxSound);
        conductor.active = true;
    }

    override function update(elapsed:Float):Void {
        scripts.call("onUpdate", [elapsed]);
        superUpdate(elapsed);

        boyfriend.scale.set(Tools.lerp(boyfriend.scale.x, 0.25, 12), Tools.lerp(boyfriend.scale.y, 0.25, 12));

        if (boyfriend.visible && FlxG.mouse.overlaps(boyfriend) && FlxG.mouse.justPressed) {
            if (sound.playing) sound.stop();

            var selectedSound:Int = FlxG.random.int(1, 8, [lastSound]);
            lastSound = selectedSound;

            sound.loadEmbedded(Assets.sound('options/sound${selectedSound}')).play();
            boyfriend.scale.set(FlxG.random.float(0.3, 0.5), FlxG.random.float(0.3, 0.5));
        }

        scripts.call("onUpdatePost", [elapsed]);
    }

    function onChangeAntialiasing(i:Bool):Void
        boyfriend.antialiasing = !i;

    override function changeSelection(i:Int = 0) {
        super.changeSelection(i);
        FlxG.mouse.visible = boyfriend.visible = (optionsGroup.members[currentSelection].option == "noAntialiasing");
    }

    override function beatHit(beat:Int):Void {
        if (boyfriend != null)
            boyfriend.angle = (beat % 2 == 0) ? 20 : -20;

        super.beatHit(beat);
    }

    override function close():Void {
        FlxG.sound.list.remove(sound, true);
        sound.destroy();

        FlxG.mouse.visible = false;
        super.close();
    }
}
