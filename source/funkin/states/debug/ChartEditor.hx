package funkin.states.debug;

import flixel.FlxSubState;
import flixel.sound.FlxSound;
import funkin.objects.Camera;

import flixel.text.FlxText;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxTiledSprite;

import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

import flixel.util.FlxGradient;
import flixel.util.FlxStringUtil;
import flixel.addons.display.FlxGridOverlay;

import funkin.music.MusicPlayback;
import funkin.music.EventManager.EventManager;
import funkin.music.EventManager.EventDetails;

import eternal.ui.NoteViewer;
import funkin.objects.ui.HealthIcon;
import funkin.objects.notes.Receptor;
import haxe.ui.components.HorizontalSlider;

import eternal.ChartFormat.Chart;
import eternal.ChartFormat.ChartNote;
import eternal.ChartFormat.ChartEvent;

import tjson.TJSON as Json;

class ChartEditor extends MusicBeatState #if ENGINE_CRASH_HANDLER implements eternal.core.crash.CrashHandler.ICrashListener #end {
    public static final hoverColor:FlxColor = 0x9B9BFA;
    public static final lateAlpha:Float = 0.6;
    public static final checkerSize:Int = 40;

    public var music:MusicPlayback;
    public var difficulty:String;
    public var chart:Chart;

    public var eventList:Map<String, EventDetails>;
    public var currentEvent:EventDetails;
    public var defaultArgs:Array<Any>;

    public var uiCamera:Camera;

    public var notes:FlxTypedGroup<DebugNote>;
    public var events:FlxTypedGroup<EventSprite>;

    public var checkerboard:FlxTiledSprite;
    public var line:FlxSprite;

    public var selectedNote(default, set):DebugNote;
    public var selectedEvent(default, set):EventSprite;

    public var receptors:FlxTypedSpriteGroup<Receptor>;
    public var noteViewer:NoteViewer;
    public var mouseCursor:FlxSprite;

    public var overlay:FlxSprite;
    public var musicText:FlxText;
    public var timeBar:HorizontalSlider;

    public var measures:FlxTypedGroup<FlxText>;
    public var beatIndicators:FlxSpriteGroup;

    public var hitsound:openfl.media.Sound; // avoid lag
    public var metronome:FlxSound;

    public var eventBPM:Bool = false;

    var startTime:Float = 0;
    var lastPosition:Float;
    var lastStep:Int;

    public function new(chart:Chart, difficulty:String = "normal", startTime:Float = 0):Void {
        super();

        this.chart = chart;
        this.difficulty = difficulty;
        this.startTime = startTime;
    }

    override function create():Void {
        @:privateAccess {
            if (haxe.ui.Toolkit._initialized) {
                FlxG.signals.postGameStart.add(haxe.ui.core.Screen.instance.onPostGameStart);
                FlxG.signals.postStateSwitch.add(haxe.ui.core.Screen.instance.onPostStateSwitch);
                FlxG.signals.preStateCreate.add(haxe.ui.core.Screen.instance.onPreStateCreate);
            }
            else
                haxe.ui.Toolkit.init();
        }
        
        super.create();

        FlxG.cameras.reset(new Camera());

        #if ENGINE_DISCORD_RPC
        DiscordPresence.presence.details = "Charting " + chart.meta.name;
        DiscordPresence.presence.state = "(in-dev)";
        #end

        loadSong();
        loadEvents();
        createBackground();
        createGrid();
        createUI();

        hitsound = AssetHelper.sound("editors/hitsound");

        metronome = FlxG.sound.load(AssetHelper.sound("editors/metronome"));
        metronome.volume = Settings.get("CHART_metronomeVolume");

        // spawn existing notes
        if (chart.notes.length > 0)
            spawnNotes(chart.notes);

        // spawn existing events
        if (chart.events.length > 0)
            spawnEvents(chart.events);

        FlxG.stage.window.onClose.add(autoSave);
    }

    override function update(elapsed:Float):Void {
        if (FlxG.keys.justPressed.TAB || FlxG.keys.justPressed.SEVEN) {
            openSubState(new ChartSubScreen(this));
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
            Tools.saveData('${difficulty.toLowerCase()}.json', Json.encode(chart, null, false));
        }

        if (FlxG.keys.justPressed.SPACE) {
            if (music.playing)
                pauseMusic();
            else
                music.play(Conductor.position);
        }

        mouseCursor.x = FlxMath.bound(floorMousePosition(FlxG.mouse.x), checkerboard.x - checkerSize, checkerboard.x + checkerSize * 7);
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

        if (selectedNote != null && (FlxG.keys.justPressed.Q || FlxG.keys.justPressed.E)) {
            selectedNote.data.length += Conductor.stepCrochet * ((FlxG.keys.justPressed.Q) ? 1 : -1);
            if (selectedNote.data.length < 0)
                killNote(selectedNote);
        }

        if (FlxG.mouse.wheel != 0)
            incrementTime(-FlxG.mouse.wheel * 50 * Tools.framerateMult(120));
        if (FlxG.keys.pressed.UP || FlxG.keys.pressed.DOWN)
            incrementTime(Conductor.stepCrochet / 4 * ((FlxG.keys.pressed.UP) ? -1 : 1) * Tools.framerateMult());

        super.update(elapsed);
        updateCurrentBPM();

        // reposition the follow line
        if (music.playing || Settings.get("CHART_strumlineSnap") || FlxG.keys.justPressed.SHIFT)
            line.y = getYFromTime(music.instrumental.time);
        else
            line.y = Tools.lerp(line.y, getYFromTime(music.instrumental.time), 12);

        if (!music.playing && Conductor.position >= music.instrumental.length) {
            music.instrumental.time = 0;
            line.y = 0;
        }
        
        if (receptors.visible) {
            for (receptor in receptors)
                receptor.y = line.y - (receptor.height * 0.5);
        }

        if (beatIndicators.visible) {
            for (ind in beatIndicators) {
                ind.color = Tools.colorLerp(ind.color, FlxColor.RED, 6);
                ind.y = line.y - ((line.height + ind.height) * 0.25);
            }
        }

        if (measures.visible)
            measures.forEachAlive((measure) -> measure.alpha = (measure.ID < Conductor.decimalMeasure && Settings.get("CHART_lateAlpha")) ? lateAlpha : 1);

        timeBar.disabled = !timeBar.visible;
        updateMusicText();

        if (music.playing) {
            var hitsoundVolume:Float = Settings.get("CHART_hitsoundVolume");
            notes.forEachAlive((note) -> {
                var late:Bool = (note.data.time <= Conductor.position);
                var hit:Bool = (late && note.data.time > lastPosition);

                if (hit && hitsoundVolume > 0)
                    FlxG.sound.play(hitsound, hitsoundVolume);

                if (receptors.visible && (hit || (late && note.data.length > 0 && note.data.time + note.data.length > Conductor.position
                    && (Settings.get("CHART_rStaticGlow") || lastStep != Conductor.currentStep))))
                    receptors.members[note.data.direction + 4 * note.data.strumline].playAnimation("confirm", true);
            });
        }

        lastPosition = Conductor.position;
        lastStep = Conductor.currentStep;
    }

    override function stepHit(currentStep:Int):Void {
        if (music.playing)
            music.resyncCheck();

        super.stepHit(currentStep);
    }

    override function beatHit(currentBeat:Int):Void {
        if (music.playing) {
            if (beatIndicators.visible)
                for (ind in beatIndicators)
                    ind.color = FlxColor.CYAN;

            if (metronome.volume > 0)
                metronome.play(true);
        }

        super.beatHit(currentBeat);
    }

    inline function checkSpawnNote():Void {
        var calc:Int = Std.int(mouseCursor.x / checkerSize);
        var strumline:Int = (calc > 15) ? 1 : 0; // TODO: calculate the strumline instead
        var direction:Int = calc % 4;

        var existingNote:DebugNote = notes.getFirst((n) -> n.alive && n.data.direction == direction && FlxG.mouse.overlaps(n));

        // no existing note found, create one
        if (existingNote == null) {
            var note:DebugNote = notes.recycle(DebugNote);
            note.setPosition(mouseCursor.x, getMouseY()); 
            note.data = { time: getTimeFromY(note.y), strumline: strumline, direction: direction, length: 0 };
            chart.notes.push(note.data);

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
            event.setPosition(checkerboard.x - checkerSize, getMouseY());
            event.data = { time: getTimeFromY(event.y), event: currentEvent.name, arguments: defaultArgs };
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

        Conductor.resetPreviousPosition();
    }

    override function openSubState(SubState:FlxSubState):Void {
        if (SubState is TransitionSubState) {
            super.openSubState(SubState);
            return;
        }

        pauseMusic();
        persistentUpdate = false;

        SubState.camera = uiCamera;
        super.openSubState(SubState);
    }

    inline function goToPlayState():Void {
        music.stop();
        autoSave();

        persistentUpdate = false;
        FlxG.mouse.visible = false;
        AssetHelper.clearAssets = Settings.get("reload assets");

        PlayState.song = chart;
        PlayState.currentDifficulty = difficulty;

        FlxG.switchState(new PlayState((FlxG.keys.pressed.SHIFT) ? Conductor.position : 0));
    }

    inline function killNote(note:DebugNote):Void {
        if (selectedNote == note)
            selectedNote = null;

        chart.notes.remove(note.data);
        note.kill();
    }

    inline function killEvent(event:EventSprite):Void {
        if (selectedEvent == event)
            selectedEvent = null;

        chart.events.remove(event.data);
        event.kill();
    }

    inline function pauseMusic():Void {
        if (beatIndicators.visible)
            for (ind in beatIndicators)
                ind.color = FlxColor.RED;

        music.pause();
        metronome.stop();
    }

    inline function updateMusicText():Void {
        if (!musicText.visible)
            return;

        var currentTime:String = FlxStringUtil.formatTime(music.instrumental.time / 1000);
        var maxTime:String = FlxStringUtil.formatTime(music.instrumental.length / 1000);

        musicText.text =
        '${currentTime} / ${maxTime}\n\n'
        + 'Step: ${Conductor.currentStep}\n'
        + 'Beat: ${Conductor.currentBeat}\n'
        + 'Measure: ${Conductor.currentMeasure}\n\n'
        + 'BPM: ${Conductor.bpm}\n'
        + 'Time Signature: ${Conductor.timeSignatureSTR}'
        ;

        musicText.x = FlxG.width - musicText.width - 5;

        overlay.scale.x = musicText.width + 15;
        overlay.x = FlxG.width - overlay.scale.x;
        overlay.updateHitbox();

        if (!FlxG.mouse.overlaps(timeBar) || !FlxG.mouse.pressed)
            timeBar.pos = music.instrumental.time;
    }

    inline public function reloadGrid(updateMeasures:Bool = true):Void {
        checkerboard.height = getYFromTime(music.instrumental.length);
        line.y = getYFromTime(music.instrumental.time);

        notes.forEachAlive((note) -> note.y = getYFromTime(note.data.time));
        events.forEachAlive((event) -> event.y = getYFromTime(event.data.time));

        if (updateMeasures)
            measures.forEachAlive((measure) -> measure.y = checkerSize * Conductor.measureLength * measure.ID);

        Conductor.resetPreviousPosition();
    }

    inline public function reloadMeasureMarks():Void {
        var measureTime:Float = Conductor.calculateMeasureTime(Conductor.bpm);
        var measureFnt:String = AssetHelper.font("vcr"); // avoids 78 file exist calls
        var measureIndex:Int = 0;

        measures.forEachAlive((measure) -> measure.kill());

        while ((measureTime * measureIndex) < music.instrumental.length) {
            var text:FlxText = measures.recycle(FlxText, () -> new FlxText().setFormat(measureFnt, 32));
            text.x = checkerboard.x + checkerboard.width + checkerSize * 0.5;
            text.y = checkerSize * Conductor.measureLength * measureIndex;
            text.text = Std.string(measureIndex);
            text.ID = measureIndex;
            measures.add(text);

            measureIndex++;
        }
    }

    inline function updateCurrentBPM():Void {
        var currentBPM:Float = Conductor.bpm;

        eventBPM = false;

        if (chart.events.length > 0) {
            for (event in chart.events) {
                if (event.event == "change bpm" && event.time <= Conductor.position) {
                    currentBPM = event.arguments[0];
                    eventBPM = true;
                }
            }
        }

        if (!eventBPM)
            currentBPM = chart.bpm;

        if (currentBPM != Conductor.bpm) {
            // trace("changed bpm to " + currentBPM);
            Conductor.bpm = currentBPM;
            reloadMeasureMarks();
            reloadGrid(false);
        }
    }

    inline function loadSong():Void {
        music = new MusicPlayback(chart.meta.rawName);
        music.setupInstrumental(chart.meta.instFile);

        if (chart.meta.voiceFiles.length > 0)
            for (voiceFile in chart.meta.voiceFiles)
               music.createVoice(voiceFile);

        music.onSongEnd.add(() -> {
            Conductor.resetPreviousPosition();
            line.y = 0;
        });
        music.instrumental.time = startTime;
        add(music);

        music.instrumental.volume = (Settings.get("CHART_muteInst")) ? 0 : 1;
        music.pitch = Settings.get("CHART_pitch");

        Conductor.stepsPerBeat = chart.meta.stepsPerBeat ?? 4;
        Conductor.beatsPerMeasure = chart.meta.beatsPerMeasure ?? 4;
        Conductor.bpm = chart.bpm;

        Conductor.music = music.instrumental;
    }

    inline function loadEvents():Void {
        eventList = EventManager.getEventList();
        currentEvent = EventManager.defaultEvents[0];
        defaultArgs = [for (arg in currentEvent.arguments) arg.defaultValue];
    }

    inline function createGrid():Void {
        var checkerBitmap = FlxGridOverlay.createGrid(checkerSize, checkerSize, checkerSize * 2, checkerSize * 2, true, 0xFFD6D6D6, 0xFFBBBBBB);

        checkerboard = new FlxTiledSprite(checkerBitmap, checkerSize * 8, getYFromTime(music.instrumental.length));
        checkerboard.screenCenter(X);
        checkerboard.active = false;
        add(checkerboard);

        for (i in 0...3) {
            var separator:FlxSprite = new FlxSprite();
            separator.makeRect(5, FlxG.height);
            separator.scrollFactor.set();
            separator.x = checkerboard.x + checkerSize * 4 * i;
            separator.active = false;
            add(separator);
        }

        line = new FlxSprite();
        line.makeRect(checkerSize * 10, 5);
        line.y = getYFromTime(startTime);
        line.screenCenter(X);
        line.active = false;

        FlxG.camera.follow(line, LOCKON);
        FlxG.camera.targetOffset.y = 125;

        notes = new FlxTypedGroup<DebugNote>();
        events = new FlxTypedGroup<EventSprite>();

        measures = new FlxTypedGroup<FlxText>();
        measures.visible = Settings.get("CHART_measureText");
        measures.active = false;
        reloadMeasureMarks();

        // create receptors
        receptors = new FlxTypedSpriteGroup<Receptor>(checkerboard.x);
        receptors.visible = Settings.get("CHART_receptors");
        receptors.moves = false;

        for (i in 0...8) {
            var receptor:Receptor = new Receptor(Std.int(i % 4));
            receptor.x = checkerSize * i;

            receptor.animation.finishCallback = (name) -> {
                if (name == "confirm")
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
            losange.makeRect(checkerSize * 0.35, checkerSize * 0.35, FlxColor.WHITE);
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
        add(events);
        add(notes);
        add(line);
        add(measures);
        add(beatIndicators);
        add(receptors);
    }

    inline function createBackground():Void {
        var backdrop:FlxBackdrop = new FlxBackdrop(AssetHelper.image("menus/checkboard"));
        backdrop.scrollFactor.set(0.2, 0.2);
        backdrop.color = FlxColor.PURPLE;
        backdrop.alpha = 0.5;
        backdrop.active = false;
        add(backdrop);

        var background:FlxSprite = new FlxSprite(0, 0, AssetHelper.image("menus/menuDesat"));
        background.scrollFactor.set();
        background.blend = MULTIPLY;
        background.active = false;
        add(background);

        var cols:Array<FlxColor> = [FlxColor.PURPLE, 0xFF350D35];
		var gradient:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, cols, 1, 45);
        gradient.scrollFactor.set();
		gradient.alpha = 0.4;
        gradient.active = false;
        add(gradient);
    }

    inline function createUI():Void {
        uiCamera = new Camera();
        uiCamera.bgColor.alpha = 0;
        FlxG.cameras.add(uiCamera, false);

        overlay = new FlxSprite(0, 10);
        overlay.makeRect(1, 115, FlxColor.GRAY);
        overlay.active = false;
        overlay.alpha = 0.4;
        overlay.visible = Settings.get("CHART_timeOverlay");
        overlay.cameras = [uiCamera];
        add(overlay);

        musicText = new FlxText(0, overlay.y);
        musicText.setFormat(AssetHelper.font("vcr"), 14, FlxColor.WHITE, RIGHT);
        musicText.setBorderStyle(OUTLINE, FlxColor.BLACK, 0.5);
        musicText.visible = Settings.get("CHART_timeOverlay");
        musicText.cameras = [uiCamera];
        add(musicText);

        timeBar = new HorizontalSlider();
        timeBar.top = overlay.y + overlay.height;
        timeBar.left = FlxG.width - 180;
        timeBar.width = 175;
        timeBar.visible = Settings.get("CHART_timeOverlay");
        timeBar.cameras = [uiCamera];
        timeBar.moves = false;
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

            Conductor.resetPreviousPosition();
        }

        var opponentIcon:HealthIcon = new HealthIcon(checkerboard.x, 30, getIcon(chart.meta.opponent));
        opponentIcon.setGraphicSize(0, 100);
        opponentIcon.updateHitbox();
        opponentIcon.x -= opponentIcon.width;
        opponentIcon.scrollFactor.set();
        opponentIcon.healthAnim = false;
        opponentIcon.cameras = [uiCamera];
        opponentIcon.active = false;
        add(opponentIcon);

        var playerIcon:HealthIcon = new HealthIcon(checkerboard.x + checkerboard.width, 30, getIcon(chart.meta.player));
        playerIcon.setGraphicSize(0, 100);
        playerIcon.updateHitbox();
        playerIcon.scrollFactor.set();
        playerIcon.healthAnim = false;
        playerIcon.flipX = true;
        playerIcon.cameras = [uiCamera];
        playerIcon.active = false;
        add(playerIcon);

        /*
        noteViewer = new NoteViewer(-40, 0);
        noteViewer.screenCenter(Y);
        noteViewer.camera = uiCamera;
        add(noteViewer);
        */
    }

    inline public function loadAutoSave():Void {
        var oldChart:Chart = chart;

        Tools.invokeTempSave((save) -> {
            var saveMap:Map<String, Dynamic> = save.data.charts;
            if (saveMap != null && saveMap.exists(chart.meta.rawName))
                chart = eternal.ChartLoader.resolveChart(saveMap.get(chart.meta.rawName));           
        }, "chart_autosave");

        if (oldChart == chart)
            return;

        // perhaps it's better to not switch states at all?
        
        AssetHelper.clearAssets = false;

        subState.close();
        FlxG.switchState(new ChartEditor(chart, difficulty));
    }

    inline public function autoSave():Void {
        Tools.invokeTempSave((save) -> {
            var saveMap:Map<String, Dynamic> = save.data.charts;
            if (saveMap == null)
                saveMap = [];

            saveMap.set(chart.meta.rawName, {
                meta: chart.meta,
                notes: chart.notes,
                events: chart.events,
                speed: chart.speed,
                bpm: chart.bpm
            });
            save.data.charts = saveMap;
        }, "chart_autosave");
    }

    public function onCrash():Void {
        autoSave();
    }

    inline function spawnNotes(noteArray:Array<ChartNote>):Void {
        for (noteData in noteArray) {
            var note:DebugNote = new DebugNote();
            note.setPosition(checkerboard.x + checkerSize * noteData.direction + checkerSize * 4 * noteData.strumline, getYFromTime(noteData.time));
            note.data = noteData;
            notes.add(note);
        }
    }

    inline function spawnEvents(eventArray:Array<ChartEvent>):Void {
        var eventKeys:Map<String, String> = [for (ev in eventList) ev.name => (ev.display ?? ev.name)];

        for (eventData in eventArray) {
            var event:EventSprite = new EventSprite();
            event.setPosition(checkerboard.x - checkerSize, getYFromTime(eventData.time));
            event.display = eventKeys.get(eventData.event);
            event.data = eventData;
            events.add(event);
        }
    }

    override function destroy():Void {
        FlxG.stage.window.onClose.remove(autoSave);

        super.destroy();

        // temporary fix for haxeui crash
        @:privateAccess {
            FlxG.signals.postGameStart.remove(haxe.ui.core.Screen.instance.onPostGameStart);
            FlxG.signals.postStateSwitch.remove(haxe.ui.core.Screen.instance.onPostStateSwitch);
            FlxG.signals.preStateCreate.remove(haxe.ui.core.Screen.instance.onPreStateCreate);
        }
    }

    inline function set_selectedNote(v:DebugNote):DebugNote {
        if (selectedNote != null)
            selectedNote.color = FlxColor.WHITE;

        if (v != null)
            v.color = hoverColor;

        // noteViewer.view(v);

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
        return (FlxG.keys.pressed.SHIFT) ? FlxG.mouse.y : floorMousePosition(FlxG.mouse.y);
    }

    inline static function floorMousePosition(position:Float):Float {
        return Math.floor(position / checkerSize) * checkerSize;
    }

    inline static function getTimeFromY(y:Float):Float {
        return Conductor.stepCrochet * (y / checkerSize);
    }

    inline static function getYFromTime(time:Float):Float {
        return checkerSize * (time / Conductor.stepCrochet);
    }

    inline static function getIcon(character:String):String {
        if (character == null)
            return "face";

        var file:String = AssetHelper.yaml('data/characters/${character}');
        if (!FileTools.exists(file))
            return "face";

        var icon:String = Tools.parseYAML(FileTools.getContent(file)).icon;
        return (icon == null) ? "face" : icon;
    }
}

