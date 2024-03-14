package funkin.states.menus;

import flixel.text.FlxText;
import flixel.sound.FlxSound;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;

import funkin.objects.Alphabet;
import funkin.objects.HealthIcon;
import funkin.states.debug.ChartEditor;
import funkin.states.substates.ResetScoreScreen;

class FreeplayMenu extends MusicBeatState {
    public var background:Background;
    public var items:FlxTypedGroup<Alphabet>;
    public var icons:FlxTypedGroup<HealthIcon>;

    public var scoreText:FlxText;
    public var scoreBG:FlxSprite;
    public var difficultyText:FlxText;
    public var instructions:Instructions;
    public var extraInfo:ExtraInfo;

    public var songs:Array<SongStructure>;
    public var difficulties:Array<String> = [];
    public var selection:Int = 0;
    public var difficulty:Int = 0;

    public var playInst:Bool = false;
    public var inst:FlxSound;

    public var scoreData:ScoreMeasure;
    public var lerpScore:Float;

    var allowInputs:Bool = true;
    var error:Bool = false;

    #if ENGINE_SCRIPTING
    var overrideCode:Bool = false;
    #end

    override function create():Void {
        songs = loadFreeplaySongs();

        if (songs == null || songs.length < 1) {
            trace("Error loading freeplay songs!");
            error = true;
        }

        #if ENGINE_DISCORD_RPC
        DiscordPresence.presence.details = "Freeplay Menu";
        #end

        PlayState.gameMode = FREEPLAY;

        super.create();

        #if ENGINE_SCRIPTING
        initStateScript();
        hxsCall("onCreate");

        if (overrideCode) {
            hxsCall("onCreatePost");
            return;
        }
        #end

        background = new Background(this);
        add(background);

        if (error) {
            // show a notice
            var overlay:FlxSprite = new FlxSprite();
            overlay.makeRect(FlxG.width, FlxG.height - 100, FlxColor.BLACK);
            overlay.screenCenter(Y);
            overlay.alpha = 0.6;
            add(overlay);

            var text:Alphabet = new Alphabet(0, 0, "NO SONGS FOUND!");
            text.screenCenter();
            add(text);

            var goBack:Alphabet = new Alphabet(0, 0, "", false);
            goBack.scale.set(0.4, 0.4);
            goBack.text = 'Press ${controls.listKeys("back", " or ")} to go back to the Main Menu.';
            goBack.y = overlay.y + overlay.height - goBack.height - 10;
            goBack.x = overlay.width - goBack.width - 10;
            add(goBack);

            background.intendedColor = background.color = FlxColor.RED;

            #if ENGINE_SCRIPTING
            hxsCall("onCreatePost");
            #end

            return;
        }

        items = new FlxTypedGroup<Alphabet>();
        add(items);

        icons = new FlxTypedGroup<HealthIcon>();
        add(icons);

        for (i in 0...songs.length) {
            var data:SongStructure = songs[i];

            var item:Alphabet = new Alphabet(0, 0, data.name);
            item.target = item.ID = i;
            item.menuItem = true;
            item.doIntro();
            items.add(item);

            var icon:HealthIcon = new HealthIcon(0, 0, data.icon);
            icon.healthAnim = false;
            icon.ID = i;
            icons.add(icon);
        }

        scoreBG = new FlxSprite();
        scoreBG.makeRect(1, 66, 0x99000000);
        add(scoreBG);

        scoreText = new FlxText(FlxG.width * 0.7, 5);
        scoreText.setFormat(Assets.font("vcr"), 32, FlxColor.WHITE, RIGHT);
        add(scoreText);
        
        difficultyText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
        difficultyText.font = scoreText.font;
        add(difficultyText);

        extraInfo = new ExtraInfo(this);
        add(extraInfo);

        instructions = new Instructions();
        add(instructions);

        inst = FlxG.sound.list.recycle(FlxSound);
        Tools.playMusicCheck("freakyMenu");

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

        if (error) {
            if (allowInputs && controls.justPressed("back")) leave();
            #if ENGINE_SCRIPTING hxsCall("onUpdatePost", [elapsed]); #end
            return;
        }

        if (allowInputs) {
            if (items.length > 1 && controls.anyJustPressed(["up", "down"])) changeSelection(controls.lastAction == "up" ? -1 : 1);
            if (difficulties.length > 1 && controls.anyJustPressed(["left", "right"])) changeDiff(controls.lastAction == "left" ? -1 : 1);

            if (FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.ENTER && Settings.get("editor access")) {
                openChartEditor();

                #if ENGINE_SCRIPTING
                hxsCall("onUpdatePost", [elapsed]);
                #end

                return; // avoid conflicts with other keybinds
            }

            if (controls.justPressed("accept")) accept();
            if (controls.justPressed("back")) leave();

            if (FlxG.keys.justPressed.R && subState == null) openResetScreen();
            if (FlxG.keys.justPressed.CONTROL) extraInfo.show = !extraInfo.show;

            if (FlxG.keys.justPressed.SPACE) {
                playInst = !playInst;
                (playInst) ? playInstrumental() : stopInst();
            }
        }

        icons.forEach((icon) -> iconFollow(icon, items.members[icon.ID]));

        if (lerpScore != scoreData.score) {
            lerpScore = Math.floor(Tools.lerp(lerpScore, scoreData.score, 24));
            if (Math.abs(lerpScore - scoreData.score) <= 10)
                lerpScore = scoreData.score;
        }

        scoreText.text = "HIGH SCORE: " + lerpScore;
        scoreText.x = Tools.lerp(scoreText.x, FlxG.width - scoreText.width - 3, 24);

        scoreBG.scale.x = Tools.lerp(scoreBG.scale.x, scoreText.width + 6, 24);
        scoreBG.x = FlxG.width - scoreBG.scale.x * 0.5;

        var diffText:String = difficulties[difficulty].toUpperCase();
        if (difficulties.length > 1) diffText = "< " + diffText + " >";

        difficultyText.text = diffText;
        difficultyText.centerToObject(scoreBG, X);

        #if ENGINE_SCRIPTING
        hxsCall("onUpdatePost", [elapsed]);
        #end
    }

