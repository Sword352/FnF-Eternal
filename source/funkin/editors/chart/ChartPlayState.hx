package funkin.editors.chart;

import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.*;

import funkin.gameplay.notes.*;
import funkin.ui.HealthIcon;
import funkin.gameplay.components.Rating;
import funkin.gameplay.components.ComboPopup;
import funkin.data.ChartLoader;

/**
 * TODO:
 * - Fix bugs
 *   - Time resync at music start
 * - Do less copy-paste and make the code cleaner
 */
class ChartPlayState extends MusicBeatSubState {
    var strumLines:Array<StrumLine>;
    var opponentStrumline:StrumLine;
    var playerStrumline:StrumLine;
    var noteSpawner:NoteSpawner;

    var ratings:Array<Rating> = Rating.getDefault();

    var playerNoteCount:FlxText;
    var oppNoteCount:FlxText;
    var infos:FlxText;

    var comboPopup:ComboPopup;
    var icons:Array<HealthIcon> = [];

    var playAsOpponent:Bool = false;
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

    public function new(parent:ChartEditor, startTime:Float = 0, playAsOpponent:Bool = false):Void {
        super();

        this.parent = parent;
        this.playAsOpponent = playAsOpponent;
        this.startTime = startTime;
    }

    override function create():Void {
        conductor.interpolate = true;
        conductor.active = true;
        conductor.music = null;

        conductor.onMeasure.remove(parent.measureHit);
        conductor.onBeat.remove(parent.beatHit);

        super.create();

        var background:FlxSprite = new FlxSprite();
        background.makeRect(FlxG.width, FlxG.height, FlxColor.BLACK, false, "charteditor_substatebg");
        background.alpha = 0.6;
        add(background);

        comboPopup = new ComboPopup(ratings.length);
        comboPopup.cameras = cameras; // TODO: remove this when sprite group cameras are fixed
        add(comboPopup);

        Paths.image('game/combo-numbers');
        Paths.image('game/ratings');

        var noteSkinExists:Bool = parent.chart.gameplayInfo.noteSkins != null;
        var plrNoteSkin:String = (noteSkinExists ? parent.chart.gameplayInfo.noteSkins[1] : "default") ?? "default";
        var oppNoteSkin:String = (noteSkinExists ? parent.chart.gameplayInfo.noteSkins[0] : "default") ?? "default";

        opponentStrumline = new StrumLine(FlxG.width * 0.25, 55, !playAsOpponent, oppNoteSkin);
        opponentStrumline.scrollSpeed = parent.chart.gameplayInfo.scrollSpeed;

        playerStrumline = new StrumLine(FlxG.width * 0.75, 55, playAsOpponent, plrNoteSkin);
        playerStrumline.scrollSpeed = opponentStrumline.scrollSpeed;
        playerStrumline.owner = PLAYER;

        if (playAsOpponent) {
            var temp:StrumLine = playerStrumline;
            playerStrumline = opponentStrumline;
            opponentStrumline = temp;
        }

        opponentStrumline.onNoteHit.add(onOpponentNoteHit);
        playerStrumline.onNoteHit.add(processNoteHit);
        playerStrumline.onHoldInvalidation.add(onHoldInvalidation);
        playerStrumline.onGhostMiss.add((_) -> onMiss());
        playerStrumline.onHold.add(onHold);
        playerStrumline.onMiss.add(onMiss);

        strumLines = [opponentStrumline, playerStrumline];
        if (playAsOpponent) strumLines.reverse();

        noteSpawner = new NoteSpawner(strumLines, startTime);
        add(noteSpawner);

        add(opponentStrumline);
        add(playerStrumline);

        if (Options.downscroll) {
            playerStrumline.y = opponentStrumline.y = FlxG.height * 0.8;
        }
        if (Options.centeredStrumline) {
            playerStrumline.x = FlxG.width / 2;
            opponentStrumline.visible = false;
        }

        createUI();

        conductor.time = startTime - (850 * parent.music.pitch);
        conductor.rate = parent.music.pitch;
        parent.music.onComplete.add(close);

        camera.alpha = 0;
        FlxTween.tween(camera, {alpha: 1}, 0.6, {ease: FlxEase.circOut});

        startTimer = new FlxTimer().start(0.85, (_) -> {
            conductor.music = parent.music.instrumental;
            conductor.interpolate = false;
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

        parent.updateCurrentBPM();
        super.update(elapsed);
        updateUI();
    }

    override function beatHit(beat:Int):Void {
        if (parent.music.playing)
            for (icon in icons)
                icon.bop();
    }

    inline function processNoteHit(note:Note):Void {
        if (playerStrumline.cpu)
            onBotplayNoteHit(note);
        else
            onNoteHit(note);
    }

    inline function onNoteHit(note:Note):Void {
        note.ID = -1;
        totalPlayerNotes++;

        var rating:Rating = ratings[ratings.length - 1];

        for (entry in ratings) {
            if ((Math.abs(note.time - Conductor.self.time) / Conductor.self.rate) <= entry.hitWindow) {
                rating = entry;
                break;
            }
        }

        health += rating.health;
        accuracyMod += rating.accuracyMod;
        accuracyNotes++;

        comboPopup.displayRating(rating);

        combo++;
        if (!rating.breakCombo && combo > 0)
            comboPopup.displayCombo(combo);

        if (rating.displaySplash && !Options.noNoteSplash)
            playerStrumline.popSplash(note);
    }

    inline function onBotplayNoteHit(note:Note):Void {
        note.ID = -1;
        totalPlayerNotes++;
        health += 0.023;
    }

    inline function onHold(_):Void {
        health += 0.023;
    }

    inline function onHoldInvalidation(note:Note):Void {
        var remainingLength:Float = note.length - (conductor.time - note.time);
        var fraction:Float = (remainingLength / (conductor.semiQuaver * 2)) + 1;

        health -= 0.0475 * fraction;
        accuracyNotes += Math.floor(fraction);
        missCount++;
        combo = 0;
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

    function updateUI():Void {
        var acc:String = "N/A";
        if (accuracyNotes > 0 && accuracyMod > 0)
            acc = FlxMath.roundDecimal(FlxMath.bound(accuracyMod / accuracyNotes, 0, 1) * 100, 2) + "%";

        infos.text = '${parent.getTimeInfo()} - ${parent.getBPMInfo()}\n'
            + 'Step: ${conductor.step} - Beat: ${conductor.beat} - Measure: ${conductor.measure}\n'
            + 'Misses: ${missCount} - Accuracy: ${acc} - Botplay: ${(playerStrumline.cpu) ? 'ON' : 'OFF'}';
        infos.screenCenter(X);

        for (text in [oppNoteCount, playerNoteCount]) {
            var count:String = Std.string((text == (playAsOpponent ? playerNoteCount : oppNoteCount)) ? totalOppNotes : totalPlayerNotes);
            while (count.length < 4)
                count = "0" + count;

            var seperatedCount:Array<String> = count.split("");
            for (i in 0...seperatedCount.length - 1)
                seperatedCount[i] = seperatedCount[i] + " ";

            text.text = seperatedCount.join("");
            text.x = ((FlxG.width - text.width) * ((text == oppNoteCount) ? 0.35 : 0.65));
        }

        var actualHealth:Float = health * 50;
        if (playAsOpponent) actualHealth = 100 - actualHealth;

        for (i in 0...icons.length) {
            var icon:HealthIcon = icons[i];
            icon.x = (i == 0) ? (infos.x - icon.width - 5) : (infos.x + infos.width + 5);
            icon.health = (i == 0 ? 100 - actualHealth : actualHealth);
            icon.centerToObject(infos, Y);
        }
    }

    inline function createUI():Void {
        infos = new FlxText(0, FlxG.height * ((playerStrumline.downscroll) ? 0.1 : 0.875));
        infos.setFormat(Paths.font("vcr"), 20, FlxColor.WHITE, CENTER);
        infos.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        add(infos);

        oppNoteCount = new FlxText(0, FlxG.height * ((playerStrumline.downscroll) ? 0.95 : 0.025), 0, "0 0 0 0");
        oppNoteCount.setFormat(infos.font, 32);
        oppNoteCount.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.25);
        add(oppNoteCount);

        playerNoteCount = new FlxText(0, oppNoteCount.y, 0, "0 0 0 0");
        playerNoteCount.setFormat(infos.font, 32);
        playerNoteCount.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.25);
        add(playerNoteCount);

        updateUI();

        var parentIcons:Array<HealthIcon> = [parent.opponentIcon, parent.playerIcon];

        for (i in 0...parentIcons.length) {
            var parentIcon:HealthIcon = parentIcons[i];

            var icon:HealthIcon = new HealthIcon(0, 0, parentIcon.character);
            icon.flipX = (i == 1);
            icon.health = 50;
            icons.push(icon);
            add(icon);
        }
    }

    override function destroy():Void {
        ratings = FlxDestroyUtil.destroyArray(ratings);
        strumLines = null;
        startTimer = null;
        ratings = null;
        icons = null;

        FlxG.mouse.visible = true;

        parent.music.onComplete.remove(close);
        parent.music.pause();

        conductor.music = parent.music.instrumental;
        conductor.interpolate = false;
        conductor.rate = 1;

        conductor.onMeasure.add(parent.measureHit);
        conductor.onBeat.add(parent.beatHit);

        parent.line.y = ChartEditor.getYFromTime(conductor.rawTime);
        parent = null;

        super.destroy();
    }

    inline function set_health(v:Float):Float
        return health = FlxMath.bound(v, 0, 2);
}
