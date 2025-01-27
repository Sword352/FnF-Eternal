package funkin.menus.options;

import flixel.FlxSubState;
import flixel.group.FlxSpriteGroup;

import funkin.ui.Alphabet;
import funkin.menus.MainMenu;

typedef OptionCategory = {
    var name:String;
    var action:Void->Void;
    var ?noSound:Bool;
}

class OptionsMenu extends MusicBeatState {
    public var background:FlxSprite;
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
            {name: "Calibrate offset", action: goToOffset},
            {name: "Keybinds", action: goToKeybind},
            {name: "Debug", action: goToDebug},
            {name: "Exit", action: exit, noSound: true},
        ];

        Assets.clearCache = !toPlayState || Options.reloadAssets;

        #if DISCORD_RPC
        DiscordRPC.self.details = "In the options";
        #end

        BGM.playMusic(toPlayState ? "chillFresh" : "freakyMenu");
        conductor.bpm = (toPlayState ? 117 : 102);
        conductor.music = FlxG.sound.music;

        background = new FlxSprite(0, 0, Paths.image('menus/menuDesat'));
        background.color = 0x2E2E96;
        background.screenCenter();
        add(background);

        uiGroup = new FlxSpriteGroup();
        add(uiGroup);

        for (i in 0...categories.length) {
            var graphic = Paths.image('menus/options/icon_${categories[i].name.toLowerCase().replace(" ", "-")}');
            if (graphic == null)
                graphic = Paths.image('menus/options/icon_default');

            var left:Bool = (i % 2 == 0);

            var categoryText:Alphabet = new Alphabet(FlxG.width * (left ? 0.1 : 0.9));
            categoryText.scale.set(0.7, 0.7);
            categoryText.text = categories[i].name;

            categoryText.screenCenter(Y);
            categoryText.y += 100 * Math.floor(((i + 1) / 2) - (categories.length / 2)) + (categoryText.height * 2);

            if (!left)
                categoryText.x -= categoryText.width;

            var icon:FlxSprite = new FlxSprite(0, categoryText.y, graphic);
            icon.scale.set(0.5, 0.5);
            icon.updateHitbox();

            icon.x = (left ? categoryText.x - (icon.width + 10) : categoryText.x + categoryText.width + 10);
            icon.offset.y += icon.height * 0.25;
            categoryText.ID = icon.ID = i;

            uiGroup.add(categoryText);
            uiGroup.add(icon);
        }

        changeSelection();
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

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
    }

    function changeSelection(i:Int = 0):Void {
        currentSelection = FlxMath.wrap(currentSelection + i, 0, categories.length - 1);
        uiGroup.forEach((element) -> element.alpha = (element.ID == currentSelection ? 1 : 0.4));

        if (i != 0)
            FlxG.sound.play(Paths.sound("scrollMenu"));
    }

    function accept():Void {
        var category:OptionCategory = categories[currentSelection];
        if (!category.noSound) FlxG.sound.play(Paths.sound("scrollMenu"));
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
        openSubState(new OffsetCalibrationOverlay());
    }

    inline function goToDebug():Void {
        openSubState(new DebugOptionSubState());
    }

    function exit():Void {
        FlxG.sound.play(Paths.sound("cancelMenu"));
        FlxG.switchState(toPlayState ? (Assets.clearCache ? LoadingScreen.new.bind(0) : PlayState.new.bind(0)) : MainMenu.new);

        if (toPlayState && !Assets.clearCache)
            FlxG.sound.music.persist = false;
    }

    override function onSubStateOpen(subState:FlxSubState):Void {
        uiGroup.visible = false;
        super.onSubStateOpen(subState);
    }

    override function onSubStateClose(subState:FlxSubState):Void {
        uiGroup.visible = allowInputs = true;
        super.onSubStateClose(subState);
    }

    override function destroy():Void {
        categories = null;
        super.destroy();
    }
}
