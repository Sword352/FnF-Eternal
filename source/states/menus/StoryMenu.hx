package states.menus;

import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;

import objects.OffsetSprite;
import objects.DancingSprite;
import states.substates.ResetScoreScreen;
import globals.SongProgress;

class StoryMenu extends MusicBeatState {
    var weekSprites:FlxTypedSpriteGroup<WeekSprite>;
    var difficultySprite:FlxSprite;
    var arrows:FlxSpriteGroup;

    var yellowOverlay:FlxSprite;
    var scoreText:FlxText;
    var tagline:FlxText;

    var songDisplay:FlxText;
    var tracks:FlxText;

    var charactersData:Map<String, StoryCharacterData> = [];
    var characters:FlxTypedSpriteGroup<StoryMenuCharacter>;

    var weeks:Array<WeekStructure>;
    var difficulties:Array<String>;

    var currentDifficulty:Int = 0;
    var currentSelection:Int = 0;

    var intendedScore:Float;
    var lerpScore:Float;

    var flashTimer:Float = 0;
    var doFlash:Bool = false;

    var allowInputs:Bool = true;
    var error:Bool = false;

    override function create():Void {
        weeks = loadWeeks();

        if (weeks == null || weeks.length < 1) {
            trace("Error loading weeks, going back to the Main Menu.");

            error = true;
            FlxG.switchState(MainMenu.new);
            return;
        }

        PlayState.gameMode = STORY;

        #if ENGINE_DISCORD_RPC
        DiscordPresence.presence.details = "Story Menu";
        #end

        super.create();

        #if ENGINE_SCIRPTING
        initStateScripts();
        scripts.call("onCreate");
        #end

        Tools.playMusicCheck("freakyMenu");
        conductor.music = FlxG.sound.music;
        conductor.bpm = 102;

        // load menu characters
        for (week in weeks) {
            if (week.characters == null) continue;

            for (character in week.characters) {
                if (character == "#NONE" || charactersData.exists(character)) continue;

                var data:StoryCharacterData = Tools.parseYAML(FileTools.getContent(Assets.yaml('images/menus/story/characters/${character}')));
                charactersData.set(character, data);

                // TODO: find a better solution, this should be good for now
                var cache:FlxSprite = new FlxSprite();
                cache.frames = Assets.getSparrowAtlas('menus/story/characters/${data.image ?? character}');
                cache.alpha = 0.000001;
                add(cache);

                @:privateAccess cache.drawComplex(camera);
            }
        }

        weekSprites = new FlxTypedSpriteGroup<WeekSprite>();
        add(weekSprites);

        yellowOverlay = new FlxSprite(0, 56);
        yellowOverlay.makeRect(FlxG.width, 400, 0xFFF9CF51);

        tracks = new FlxText(FlxG.width * 0.05, yellowOverlay.x + yellowOverlay.height + 100, 0, "TRACKS");
        tracks.setFormat(Assets.font("vcr"), 44, 0xFFe55777);
        add(tracks);

        songDisplay = new FlxText(tracks.x, tracks.y + 50);
        songDisplay.setFormat(tracks.font, 32, tracks.color, CENTER);
        add(songDisplay);

        for (i in 0...weeks.length)
            weekSprites.add(new WeekSprite(weeks[i], i));

        add(yellowOverlay);

        arrows = new FlxSpriteGroup();
        add(arrows);

        for (i in 0...2) {
            var direction:String = (i == 0) ? "left" : "right";

            var arrow:OffsetSprite = new OffsetSprite((FlxG.width * 0.8) + (150 * i), yellowOverlay.y + yellowOverlay.height + 10);
            arrow.frames = Assets.getSparrowAtlas("menus/story/ui");
            arrow.animation.addByPrefix("normal", 'arrow ${direction}', 0);
            arrow.animation.addByPrefix("press", 'arrow push ${direction}', 0);
            arrow.animation.play("normal", true);
            arrow.ID = i;
            arrows.add(arrow);
        }

        add(difficultySprite = new OffsetSprite());

        scoreText = new FlxText(10, 10);
        scoreText.setFormat(tracks.font, 32);
        add(scoreText);

        tagline = new FlxText(0, 10);
        tagline.setFormat(tracks.font, 32, FlxColor.WHITE, RIGHT);
        tagline.alpha = 0.7;
        add(tagline);

        characters = new FlxTypedSpriteGroup<StoryMenuCharacter>();
        for (i in 0...3) characters.add(new StoryMenuCharacter());
        add(characters);

        changeSelection();

        #if ENGINE_SCRIPTING
        scripts.call("onCreatePost");
        #end
    }

