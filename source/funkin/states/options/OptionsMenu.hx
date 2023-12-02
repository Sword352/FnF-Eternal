package funkin.states.options;

import flixel.FlxSubState;

import flixel.text.FlxText;
import flixel.addons.display.FlxBackdrop;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

import flixel.group.FlxGroup.FlxTypedGroup;

import funkin.states.menus.MainMenu;

typedef OptionCategory = {
    var name:String;
    var action:Void->Void;
    var ?skipOutro:Bool;
}

class OptionsMenu extends MusicBeatState {
    public var bg:FlxSprite;
    var categoryTexts:FlxTypedGroup<FlxText>;
    var checkerBackdrop:FlxBackdrop;

    var categories:Array<OptionCategory>;
    var currentSelection:Int = 0;
    var toPlayState:Bool;

    #if ENGINE_SCRIPTING
    var overrideCode:Bool = false;
    #end

    public function new(toPlayState:Bool = false):Void {
        super();
        this.toPlayState = toPlayState;
    }

    override function create():Void {
        super.create();

        #if ENGINE_SCRIPTING
        initStateScript();
        hxsCall("onCreate");

        if (overrideCode) {
            hxsCall("onCreatePost");
            return;
        }
        #end
          
        categories = [
            {name: "General", action: goToGeneral},
            {name: "Gameplay", action: goToGameplay},
            {name: "Keybinds", action: goToKeybind},
            {name: "Adjust offset", action: goToOffset},
            {name: "Debug", action: goToDebug},
            {name: "Exit", action: exit, skipOutro: true},
        ];

        #if ENGINE_MODDING
        if (Settings.modSettings.length > 0)
            categories.insert(4, {name: (Mods.currentMod.title ?? Mods.currentMod.folder), action: goToModOptions});
        #end

        AssetHelper.clearAssets = !toPlayState;

        #if ENGINE_DISCORD_RPC
        DiscordPresence.presence.state = "(in-dev)";
        DiscordPresence.presence.details = "In the options";
        #end

        Tools.playMusicCheck(toPlayState ? "chillFresh" : "freakyMenu");
        Conductor.bpm = 102;

		bg = new FlxSprite(0, 0, AssetHelper.image('menus/menuDesat'));
        bg.scale.set(1.15, 1.15);
		bg.screenCenter();
        bg.color = 0x3E3E7A;
		add(bg);

        checkerBackdrop = new FlxBackdrop(AssetHelper.image("menus/checkboard"));
        checkerBackdrop.color = 0xFF120E7A;
        checkerBackdrop.alpha = 0.4;
        checkerBackdrop.velocity.x = 50;
        add(checkerBackdrop);

        categoryTexts = new FlxTypedGroup<FlxText>();
        add(categoryTexts);

        for (i in 0...categories.length) {
            var categoryText:FlxText = new FlxText(50, 150 + 100 * i, 0, categories[i].name.toUpperCase());
            categoryText.setFormat(AssetHelper.font('vcr'), 54);
            categoryText.setBorderStyle(OUTLINE, FlxColor.BLACK, 4);
            categoryText.ID = i;
            categoryTexts.add(categoryText);
        }
        
        changeSelection();

        #if ENGINE_SCRIPTING
        hxsCall("onCreatePost");
        #end
    }

    var allowInputs:Bool = true;
    var inputHoldTime:Float = 0;

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

        var ratio:Float = FlxMath.bound(elapsed * 6, 0, 1);
        bg.scale.set(FlxMath.lerp(bg.scale.x, 1, ratio), FlxMath.lerp(bg.scale.y, 1, ratio));

        for (text in categoryTexts)
            text.y = FlxMath.lerp(text.y, 150 + 100 * text.ID, FlxMath.bound(elapsed * 12, 0, 1));

        if (allowInputs && controls.anyJustPressed(["up", "down"])) {
            changeSelection(controls.lastAction == "up" ? -1 : 1);
            inputHoldTime = 0;
        }

        if (allowInputs && controls.anyPressed(["up", "down"])) {
            inputHoldTime += 1 * elapsed;
            if (inputHoldTime > 0.75) {
                changeSelection(controls.lastAction == "up" ? -1 : 1);
                inputHoldTime -= 15 * elapsed;
            }
        }

        if (allowInputs && controls.justPressed("back")) {
            allowInputs = false;
            exit();
        }

        if (allowInputs && controls.justPressed("accept")) {
            allowInputs = false;
            accept();
        }

        if (allowInputs && FlxG.mouse.wheel != 0)
            changeSelection(Std.int(FlxMath.bound(-FlxG.mouse.wheel, -1, 1)));

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

        categoryTexts.forEach((text) -> {
            text.ID = categoryTexts.members.indexOf(text) - currentSelection;
            text.alpha = (text.ID == 0) ? 1 : 0.6;
        });

        if (i != 0)
            FlxG.sound.play(AssetHelper.sound("scrollMenu"));

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

        FlxG.sound.play(AssetHelper.sound("confirmMenu"));

        for (text in categoryTexts)
            FlxTween.tween(text, {x: -text.width}, 0.75, {ease: FlxEase.circInOut});

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
        FlxG.sound.play(AssetHelper.sound("cancelMenu"));
        FlxG.switchState((toPlayState) ? new PlayState() : new MainMenu());
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
        
        allowInputs = true;

        if (!skipOutro(categories[currentSelection]))
            for (text in categoryTexts)
                FlxTween.tween(text, {x: 50}, 0.75, {ease: FlxEase.circInOut});
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
        return category.skipOutro != null && category.skipOutro;
    }
}