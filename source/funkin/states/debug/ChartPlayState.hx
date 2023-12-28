package funkin.states.debug;

import flixel.text.FlxText;
import flixel.tweens.FlxTween;

import funkin.objects.notes.Note;
import funkin.objects.notes.Receptor;
import funkin.objects.notes.StrumLine;

import eternal.ChartLoader;

class ChartPlayState extends MusicBeatSubState {
    var playerStrumline:StrumLine;
    var opponentStrumline:StrumLine;
    var strumlines:Array<StrumLine>;
    var notes:Array<Note>;

    var infos:FlxText;
    var oppNoteCount:FlxText;
    var playerNoteCount:FlxText;

    var missCount:Int = 0;
    var totalPlayerNotes:Int = 0;
    var totalOppNotes:Int = 0;

    var startTimer:FlxTimer;
    var startTime:Float;
    var spawnTime:Float;

    var parent:ChartEditor;
    var lastPosition:Float;

    public function new(parent:ChartEditor, startTime:Float = 0):Void {
        super();
        this.parent = parent;
        this.startTime = startTime;
    }

    override function create():Void {
        lastPosition = Conductor.position;
        Conductor.resetPosition();
        Conductor.music = null;

        Conductor.onStep.remove(parent.stepHit);
        Conductor.onBeat.remove(parent.beatHit);
        Conductor.onMeasure.remove(parent.measureHit);

        super.create();

        var background:FlxSprite = new FlxSprite();
        background.makeRect(FlxG.width, FlxG.height, FlxColor.BLACK);
        background.alpha = 0;
        add(background);

        FlxTween.tween(background, {alpha: 0.6}, 0.25);

        opponentStrumline = new StrumLine(FlxG.width * 0.25, FlxG.height * 0.085, true);
        opponentStrumline.scrollSpeed = parent.chart.speed * parent.music.pitch;
        opponentStrumline.onNoteHit.add(onOpponentNoteHit);
        add(opponentStrumline);
  
        playerStrumline = new StrumLine(FlxG.width * 0.75, FlxG.height * 0.085);
        playerStrumline.scrollSpeed = opponentStrumline.scrollSpeed;
        playerStrumline.onNoteHit.add(onBotplayNoteHit);
        playerStrumline.onMiss.add(onMiss);
        add(playerStrumline);

        createUI();

        if (Settings.get("downscroll")) {
            playerStrumline.y = opponentStrumline.y = FlxG.height * 0.8;
            playerStrumline.downscroll = opponentStrumline.downscroll = true;

            oppNoteCount.y = playerNoteCount.y = FlxG.height * 0.95;
            infos.y = FlxG.height * 0.1;
        }
        if (Settings.get("centered strumline")) {
            opponentStrumline.visible = false;
            playerStrumline.screenCenter(X);
        }

        opponentStrumline.tweenReceptors();
        playerStrumline.tweenReceptors();

        notes = ChartLoader.generateNotes(parent.chart, startTime);
        strumlines = [opponentStrumline, playerStrumline];
        spawnTime = 1800 / opponentStrumline.scrollSpeed;

        Controls.globalControls.onKeyJustPressed.add(onKeyDown);
        Controls.globalControls.onKeyJustReleased.add(onKeyUp);

        Conductor.position = startTime - (1500 * parent.music.pitch);
        Conductor.playbackRate = parent.music.pitch;
        parent.music.onSongEnd.add(close);

        startTimer = new FlxTimer().start(1.5, (_) -> parent.music.play(startTime));
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

        while (notes.length > 0 && notes[0].time - Conductor.position < spawnTime)
            strumlines[notes[0].strumline].addNote(notes.shift());

        updateUI();
        super.update(elapsed);
    }

    override function stepHit(currentStep:Int):Void
        parent.music.resyncCheck();