    override function update(elapsed:Float):Void {
        if (error) return;

        scripts.call("onUpdate", [elapsed]);
        super.update(elapsed);

        if (allowInputs) {
            if (controls.justPressed("back")) {
                allowInputs = false;
                FlxG.sound.play(Assets.sound("cancelMenu"));
                FlxG.switchState(MainMenu.new);
            }

            if (weekSprites.length > 1 && controls.anyJustPressed(["up", "down"])) changeSelection((controls.lastAction == "up") ? -1 : 1);
            if (difficulties.length > 1 && controls.anyJustPressed(["left", "right"])) changeDifficulty((controls.lastAction == "left") ? -1 : 1);

            if (controls.justPressed("accept")) accept();

            if (FlxG.keys.justPressed.R) {
                persistentUpdate = false;

                var screen:ResetScoreScreen = new ResetScoreScreen();
                screen.songs = [for (s in weeks[currentSelection].songs) s.folder];
                screen.difficulty = difficulties[currentDifficulty];
                screen.display = '"Week ${currentSelection + 1}" with difficulty "${screen.difficulty}"';
                screen.onReset = updateScore;
                screen.story = true;
                openSubState(screen);
            }
        }

        if (doFlash) {
            flashTimer += elapsed;
            if (flashTimer >= 0.05) {
                var sprite:FlxSprite = weekSprites.members[currentSelection];
                sprite.color = (sprite.color == FlxColor.WHITE) ? FlxColor.CYAN : FlxColor.WHITE;
                flashTimer = 0;
            }
        }

        lerpScore = Math.floor(Tools.lerp(lerpScore, intendedScore, 10));
        if (lerpScore != intendedScore && Math.abs(lerpScore - intendedScore) <= 10)
            lerpScore = intendedScore;

        scoreText.text = 'SCORE: ${lerpScore}';

        for (sprite in weekSprites) {
            sprite.y = Tools.lerp(sprite.y, sprite.ID * 120 + 480, 8.5);
            sprite.visible = (sprite.y > yellowOverlay.y);
        }

        for (arrow in arrows) {
            var animation:String = (controls.pressed((arrow.ID == 0) ? "left" : "right")) ? "press" : "normal";
            if (arrow.animation.name != animation)
                arrow.animation.play(animation, true);
        }

        #if ENGINE_SCRIPTING
        scripts.call("onUpdatePost", [elapsed]);
        #end
    }

    override function beatHit(beat:Int):Void {
        for (character in characters)
            if (character.danceSteps.length > 0 && character.animation.name != "confirm")
                character.dance(beat, true);

        super.beatHit(beat);
    }