    inline function changeSelection(change:Int = 0):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onSelectionChange", [change]))
            return;
        #end

        var maxSelect:Int = items.length - 1;
        var oldSelect:Int = selection;
        var doTween:Bool = false;

        if (change != 0) {
            selection = FlxMath.wrap(selection + change, 0, maxSelect);
            doTween = ((selection == 0 && oldSelect == maxSelect) || (selection == maxSelect && oldSelect == 0));
            FlxG.sound.play(Assets.sound("scrollMenu"));
        }

        for (item in items) {
            var icon:HealthIcon = icons.members[item.ID];

            item.target = item.ID - selection;
            item.alpha = icon.alpha = (item.target == 0) ? 1 : 0.6;

            if (doTween) {
                item.snapToPosition();
                iconFollow(icon, item);
                item.doIntro();
            }
        }

        var oldDiff:String = difficulties[difficulty];
        difficulties = songs[selection].difficulties;
        difficulty = Std.int(FlxMath.bound(difficulty, 0, difficulties.length - 1));
        if (difficulties.contains(oldDiff)) difficulty = difficulties.indexOf(oldDiff);

        background.intendedColor = songs[selection].color;
        updateScoreData();

        #if ENGINE_SCRIPTING
        hxsCall("onSelectionChangePost", [change]);
        #end
    }

    inline function changeDiff(i:Int):Void {
        #if ENGINE_SCRIPTING if (cancellableCall("onDifficultyChange")) return; #end

        difficulty = FlxMath.wrap(difficulty + i, 0, difficulties.length - 1);
        updateScoreData();

        #if ENGINE_SCRIPTING
        hxsCall("onDifficultyChangePost");
        #end
    }

    inline function accept():Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onAccept"))
            return;
        #end

        allowInputs = false;

        Transition.onComplete.add(() -> PlayState.load(songs[selection].rawName, difficulties[difficulty]));
        FlxG.switchState(LoadingScreen.new.bind(0));
    }

    inline function leave():Void {
        if (FlxG.keys.pressed.SHIFT && inst.playing) {
            FlxG.sound.music.fadeTween?.cancel();
            FlxG.sound.music.destroy();
            FlxG.sound.music = inst;
            inst.persist = true;
        }

        FlxG.sound.play(Assets.sound("cancelMenu"));
        allowInputs = false;

        FlxG.switchState(MainMenu.new);
    }

    inline function openResetScreen():Void {
        var screen:ResetScoreScreen = new ResetScoreScreen();
        screen.songs = [songs[selection].rawName];
        screen.difficulty = difficulties[difficulty];
        screen.display = '"${songs[selection].name}" with difficulty "${screen.difficulty}"';
        screen.onReset = updateScoreData;
        openSubState(screen);
    }

    inline function openChartEditor():Void {
        Tools.stopMusic();

        PlayState.gameMode = DEBUG;
        allowInputs = false;

        var chartEditor:ChartEditor = new ChartEditor(null, difficulties[difficulty]);
        Transition.onComplete.add(() -> {
            // avoid lag
            PlayState.load(songs[selection].rawName, chartEditor.difficulty);
            chartEditor.chart = PlayState.song;
        });

        FlxG.switchState(() -> chartEditor);
    }

    inline function updateScoreData():Void {
        scoreData = HighScore.get('${songs[selection].rawName}-${difficulties[difficulty]}');
    }

    inline function iconFollow(icon:HealthIcon, item:Alphabet):Void {
        icon.setPosition(item.x + item.width + 10, item.y + (item.height - icon.height) * 0.5);
    }

    inline function playInstrumental():Void {
        if (inst == null) return;

        FlxG.sound.music.fadeOut(0.5, 0);

        #if (target.threaded)
        sys.thread.Thread.create(loadInst);
        #else
        loadInst();
        #end
    }

    inline function stopInst():Void {
        if (inst == null) return;

        inst.fadeOut(0.5, 0, ((_) -> inst.pause()));
        FlxG.sound.music.fadeOut(0.5, 1);
    }

    inline function loadInst():Void {
        // get the corresponding inst file
        var finalAsset:openfl.media.Sound = null;

        try {
            var song:String = songs[selection].rawName;
            var meta:String = Assets.json('songs/${song}/meta');
    
            var chartFile:String = FileTools.getContent(Assets.json('songs/${song}/charts/${difficulties[difficulty]}'));
            if (!chartFile.contains("instFile") && FileTools.exists(meta))
                chartFile = FileTools.getContent(meta);
    
            var data:Dynamic = haxe.Json.parse(chartFile);
            var file:String = (data.song != null ? "Inst" : (data.instFile ?? data.meta.instFile));
            finalAsset = Assets.songAudio(song, "song/" + file);
        }
        catch (e) {
            // fallback
            trace('Failed to load instrumental! [${e.message}]');
            finalAsset = Assets.music("chillFresh");
        }

        inst.loadEmbedded(finalAsset);
        inst.volume = 0;
        inst.play();
        inst.fadeOut(0.5, 1);
    }

    override function destroy():Void {
        if (inst != null && inst != FlxG.sound.music) {
            FlxG.sound.list.remove(inst, true);
            inst.destroy();

            if (FlxG.sound.music.fadeTween != null)
                FlxG.sound.music.fadeTween.cancel();
            FlxG.sound.music.volume = 1;
        }

        songs = null;
        difficulties = null;
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
                icon: elements[2] ?? HealthIcon.DEFAULT_ICON,
                color: Tools.getColor(elements[3]),
                difficulties: (elements[4] == null) ? ["Easy", "Normal", "Hard"] : elements[4].split("/")
            });
        }

        return list;
    }
}

