package funkin.menus;

import flixel.FlxObject;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.effects.FlxFlicker;

import flixel.math.FlxPoint;
import flixel.util.FlxSort;

import funkin.objects.Camera;
import funkin.menus.options.OptionsMenu;

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

    override function create():Void {
        #if DISCORD_RPC
        DiscordPresence.presence.details = "Main Menu";
        #end

        super.create();

        initStateScripts();
        scripts.call("onCreate");

        Tools.playMusicCheck("freakyMenu");
        FlxG.cameras.reset(new Camera());

        background = new FlxSprite();
        background.loadGraphic(Assets.image("menus/menuBG"));
        background.scrollFactor.set(0, 0.17);
        background.scale.set(1.2, 1.2);
        background.updateHitbox();
        background.screenCenter();
        add(background);

        if (!Options.noFlashingLights) {
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

        bottomText = new FlxText(5, 0, 0, 'Press ${controls.listKeys("open mods", " or ")} to open the mods menu\nEternal v${Tools.gameVersion}${devState}');
        bottomText.setFormat(Assets.font("vcr"), 16);
        bottomText.setBorderStyle(OUTLINE, FlxColor.BLACK);
        bottomText.y = FlxG.height - bottomText.height;
        bottomText.scrollFactor.set();
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

        scripts.call("onCreatePost");
    }

    override function update(elapsed:Float):Void {
        scripts.call("onUpdate", [elapsed]);
        super.update(elapsed);

        var itemMidpoint:FlxPoint = itemOrder[currentSelection].getMidpoint();
        cameraTarget.setPosition(Tools.lerp(cameraTarget.x, itemMidpoint.x, cameraSpeed), Tools.lerp(cameraTarget.y, itemMidpoint.y, cameraSpeed));
        itemMidpoint.put();

        if (allowInputs) {
            if (controls.anyJustPressed(["up", "down"])) changeSelection(controls.lastAction == "up" ? -1 : 1);
            if (controls.justPressed("accept")) accept();
            if (controls.justPressed("back")) leave();

            if (subState == null && controls.justPressed("open mods"))
                openSubState(new funkin.core.modding.ModsOverlay());
        }

        scripts.call("onUpdatePost", [elapsed]);
    }

    function changeSelection(i:Int = 0):Void {
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
    }

    function accept():Void {
        if (scripts.quickEvent("onAccept").cancelled)
            return;

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
    }

    function leave():Void {
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