    function changeSelection(i:Int = 0):Void {
        currentSelection = FlxMath.wrap(currentSelection + i, 0, weeks.length - 1);

        if (i != 0)
            FlxG.sound.play(Assets.sound("scrollMenu"));

        for (sprite in weekSprites) {
            sprite.ID = weekSprites.members.indexOf(sprite) - currentSelection;
            sprite.alpha = (sprite.ID == 0) ? 1 : 0.6;
        }

        tagline.text = weeks[currentSelection].tagline;
        tagline.x = FlxG.width - tagline.width - 10;

        var oldDifficulty:String = (difficulties != null) ? difficulties[currentDifficulty] : null;

        difficulties = weeks[currentSelection].difficulties;
        currentDifficulty = Std.int(FlxMath.bound(currentDifficulty, 0, difficulties.length - 1));

        if (difficulties.contains(oldDifficulty))
            currentDifficulty = difficulties.indexOf(oldDifficulty);

        updateDifficultySprite();

        var songList:String = "";
        for (song in weeks[currentSelection].songs)
            songList += song.name + "\n";

        songDisplay.text = songList;
        songDisplay.centerToObject(tracks, X);

        updateScore();

        var intendedCharacters:Array<String> = weeks[currentSelection].characters;
        characters.visible = intendedCharacters != null;

        if (characters.visible) {
            for (i in 0...characters.members.length) {
                var characterString:String = intendedCharacters[i];
                var character:StoryMenuCharacter = characters.members[i];

                character.visible = (characterString != null && characterString != "#NONE");
                if (!character.visible) continue;

                character.setup(characterString, charactersData.get(characterString));
                character.x = (FlxG.width * 0.25) * (i + 1) - 150;
                character.centerToObject(yellowOverlay, Y);
            }
        }
    }

    function changeDifficulty(i:Int = 0):Void {
        currentDifficulty = FlxMath.wrap(currentDifficulty + i, 0, difficulties.length - 1);
        updateDifficultySprite();
        updateScore();
    }

    function updateDifficultySprite():Void {
        // TODO: do not lowercase the difficulty (this is a temporary workaround for openfl assets)
        var graphic = Assets.image('menus/story/${difficulties[currentDifficulty].toLowerCase()}');
        if (difficultySprite.graphic == graphic) return;

        FlxTween.cancelTweensOf(difficultySprite);

        difficultySprite.loadGraphic(graphic);
        difficultySprite.updateHitbox();
        difficultySprite.x = (FlxG.width * 0.825) - (difficultySprite.width * 0.5);

        var leftArrow:FlxSprite = arrows.members[0];
        var rightArrow:FlxSprite = arrows.members[1];

        leftArrow.x = difficultySprite.x - leftArrow.width - 10;
        rightArrow.x = difficultySprite.x + difficultySprite.width + 10;
        difficultySprite.y = rightArrow.y - 15;

        difficultySprite.alpha = 0;
        FlxTween.tween(difficultySprite, {y: rightArrow.y + 15, alpha: 1}, 0.07);
    }

    inline function updateScore():Void {
        intendedScore = 0;

        for (song in weeks[currentSelection].songs)
            intendedScore += Math.floor(HighScore.get('${song.folder}-${difficulties[currentDifficulty]}_story').score);
    }

    function accept():Void {
        // locked week
        if (weekSprites.members[currentSelection].lock != null) {
            // FlxG.sound.play(Assets.sound("dialogueTick"));
            return;
        }

        #if ENGINE_SCRIPTING
        if (scripts.quickEvent("onAccept").cancelled) return;
        #end

        allowInputs = false;
        FlxG.sound.play(Assets.sound("confirmMenu"));

        weekSprites.members[currentSelection].color = FlxColor.CYAN;
        doFlash = !Options.noFlashingLights;

        for (character in characters)
            if (character.animation.exists("confirm"))
                character.playAnimation("confirm", true);

        var songs:Array<String> = [for (s in weeks[currentSelection].songs) s.folder];
        Transition.onComplete.add(() -> PlayState.load(songs.shift(), difficulties[currentDifficulty]));

        PlayState.weekToUnlock = weeks[currentSelection].unlockableWeek;
        PlayState.songPlaylist = songs;

        new FlxTimer().start(1, (_) -> FlxG.switchState(LoadingScreen.new.bind(0)));
    }

    override function destroy():Void {
        weeks = null;
        difficulties = null;
        charactersData = null;

        super.destroy();
    }

