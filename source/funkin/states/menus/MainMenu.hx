package funkin.states.menus;

import flixel.FlxObject;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.effects.FlxFlicker;

import flixel.math.FlxPoint;
import flixel.util.FlxSort;

import funkin.objects.Camera;
import funkin.states.options.OptionsMenu;

class MainMenu extends MusicBeatState {
    static var lastSelection:Int = 0;

    var itemList:Array<String> = ["story mode", "freeplay", "options"];

    var background:FlxSprite;
    var flicker:FlxSprite;

    var items:FlxSpriteGroup;
    var itemOrder:Array<FlxSprite>;

    var cameraTarget:FlxObject;
    var bottomText:FlxText;

    var currentSelection:Int = 0;
    var allowInputs:Bool = true;

    var itemSpacing:Float = 145;
    var cameraSpeed:Float = 4.5;

    #if ENGINE_SCRIPTING
    var overrideCode:Bool = false;
    #end

    override function create():Void {
        #if ENGINE_DISCORD_RPC
        DiscordPresence.presence.details = "Main Menu";
        #end

        super.create();

        #if ENGINE_SCRIPTING
        initStateScript();
        hxsCall("onCreate");

        if (overrideCode) {
            hxsCall("onCreatePost");
            return;
        }
        #end

        Tools.playMusicCheck("freakyMenu");

        FlxG.cameras.reset(new Camera());

        background = new FlxSprite();
        background.loadGraphic(Assets.image("menus/menuBG"));
        background.scrollFactor.set(0, 0.17);
        background.scale.set(1.2, 1.2);
        background.updateHitbox();
        background.screenCenter();
        add(background);

        if (!Settings.get("disable flashing lights")) {
            flicker = new FlxSprite(0, 0, Assets.image("menus/menuDesat"));
            flicker.scrollFactor.set(0, background.scrollFactor.y);
            flicker.color = 0xFFfd719b;
            flicker.scale.set(1.2, 1.2);
            flicker.updateHitbox();
            flicker.screenCenter();
            flicker.visible = false;
            add(flicker);
        }

        var devState:String = "";
        if (Tools.devState.length > 0)
            devState = ' (${Tools.devState})';

        bottomText = new FlxText(5, 0, 0, #if ENGINE_MODDING 'Press ${controls.listKeys("open mods", " or ")} to open the mods menu\n' + #end
            'Eternal Engine v${Tools.gameVersion}${devState}');
        bottomText.setFormat(Assets.font("vcr"), 16);
        bottomText.setBorderStyle(OUTLINE, FlxColor.BLACK);
        bottomText.scrollFactor.set();
        bottomText.y = FlxG.height - bottomText.height;
        add(bottomText);

        items = new FlxSpriteGroup();
        items.scrollFactor.set();
        add(items);

        for (i in 0...itemList.length) {
            var item:FlxSprite = new FlxSprite();
            item.frames = Assets.getSparrowAtlas('menus/main/${itemList[i]}');
            item.animation.addByPrefix("normal", "basic", 24);
            item.animation.addByPrefix("selected", "white", 24);
            item.animation.play("normal", true);
            item.updateHitbox();
            item.screenCenter();
            item.y += itemSpacing * (i - itemList.length / 2) + 25;
            item.ID = i;
            items.add(item);
        }

        var midpoint:FlxPoint = items.members[0].getMidpoint();

        cameraTarget = new FlxObject(midpoint.x, midpoint.y, 1, 1);
        cameraTarget.visible = false;
        add(cameraTarget);

        FlxG.camera.follow(cameraTarget, LOCKON);
        FlxG.camera.snapToTarget();
        midpoint.put();

        itemOrder = items.members.copy();
        currentSelection = lastSelection % itemList.length;
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

        var itemMidpoint:FlxPoint = itemOrder[currentSelection].getMidpoint();
        cameraTarget.setPosition(Tools.lerp(cameraTarget.x, itemMidpoint.x, cameraSpeed), Tools.lerp(cameraTarget.y, itemMidpoint.y, cameraSpeed));
        itemMidpoint.put();

        if (allowInputs) {
            if (controls.anyJustPressed(["up", "down"])) changeSelection(controls.lastAction == "up" ? -1 : 1);
            if (controls.justPressed("accept")) accept();
            if (controls.justPressed("back")) leave();

            #if ENGINE_MODDING
            if (subState == null && controls.justPressed("open mods"))
                openSubState(new ModsMenu());
            #end
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

        currentSelection = FlxMath.wrap(currentSelection + i, 0, itemList.length - 1);

        for (item in itemOrder) {
            var selected:Bool = (item.ID == currentSelection);
            var scale:Float = (selected) ? 0.85 : 1;

            item.animation.play((selected) ? "selected" : "normal");
            item.scale.set(scale, scale);
            item.updateHitbox();
            item.screenCenter(X);
        }

        items.members.sort((s1, s2) -> {
            if (s1.ID == currentSelection) return 1;
            if (s2.ID == currentSelection) return -1;
            return FlxSort.byY(FlxSort.ASCENDING, s1, s2);
        });

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

        allowInputs = false;
        FlxG.sound.play(Assets.sound("confirmMenu"));

        for (item in items.members.filter((i) -> i.ID != currentSelection))
            FlxTween.tween(item, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});

        if (flicker != null) {
            FlxFlicker.flicker(flicker, 1.1, 0.15, false, true, (_) -> goToNextState());
            FlxFlicker.flicker(itemOrder[currentSelection], 1.1, 0.06, false, true);
        }
        else
            new FlxTimer().start(1.1, (_) -> goToNextState());

        #if ENGINE_SCRIPTING
        hxsCall("onAcceptPost");
        #end
    }

    inline function leave():Void {
        FlxG.sound.play(Assets.sound("cancelMenu"));
        FlxG.switchState(TitleScreen.new);
        Transition.skipNextTransIn = true;
        allowInputs = false;
    }

    inline function goToNextState():Void {
        switch (itemList[currentSelection]) {
            case "story mode":
                FlxG.switchState(StoryMenu.new);
            case "freeplay":
                FlxG.switchState(FreeplayMenu.new);
            case "options":
                FlxG.switchState(OptionsMenu.new.bind(false));
        }
    }

    override function destroy():Void {
        lastSelection = currentSelection;
        itemList = null;
        itemOrder = null;
        super.destroy();
    }
}