    inline function onKeyDown(rawID:Int, action:String):Void {
        if (playerStrumline.cpu || action == null || !Note.directions.contains(action))
            return;

        var index:Int = Note.directions.indexOf(action);
        var receptor:Receptor = playerStrumline.receptors.members[index];
  
        playerStrumline.holdKeys[index] = true;

        var possibleNotes:Array<Note> = playerStrumline.notes.members.filter((note) -> note.direction == index && note.canBeHit);

        if (possibleNotes.length > 0) {
            possibleNotes.sort(PlayState.sortHitNotes);

            var noteToHit:Note = possibleNotes[0];

            // Delete stacked notes
            if (possibleNotes.length > 1) {
                for (i => note in possibleNotes) {
                    if (i == 0) continue;
   
                    if (note.direction == noteToHit.direction && Math.abs(note.time - noteToHit.time) <= 10)
                        playerStrumline.removeNote(note);
                    else break;
                }
            }

            onNoteHit(noteToHit);
        }
        else {
            receptor.playAnimation("press", true);
            if (!Settings.get("ghost tapping"))
               onMiss();
        }
    }

    inline function onKeyUp(rawID:Int, action:String):Void {
        if (playerStrumline.cpu || action == null || !Note.directions.contains(action))
            return;

        var index:Int = Note.directions.indexOf(action);
        playerStrumline.receptors.members[index].playAnimation("static", true);
        playerStrumline.holdKeys[index] = false;
    }

    inline function onNoteHit(note:Note):Void  {
        note.goodHit = true;
        note.checked = true;

        playerStrumline.receptors.members[note.direction].playAnimation("confirm", true);
        playerStrumline.hitNote(note);
        totalPlayerNotes++;
    }

    inline function onBotplayNoteHit(note:Note):Void {
        note.checked = true;
        totalPlayerNotes++;
    }

    inline function onOpponentNoteHit(_):Void {
        totalOppNotes++;
    }

    inline function onMiss(?note:Note):Void {
        if (note != null && !note.checked) {
            totalPlayerNotes++;
            note.checked = true;
        }

        missCount++;
    }

    inline function updateUI():Void {
        infos.text = 'MISSES: ${missCount} - BOTPLAY: ${(playerStrumline.cpu) ? 'ON' : 'OFF'}';
        infos.screenCenter(X);

        for (text in [oppNoteCount, playerNoteCount]) {
            var count:String = Std.string((text == oppNoteCount) ? totalOppNotes : totalPlayerNotes);
            while (count.length < 4)
                count = "0" + count;

            var seperatedCount:Array<String> = count.split("");
            for (i in 0...seperatedCount.length - 1)
                seperatedCount[i] = seperatedCount[i] + " ";

            text.text = seperatedCount.join("");
        }
    }

    inline function createUI():Void {
        infos = new FlxText(0, FlxG.height * 0.9);
        infos.setFormat(Assets.font("vcr"), 20, FlxColor.WHITE, CENTER);
        infos.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        infos.alpha = 0;
        add(infos);

        oppNoteCount = new FlxText(FlxG.width * 0.175 + 15, FlxG.height * 0.025, 0, "0 0 0 0");
        oppNoteCount.setFormat(infos.font, 32);
        oppNoteCount.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.25);
        oppNoteCount.alpha = 0;
        add(oppNoteCount);

        playerNoteCount = new FlxText(FlxG.width * 0.675 + 15, oppNoteCount.y, 0, "0 0 0 0");
        playerNoteCount.setFormat(infos.font, 32);
        playerNoteCount.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.25);
        playerNoteCount.alpha = 0;
        add(playerNoteCount);

        for (text in [infos, oppNoteCount, playerNoteCount])
            FlxTween.tween(text, {alpha: 1}, 1, {startDelay: 0.5});
    }

    override function destroy():Void {
        while (notes.length > 0)
            notes.shift().destroy();

        strumlines = null;
        notes = null;

        Controls.globalControls.onKeyJustPressed.remove(onKeyDown);
        Controls.globalControls.onKeyJustReleased.remove(onKeyUp);

        super.destroy();

        parent.music.onSongEnd.remove(close);
        parent.music.pause();

        Conductor.resetPosition();
        Conductor.playbackRate = 1;

        parent.music.instrumental.time = lastPosition;
        Conductor.music = parent.music.instrumental;

        Conductor.onStep.add(parent.stepHit);
        Conductor.onBeat.add(parent.beatHit);
        Conductor.onMeasure.add(parent.measureHit);

        parent = null;
    }
}