    public static function loadWeeks():Array<WeekStructure> {
        var directories:Array<String> = Assets.listFiles((structure) -> {
            var path:String = structure.getPath("data/weeks", NONE);
            structure.entryExists(path) ? path : null;
        });

        if (directories.length == 0) return null;

        var list:Array<WeekStructure> = [];
        var foundWeeks:Array<String> = [];

        for (directory in directories)
            for (entry in FileTools.readDirectory(directory))
                foundWeeks.push(FileTools.getContent(directory + "/" + entry));

        for (file in foundWeeks) {
            var data = Tools.parseYAML(file);

            var songs:Array<WeekSong> = cast data.songs;
            if (songs == null || songs.length == 0) continue;

            for (song in songs) {
                if (song.folder != null && song.name == null) song.name = song.folder;
                else if (song.folder == null && song.name != null) song.folder = song.name;
            }

            var id:String = file.substring(0, file.lastIndexOf("."));
            var hideIfLocked:Bool = data.hideIfLocked ?? false;
            var locked:Bool = data.locked ?? false;

            if (locked && hideIfLocked && !SongProgress.unlocked(id, true)) continue;

            list.push({
                songs: songs,
                difficulties: data.difficulties ?? ["Easy", "Normal", "Hard"],
                unlockableWeek: data.unlockableWeek,
                locked: locked,
                id: id,

                image: data.image ?? "week",
                tagline: data.tagline ?? "",
                characters: data.characters
            });
        }

        // TODO: reimplement back week orders without messing with mod orders.
        /*
        var orders:Array<String> = Assets.listFiles((structure) -> {
            var path:String = structure.getPath("data/weeks/weekOrder", TEXT);

            if (structure.entryExists(path)) {
                allWeeks.remove(entry.getPath("data/weeks", NONE));
                return structure.getContent(path);
            }
            
            return null;
        });
        */

        return list;
    }
}

class WeekSprite extends FlxSpriteGroup {
    public var handle:OffsetSprite;
    public var lock:OffsetSprite;

    public function new(week:WeekStructure, id:Int):Void {
        super();
        this.ID = id;

        handle = new OffsetSprite();
        handle.loadGraphic(Assets.image('menus/story/${week.image}'));
        handle.screenCenter(X);
        add(handle);

        if (week.locked && !SongProgress.unlocked(week.id, true)) {
            lock = new OffsetSprite(handle.x + handle.width + 10);
            lock.frames = Assets.getSparrowAtlas("menus/story/ui");
            lock.animation.addByPrefix("lock", "lock", 0);
            lock.animation.play("lock", true);
            add(lock);
        }

        y = id * 120 + 480;
    }
}

class StoryMenuCharacter extends DancingSprite {
    var character:String;

    public function setup(character:String, data:StoryCharacterData):Void {
        if (this.character == character) return;
        this.character = character;

        frames = Assets.getSparrowAtlas('menus/story/characters/${data.image ?? character}');
        Tools.addYamlAnimations(this, data.animations);

        danceSteps = data.danceSteps ?? ["idle"];
        beat = data.danceBeat ?? 1;
        flipX = data.flipX ?? false;

        scale.set(data.scale ?? 1, data.scale ?? 1);
        updateHitbox();

        if (data.globalOffsets != null)
            offset.add(data.globalOffsets[0] ?? 0, data.globalOffsets[1] ?? 0);

        forceDance(true);
        animation.finish();

        currentDance = 0;
    }

    override function destroy():Void {
        character = null;
        super.destroy();
    }
}

@:structInit class WeekStructure {
    public var id:String;

    public var songs:Array<WeekSong>;
    public var difficulties:Array<String>;
    public var unlockableWeek:String;
    public var locked:Bool;

    public var image:String;
    public var characters:Array<String>;
    public var tagline:String;
}

typedef WeekSong = {
    var name:String;
    var folder:String;
}

typedef StoryCharacterData = {
    var ?image:String;
    var animations:Array<YAMLAnimation>;

    var ?danceSteps:Array<String>;
    var ?danceBeat:Float;

    var ?globalOffsets:Array<Float>;
    var ?scale:Float;
    var ?flipX:Bool;
}