class DebugNote extends FlxSprite {
    static final sustainColors:Array<FlxColor> = [0xC24A98, 0x00FEFE, 0x13FB05, 0xF9383E];

    public var data:ChartNote = null;
    var sustain:FlxSprite;

    public function new():Void {
        super();

        loadGraphic(AssetHelper.image("ui/debug/NoteGrid"), true, 161, 161);
        animation.add('note', [for (i in 0...4) i], 0);
        animation.play('note', true);

        setGraphicSize(ChartEditor.checkerSize, ChartEditor.checkerSize);
        updateHitbox();

        sustain = new FlxSprite();
        sustain.makeRect(ChartEditor.checkerSize * 0.25, 1, FlxColor.WHITE, false, "charteditor_susrect");
    }

    override function update(elapsed:Float):Void {
        alpha = (data.time < Conductor.position && Settings.get("CHART_lateAlpha")) ? ChartEditor.lateAlpha : 1;
        // super.update(elapsed);
    }

    override function draw():Void {
        if (data.length > 0) {
            sustain.scale.y = ChartEditor.checkerSize * ((data.length / Conductor.stepCrochet) - 0.5);
            if (sustain.scale.y < ChartEditor.checkerSize)
                sustain.scale.y = ChartEditor.checkerSize;

            sustain.updateHitbox();

            sustain.x = x + (width - sustain.width) * 0.5; 
            sustain.y = y + height * 0.5;

            sustain.color = sustainColors[data.direction];
            sustain.alpha = alpha;
            sustain.draw();

            /*
            if (length > 1)
                drawSustainPiece(0.65);

            for (i in 0...length) {
                if (i == (length - 1))
                    drawSustainEnd(i + 1);
                else
                    drawSustainPiece(i + 1);
            }
            */
        }

        animation.curAnim.curFrame = data.direction;
        super.draw();
    }

