package funkin.states.substates;

import flixel.text.FlxText;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;

import funkin.objects.ui.Alphabet;

import funkin.states.menus.StoryMenu;
import funkin.states.menus.FreeplayMenu;
import funkin.states.options.OptionsMenu;

class PauseScreen extends MusicBeatSubState {
    // in case i do difficulty stuff later
    var itemLists:Map<String, Array<String>> = [
        "default" => ["Resume", "Restart Song", "Go To Options", "Exit To Menu"]
    ];

    var currentList:Array<String>;
    var currentSelection:Int = 0;

    var background:FlxSprite;
    var lossCounter:FlxText;
    var songText:FlxText;

    var items:FlxTypedGroup<Alphabet>;
    var music:FlxSound;

    #if ENGINE_SCRIPTING
    var overrideCode:Bool = false;
    #end
    
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

        // Caching
        AssetHelper.sound("scrollMenu");
        
        background = new FlxSprite();
        background.makeRect(FlxG.width, FlxG.height, FlxColor.BLACK);
        background.alpha = 0;
        add(background);
        
        items = new FlxTypedGroup<Alphabet>();
        add(items);

        changeList("default");

        songText = new FlxText(0, 15);
        songText.setFormat(AssetHelper.font('vcr'), 32);
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

        music = FlxG.sound.load(AssetHelper.music("breakfast"), 0, true);
        music.play(false, FlxG.random.int(0, Math.floor(music.length * 0.5)));

        FlxTween.tween(background, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
        FlxTween.tween(songText, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
        FlxTween.tween(lossCounter, {alpha: 1, y: 52}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});

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

        if (music.volume < 0.5)
            music.volume += 0.01 * elapsed;

        if (controls.anyJustPressed(["up", "down"]))
            changeSelection((controls.lastAction == "up") ? -1 : 1);

        if (controls.justPressed("accept"))
            accept(currentList[currentSelection]);

        #if ENGINE_SCRIPTING
        hxsCall("onUpdatePost", [elapsed]);
        #end
    }
    
    inline function changeSelection(i:Int = 0):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onSelectionChange", [i]))
            return;
        #end

        currentSelection = FlxMath.wrap(currentSelection + i, 0, currentList.length - 1);
        
        if (items != null) {
            for (i in items) {
                i.target = items.members.indexOf(i) - currentSelection;
                i.alpha = (i.ID == currentSelection) ? 1 : 0.6;
            }
        }

        if (i != 0)
            FlxG.sound.play(AssetHelper.sound("scrollMenu"));

        #if ENGINE_SCRIPTING
        hxsCall("onSelectionChangePost", [i]);
        #end
    }

    inline function accept(item:String):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onAccept", [item]))
            return;
        #end

        switch (item.toLowerCase()) {
            case "resume": 
                close();
            case "restart song":
                TransitionSubState.skipNextTransIn = TransitionSubState.skipNextTransOut = true;
                AssetHelper.clearAssets = false;
                FlxG.resetState();
            case "go to options":
                AssetHelper.clearAssets = false;
                FlxG.switchState(new OptionsMenu(true));
            case "exit to menu":
                PlayState.lossCounter = 0;
                FlxG.switchState(switch (PlayState.gameMode) {
                    case STORY: new StoryMenu();
                    default: new FreeplayMenu();
                });
        }

        #if ENGINE_SCRIPTING
        hxsCall("onAcceptPost", [item]);
        #end
    }

    function changeList(list:String):Void {
        currentList = itemLists[list];
        currentSelection = 0;

        while (items.length > 0)
            items.remove(items.members[0], true).destroy();

        for (i in 0...currentList.length) {
            var item:Alphabet = items.recycle(Alphabet);
            item.setPosition(0, 0);
            item.text = currentList[i];
            item.menuItem = true;

            item.target = i;
            item.ID = i;
            item.doIntro();

            items.remove(item);
            items.add(item);
        }

        changeSelection();
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
