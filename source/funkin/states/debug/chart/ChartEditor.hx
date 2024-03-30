package funkin.states.debug.chart;

import flixel.FlxSubState;
import flixel.sound.FlxSound;
import funkin.objects.Camera;

import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;

import flixel.util.FlxStringUtil;
import flixel.addons.display.FlxBackdrop;

import funkin.states.debug.chart.ChartNoteGroup;
import funkin.states.debug.chart.ChartEventGroup;

import funkin.objects.HealthIcon;
import funkin.objects.HelpButton;
import funkin.gameplay.notes.Receptor;

import funkin.music.MusicPlayback;
import funkin.globals.ChartFormat;
import funkin.gameplay.EventManager;

import haxe.ui.components.HorizontalSlider;
import haxe.Json;

class ChartEditor extends MusicBeatState #if ENGINE_CRASH_HANDLER implements eternal.core.crash.CrashHandler.ICrashListener #end {
    public static final hoverColor:FlxColor = 0x9B9BFA;
    public static final lateAlpha:Float = 0.6;
    public static final separatorWidth:Int = 4;
    public static final checkerSize:Int = 45;

    public var music:MusicPlayback;
    public var difficulty:String;
    public var chart:Chart;

    public var eventList:Map<String, EventDetails>;
    public var currentEvent:EventDetails;
    public var defaultArgs:Array<Any>;

    public var notes:ChartNoteGroup;
    public var events:ChartEventGroup;

    public var checkerboard:ChartCheckerboard;
    public var line:FlxSprite;

    public var selectedNote(default, set):DebugNote;
    public var selectedEvent(default, set):EventSprite;

    public var receptors:FlxTypedSpriteGroup<Receptor>;
    public var mouseCursor:FlxSprite;

    public var beatIndicators:FlxSpriteGroup;
    public var measureBackdrop:FlxBackdrop;

    public var helpButton:HelpButton;
    public var uiCamera:Camera;

    public var timeBar:HorizontalSlider;
    public var musicText:FlxText;
    public var overlay:FlxSprite;

    public var opponentIcon:HealthIcon;
    public var playerIcon:HealthIcon;

    public var hitsound:openfl.media.Sound;
    public var hitsoundVolume:Float = 0;
    public var metronome:FlxSound;

    public var startTime:Float = 0;
    public var lastTime:Float = 0;
    public var lastStep:Int = 0;

    var lastBpmChange:Float = 0;
    var awaitBPMReload:Bool = false;
    var eventBPM:Bool = false;

    public function new(chart:Chart, difficulty:String = "normal", startTime:Float = 0):Void {
        super();

        this.chart = chart;
        this.difficulty = difficulty;
        this.startTime = startTime;
    }

    override function create():Void {
        super.create();

        FlxG.cameras.reset(new Camera());

        #if ENGINE_DISCORD_RPC
        DiscordPresence.presence.details = "Charting " + chart.meta.name;
        #end

        loadSong();
        loadEvents();
        createBackground();
        createGrid();
        createUI();

        hitsound = Assets.sound("editors/hitsound");
        hitsoundVolume = Settings.get("CHART_hitsoundVolume");

        metronome = FlxG.sound.load(Assets.sound("editors/metronome"));
        metronome.volume = Settings.get("CHART_metronomeVolume");

        // cache a small amount of note sprites
        for (i in 0...32) notes.add(new DebugNote()).kill();

        // make sure notes are sorted to avoid odd behaviours
        sortNotes();

        // spawn existing events
        if (chart.events.length > 0)
            spawnEvents(chart.events);

        FlxG.stage.window.onClose.add(autoSave);
    }

    override function update(elapsed:Float):Void {
        if (FlxG.keys.justPressed.TAB) {
            openSubState(new ChartSubScreen(this));
            return;
        }

        if (FlxG.keys.justPressed.ESCAPE) {
            playTest();
            return;
        }

        if (FlxG.keys.justPressed.ENTER) {
            goToPlayState();
            return;
        }

        // the mouse visible field doesn't seems to be working properly,
        // so we're just setting it to true on update to make sure it is always visible
        FlxG.mouse.useSystemCursor = false;
        FlxG.mouse.visible = true;

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S) {
            pauseMusic();
            Tools.saveData('${difficulty.toLowerCase()}.json', Json.stringify(chart.toStruct()));
        }

        if (FlxG.keys.justPressed.SPACE) {
            if (music.playing)
                pauseMusic();
            else
                music.play(Conductor.time);
        }

        // TODO: bound the mouse cursor x so it doesn't go out of the grid (any bounding methods doesn't seems to be working??)
        var mouseX:Float = quantizeMouse(FlxG.mouse.x - checkerboard.x);
        mouseCursor.x = checkerboard.x + mouseX + separatorWidth * Math.floor(mouseX / checkerSize / 4);
        mouseCursor.y = FlxMath.bound(getMouseY(), 0, checkerboard.height - checkerSize);
        mouseCursor.visible = (isMouseXValid() && isMouseYValid());

        if (mouseCursor.visible) {
            if (FlxG.mouse.justPressed) {
                if (FlxG.mouse.x > checkerboard.x)
                    checkSpawnNote();
                else
                    checkSpawnEvent();
            }
            else if (FlxG.keys.pressed.Z)
                checkObjectDeletion();
        }

        if (selectedNote != null) {
            var pressed:Bool = (FlxG.keys.justPressed.Q || FlxG.keys.justPressed.E);
            var holding:Bool = (FlxG.keys.pressed.SHIFT && (FlxG.keys.pressed.Q || FlxG.keys.pressed.E));

            if (pressed || holding) {
                var mult:Int = (FlxG.keys.pressed.Q) ? 1 : -1;
                selectedNote.data.length += (holding) ? (Conductor.stepCrochet / 10 * Tools.framerateMult() * mult) : (Conductor.stepCrochet * mult);
                if (selectedNote.data.length < 0) killNote(selectedNote);
            }
        }

        if (FlxG.mouse.wheel != 0)
            incrementTime(-FlxG.mouse.wheel * 50 * Tools.framerateMult(120));
        if (FlxG.keys.pressed.UP || FlxG.keys.pressed.DOWN)
            incrementTime(Conductor.stepCrochet / 4 * ((FlxG.keys.pressed.UP) ? -1 : 1) * Tools.framerateMult());

        super.update(elapsed);
        updateCurrentBPM();

        // only update notes after so it listens to bpm changes
        notes.update(elapsed);

        // reposition the follow line
        if (music.playing || Settings.get("CHART_strumlineSnap") || FlxG.keys.justPressed.SHIFT)
            line.y = getYFromTime(Conductor.time);
        else
            line.y = Tools.lerp(line.y, getYFromTime(Conductor.time), 12);

        if (!music.playing && Conductor.time >= music.instrumental.length) {
            music.instrumental.time = 0;
            line.y = 0;
        }

        if (receptors.visible) {
            for (receptor in receptors)
                receptor.y = line.y - (receptor.height * 0.5);
        }

        if (beatIndicators.visible) {
            for (ind in beatIndicators) {
                ind.color = FlxColor.interpolate(FlxColor.CYAN, FlxColor.RED, (music.playing) ? (Conductor.decimalBeat - Conductor.currentBeat) : 1);
                ind.y = line.y - ((line.height + ind.height) * 0.25);
            }
        }

        updateMusicText();

        lastStep = Conductor.currentStep;
        lastTime = Conductor.time;
    }

    override function stepHit(currentStep:Int):Void {
        if (music.playing)
            music.resync();

        super.stepHit(currentStep);
    }

    override function beatHit(currentBeat:Int):Void {
        // sometimes it just mutes itself, and sometimes it proceeds to play hitsound instead of metronome
        // TODO: fix this bug
        
        if (music.playing && metronome.volume > 0)
            metronome.play(true);

        super.beatHit(currentBeat);
    }

    inline function checkSpawnNote():Void {
        var direction:Int = Math.floor((mouseCursor.x - checkerboard.x) / checkerSize);
        var strumline:Int = Math.floor(direction / 4);
        direction %= 4;

        var existingNote:DebugNote = notes.getFirst((n) -> n.alive && n.data.direction == direction && FlxG.mouse.overlaps(n));

        // no existing note found, create one
        if (existingNote == null) {
            var note:DebugNote = notes.recycle(DebugNote);
            note.setPosition(mouseCursor.x, getMouseY());
            note.data = {
                time: getTimeFromY(note.y),
                strumline: strumline,
                direction: direction,
                length: 0
            };

            chart.notes.push(note.data);
            sortNotes();

            notes.pushNote(note);
            selectedNote = note;
        }
        // existing note found, delete it if CONTROL isn't pressed
        else if (!FlxG.keys.pressed.CONTROL)
            killNote(existingNote);
        // otherwise, (un)select it
        else {
            if (selectedNote == existingNote)
                selectedNote = null;
            else
                selectedNote = existingNote;
        }
    }

    inline function checkSpawnEvent():Void {
        var existingEvent:EventSprite = events.getFirst((e) -> e.alive && FlxG.mouse.overlaps(e));

        // no existing event found, create one
        if (existingEvent == null) {
            var event:EventSprite = events.recycle(EventSprite);
            event.setPosition(checkerboard.x - checkerSize - separatorWidth, getMouseY());
            event.data = {
                time: getTimeFromY(event.y),
                event: currentEvent.name,
                arguments: defaultArgs
            };
            event.display = (currentEvent.display ?? currentEvent.name);
            chart.events.push(event.data);

            selectedEvent = event;
        }
        // existing event found, delete it if CONTROL isn't pressed
        else if (!FlxG.keys.pressed.CONTROL)
            killEvent(existingEvent);
        // otherwise, (un)select it
        else {
            if (selectedEvent == existingEvent)
                selectedEvent = null;
            else
                selectedEvent = existingEvent;
        }
    }

    inline function checkObjectDeletion():Void {
        // look for notes to delete
        notes.forEachAlive((note) -> {
            if (FlxG.mouse.overlaps(note))
                killNote(note);
        });

        // look for events to delete
        events.forEachAlive((event) -> {
            if (FlxG.mouse.overlaps(event))
                killEvent(event);
        });
    }

    inline function incrementTime(val:Float):Void {
        if (music.playing)
            pauseMusic();

        music.instrumental.time += val * ((FlxG.keys.pressed.SHIFT) ? 10 : 1);
        music.instrumental.time = FlxMath.bound(music.instrumental.time, -1000, music.instrumental.length);

        if (music.instrumental.time < 0) {
            music.instrumental.time = music.instrumental.length - 100;
            line.y = getYFromTime(music.instrumental.time);
        }

        for (vocals in music.vocals)
            vocals.time = music.instrumental.time;

        Conductor.resetPrevTime();
    }

    override function openSubState(SubState:FlxSubState):Void {
        if (!(SubState is TransitionSubState)) {
            SubState.camera = uiCamera;
            pauseMusic();
        }
        else
            Transition.noPersistentUpdate = (cast(SubState, TransitionSubState).type == OUT);

        super.openSubState(SubState);
    }

    override function closeSubState():Void {
        if (!(subState is TransitionSubState) && awaitBPMReload) {
            reloadGrid(false, !eventBPM);
            awaitBPMReload = false;
        }

        super.closeSubState();
    }

    inline function goToPlayState():Void {
        var time:Float = Conductor.time;

        music.stop();
        autoSave();

        FlxG.mouse.visible = false;
        Assets.clearAssets = Settings.get("reload assets");

        PlayState.song = chart;
        PlayState.currentDifficulty = difficulty;

        var time:Float = (FlxG.keys.pressed.SHIFT ? time : 0);
        FlxG.switchState(Assets.clearAssets ? LoadingScreen.new.bind(time) : PlayState.new.bind(time));
    }

    inline function playTest():Void {
        var time:Float = Conductor.time;

        music.stop();
        autoSave();

        FlxG.mouse.visible = false;
        openSubState(new ChartPlayState(this, (FlxG.keys.pressed.SHIFT) ? time : 0));
    }

    inline function openHelpPage():Void {
        openSubState(new HelpSubState("SPACE: Play/Stop music\n"
            + "UP/DOWN/Mouse wheel: Increase/Decrease music time (faster if SHIFT pressed)\n"
            + "Mouse click on grid: Place a note/event\n"
            + "Q/E: Increase/Decrease selected note hold length (faster if SHIFT pressed)\n"
            + "CTRL + Mouse click: Select hovered note/event\n"
            + "SHIFT (hold): Un-snap cursor to grid\n"
            + "Z (hold): Delete hovered notes/events\n\n"

            + "TAB: Open Sub-screen\n"
            + "ESCAPE: Play chart in the chart editor\n"
            + "ESCAPE+SHIFT: Play chart in the chart editor at current time\n"
            + "ENTER: Play chart\n"
            + "ENTER+SHIFT: Play chart at current time\n"
            + "CTRL+S: Save chart"));
    }

    inline function killNote(note:DebugNote):Void {
        if (selectedNote == note)
            selectedNote = null;

        chart.notes.remove(note.data);
        notes.killNote(note);

        // sortNotes();
    }

    inline function killEvent(event:EventSprite):Void {
        if (selectedEvent == event)
            selectedEvent = null;

        chart.events.remove(event.data);
        event.kill();
    }

    inline function pauseMusic():Void {
        music.pause();
        metronome.stop();
    }

    inline function updateMusicText():Void {
        if (!musicText.visible)
            return;

        musicText.text = '${getTimeInfo()}\n\n' + 'Step: ${Conductor.currentStep}\n' + 'Beat: ${Conductor.currentBeat}\n'
            + 'Measure: ${Conductor.currentMeasure}\n\n' + '${getBPMInfo()}\n' + 'Time Signature: ${Conductor.getSignature()}';

        musicText.x = FlxG.width - musicText.width - 5;

        overlay.scale.x = musicText.width + 15;
        overlay.x = FlxG.width - overlay.scale.x;
        overlay.updateHitbox();

        if (!FlxG.mouse.overlaps(timeBar) || !FlxG.mouse.pressed)
            timeBar.pos = music.instrumental.time;
    }

    inline public function getTimeInfo():String {
        var currentTime:String = FlxStringUtil.formatTime(music.instrumental.time * 0.001);
        var maxTime:String = FlxStringUtil.formatTime(music.instrumental.length * 0.001);

        var playbackRate:String = Std.string(music.pitch);
        if (music.pitch is Int)
            playbackRate += ".0";

        return '${currentTime} / ${maxTime} (${playbackRate}x)';
    }

    inline public function getBPMInfo():String
        return 'BPM: ${Conductor.bpm} (${chart.gameplayInfo.bpm})';

    inline public function reloadGrid(updateMeasure:Bool = true, resetTime:Bool = true):Void {
        checkerboard.height = getYFromTime(music.instrumental.length);
        line.y = getYFromTime(music.instrumental.time);

        notes.forEachAlive((note) -> note.y = getYFromTime(note.data.time));
        events.forEachAlive((event) -> event.y = getYFromTime(event.data.time));

        if (updateMeasure) refreshMeasureMark();
        if (resetTime) Conductor.resetPrevTime();
    }

    public inline function refreshMeasureMark():Void {
        // without reducing by 1 makes the spacing somehow
        measureBackdrop.spacing.y = checkerSize * Conductor.measureLength / measureBackdrop.height - 1;
    }

    public inline function updateCurrentBPM():Void {
        var currentBPM:Float = chart.gameplayInfo.bpm;
        var stepOffset:Float = 0;
        var lastChange:Float = 0;

        eventBPM = false;

        if (chart.events.length > 0) {
            for (event in chart.events) {
                if (event.event == "change bpm" && event.time <= Conductor.time) {
                    stepOffset += ((event.time - lastChange) / (((60 / currentBPM) * 1000) / Conductor.stepsPerBeat));
                    lastChange = event.time;

                    currentBPM = event.arguments[0];
                    eventBPM = true;
                }
            }
        }

        Conductor.beatOffset.time = lastChange;
        Conductor.beatOffset.step = stepOffset;

        if (currentBPM != Conductor.bpm || lastBpmChange != lastChange) {
            Conductor.bpm = currentBPM;
            lastBpmChange = lastChange;

            awaitBPMReload = (subState != null);
            if (!awaitBPMReload) reloadGrid(false, !eventBPM);
        }
    }

    inline function loadSong():Void {
        music = new MusicPlayback(chart.meta.folder);
        music.setupInstrumental(chart.gameplayInfo.instrumental);

        if (chart.gameplayInfo.voices?.length > 0)
            for (voiceFile in chart.gameplayInfo.voices)
                music.createVoice(voiceFile);

        music.onSongEnd.add(() -> {
            Conductor.resetPrevTime();
            line.y = 0;
        });

        music.instrumental.time = startTime;
        add(music);

        music.instrumental.volume = (Settings.get("CHART_muteInst")) ? 0 : 1;
        music.pitch = Settings.get("CHART_pitch");

        Conductor.beatsPerMeasure = chart.gameplayInfo.beatsPerMeasure ?? 4;
        Conductor.stepsPerBeat = chart.gameplayInfo.stepsPerBeat ?? 4;
        Conductor.bpm = chart.gameplayInfo.bpm;
        Conductor.music = music.instrumental;
    }

    inline function loadEvents():Void {
        eventList = EventManager.getEventList();
        currentEvent = EventManager.defaultEvents[0];
        defaultArgs = [for (arg in currentEvent.arguments) arg.defaultValue];
    }

    inline function createGrid():Void {
        checkerboard = new ChartCheckerboard();
        checkerboard.height = getYFromTime(music.instrumental.length);
        add(checkerboard);

        line = new FlxSprite();
        line.makeRect(checkerSize * 10, 5);
        line.y = getYFromTime(startTime);
        line.screenCenter(X);
        line.active = false;

        FlxG.camera.follow(line, LOCKON);
        FlxG.camera.targetOffset.y = 125;

        notes = new ChartNoteGroup(this);
        events = new ChartEventGroup();

        // we're updating it manually
        notes.active = false;

        measureBackdrop = new FlxBackdrop(null, Y);
        measureBackdrop.makeRect(checkerSize * 8 + separatorWidth, 5, FlxColor.WHITE);
        measureBackdrop.visible = Settings.get("CHART_measureMark");
        measureBackdrop.x = checkerboard.x;
        measureBackdrop.active = false;
        refreshMeasureMark();

        // create receptors
        receptors = new FlxTypedSpriteGroup<Receptor>(checkerboard.x);
        receptors.visible = Settings.get("CHART_receptors");
        receptors.moves = false;

        for (i in 0...8) {
            var receptor:Receptor = new Receptor(Std.int(i % 4));
            receptor.x = checkerSize * i + separatorWidth * Math.floor(i / 4);

            receptor.animation.finishCallback = (name) -> {
                if (name.startsWith("confirm"))
                    receptor.playAnimation("static", true);
            };

            receptor.setGraphicSize(checkerSize, checkerSize);
            receptor.updateHitbox();

            receptor.moves = false;
            receptors.add(receptor);
        }
        //

        beatIndicators = new FlxSpriteGroup();
        beatIndicators.visible = Settings.get("CHART_beatIndices");
        beatIndicators.active = false;

        for (i in 0...2) {
            var losange:FlxSprite = new FlxSprite();
            losange.makeRect(checkerSize * 0.35, checkerSize * 0.35, FlxColor.WHITE, false, "charteditor_losange");
            losange.x = (line.x - losange.width * 0.5) + ((line.width + losange.width * 0.5) * i);
            losange.color = FlxColor.RED;
            losange.angle = 45;
            losange.active = false;
            beatIndicators.add(losange);
        }

        mouseCursor = new FlxSprite();
        mouseCursor.makeRect(checkerSize, checkerSize);
        mouseCursor.setPosition(checkerboard.x, checkerboard.y + checkerSize);
        mouseCursor.active = false;

        add(mouseCursor);
        add(measureBackdrop);
        add(events);
        add(notes);
        add(line);
        add(beatIndicators);
        add(receptors);
    }

    inline function createBackground():Void {
        var background:FlxSprite = new FlxSprite(0, 0, Assets.image("menus/menuDesat"));
        background.scrollFactor.set();
        background.color = 0x312c2d;
        background.active = false;
        add(background);
    }

    inline function createUI():Void {
        uiCamera = new Camera();
        uiCamera.bgColor.alpha = 0;
        FlxG.cameras.add(uiCamera, false);

        overlay = new FlxSprite(0, 10);
        overlay.makeRect(1, 115, FlxColor.GRAY);
        overlay.visible = Settings.get("CHART_timeOverlay");
        overlay.cameras = [uiCamera];
        overlay.active = false;
        overlay.alpha = 0.4;
        add(overlay);

        musicText = new FlxText(0, overlay.y);
        musicText.setFormat(Assets.font("vcr"), 14, FlxColor.WHITE, RIGHT);
        musicText.setBorderStyle(OUTLINE, FlxColor.BLACK, 0.5);
        musicText.visible = Settings.get("CHART_timeOverlay");
        musicText.cameras = [uiCamera];
        musicText.active = false;
        add(musicText);

        timeBar = new HorizontalSlider();
        timeBar.top = overlay.y + overlay.height;
        timeBar.left = FlxG.width - 180;
        timeBar.width = 175;
        timeBar.visible = Settings.get("CHART_timeOverlay");
        timeBar.disabled = !timeBar.visible;
        timeBar.cameras = [uiCamera];
        add(timeBar);

        timeBar.min = 0;
        timeBar.step = 1;
        timeBar.max = music.instrumental.length;

        timeBar.onChange = (_) -> {
            if (!FlxG.mouse.overlaps(timeBar) || !FlxG.mouse.pressed)
                return;

            pauseMusic();
            music.instrumental.time = timeBar.pos;

            for (vocals in music.vocals)
                vocals.time = music.instrumental.time;

            Conductor.resetPrevTime();
        }

        opponentIcon = new HealthIcon(checkerboard.x, 30, getIcon(chart.gameplayInfo.opponent));
        opponentIcon.setGraphicSize(0, 100);
        opponentIcon.updateHitbox();
        opponentIcon.x -= opponentIcon.width;
        opponentIcon.cameras = [uiCamera];
        opponentIcon.healthAnim = false;
        opponentIcon.active = false;
        add(opponentIcon);

        playerIcon = new HealthIcon(checkerboard.x + checkerboard.width, 30, getIcon(chart.gameplayInfo.player));
        playerIcon.setGraphicSize(0, 100);
        playerIcon.updateHitbox();
        playerIcon.cameras = [uiCamera];
        playerIcon.healthAnim = false;
        playerIcon.active = false;
        playerIcon.flipX = true;
        add(playerIcon);

        helpButton = new HelpButton();
        helpButton.onClick = openHelpPage;
        helpButton.camera = uiCamera;
        add(helpButton);

        // add(haxe.ui.RuntimeComponentBuilder.build("assets/chartEditor.xml").screenCenter(Y));
    }

    inline public function loadAutoSave():Void {
        var oldChart:Chart = chart;

        Tools.invokeTempSave((save) -> {
            var saveMap:Map<String, Dynamic> = save.data.charts;
            if (saveMap != null && saveMap.exists(chart.meta.folder))
                chart = Chart.resolve(saveMap.get(chart.meta.folder));
        }, "chart_autosave");

        if (oldChart == chart)
            return;

        // perhaps it's better to not switch states at all?

        Assets.clearAssets = false;

        subState.close();
        FlxG.switchState(ChartEditor.new.bind(chart, difficulty, 0));
    }

    inline public function autoSave():Void {
        Tools.invokeTempSave((save) -> {
            var saveMap:Map<String, Dynamic> = save.data.charts;
            if (saveMap == null)
                saveMap = [];

            saveMap.set(chart.meta.folder, chart.toStruct());
            save.data.charts = saveMap;
        }, "chart_autosave");
    }

    public function onCrash():Void {
        autoSave();
    }

    inline function spawnEvents(eventArray:Array<ChartEvent>):Void {
        var eventKeys:Map<String, String> = [for (ev in eventList) ev.name => (ev.display ?? ev.name)];

        for (eventData in eventArray) {
            var event:EventSprite = new EventSprite();
            event.setPosition(checkerboard.x - checkerSize - separatorWidth, getYFromTime(eventData.time));
            event.display = eventKeys.get(eventData.event);
            event.data = eventData;
            events.add(event);
        }
    }

    inline function sortNotes():Void {
        chart.notes.sort((a, b) -> Std.int(a.time - b.time));
    }

    override function destroy():Void {
        difficulty = null;
        chart = null;

        eventList = null;
        currentEvent = null;
        defaultArgs = null;
        hitsound = null;

        FlxG.stage.window.onClose.remove(autoSave);
        super.destroy();
    }

    inline function set_selectedNote(v:DebugNote):DebugNote {
        if (selectedNote != null)
            selectedNote.color = FlxColor.WHITE;

        if (v != null) {
            notes.lastSelectedNote = null;
            v.color = hoverColor;
        }

        return selectedNote = v;
    }

    inline function set_selectedEvent(v:EventSprite):EventSprite {
        if (selectedEvent != null)
            selectedEvent.rect.visible = false;

        if (v != null)
            v.rect.visible = true;

        return selectedEvent = v;
    }

    inline function isMouseXValid():Bool
        return FlxG.mouse.x > checkerboard.x - checkerSize && FlxG.mouse.x < checkerboard.x + checkerboard.width;

    inline function isMouseYValid():Bool
        return FlxG.mouse.y > 0 && FlxG.mouse.y < checkerboard.height;

    inline static function getMouseY():Float {
        return (FlxG.keys.pressed.SHIFT) ? FlxG.mouse.y : quantizeMouse(FlxG.mouse.y);
    }

    inline static function quantizeMouse(position:Float):Float {
        return Math.floor(position / checkerSize) * checkerSize;
    }

    public static inline function getTimeFromY(y:Float):Float {
        return Conductor.beatOffset.time + Conductor.stepCrochet * ((y / checkerSize) - Conductor.beatOffset.step);
    }

    public static inline function getYFromTime(time:Float):Float {
        return checkerSize * (Conductor.beatOffset.step + ((time - Conductor.beatOffset.time) / Conductor.stepCrochet));
    }

    inline static function getIcon(character:String):String {
        if (character == null)
            return HealthIcon.DEFAULT_ICON;

        var file:String = Assets.yaml('data/characters/${character}');
        if (!FileTools.exists(file))
            return HealthIcon.DEFAULT_ICON;

        var icon:String = Tools.parseYAML(FileTools.getContent(file)).icon;
        return (icon == null) ? HealthIcon.DEFAULT_ICON : icon;
    }
}
