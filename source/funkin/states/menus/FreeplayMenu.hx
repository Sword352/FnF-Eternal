package funkin.states.menus;

import flixel.text.FlxText;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;

import funkin.objects.ui.BGText;
import funkin.objects.ui.Alphabet;
import funkin.objects.ui.HealthIcon;

import funkin.states.debug.ChartEditor;
import funkin.states.substates.ResetScoreScreen;

class FreeplayMenu extends MusicBeatState {
    var items:FlxTypedGroup<Alphabet>;
    var background:FlxSprite;

    var scoreText:BGText;
    var scoreBG:FlxSprite;

    var detailsText:FlxText;
    var difficultyText:FlxText;

    var instructionBG:FlxSprite;
    var instructionSep:FlxSprite;
    var instructionTexts:Array<FlxText> = []; // for scripting purposes

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

        background = new FlxSprite().loadGraphic(Assets.image("menus/menuDesat"));
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
        scoreText.setFormat(Assets.font("vcr"), 32, FlxColor.WHITE, RIGHT);
        scoreText.automaticScale = scoreText.automaticPosition = false;
        scoreText.background.makeGraphic(1, 66, 0x99000000);
        scoreBG = scoreText.background;
        add(scoreText);

        difficultyText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
        difficultyText.font = scoreText.font;
        add(difficultyText);

        var instructionText:Array<String> = ["SPACE: play/stop instrumental"];
        var sepScale:Float = 0.25;
        var sepY:Float = 0.65;

        if (Settings.get("editor access")) {
            instructionText.push("ENTER + SHIFT: open song in chart editor");
            sepScale = sepY = 0.5;
        }

        instructionText.push("CTRL: show/hide song score details");
        instructionText.push("R: reset song score");

        instructionBG = new FlxSprite();
        instructionBG.makeRect(FlxG.width, 70, FlxColor.BLACK);
        instructionBG.y = FlxG.height - instructionBG.height;
        instructionBG.alpha = 0.4;
        add(instructionBG);

        instructionSep = new FlxSprite();
        instructionSep.makeRect(1.75, instructionBG.height * sepScale);
        instructionSep.y = instructionBG.y + (instructionBG.height - instructionSep.height) * sepY;
        instructionSep.screenCenter(X);
        add(instructionSep);

        var odd:Bool = ((instructionText.length % 2) == 0);

        for (i in 0...instructionText.length) {
            var center:Bool = (!odd && i == 0);
            var right:Bool = ((i % 2) == 0);

            var text:FlxText = new FlxText();
            text.setFormat(scoreText.font, 18, FlxColor.WHITE, (center) ? CENTER : ((right) ? RIGHT : LEFT));
            text.text = instructionText[i];

            if (center) {
                text.y = instructionSep.y - text.height;
                text.screenCenter(X);
            }
            else {
                text.y = instructionSep.y;
                if (odd) 
                    text.y += ((instructionSep.height - text.height) * Math.floor(i / 2));

                text.x = (right) ? (instructionSep.x - text.width - 15) : (instructionSep.x + 15);
            }

            instructionTexts.push(text);
            add(text);
        }

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
                currentDifficulty = Math.floor(FlxMath.bound(currentDifficulty + (controls.lastAction == "left" ? -1 : 1), 0, difficulties.length - 1));
                updateScoreData();
                
