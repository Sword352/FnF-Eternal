package funkin.states.options;

import flixel.FlxSubState;
import flixel.group.FlxSpriteGroup;

import funkin.objects.ui.Alphabet;
import funkin.objects.sprites.CheckerboardBG;
import funkin.states.menus.MainMenu;

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

    #if ENGINE_SCRIPTING
    var overrideCode:Bool = false;
    #end

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

        #if ENGINE_MODDING
        if (Settings.modSettings.length > 0)
            categories.insert(4, {name: (Mods.currentMod.title ?? Mods.currentMod.id), action: goToModOptions});
        #end

        #if ENGINE_SCRIPTING
        initStateScript();
        hxsCall("onCreate");

        if (overrideCode) {
            hxsCall("onCreatePost");
            return;
        }
        #end

        Assets.clearAssets = !toPlayState || Settings.get("reload assets");

        #if ENGINE_DISCORD_RPC
        DiscordPresence.presence.details = "In the options";
        #end

        Tools.playMusicCheck(toPlayState ? "chillFresh" : "freakyMenu");
        Conductor.bpm = (toPlayState ? 117 : 102);

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
        hxsCall("onCreatePost");
        #end
    }

    override function update(elapsed:Float):Void {
        #if ENGINE_SCRIPTING
        hxsCall("onUpdate", [elapsed]);
        super.update(elapsed);

        if (overrideCode) {
            hxsCall("onUpdatePost", [elapsed]);
            return;
        }
        #else
        super.update(elapsed);
        #end

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
        hxsCall("onUpdatePost", [elapsed]);
        #end
    }

    inline function changeSelection(i:Int = 0):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onSelectionChange", [i]))
            return;
        #end

        currentSelection = FlxMath.wrap(currentSelection + i, 0, categories.length - 1);
        uiGroup.forEach((element) -> element.alpha = (element.ID == currentSelection ? 1 : 0.4));

        if (i != 0)
            FlxG.sound.play(Assets.sound("scrollMenu"));

        #if ENGINE_SCRIPTING
        hxsCall("onSelectionChangePost", [i]);
        #end
    }

    inline function accept():Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onAccept"))
            return;
        #end

        var category:OptionCategory = categories[currentSelection];
        if (!category.noSound) FlxG.sound.play(Assets.sound("scrollMenu"));
        category.action();

        #if ENGINE_SCRIPTING
        hxsCall("onAcceptPost");
        #end
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

    #if ENGINE_MODDING
    inline function goToModOptions():Void {
        openSubState(new ModOptionSubState());
    }
    #end

    inline function goToDebug():Void {
        openSubState(new DebugOptionSubState());
    }

    inline function exit():Void {
        FlxG.sound.play(Assets.sound("cancelMenu"));
        FlxG.switchState(toPlayState ? (Assets.clearAssets ? LoadingScreen.new.bind(0) : PlayState.new.bind(0)) : MainMenu.new);
    }

    override function openSubState(subState:FlxSubState):Void {
        if (uiGroup != null && !(subState is TransitionSubState)) uiGroup.visible = false;
        super.openSubState(subState);
    }

    override function closeSubState():Void {
        var transition:Bool = (subState is TransitionSubState);
        super.closeSubState();

        if (!transition) {
            uiGroup.visible = true;
            allowInputs = true;
        }
    }

    override function destroy():Void {
        categories = null;
        super.destroy();
    }
}
