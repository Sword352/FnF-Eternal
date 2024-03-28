package funkin.states.debug.chart;

import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxStringUtil;
import flixel.group.FlxSpriteGroup;

import funkin.gameplay.Rating;
import funkin.gameplay.notes.*;
import funkin.objects.HealthIcon;
import funkin.gameplay.ComboPopup;
import funkin.gameplay.notes.StrumLine.NoteHit;

import funkin.globals.ChartLoader;

/**
 * TODO:
 * - Fix bugs
 *   - Time resync at music start
 *   - Beat callbacks not being called when starting at precise times (?)
 * - Do less copy-paste and make the code cleaner
 */
class ChartPlayState extends MusicBeatSubState {
    var strumLines:Array<StrumLine>;
    var opponentStrumline:StrumLine;
    var playerStrumline:StrumLine;
    var notes:Array<Note>;

    var ratings:Array<Rating> = Rating.getDefaultList();

    var playerNoteCount:FlxText;
    var oppNoteCount:FlxText;
    var infos:FlxText;

    var ratingSprites:FlxTypedSpriteGroup<RatingSprite>;
    var comboSprites:FlxTypedSpriteGroup<ComboSprite>;
    var icons:Array<HealthIcon> = [];

    var totalPlayerNotes:Int = 0;
    var totalOppNotes:Int = 0;

    var missCount:Int = 0;
    var combo:Int = 0;

    var health(default, set):Float = 1;
    var accuracyNotes:Int = 0;
    var accuracyMod:Float = 0;

    var startTimer:FlxTimer;
    var startTime:Float;

    var parent:ChartEditor;

    public function new(parent:ChartEditor, startTime:Float = 0):Void {
        super();
        this.parent = parent;
        this.startTime = startTime;
    }

    override function create():Void {
        Conductor.resetTime();
        Conductor.music = null;
        Conductor.updateInterp = true;

        Conductor.onStep.remove(parent.stepHit);
        Conductor.onBeat.remove(parent.beatHit);
        Conductor.onMeasure.remove(parent.measureHit);

        super.create();

        var background:FlxSprite = new FlxSprite();
        background.makeRect(FlxG.width, FlxG.height, FlxColor.BLACK, false, "charteditor_substatebg");
        background.alpha = 0;
        add(background);

        FlxTween.tween(background, {alpha: 0.6}, 0.25);

        comboSprites = new FlxTypedSpriteGroup<ComboSprite>();
        add(comboSprites);

        ratingSprites = new FlxTypedSpriteGroup<RatingSprite>();
        add(ratingSprites);

        for (rating in ratings)
            if (rating.image != null)
                Assets.image('ui/gameplay/${rating.image}');

        for (i in 0...10)
            Assets.image('ui/gameplay/num${i}');

        opponentStrumline = new StrumLine(FlxG.width * 0.25, 55, true);
        opponentStrumline.scrollSpeed = parent.chart.meta.scrollSpeed / parent.music.pitch;
        opponentStrumline.onNoteHit.add(onOpponentNoteHit);
        add(opponentStrumline);

        playerStrumline = new StrumLine(FlxG.width * 0.75, 55);
        playerStrumline.scrollSpeed = opponentStrumline.scrollSpeed;
        playerStrumline.onNoteHit.add(onBotplayNoteHit);
        playerStrumline.onHold.add(onHold);
        playerStrumline.onMiss.add(onMiss);
        add(playerStrumline);

        if (Settings.get("downscroll")) {
            playerStrumline.downscroll = opponentStrumline.downscroll = true;
            playerStrumline.y = opponentStrumline.y = FlxG.height * 0.8;
        }
        if (Settings.get("centered strumline")) {
            opponentStrumline.visible = false;
            playerStrumline.screenCenter(X);
        }

        createUI();

        opponentStrumline.tweenReceptors(0, 0.05);
        playerStrumline.tweenReceptors(0, 0.05);

        strumLines = [opponentStrumline, playerStrumline];

        // TODO: recycle notes
        notes = ChartLoader.generateNotes(parent.chart, startTime, strumLines);

        FlxG.stage.application.window.onKeyDown.add(onKeyDown);
        FlxG.stage.application.window.onKeyUp.add(onKeyUp);

        Conductor.time = startTime - (850 * parent.music.pitch);
        Conductor.playbackRate = parent.music.pitch;
        parent.music.onSongEnd.add(close);

        startTimer = new FlxTimer().start(0.85, (_) -> {
            Conductor.music = parent.music.instrumental;
            parent.music.play(startTime);
        });
    }