                #if ENGINE_SCRIPTING
                hxsCall("onDifficultyChangePost");
                #end
            }

            if (FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.ENTER && Settings.get("editor access")) {
                openChartEditor();

                // we return here in case the "accept" keybind contains the "ENTER" key
                return; 
            }

            if (controls.justPressed("accept"))
                accept();

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

        lerpScore = Math.floor(Tools.lerp(lerpScore, scoreData.score, 24));
        if (lerpScore != scoreData.score && Math.abs(lerpScore - scoreData.score) <= 10)
            lerpScore = scoreData.score;

        lerpAccuracy = Tools.lerp(lerpAccuracy, scoreData.accuracy, 6);
        if (lerpAccuracy != scoreData.accuracy && Math.abs(lerpAccuracy - scoreData.accuracy) <= 5)
            lerpAccuracy = scoreData.accuracy;

        scoreText.text = "HIGH SCORE: " + lerpScore;
        scoreText.x = Tools.lerp(scoreText.x, FlxG.width - scoreText.width - 6, 24);

        scoreBG.x = FlxG.width - scoreBG.scale.x * 0.5;
        scoreBG.scale.set(
            Tools.lerp(scoreBG.scale.x, FlxG.width - scoreText.x + 6, 24),
            Tools.lerp(scoreBG.scale.y, (showDetails) ? 5.5 : 1, 6 * ((showDetails) ? 1 : 0.75))
        );

        detailsText.text = 'MISSES: ${scoreData.misses}\nACCURACY: ${FlxMath.roundDecimal(lerpAccuracy, 2)}%';
        if (scoreData.rank.length > 0)
            detailsText.text += '\nRANK: ${scoreData.rank}';

        detailsText.clipRect.setSize(detailsText.width, detailsText.height * (scoreBG.scale.y - 4));
        detailsText.clipRect = detailsText.clipRect;

        detailsText.x = Tools.lerp(detailsText.x, scoreText.x + (scoreText.width * 0.5) - (detailsText.width * 0.5), 24);

        updateDifficultyText();

        #if ENGINE_SCRIPTING
        hxsCall("onUpdatePost", [elapsed]);
        #end
    }

    inline function changeSelection(change:Int = 0):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onSelectionChange", [change]))
            return;
        #end

        if (change != 0) {
            currentSelection = FlxMath.wrap(currentSelection + change, 0, items.length - 1);
            FlxG.sound.play(Assets.sound("scrollMenu"));
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

    inline function accept():Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onAccept"))
            return;
        #end

        allowInputs = false;
        
        TransitionSubState.onComplete.add(() -> PlayState.load(songs[currentSelection].rawName, difficulties[currentDifficulty]));
        FlxG.switchState(new PlayState());
    }

    inline function openChartEditor():Void {
        Tools.stopMusic();

        PlayState.gameMode = DEBUG;
        allowInputs = false;

        var chartEditor:ChartEditor = new ChartEditor(null, difficulties[currentDifficulty]);
        TransitionSubState.onComplete.add(() -> {
            // avoid lag
            PlayState.load(songs[currentSelection].rawName, chartEditor.difficulty);
            chartEditor.chart = PlayState.song;
        });

        FlxG.switchState(chartEditor);
    }

    inline function updateScoreData():Void {
        scoreData = HighScore.get('${songs[currentSelection].rawName}-${difficulties[currentDifficulty]}');
    }

    inline function updateDifficultyText():Void {
        var baseText:String = difficulties[currentDifficulty].toUpperCase();

        if (difficulties.length > 1) {
            var max:Int = difficulties.length - 1;

            if (currentDifficulty == 0 || currentDifficulty != max)
                baseText += " >";
            if (currentDifficulty != 0)
                baseText = "< " + baseText;
        }

        difficultyText.text = baseText;
        difficultyText.x = Math.floor(scoreText.background.x + scoreText.background.width * 0.5) - (difficultyText.width * 0.5);
    }

    inline function playInstrumental():Void {
        if (music == null)
            return;

        FlxG.sound.music.fadeOut(0.5, 0);

        #if (target.threaded)
        sys.thread.Thread.create(playNextSong);
        #else
        playNextSong();
        #end
    }

    inline function stopMusic():Void {
        if (music == null)
            return;

        music.fadeOut(0.5, 0, ((_) -> music.pause()));
        FlxG.sound.music.fadeOut(0.5, 1);
    }

    inline function playNextSong():Void {
        music.loadEmbedded(Assets.songAudio(songs[currentSelection].rawName, "song/Inst"));
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

        instructionTexts = null;
        scoreData = null;

        super.destroy();
    }

    public static function loadFreeplaySongs():Array<SongStructure> {
        var listPath:String = Assets.txt("data/freeplaySongs");

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
