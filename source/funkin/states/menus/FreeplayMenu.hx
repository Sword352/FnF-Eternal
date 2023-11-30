package funkin.states.menus;

import funkin.objects.ui.BGText;
import funkin.objects.ui.Alphabet;
import funkin.objects.ui.HealthIcon;
import funkin.states.substates.ResetScoreScreen;

import flixel.text.FlxText;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;

class FreeplayMenu extends MusicBeatState {
    var items:FlxTypedGroup<Alphabet>;
    var background:FlxSprite;

    var scoreText:BGText;
    var scoreBG:FlxSprite; // base game compat
    var instructions:BGText;
    var detailsText:FlxText;
    var difficultyText:FlxText;

    var songs:Array<SongStructure>;
    var currentSelection:Int = 0;

    var difficulties:Array<String> = [];
    var currentDifficulty:Int = 0;

    var playMusic:Bool = false;
    var music:FlxSound;

    var showDetails:Bool = false;
    var allowInputs:Bool = true;

    var scoreData:ScoreMeasure;

    var lerpScore:Float;
    var lerpAccuracy:Float;

    #if ENGINE_SCRIPTING
    var overrideCode:Bool = false;
    #end

    var error:Bool = false;

    override function create():Void {
        songs = loadFreeplaySongs();

        if (songs == null || songs.length < 1) {
            trace("Error loading freeplay songs, going back to the Main Menu.");

            error = true;
            // persistentUpdate = false; // this does not seems to work??
            FlxG.switchState(new MainMenu());
            return;
        }

        PlayState.gameMode = FREEPLAY;

        #if ENGINE_DISCORD_RPC
        DiscordPresence.presence.state = "(in-dev)";
        DiscordPresence.presence.details = "Freeplay Menu";
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

        background = new FlxSprite().loadGraphic(AssetHelper.image("menus/menuDesat"));
        add(background);

        items = new FlxTypedGroup<Alphabet>();
        add(items);

        for (songData in songs) {
            var i:Int = songs.indexOf(songData);

            var item:Alphabet = new Alphabet(0, 0, songData.name);
            item.menuItem = true;
            item.target = i;
            item.ID = i;

            var icon:HealthIcon = new HealthIcon(0, 0, songData.icon);
            icon.offset.y = icon.frameHeight * 0.25;
            icon.healthAnim = false;
            item.spriteTrackers.set(icon, RIGHT);
            add(icon);

            items.add(item);
            item.doIntro();
        }
        
        scoreText = new BGText(FlxG.width * 0.7, 5);
        scoreText.setFormat(AssetHelper.font("vcr"), 32, FlxColor.WHITE, RIGHT);
        scoreText.automaticScale = scoreText.automaticPosition = false;
        scoreText.background.makeGraphic(1, 66, 0x99000000);
        scoreBG = scoreText.background;
        add(scoreText);

        difficultyText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
        difficultyText.font = scoreText.font;
        add(difficultyText);

        instructions = new BGText();
        instructions.setFormat(scoreText.font, 16, FlxColor.WHITE, RIGHT);
        instructions.text = "Press SPACE to play/stop the instrumental | Press CTRL to show/hide score details | ";
        instructions.text += "Press R to reset the score of the current song";
        instructions.background.alpha = 0.6;
        instructions.screenCenter(X);
        instructions.y = FlxG.height - instructions.height;
        add(instructions);

        detailsText = new FlxText(0, scoreText.y + 104);
        detailsText.setFormat(scoreText.font, 32, FlxColor.WHITE, RIGHT);
        detailsText.clipRect = flixel.math.FlxRect.get();
        add(detailsText);

        music = FlxG.sound.list.recycle(FlxSound);
        Tools.playMusicCheck("freakyMenu");

        persistentUpdate = true;
        changeSelection();

        #if ENGINE_SCRIPTING
        hxsCall("onCreatePost");
        #end
    }