    override function update(elapsed:Float):Void {
        if (FlxG.keys.justPressed.ESCAPE) {
            if (!startTimer.finished)
                startTimer.cancel();

            close();
            return;
        }

        if (controls.justPressed("autoplay"))
            playerStrumline.cpu = !playerStrumline.cpu;

        Conductor.update(elapsed);
        parent.updateCurrentBPM();

        while (notes.length > 0) {
            var note:Note = notes[0];
            if ((note.time - Conductor.time) > (1800 / note.getScrollSpeed()))
                break;

            strumLines[note.strumline].addNote(note);
            notes.shift();
        }

        updateUI();
        super.update(elapsed);
    }

    override function stepHit(currentStep:Int):Void
        parent.music.resync();

    override function beatHit(currentBeat:Int):Void {
        if (parent.music.playing)
            for (icon in icons)
                icon.bop();
    }

    inline function onKeyDown(rawKey:Int, _):Void {
        var dir:Int = playerStrumline.getDirFromKey(Tools.convertLimeKey(rawKey));
        if (playerStrumline.cpu || dir == -1) return;

        var noteHit:NoteHit = playerStrumline.keyHit(dir);
        if (noteHit != null) {
            switch (noteHit) {
                case NOTE_HIT(note):
                    onNoteHit(note);
                case MISSED:
                    onMiss();
            }
        }
    }

    inline function onKeyUp(rawKey:Int, _):Void {
        var dir:Int = playerStrumline.getDirFromKey(Tools.convertLimeKey(rawKey), true);
        if (dir != -1 && !playerStrumline.cpu)
            playerStrumline.keyRelease(dir);
    }

    inline function onNoteHit(note:Note):Void {
        note.goodHit = true;
        note.ID = -1;

        playerStrumline.receptors.members[note.direction].playAnimation("confirm", true);
        totalPlayerNotes++;
        health += 0.023;

        var rating:Rating = note.findRating(ratings);

        accuracyMod += rating.accuracyMod;
        accuracyNotes++;

        displayRating(rating);

        combo++;
        if (rating.displayCombo && combo > 0)
            displayCombo();

        if (rating.displayNoteSplash && !Settings.get("disable note splashes"))
            playerStrumline.popSplash(note.direction);

        playerStrumline.hitNote(note);
    }

    inline function onBotplayNoteHit(note:Note):Void {
        note.ID = -1;
        totalPlayerNotes++;
        health += 0.023;
    }

    inline function onHold(_):Void {
        health += 0.023;
    }

    inline function onOpponentNoteHit(_):Void {
        totalOppNotes++;
    }

    inline function onMiss(?note:Note):Void {
        if (note != null && note.ID != -1) {
            totalPlayerNotes++;
            note.ID = -1;
        }

        health -= 0.0475;

        combo = 0;
        accuracyNotes++;
        missCount++;
    }

    inline function displayCombo():Void {
        var separatedCombo:String = Std.string(combo);
        if (!Settings.get("simplify combo number"))
            while (separatedCombo.length < 3)
                separatedCombo = "0" + separatedCombo;

        if (Settings.get("disable combo stacking")) {
            for (spr in comboSprites)
                spr.kill();
        }

        for (i in 0...separatedCombo.length) {
            var sprite:ComboSprite = comboSprites.recycle(ComboSprite);
            sprite.loadGraphic(Assets.image('ui/gameplay/num${separatedCombo.charAt(i)}'));
            sprite.scale.set(0.5, 0.5);
            sprite.updateHitbox();
            sprite.screenCenter();
            sprite.x += 43 * (i + 1);
            sprite.y += 140;

            comboSprites.remove(sprite, true);
            comboSprites.insert(comboSprites.length + 1, sprite);
        }
    }

    inline function displayRating(rating:Rating):Void {
        if (rating.image == null) return;

        if (Settings.get("disable combo stacking")) {
            for (spr in ratingSprites)
                spr.kill();
        }

        var sprite:RatingSprite = ratingSprites.recycle(RatingSprite);
        sprite.loadGraphic(Assets.image('ui/gameplay/${rating.image}'));
        sprite.scale.set(0.7, 0.7);
        sprite.updateHitbox();
        sprite.screenCenter();

        ratingSprites.remove(sprite, true);
        ratingSprites.insert(ratingSprites.length + 1, sprite);
    }

