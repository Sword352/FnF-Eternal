package funkin.menus;

import flixel.text.FlxText;
import flixel.sound.FlxSound;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;

import funkin.ui.Alphabet;
import funkin.ui.HealthIcon;
import funkin.editors.chart.ChartEditor;

import funkin.data.ChartFormat;
import funkin.save.SongProgress;
import funkin.save.Scoring;
import haxe.Json;

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

    public var scoreData:GameSession;
    public var lerpScore:Float;

    var allowInputs:Bool = true;
    var error:Bool = false;

    override function create():Void {
        songs = loadFreeplaySongs();

        if (songs == null || songs.length < 1) {
            trace("No songs available!");
            error = true;
        }

        #if DISCORD_RPC
        DiscordRPC.self.details = "Freeplay Menu";
        #end

        PlayState.gameMode = FREEPLAY;

        super.create();

        initStateScripts();
        scripts.call("onCreate");

        background = new Background(this);
        add(background);

        if (error) {
            // show a notice
            var overlay:FlxSprite = new FlxSprite();
            overlay.makeRect(FlxG.width, FlxG.height - 100, FlxColor.BLACK);
            overlay.screenCenter(Y);
            overlay.alpha = 0.6;
            add(overlay);

            var text:Alphabet = new Alphabet(0, 0, "NO SONGS AVAILABLE!");
            text.screenCenter();
            add(text);

            var goBack:Alphabet = new Alphabet(0, 0, "", false);
            goBack.scale.set(0.4, 0.4);
            goBack.text = 'Press ${controls.listKeys("back", " or ")} to go back to the Main Menu.';
            goBack.y = overlay.y + overlay.height - goBack.height - 10;
            goBack.x = overlay.width - goBack.width - 10;
            add(goBack);

            scripts.call("onCreatePost");

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
        scoreText.setFormat(Paths.font("vcr"), 32, FlxColor.WHITE, RIGHT);
        add(scoreText);
        
        difficultyText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
        difficultyText.font = scoreText.font;
        add(difficultyText);

        extraInfo = new ExtraInfo(this);
        add(extraInfo);

        instructions = new Instructions();
        add(instructions);

        inst = FlxG.sound.list.recycle(FlxSound);
        BGM.playMusic("freakyMenu");

        changeSelection();

        scripts.call("onCreatePost");
    }

    override function update(elapsed:Float):Void {
        scripts.call("onUpdate", elapsed);
        super.update(elapsed);

        if (error) {
            if (allowInputs && controls.justPressed("back")) leave();
            scripts.call("onUpdatePost", elapsed);
            return;
        }

        if (allowInputs) {
            if (items.length > 1 && controls.anyJustPressed(["up", "down"])) changeSelection(controls.lastAction == "up" ? -1 : 1);
            if (difficulties.length > 1 && controls.anyJustPressed(["left", "right"])) changeDiff(controls.lastAction == "left" ? -1 : 1);

            if (Options.editorAccess && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.ENTER) {
                openChartEditor();
                scripts.call("onUpdatePost", elapsed);

                // avoid conflicts with other keybinds
                return;
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

        scripts.call("onUpdatePost", elapsed);
    }

    function changeSelection(change:Int = 0):Void {
        var maxSelect:Int = items.length - 1;
        var oldSelect:Int = selection;
        var doTween:Bool = false;

        if (change != 0) {
            selection = FlxMath.wrap(selection + change, 0, maxSelect);
            doTween = ((selection == 0 && oldSelect == maxSelect) || (selection == maxSelect && oldSelect == 0));
            FlxG.sound.play(Paths.sound("scrollMenu"));
        }

        for (item in items) {
            var icon:HealthIcon = icons.members[item.ID];

            item.target = item.ID - selection;
            item.alpha = icon.alpha = (item.target == 0) ? 1 : 0.6;

            if (doTween && items.length > 3) {
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
    }

    function changeDiff(i:Int):Void {
        difficulty = FlxMath.wrap(difficulty + i, 0, difficulties.length - 1);
        updateScoreData();
    }

    function accept():Void {
        if (scripts.quickEvent("onAccept").cancelled)
            return;

        allowInputs = false;

        Transition.onComplete.add(() -> PlayState.load(songs[selection].folder, difficulties[difficulty]));
        FlxG.switchState(LoadingScreen.new.bind(0));
    }

    function leave():Void {
        if (FlxG.keys.pressed.SHIFT && inst.playing) {
            FlxG.sound.music.fadeTween?.cancel();
            FlxG.sound.music.destroy();
            FlxG.sound.music = inst;
            inst.persist = true;
        }

        FlxG.sound.play(Paths.sound("cancelMenu"));
        allowInputs = false;

        FlxG.switchState(MainMenu.new);
    }

    function openResetScreen():Void {
        var screen:ResetScoreScreen = new ResetScoreScreen();
        screen.songs = [songs[selection].folder];
        screen.difficulty = difficulties[difficulty];
        screen.display = '"${songs[selection].name}" with difficulty "${screen.difficulty}"';
        screen.onReset = updateScoreData;
        openSubState(screen);
    }

    function openChartEditor():Void {
        BGM.stopMusic();

        PlayState.gameMode = DEBUG;
        allowInputs = false;

        var chartEditor:ChartEditor = new ChartEditor(null, difficulties[difficulty]);
        Transition.onComplete.add(() -> {
            // avoid lag
            PlayState.load(songs[selection].folder, chartEditor.difficulty);
            chartEditor.chart = PlayState.song;
        });

        FlxG.switchState(() -> chartEditor);
    }

    function updateScoreData():Void {
        scoreData = Scoring.self.getSession('${songs[selection].folder}-${difficulties[difficulty]}');
    }

    inline function iconFollow(icon:HealthIcon, item:Alphabet):Void {
        icon.setPosition(item.x + item.width + 10, item.y + (item.height - icon.height) * 0.5);
    }

    function playInstrumental():Void {
        if (inst == null) return;

        FlxG.sound.music.fadeOut(0.5, 0);

        #if (target.threaded)
        sys.thread.Thread.create(loadInst);
        #else
        loadInst();
        #end
    }

    function stopInst():Void {
        if (inst == null) return;

        inst.fadeOut(0.5, 0, ((_) -> inst.pause()));
        FlxG.sound.music.fadeOut(0.5, 1);
    }

    function loadInst():Void {
        // get the corresponding inst file
        var finalAsset:openfl.media.Sound = null;

        try {
            var song:String = songs[selection].folder;
            var file:String = null;

            var chartFile:Dynamic = Paths.json('songs/${song}/charts/${difficulties[difficulty]}');
            if (chartFile != null) {
                if (chartFile.gameplayInfo != null || chartFile.gameplayInfo.instrumental != null)
                    file = chartFile.gameplayInfo.instrumental;
                else if (chartFile.song != null)
                    file = "Inst";
            }
            else
                file = Paths.json('songs/${song}/meta').instrumental;
    
            finalAsset = Paths.songMusic(song, file);
        }
        catch (e) {
            // fallback
            trace('Failed to load instrumental! [${e.message}]');
            finalAsset = Paths.music("chillFresh");
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

            if (FlxG.sound.music != null) {
                FlxG.sound.music.fadeTween?.cancel();
                FlxG.sound.music.volume = 1;
            }
        }

        songs = null;
        difficulties = null;
        scoreData = null;

        super.destroy();
    }

    public static function loadFreeplaySongs():Array<SongStructure> {
        var lists:Array<String> = [];

        Assets.invoke((source) -> {
            var extension:String = TXT.findExtension("data/freeplaySongs", source);

            if (extension != null)
                lists.push(source.getContent("data/freeplaySongs" + extension));
        });

        if (lists.length == 0)
            return null;

        var list:Array<SongStructure> = [];

        for (content in lists) {
            for (line in content.split("\n")) {
                var song:String = line.trim();
    
                var meta:SongMeta = Paths.json('songs/${song}/meta');
                if (meta == null || (meta.freeplayInfo?.parentWeek != null && !SongProgress.unlocked(meta.freeplayInfo.parentWeek, true)))
                    continue;
    
                var color:FlxColor = FlxColor.WHITE;
                if (meta.freeplayInfo?.color != null)
                    color = Tools.getColor(meta.freeplayInfo.color);
    
                list.push({
                    name: meta.name ?? song,
                    folder: song,
                    icon: meta.freeplayInfo?.icon ?? HealthIcon.DEFAULT_ICON,
                    difficulties: meta.difficulties ?? ["Easy", "Normal", "Hard"],
                    color: color
                });
            }
        }

        return list;
    }
}

class Background extends FlxSprite {
    public var intendedColor(default, set):FlxColor = FlxColor.WHITE;
    var oldColor:FlxColor = FlxColor.WHITE;

    var parent:FreeplayMenu;
    var tmr:Float;

    public function new(parent:FreeplayMenu):Void {
        super(0, 0, Paths.image("menus/menuDesat"));
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

        if (Options.editorAccess) {
            instructionText.insert(1, "SHIFT + ENTER: open song in chart editor");
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
            text.setFormat(Paths.font("vcr"), 18, FlxColor.WHITE, (center) ? CENTER : ((right) ? RIGHT : LEFT));
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
        if (show) updateVisuals();
        x = Tools.lerp(x, (show) ? FlxG.width - background.width : FlxG.width, 24);
    }

    inline function updateVisuals():Void {
        if (lerpAccuracy != parent.scoreData.accuracy) {
            lerpAccuracy = Tools.lerp(lerpAccuracy, parent.scoreData.accuracy, 6);
            if (Math.abs(lerpAccuracy - parent.scoreData.accuracy) <= 5)
                lerpAccuracy = parent.scoreData.accuracy;
        }
        
        var fullText:String = 'MISSES: ${parent.scoreData.misses}\nACCURACY: ${FlxMath.roundDecimal(lerpAccuracy, 2)}%';
        if (parent.scoreData.rank?.length > 0) fullText += '\nRANK: ${parent.scoreData.rank}';
        text.text = fullText;

        updateBgScale();
    }

    function updateBgScale():Void {
        background.scale.set(text.width + 10, text.height + 10);
        background.updateHitbox();
        background.centerToObject(text);
    }

    override function destroy():Void {
        parent = null;
        super.destroy();
    }
}

@:structInit class SongStructure {
    public var name:String;
    public var folder:String;
    public var difficulties:Array<String>;
    public var color:FlxColor;
    public var icon:String;
}