    override function update(elapsed:Float):Void {
        if (error)
            return;

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

        if (allowInputs) {
            if (items.length > 1 && controls.anyJustPressed(["up", "down"]))
                changeSelection(controls.lastAction == "up" ? -1 : 1);

            #if ENGINE_SCRIPTING
            if (difficulties.length > 1 && controls.anyJustPressed(["left", "right"]) && !cancellableCall("onDifficultyChange")) {
            #else
            if (difficulties.length > 1 && controls.anyJustPressed(["left", "right"])) {
            #end
                currentDifficulty = FlxMath.wrap(currentDifficulty + (controls.lastAction == "left" ? -1 : 1), 0, difficulties.length - 1);
                updateScoreData();
                
                #if ENGINE_SCRIPTING
                hxsCall("onDifficultyChangePost");
                #end
            }

            #if ENGINE_SCRIPTING
            if (controls.justPressed("accept") && !cancellableCall("onAccept")) {
            #else
            if (controls.justPressed("accept")) {
            #end
                allowInputs = false;
                FlxG.sound.play(AssetHelper.sound("confirmMenu"));
    
                TransitionSubState.onComplete.add(() -> PlayState.load(songs[currentSelection].rawName, difficulties[currentDifficulty]));
                FlxG.switchState(new PlayState());
            }

            if (controls.justPressed("back")) {
                allowInputs = false;
                FlxG.switchState(new MainMenu());
            }

            if (FlxG.keys.justPressed.SPACE) {
                playMusic = !playMusic;
                (playMusic) ? playInstrumental() : stopMusic();
            }

            if (FlxG.keys.justPressed.R) {
                persistentUpdate = false;

                var screen:ResetScoreScreen = new ResetScoreScreen();
                screen.songs = [songs[currentSelection].rawName];
                screen.difficulty = difficulties[currentDifficulty];
                screen.display = '"${songs[currentSelection].name}" with difficulty "${screen.difficulty}"';
                screen.onReset = updateScoreData;
                openSubState(screen);
            }
    
            if (FlxG.keys.justPressed.CONTROL)
                showDetails = !showDetails;
        }

        var ratio:Float = FlxMath.bound(elapsed * 24, 0, 1);
        var lowRatio:Float = FlxMath.bound(elapsed * 6, 0, 1);

        lerpScore = Math.floor(FlxMath.lerp(lerpScore, scoreData.score, ratio));
        if (lerpScore != scoreData.score && Math.abs(lerpScore - scoreData.score) <= 10)
            lerpScore = scoreData.score;

        lerpAccuracy = FlxMath.lerp(lerpAccuracy, scoreData.accuracy, lowRatio);
        if (lerpAccuracy != scoreData.accuracy && Math.abs(lerpAccuracy - scoreData.accuracy) <= 5)
            lerpAccuracy = scoreData.accuracy;

        scoreText.text = "HIGH SCORE: " + lerpScore;
        scoreText.x = FlxMath.lerp(scoreText.x, FlxG.width - scoreText.width - 6, ratio);

        scoreBG.x = FlxG.width - scoreBG.scale.x * 0.5;
        scoreBG.scale.set(
            FlxMath.lerp(scoreBG.scale.x, FlxG.width - scoreText.x + 6, ratio),
            FlxMath.lerp(scoreBG.scale.y, (showDetails) ? 5.5 : 1, lowRatio * ((showDetails) ? 1 : 0.75))
        );

        detailsText.text = 'MISSES: ${scoreData.misses}\nACCURACY: ${FlxMath.roundDecimal(lerpAccuracy, 2)}%';
        if (scoreData.rank.length > 0)
            detailsText.text += '\nRANK: ${scoreData.rank}';

        detailsText.clipRect.setSize(detailsText.width, detailsText.height * (scoreBG.scale.y - 4));
        detailsText.clipRect = detailsText.clipRect;

        detailsText.x = FlxMath.lerp(detailsText.x, scoreText.x + (scoreText.width * 0.5) - (detailsText.width * 0.5), ratio);

        difficultyText.text = '< ${difficulties[currentDifficulty].toUpperCase()} >';
        difficultyText.x = Math.floor(scoreText.background.x + scoreText.background.width * 0.5) - (difficultyText.width * 0.5);

        #if ENGINE_SCRIPTING
        hxsCall("onUpdatePost", [elapsed]);
        #end
    }

    private function changeSelection(change:Int = 0):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onSelectionChange", [change]))
            return;
        #end

        if (change != 0) {
            currentSelection = FlxMath.wrap(currentSelection + change, 0, items.length - 1);
            FlxG.sound.play(AssetHelper.sound("scrollMenu"));
        }

        for (item in items) {
            item.target = items.members.indexOf(item) - currentSelection;
            item.alpha = (item.ID == currentSelection) ? 1 : 0.6;
            
            for (spr in item.spriteTrackers.keys())
                spr.alpha = item.alpha;
        }

        FlxTween.cancelTweensOf(background);
        FlxTween.color(background, 0.75, background.color, songs[currentSelection].color);

        if (playMusic) {
            playMusic = false;
            stopMusic();
        }

        difficulties = songs[currentSelection].difficulties;
        currentDifficulty = Std.int(FlxMath.bound(currentDifficulty, 0, difficulties.length - 1));
        updateScoreData();

        #if ENGINE_SCRIPTING
        hxsCall("onSelectionChangePost", [change]);
        #end
    }

    inline private function updateScoreData():Void
        scoreData = HighScore.get('${songs[currentSelection].rawName}-${difficulties[currentDifficulty]}');

    private function playInstrumental():Void {
        if (music == null)
            return;

        FlxG.sound.music.fadeOut(0.5, 0);

        #if (target.threaded)
        sys.thread.Thread.create(playNextSong);
        #else
        playNextSong();
        #end
    }

    private function stopMusic():Void {
        if (music == null)
            return;

        music.fadeOut(0.5, 0, ((_) -> music.pause()));
        FlxG.sound.music.fadeOut(0.5, 1);
    }

    inline function playNextSong():Void {
        music.loadEmbedded(AssetHelper.songAudio(songs[currentSelection].rawName, "song/Inst"));
        music.volume = 0;
        music.play();
        music.fadeOut(0.5, 1);
    }

    override function destroy():Void {
        if (music != null) {
            FlxG.sound.list.remove(music, true);
            music.destroy();
        }

        songs = null;
        difficulties = null;

        scoreData = null;

        super.destroy();
    }

    public static function loadFreeplaySongs():Array<SongStructure> {
        var listPath:String = AssetHelper.txt("data/freeplaySongs");

        if (!FileTools.exists(listPath))
            return null;

        var list:Array<SongStructure> = [];
        var content:Array<String> = FileTools.getContent(listPath).trim().split("\n");

        for (line in content) {
            var trimmedLine:String = line.trim();

            if (trimmedLine.startsWith("#") || trimmedLine.length < 1) // skip comments and empty lines
                continue;

            var elements:Array<String> = line.split("||").map((f) -> f = f.trim());

            list.push({
                name: elements[0],
                rawName: elements[1] ?? elements[0],
                icon: elements[2] ?? "face",
                color: Tools.getColor(elements[3]),
                difficulties: (elements[4] == null) ? ["Easy", "Normal", "Hard"] : elements[4].split("/")
            });
        }

        return list;
    }
}

@:structInit class SongStructure {
    public var name:String;
    public var rawName:String;

    public var icon:String;
    public var color:FlxColor;

    public var difficulties:Array<String>;
}