class Background extends FlxSprite {
    public var intendedColor(default, set):FlxColor;
    var oldColor:FlxColor;

    var parent:FreeplayMenu;
    var tmr:Float;

    public function new(parent:FreeplayMenu):Void {
        super(0, 0, Assets.image("menus/menuDesat"));
        this.parent = parent;
    }

    override function update(elapsed:Float):Void {
        if (color != intendedColor) {
            color = FlxColor.interpolate(oldColor, intendedColor, tmr / 0.75);
            tmr = Math.min(tmr + elapsed, 0.75);
        }
        
        super.update(elapsed);
    }

    function set_intendedColor(v:FlxColor):FlxColor {
        tmr = 0;
        oldColor = color;
        return intendedColor = v;
    }
}

class Instructions extends FlxSpriteGroup {
    public function new():Void {
        super();

        var instructionText:Array<String> = ["SPACE: play/stop instrumental", "CTRL: show/hide song score details", "R: reset song score"];
        var sepScale:Float = 0.25;
        var sepY:Float = 0.65;

        if (Settings.get("editor access")) {
            instructionText.insert(1, "ENTER + SHIFT: open song in chart editor");
            sepScale = sepY = 0.5;
        }

        var odd:Bool = ((instructionText.length % 2) == 0);

        var background:FlxSprite = new FlxSprite();
        background.makeRect(FlxG.width, 70, FlxColor.BLACK);
        background.y = FlxG.height - background.height;
        background.alpha = 0.4;
        add(background);

        var separator:FlxSprite = new FlxSprite();
        separator.makeRect(1.75, background.height * sepScale);
        separator.y = background.y + (background.height - separator.height) * sepY;
        separator.screenCenter(X);
        add(separator);

        for (i in 0...instructionText.length) {
            var center:Bool = (!odd && i == 0);
            var right:Bool = ((i % 2) == 0);

            var text:FlxText = new FlxText();
            text.setFormat(Assets.font("vcr"), 18, FlxColor.WHITE, (center) ? CENTER : ((right) ? RIGHT : LEFT));
            text.text = instructionText[i];

            if (center) {
                text.y = separator.y - text.height;
                text.screenCenter(X);
            }
            else {
                text.y = separator.y;
                if (odd) text.y += ((separator.height - text.height) * Math.floor(i / 2));
                text.x = (right) ? (separator.x - text.width - 15) : (separator.x + 15);
            }
            
            add(text);
        }
    }
}

