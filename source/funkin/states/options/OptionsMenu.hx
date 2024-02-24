package funkin.states.options;

import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

import funkin.objects.ui.Alphabet;
import funkin.objects.sprites.CheckerboardBG;

import funkin.states.menus.MainMenu;

typedef OptionCategory = {
    var name:String;
    var action:Void->Void;
    var ?skipOutro:Bool;
}

class OptionsMenu extends MusicBeatState {
    public var background:FlxSprite;
    var backdrop:CheckerboardBG;

    var categoryTexts:FlxTypedGroup<Alphabet>;
    var categoryIcons:Array<FlxSprite> = [];

    var categories:Array<OptionCategory>;
    var currentSelection:Int = 0;
    var toPlayState:Bool;

    var allowInputs:Bool = true;

    #if ENGINE_SCRIPTING
    var overrideCode:Bool = false;
    #end

    public function new(toPlayState:Bool = false):Void {
        super();
        this.toPlayState = toPlayState;
    }

    override function create():Void {
        super.create();

        categories = [
            {name: "General", action: goToGeneral},
            {name: "Gameplay", action: goToGameplay},
            {name: "Adjust offset", action: goToOffset},
            {name: "Keybinds", action: goToKeybind},
            {name: "Debug", action: goToDebug},
            {name: "Exit", action: exit, skipOutro: true},
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

        Tools.playMusicCheck((toPlayState) ? "chillFresh" : "freakyMenu");
        Conductor.bpm = (toPlayState) ? 117 : 102;

		background = new FlxSprite(0, 0, Assets.image('menus/menuDesat'));
        background.scale.set(1.15, 1.15);
		background.screenCenter();
        background.color = 0x3E3E7A;
		add(background);

        backdrop = new CheckerboardBG(200, 200, 0xFF120E7A, FlxColor.TRANSPARENT);
        backdrop.alpha = 0.4;
        backdrop.velocity.x = 50;
        add(backdrop);

        categoryTexts = new FlxTypedGroup<Alphabet>();
        add(categoryTexts);

        for (i in 0...categories.length) {
            var image:String = 'menus/options/icon_${categories[i].name.toLowerCase().replace(" ", "-")}';
            if (!FileTools.exists(Assets.getPath('images/${image}', IMAGE)))
                image = 'menus/options/icon_default';

            var left:Bool = (i % 2 == 0);

            var categoryText:Alphabet = new Alphabet(FlxG.width * ((left) ? 0.1 : 0.9));
            categoryText.scale.set(0.7, 0.7);
            categoryText.text = categories[i].name;
            categoryText.ID = i;
            categoryTexts.add(categoryText);

            categoryText.screenCenter(Y);
            categoryText.y += 100 * Math.floor(((i + 1) / 2) - (categories.length / 2)) + (categoryText.height * 2);

            if (!left)
                categoryText.x -= categoryText.width;

            var icon:FlxSprite = new FlxSprite(0, 0, Assets.image(image));
            icon.scale.set(0.5, 0.5);
            icon.updateHitbox();
            icon.offset.y += icon.height * 0.25;
            icon.ID = i;
            add(icon);

            categoryText.spriteTrackers.set(icon, (left) ? LEFT : RIGHT);
            categoryIcons.push(icon);
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

        background.scale.set(
            Tools.lerp(background.scale.x, 1, 6),
            Tools.lerp(background.scale.y, 1, 6)
        );

        if (allowInputs) {
            // TODO: perhaps better inputs, this should be good for now
            if (controls.anyJustPressed(["up", "down"]))      
                changeSelection((controls.lastAction == "up") ? -2 : 2);

            if (controls.anyJustPressed(["left", "right"])) {
                var odd:Bool = (currentSelection % 2 == 0);
                var change:Int = (odd) ? 1 : -1;

                if (categories.length % 2 == 0 && ((odd && controls.lastAction == "right") || (!odd && controls.lastAction == "left")))
                    change += 2 * ((odd) ? -1 : 1);

                // changeSelection((odd) ? 1 : -1);
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

    private function changeSelection(i:Int = 0):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onSelectionChange", [i]))
            return;
        #end

        currentSelection = FlxMath.wrap(currentSelection + i, 0, categories.length - 1);
        categoryTexts.forEach((text) -> text.alpha = (text.ID == currentSelection) ? 1 : 0.6);

        for (icon in categoryIcons)
            icon.alpha = (icon.ID == currentSelection) ? 1 : 0.6;

        if (i != 0)
            FlxG.sound.play(Assets.sound("scrollMenu"));

        #if ENGINE_SCRIPTING
        hxsCall("onSelectionChangePost", [i]);
        #end
    }

    private function accept():Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onAccept"))
            return;
        #end

        var currentCategory:OptionCategory = categories[currentSelection];
        if (skipOutro(currentCategory)) {
            currentCategory.action();
            return;
        }

        FlxG.sound.play(Assets.sound("confirmMenu"));

        for (text in categoryTexts)
            FlxTween.tween(text, {x: ((text.ID % 2 == 0) ? -(text.width + 15) : FlxG.width)}, 0.75, {ease: FlxEase.circInOut});

        new FlxTimer().start(0.85, (_) -> categories[currentSelection].action());

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
        FlxG.switchState((toPlayState) ? PlayState.new.bind(0) : MainMenu.new);
    }

    override function openSubState(subState:FlxSubState):Void {
        super.openSubState(subState);
        persistentUpdate = true;
    }

    override function closeSubState():Void {
        var transition:Bool = (subState is TransitionSubState);
        super.closeSubState();

        if (transition)
            return;

        if (!skipOutro(categories[currentSelection])) {
            for (text in categoryTexts) {
                var left:Bool = (text.ID % 2 == 0);
                FlxTween.tween(text, {x: FlxG.width * ((left) ? 0.1 : 0.9) - ((left) ? 0 : text.width)}, 0.75, {ease: FlxEase.circInOut});
            }
        }
        
        allowInputs = true;
    }

    override function destroy():Void {
        if (toPlayState)
            Tools.stopMusic();

        categories = null;
        super.destroy();
    }

    private function skipOutro(category:OptionCategory):Bool {
        #if ENGINE_SCRIPTING
        var possibleValue:Dynamic = hxsCall("skipOutro", [category]);
        if (possibleValue != null && possibleValue is Bool)
            return possibleValue;
        #end

        return category.skipOutro ?? false;
    }
}