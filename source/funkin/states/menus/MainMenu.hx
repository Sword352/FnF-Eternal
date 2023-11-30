package funkin.states.menus;

import flixel.FlxObject;
import flixel.text.FlxText;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.effects.FlxFlicker;
import flixel.group.FlxSpriteGroup;

import funkin.states.options.OptionsMenu;

class MainMenu extends MusicBeatState {
    var itemList:Array<String> = [
        "story mode",
        "freeplay",
        "options"
    ];

    var bg:FlxSprite;
    var flickerBg:FlxSprite;
    var bottomText:FlxText;
    var items:FlxSpriteGroup;
    var cameraTarget:FlxObject;

    var currentSelection:Int = 0;
    var allowInputs:Bool = true;
    var itemOrder:Array<FlxSprite>;

    #if ENGINE_SCRIPTING
    var overrideCode:Bool = false;
    #end

    override function create():Void {
        #if ENGINE_DISCORD_RPC
        DiscordPresence.presence.state = "(in-dev)";
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

        bg = new FlxSprite();
        bg.loadGraphic(AssetHelper.image("menus/menuBG"));
        bg.scale.set(1.2, 1.2);
        bg.updateHitbox();
        bg.screenCenter();
        bg.scrollFactor.set(0, 0.17);
        add(bg);

        flickerBg = new FlxSprite();
        flickerBg.loadGraphic(AssetHelper.image("menus/menuDesat"));
        flickerBg.scale.set(1.2, 1.2);
        flickerBg.updateHitbox();
        flickerBg.screenCenter();
        flickerBg.scrollFactor.set(0, bg.scrollFactor.y);
        flickerBg.visible = false;
        flickerBg.color = 0xFFfd719b;
        add(flickerBg);

        bottomText = new FlxText(5, 0, 0,
            #if ENGINE_MODDING 'Press ${controls.listKeys("open mods", " or ")} to open the mods menu\n' + #end
            'Eternal Engine v0.1 (in-dev)'
        );
        bottomText.setFormat(AssetHelper.font("vcr"), 16);
        bottomText.setBorderStyle(OUTLINE, FlxColor.BLACK);
        bottomText.scrollFactor.set();
        bottomText.y = FlxG.height - bottomText.height;
        add(bottomText);

        items = new FlxSpriteGroup();
        items.scrollFactor.set();
        add(items);

        for (i in 0...itemList.length) {
            var item = new FlxSprite(0, FlxG.height * (0.1 + (0.2 * i)));
            item.frames = AssetHelper.getSparrowAtlas('menus/main/${itemList[i]}');
            item.animation.addByPrefix("normal", "basic", 24);
            item.animation.addByPrefix("selected", "white", 24);
            item.animation.play("normal");
            item.updateHitbox();
            item.ID = i;
            items.add(item);
        }

        itemOrder = items.members.copy();

        cameraTarget = new FlxObject(0, 0, 1, 1);
        cameraTarget.visible = false;
        FlxG.camera.follow(cameraTarget, LOCKON);
        add(cameraTarget);

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

        FlxG.camera.followLerp = FlxMath.bound(elapsed * 8, 0, 1);

        if (allowInputs) {
            if (controls.anyJustPressed(["up", "down"]))
                changeSelection((controls.lastAction == "up") ? -1 : 1);

            if (controls.justPressed("accept"))
                accept();

            if (controls.justPressed("back")) {
                FlxG.sound.play(AssetHelper.sound("cancelMenu"));
                TransitionSubState.skipNextTransOut = true;
                FlxG.switchState(new TitleScreen());
            }

            #if ENGINE_MODDING
            if (controls.justPressed("open mods")) {
                persistentUpdate = false;
                openSubState(new ModsMenu());
            }
            #end
        }

        #if ENGINE_SCRIPTING
        hxsCall("onUpdatePost", [elapsed]);
        #end
    }

    function changeSelection(i:Int = 0):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onSelectionChange", [i]))
            return;
        #end

        currentSelection = FlxMath.wrap(currentSelection + i, 0, itemList.length - 1);

        for (item in itemOrder) {
            item.animation.play(item.ID == currentSelection ? "selected" : "normal");
            item.updateHitbox();
            item.screenCenter(X);
        }

        var itemMidpoint = itemOrder[currentSelection].getMidpoint();
        cameraTarget.setPosition(itemMidpoint.x, itemMidpoint.y);
        itemMidpoint.put();

        items.members.sort((s1, s2) -> {
            if (s1.ID == currentSelection)
                return 1;

            if (s2.ID == currentSelection)
                return -1;

            return FlxSort.byY(FlxSort.ASCENDING, s1, s2);
        });

        if (i != 0)
            FlxG.sound.play(AssetHelper.sound("scrollMenu"));

        #if ENGINE_SCRIPTING
        hxsCall("onSelectionChangePost", [i]);
        #end
    }

    function accept():Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onAccept"))
            return;
        #end

        allowInputs = false;
        FlxG.sound.play(AssetHelper.sound("confirmMenu"));

        for (item in items.members.filter(f -> f.ID != currentSelection))
            FlxTween.tween(item, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});

        if (!Settings.get("disable flashing lights")) {
            FlxFlicker.flicker(flickerBg, 1.1, 0.15, false, true, (_) -> goToNextState());
            FlxFlicker.flicker(itemOrder[currentSelection], 1.1, 0.06, false, true);
        }
        else
            new FlxTimer().start(1.1, (_) -> goToNextState());

        #if ENGINE_SCRIPTING
        hxsCall("onAcceptPost");
        #end
    }

    function goToNextState():Void {
        switch (itemList[currentSelection]) {
            case "story mode": FlxG.switchState(new StoryMenu());
            case "freeplay": FlxG.switchState(new FreeplayMenu());
            case "options": FlxG.switchState(new OptionsMenu());
        }
    }

    override function destroy():Void {
        super.destroy();
        itemList = null;
        itemOrder = null;
    }
}