package funkin.menus.options;

import flixel.FlxSubState;
import flixel.group.FlxSpriteGroup;

import funkin.ui.Alphabet;
import funkin.objects.CheckerboardBG;
import funkin.menus.MainMenu;

typedef OptionCategory = {
    var name:String;
    var action:Void->Void;
    var ?noSound:Bool;
}

class OptionsMenu extends MusicBeatState {
    public var background:FlxSprite;
    var backdrop:CheckerboardBG;
    var uiGroup:FlxSpriteGroup;

    var categories:Array<OptionCategory>;
    var currentSelection:Int = 0;
    var toPlayState:Bool;

    var allowInputs:Bool = true;

    public function new(toPlayState:Bool = false):Void {
        this.toPlayState = toPlayState;
        super();
    }

    override function create():Void {
        persistentUpdate = true;
        super.create();

        categories = [
            {name: "General", action: goToGeneral},
            {name: "Gameplay", action: goToGameplay},
            {name: "Adjust offset", action: goToOffset},
            {name: "Keybinds", action: goToKeybind},
            {name: "Debug", action: goToDebug},
            {name: "Exit", action: exit, noSound: true},
        ];

        #if ENGINE_SCRIPTING
        initStateScripts();
        scripts.call("onCreate");
        #end

        Assets.clearAssets = !toPlayState || Options.reloadAssets;

        #if ENGINE_DISCORD_RPC
        DiscordPresence.presence.details = "In the options";
        #end

        Tools.playMusicCheck(toPlayState ? "chillFresh" : "freakyMenu");
        conductor.bpm = (toPlayState ? 117 : 102);
        conductor.music = FlxG.sound.music;

        background = new FlxSprite(0, 0, Assets.image('menus/menuDesat'));
        background.scale.set(1.15, 1.15);
        background.color = 0x3E3E7A;
        background.screenCenter();
        add(background);

        backdrop = new CheckerboardBG(200, 200, 0xFF120E7A, FlxColor.TRANSPARENT);
        backdrop.velocity.x = 50;
        backdrop.alpha = 0.4;
        add(backdrop);

        uiGroup = new FlxSpriteGroup();
        add(uiGroup);

        for (i in 0...categories.length) {
            var image:String = 'menus/options/icon_${categories[i].name.toLowerCase().replace(" ", "-")}';
            if (!FileTools.exists(Assets.getPath('images/${image}', IMAGE)))
                image = 'menus/options/icon_default';

            var left:Bool = (i % 2 == 0);

            var categoryText:Alphabet = new Alphabet(FlxG.width * (left ? 0.1 : 0.9));
            categoryText.scale.set(0.7, 0.7);
            categoryText.text = categories[i].name;

            categoryText.screenCenter(Y);
            categoryText.y += 100 * Math.floor(((i + 1) / 2) - (categories.length / 2)) + (categoryText.height * 2);

            if (!left)
                categoryText.x -= categoryText.width;

            var icon:FlxSprite = new FlxSprite(0, categoryText.y, Assets.image(image));
            icon.scale.set(0.5, 0.5);
            icon.updateHitbox();
            add(icon);

            icon.x = (left ? categoryText.x - (icon.width + 10) : categoryText.x + categoryText.width + 10);
            icon.offset.y += icon.height * 0.25;
            categoryText.ID = icon.ID = i;

            uiGroup.add(categoryText);
            uiGroup.add(icon);
        }

        changeSelection();

        #if ENGINE_SCRIPTING
        scripts.call("onCreatePost");
        #end
    }

    override function update(elapsed:Float):Void {
        scripts.call("onUpdate", [elapsed]);
        super.update(elapsed);

        background.scale.set(Tools.lerp(background.scale.x, 1, 6), Tools.lerp(background.scale.y, 1, 6));

        if (allowInputs) {
            if (controls.anyJustPressed(["up", "down"])) changeSelection((controls.lastAction == "up") ? -2 : 2);

            if (controls.anyJustPressed(["left", "right"])) {
                var odd:Bool = (currentSelection % 2 == 0);
                var change:Int = (odd) ? 1 : -1;

                if (categories.length % 2 == 0 && ((odd && controls.lastAction == "right") || (!odd && controls.lastAction == "left")))
                    change += 2 * -change;

                changeSelection(change);
            }

            if (FlxG.mouse.wheel != 0)
                changeSelection(Std.int(FlxMath.bound(-FlxG.mouse.wheel, -1, 1)) * 2);

            if (controls.justPressed("back")) {
                allowInputs = false;
                exit();
            }

            if (controls.justPressed("accept")) {
                allowInputs = false;
                accept();
            }
        }

        #if ENGINE_SCRIPTING
        scripts.call("onUpdatePost", [elapsed]);
        #end
    }

    function changeSelection(i:Int = 0):Void {
        currentSelection = FlxMath.wrap(currentSelection + i, 0, categories.length - 1);
        uiGroup.forEach((element) -> element.alpha = (element.ID == currentSelection ? 1 : 0.4));

        if (i != 0)
            FlxG.sound.play(Assets.sound("scrollMenu"));
    }

    function accept():Void {
        #if ENGINE_SCRIPTING
        if (scripts.quickEvent("onAccept").cancelled) return;
        #end

        var category:OptionCategory = categories[currentSelection];
        if (!category.noSound) FlxG.sound.play(Assets.sound("scrollMenu"));
        category.action();
    }

    inline function goToGeneral():Void {
        openSubState(new GeneralOptionSubState());
    }

    inline function goToGameplay():Void {
        openSubState(new GameplayOptionSubState());
    }

    inline function goToKeybind():Void {
        openSubState(new KeybindSubState());
    }

    inline function goToOffset():Void {
        openSubState(new OffsetSubState());
    }

    inline function goToDebug():Void {
        openSubState(new DebugOptionSubState());
    }

    function exit():Void {
        FlxG.sound.play(Assets.sound("cancelMenu"));
        FlxG.switchState(toPlayState ? (Assets.clearAssets ? LoadingScreen.new.bind(0) : PlayState.new.bind(0)) : MainMenu.new);
    }

    override function onSubStateOpen(subState:FlxSubState):Void {
        if (uiGroup != null && !(subState is TransitionSubState))
            uiGroup.visible = false;

        super.onSubStateOpen(subState);
    }

    override function onSubStateClose(subState:FlxSubState):Void {
        if (subState is TransitionSubState) return;
        uiGroup.visible = allowInputs = true;

        super.onSubStateClose(subState);
    }

    override function destroy():Void {
        // removing the group ourselves because new flixel update broke options, not sure if it flixel's fault though...
        // TODO: investigate on why this happens
        remove(uiGroup, true);
        uiGroup.destroy();
        //

        categories = null;
        super.destroy();
    }
}