    /*
    function drawSustainPiece(spacing:Float):Void {
        var baseY:Float = y;

        animation.curAnim.curFrame = data.direction + 4;

        y += ChartEditor.checkerSize * spacing;
        scale.y *= 4;

        super.draw();

        scale.y *= 0.25;
        y = baseY;
    }

    function drawSustainEnd(spacing:Float):Void {
        var baseY:Float = y;

        animation.curAnim.curFrame = data.direction + 8;

        y += ChartEditor.checkerSize * spacing - ChartEditor.checkerSize * 0.5;
        super.draw();

        y = baseY;
    }
    */

    override function destroy():Void {
        sustain = FlxDestroyUtil.destroy(sustain);
        data = null;

        super.destroy();
    }
}

class EventSprite extends FlxSprite {
    public var display:String;
    public var rect:FlxSprite;
    public var text:FlxText;

    public var data:ChartEvent;

    public function new():Void {
        super();

        loadGraphic(AssetHelper.image("ui/debug/evt_ic"));
        setGraphicSize(ChartEditor.checkerSize, ChartEditor.checkerSize);
        updateHitbox();

        rect = new FlxSprite();
        rect.makeRect(ChartEditor.checkerSize, ChartEditor.checkerSize, 0x860051FF, false, "charteditor_evrect");
        rect.visible = false;

        text = new FlxText();
        text.setFormat(AssetHelper.font("vcr"), 12, FlxColor.WHITE, RIGHT);
    }

    override function update(elapsed:Float):Void {
        alpha = (data.time < Conductor.position && Settings.get("CHART_lateAlpha")) ? ChartEditor.lateAlpha : 1;
        color = (FlxG.mouse.overlaps(this)) ? ChartEditor.hoverColor : FlxColor.WHITE;

        text.alpha = alpha;
        text.color = color;

        // super.update(elapsed);
    }

    override function draw():Void {
        text.text = '${display ?? data.event}\nArguments: ${data.arguments.join(", ")}';
        text.setPosition(x - text.width, y);

        if (rect.visible) {
            rect.scale.x = text.width + width;
            rect.updateHitbox();

            rect.setPosition(text.x, y);
            rect.draw();
        }

        super.draw();
        text.draw();
    }

    override function destroy():Void {
        rect = FlxDestroyUtil.destroy(rect);
        text = FlxDestroyUtil.destroy(text);
        display = null;
        data = null;

        super.destroy();
    }
}