class ExtraInfo extends FlxSpriteGroup {
    public var show:Bool = false;
    public var background:FlxSprite;
    public var text:FlxText;

    var parent:FreeplayMenu;
    var lerpAccuracy:Float;

    public function new(parent:FreeplayMenu):Void {
        super();

        this.parent = parent;

        background = new FlxSprite();
        background.makeRect(1, 1, FlxColor.BLACK);
        background.alpha = 0.6;
        add(background);

        text = new FlxText();
        text.setFormat(parent.scoreText.font, 32, FlxColor.WHITE, RIGHT);
        text.text = 'MISSES: 0\nACCURACY: 0%\nRANK: ?';
        add(text);

        setPosition(FlxG.width, parent.scoreText.y + 80);
        updateBgScale();
    }

    override function update(elapsed:Float):Void {
        x = Tools.lerp(x, (show) ? FlxG.width - background.width : FlxG.width - 3, 24);
        if (!show) return;

        if (lerpAccuracy != parent.scoreData.accuracy) {
            lerpAccuracy = Tools.lerp(lerpAccuracy, parent.scoreData.accuracy, 6);
            if (Math.abs(lerpAccuracy - parent.scoreData.accuracy) <= 5)
                lerpAccuracy = parent.scoreData.accuracy;
        }
        
        var fullText:String = 'MISSES: ${parent.scoreData.misses}\nACCURACY: ${FlxMath.roundDecimal(lerpAccuracy, 2)}%';
        if (parent.scoreData.rank.length > 0) fullText += '\nRANK: ${parent.scoreData.rank}';
        text.text = fullText;

        updateBgScale();
        background.centerToObject(text);
    }

    inline function updateBgScale():Void {
        background.scale.set(text.width + 10, text.height + 10);
        background.updateHitbox();
    }

    override function destroy():Void {
        parent = null;
        super.destroy();
    }
}

@:structInit class SongStructure {
    public var name:String;
    public var rawName:String;

    public var icon:String;
    public var color:FlxColor;

    public var difficulties:Array<String>;
}
