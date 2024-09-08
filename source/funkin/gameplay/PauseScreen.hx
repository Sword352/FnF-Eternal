package funkin.gameplay;

import flixel.text.FlxText;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;

import funkin.ui.Alphabet;
import funkin.menus.StoryMenu;
import funkin.menus.FreeplayMenu;
import funkin.menus.options.OptionsMenu;
import funkin.menus.LoadingScreen;

class PauseScreen extends MusicBeatSubState {
    // in case i do difficulty stuff later
    var itemLists:Map<String, Array<String>> = ["default" => ["Resume", "Restart Song", "Go To Options", "Exit To Menu"]];

    var currentList:Array<String>;
    var currentSelection:Int = 0;

    var background:FlxSprite;
    var lossCounter:FlxText;
    var songText:FlxText;

    var items:FlxTypedGroup<Alphabet>;
    var music:FlxSound;

    override function create():Void {
        super.create();

        initStateScripts();
        scripts.call("onCreate");

        // Caching
        Assets.sound("scrollMenu");

        background = new FlxSprite();
        background.makeRect(FlxG.width, FlxG.height, FlxColor.BLACK);
        background.alpha = 0;
        add(background);

        items = new FlxTypedGroup<Alphabet>();
        add(items);

        changeList("default");

        songText = new FlxText(0, 15);
        songText.setFormat(Assets.font('vcr'), 32);
        songText.updateHitbox();
        songText.text = '${PlayState.song.meta.name} (${PlayState.currentDifficulty.toUpperCase()})';
        songText.x = FlxG.width - songText.width - 10;
        songText.alpha = 0;
        add(songText);

        lossCounter = new FlxText(0, 47);
        lossCounter.setFormat(songText.font, 32);
        lossCounter.updateHitbox();
        lossCounter.text = 'Lost: ${PlayState.lossCounter}';
        lossCounter.x = FlxG.width - lossCounter.width - 10;
        lossCounter.alpha = 0;
        add(lossCounter);

        music = FlxG.sound.load(Assets.music("breakfast"), 0, true);
        music.play(false, FlxG.random.int(0, Math.floor(music.length * 0.5)));

        FlxTween.tween(background, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
        FlxTween.tween(songText, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
        FlxTween.tween(lossCounter, {alpha: 1, y: 52}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});

        #if DISCORD_RPC
        PlayState.self.updatePresenceState(true);
        #end

        scripts.call("onCreatePost");
    }

    override function update(elapsed:Float):Void {
        scripts.call("onUpdate", elapsed);
        super.update(elapsed);

        if (music.volume < 0.5)
            music.volume += 0.01 * elapsed;

        if (controls.anyJustPressed(["up", "down"]))
            changeSelection((controls.lastAction == "up") ? -1 : 1);

        if (controls.justPressed("accept"))
            accept(currentList[currentSelection]);

        scripts.call("onUpdatePost", elapsed);
    }

    function changeSelection(i:Int = 0):Void {
        currentSelection = FlxMath.wrap(currentSelection + i, 0, currentList.length - 1);

        for (i in items) {
            i.target = items.members.indexOf(i) - currentSelection;
            i.alpha = (i.ID == currentSelection) ? 1 : 0.6;
        }

        if (i != 0)
            FlxG.sound.play(Assets.sound("scrollMenu"));
    }

    function accept(item:String):Void {
        switch (item.toLowerCase()) {
            case "resume":
                close();
            case "restart song":
                Assets.clearAssets = Transition.openOnSubState = Options.reloadAssets;
                Transition.skipNextTransIn = Transition.skipNextTransOut = !Assets.clearAssets;

                if (!Assets.clearAssets) FlxG.resetState();
                else {
                    Transition.noPersistentUpdate = true;
                    FlxG.switchState(LoadingScreen.new.bind(PlayState.self.startTime));
                }
            case "go to options":
                Transition.openOnSubState = Transition.noPersistentUpdate = true;
                Assets.clearAssets = Options.reloadAssets;
                FlxG.switchState(OptionsMenu.new.bind(true));
            case "exit to menu":
                Transition.openOnSubState = Transition.noPersistentUpdate = true;
                PlayState.lossCounter = 0;
                
                FlxG.switchState(switch (PlayState.gameMode) {
                    case STORY: StoryMenu.new;
                    default: FreeplayMenu.new;
                });
        }
    }

    function changeList(list:String):Void {
        currentList = itemLists[list];
        currentSelection = 0;

        while (items.length > 0)
            items.remove(items.members[0], true).destroy();

        for (i in 0...currentList.length) {
            var item:Alphabet = new Alphabet(0, 0, currentList[i]);
            item.menuItem = true;
            item.target = i;
            item.ID = i;
            item.doIntro();
            items.add(item);
        }

        changeSelection();
    }

    override function close():Void {
        #if DISCORD_RPC
        PlayState.self.updatePresenceState();
        #end

        super.close();
    }

    override function destroy():Void {
        if (music != null) {
            FlxG.sound.list.remove(music, true);
            music.destroy();
        }

        currentList = null;
        itemLists = null;

        super.destroy();
    }
}