    inline function updateUI():Void {
        var acc:String = "N/A";
        if (accuracyNotes > 0 && accuracyMod > 0)
            acc = FlxMath.roundDecimal(FlxMath.bound(accuracyMod / accuracyNotes, 0, 1) * 100, 2) + "%";

        infos.text = '${parent.getTimeInfo()} - ${parent.getBPMInfo()}\n'
            + 'Step: ${Conductor.currentStep} - Beat: ${Conductor.currentBeat} - Measure: ${Conductor.currentMeasure}\n'
            + 'Misses: ${missCount} - Accuracy: ${acc} - Botplay: ${(playerStrumline.cpu) ? 'ON' : 'OFF'}';
        infos.screenCenter(X);

        for (text in [oppNoteCount, playerNoteCount]) {
            var count:String = Std.string((text == oppNoteCount) ? totalOppNotes : totalPlayerNotes);
            while (count.length < 4)
                count = "0" + count;

            var seperatedCount:Array<String> = count.split("");
            for (i in 0...seperatedCount.length - 1)
                seperatedCount[i] = seperatedCount[i] + " ";

            text.text = seperatedCount.join("");
            text.x = ((FlxG.width - text.width) * ((text == oppNoteCount) ? 0.35 : 0.65));
        }

        for (i in 0...icons.length) {
            var icon:HealthIcon = icons[i];

            icon.x = (i == 0) ? (infos.x - icon.width - 5) : (infos.x + infos.width + 5);
            icon.health = (health * 50);

            if (i == 0)
                icon.health = (100 - icon.health);
        }
    }

    inline function createUI():Void {
        infos = new FlxText(0, FlxG.height * ((playerStrumline.downscroll) ? 0.1 : 0.875));
        infos.setFormat(Assets.font("vcr"), 20, FlxColor.WHITE, CENTER);
        infos.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        infos.alpha = 0;
        add(infos);

        oppNoteCount = new FlxText(0, FlxG.height * ((playerStrumline.downscroll) ? 0.95 : 0.025), 0, "0 0 0 0");
        oppNoteCount.setFormat(infos.font, 32);
        oppNoteCount.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.25);
        oppNoteCount.alpha = 0;
        add(oppNoteCount);

        playerNoteCount = new FlxText(0, oppNoteCount.y, 0, "0 0 0 0");
        playerNoteCount.setFormat(infos.font, 32);
        playerNoteCount.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.25);
        playerNoteCount.alpha = 0;
        add(playerNoteCount);

        updateUI();

        var parentIcons:Array<HealthIcon> = [parent.opponentIcon, parent.playerIcon];

        for (i in 0...parentIcons.length) {
            var parentIcon:HealthIcon = parentIcons[i];

            var icon:HealthIcon = new HealthIcon(0, 0, parentIcon.character);
            icon.y = infos.y + ((infos.height - icon.height) * 0.5);
            icon.flipX = (i == 1);
            icon.bopping = true;
            icon.health = 50;
            icon.alpha = 0;

            icon.bopSpeed *= parent.music.pitch;
            icons.push(icon);
            add(icon);
        }

        for (text in [infos, oppNoteCount, playerNoteCount]) {
            var twn = FlxTween.tween(text, {alpha: 1}, 1, {startDelay: 0.25});
            if (text == infos) {
                twn.onUpdate = (_) -> {
                    if (icons != null)
                        for (icon in icons)
                            icon.alpha = text.alpha;
                };
            }
        }
    }

    override function destroy():Void {
        while (notes.length > 0)
            notes.pop().destroy();

        while (ratings.length > 0)
            ratings.pop().destroy();

        strumLines = null;
        startTimer = null;
        ratings = null;
        notes = null;
        icons = null;

        FlxG.stage.application.window.onKeyDown.remove(onKeyDown);
        FlxG.stage.application.window.onKeyUp.remove(onKeyUp);

        super.destroy();

        parent.music.onSongEnd.remove(close);
        parent.music.pause();

        Conductor.music = parent.music.instrumental;
        Conductor.updateInterp = false;
        Conductor.playbackRate = 1;

        Conductor.onStep.add(parent.stepHit);
        Conductor.onBeat.add(parent.beatHit);
        Conductor.onMeasure.add(parent.measureHit);

        parent.line.y = ChartEditor.getYFromTime(Conductor.time);
        parent = null;
    }

    inline function set_health(v:Float):Float
        return health = FlxMath.bound(v, 0, 2);
}
