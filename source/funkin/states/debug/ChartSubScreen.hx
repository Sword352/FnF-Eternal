package funkin.states.debug;

import flixel.FlxSubState;

import haxe.ui.components.*;
import haxe.ui.containers.*;
import haxe.ui.containers.properties.*;
import haxe.ui.styles.StyleSheet;

import funkin.music.EventManager.EventDetails;
import haxe.Json;

class ChartSubScreen extends FlxSubState {
    static var lastPage:Int = 0;

    var parent:ChartEditor;
    var menu:TabView;

    var beatsChanged:Bool = false;
    var stepsChanged:Bool = false;
    var bpmChanged:Bool = false;

    public function new(parent:ChartEditor):Void {
        super();
        this.parent = parent;
    }

    override function create():Void {
        super.create();

        var background:FlxSprite = new FlxSprite();
        background.makeRect(FlxG.width, FlxG.height, FlxColor.BLACK);
        background.alpha = 0.6;
        add(background);

        menu = new TabView();
        menu.setSize(FlxG.width * 0.8, FlxG.height * 0.8);
        menu.color = FlxColor.PURPLE;
        menu.screenCenter();

        menu.styleSheet = new StyleSheet();
        menu.styleSheet.parse('
        .tabbar-button {
            color: #000000;
            font-size: 16px;
            font-name: ${Assets.font("vcr")};
            border-top-color: #000000;
            border-left-color: #000000;
            border-right-color: #000000;
            border-bottom-color: #000000;
        }

        .tabbar-button-selected {
            background-color: #800080;
            border-top-color: #000000;
            border-bottom-color: #800080;
            border-left-color: #000000;
            border-right-color: #000000;
        }
        ');
        menu.styleNames = "rounded-tabs full-width-buttons";

        createAudioPage();
        createVisualPage();
        createMetaPage();
        createEventPage();
        createSavePage();
        createSavePrefs();

        menu.pageIndex = lastPage;
        add(menu);
    }

    override function update(elapsed:Float):Void {
        if (FlxG.keys.justPressed.TAB) {
            close();
            return;
        }

        super.update(elapsed);
    }

    override function destroy():Void {
        if (Settings.get("CHART_autoSave"))
            Settings.save();

        if (!bpmChanged) {
            if (stepsChanged)
                parent.reloadGrid(!beatsChanged);

            if (beatsChanged)
                parent.reloadMeasureMarks();
        }

        lastPage = menu.pageIndex;
        parent = null;

        super.destroy();
    }

    inline function createAudioPage():Void {
        var page:Box = createPage("Audio");

        // metronome
        var metronomeSlider:HorizontalSlider = new HorizontalSlider();
        metronomeSlider.min = 0;
        metronomeSlider.max = 100;
        metronomeSlider.step = 1;
        metronomeSlider.includeInLayout = false;
        metronomeSlider.top = 20;

        var vol:Float = Settings.get("CHART_metronomeVolume");
        metronomeSlider.pos = vol * 100;

        var metroText:Label = createText('Metronome Volume (${metronomeSlider.pos}%)');
        metroText.left = 5;
        metroText.top = 10;

        metronomeSlider.onChange = (_) -> {
            var vol:Float = metronomeSlider.pos / 100;

            Settings.settings["CHART_metronomeVolume"].value = vol;
            metroText.text = 'Metronome Volume (${metronomeSlider.pos}%)';
            parent.metronome.volume = vol;
        }

        // hitsound
        var hitsoundSlider:HorizontalSlider = new HorizontalSlider();
        hitsoundSlider.min = 0;
        hitsoundSlider.max = 100;
        hitsoundSlider.step = 1;
        hitsoundSlider.includeInLayout = false;
        hitsoundSlider.top = 60;

        var vol:Float = Settings.get("CHART_hitsoundVolume");
        hitsoundSlider.pos = vol * 100;

        var hitsoundText:Label = createText('Hitsound Volume (${hitsoundSlider.pos}%)');
        hitsoundText.left = 5;
        hitsoundText.top = 50;

        hitsoundSlider.onChange = (_) -> {
            Settings.settings["CHART_hitsoundVolume"].value = hitsoundSlider.pos / 100;
            hitsoundText.text = 'Hitsound Volume (${hitsoundSlider.pos}%)';
        }

        // pitching
        var pitchSlider:HorizontalSlider = new HorizontalSlider();
        pitchSlider.pos = Settings.get("CHART_pitch");
        pitchSlider.step = 0.05;
        pitchSlider.min = 0.1;
        pitchSlider.max = 5;

        pitchSlider.includeInLayout = false;
        pitchSlider.top = 100;

        var pitchText:Label = createText('Playback Rate (${pitchSlider.pos})');
        pitchText.left = 5;
        pitchText.top = 90;

        pitchSlider.onChange = (_) -> {
            Settings.settings["CHART_pitch"].value = pitchSlider.pos;
            pitchText.text = 'Playback Rate (${pitchSlider.pos})';
            parent.music.pitch = pitchSlider.pos;
        }

        // music mute
        var muteInst:CheckBox = createCheckbox("Mute Instrumental");
        muteInst.selected = Settings.get("CHART_muteInst");
        muteInst.top = metroText.top;
        muteInst.left = 200;

        muteInst.onChange = (_) -> {
            Settings.settings["CHART_muteInst"].value = muteInst.selected;
            parent.music.instrumental.volume = (muteInst.selected) ? 0 : 1;
        }

        for (i in 0...parent.music.vocals.length) {
            var muteVoice:CheckBox = createCheckbox('Mute Voice "${parent.chart.meta.voiceFiles[i]}"');
            muteVoice.top = muteInst.top + 25 * (i + 1);
            muteVoice.left = 200;

            muteVoice.onChange = (_) -> parent.music.vocals[i].volume = (muteVoice.selected) ? 0 : 1;
            muteVoice.selected = (parent.music.vocals[i].volume < 1);
            page.addComponent(muteVoice);
        }

        page.addComponent(metroText);
        page.addComponent(metronomeSlider);
        page.addComponent(hitsoundText);
        page.addComponent(hitsoundSlider);
        page.addComponent(pitchText);
        page.addComponent(pitchSlider);
        page.addComponent(muteInst);
    }

    inline function createVisualPage():Void {
        var page:Box = createPage("Visual");

        var lateAlpha:CheckBox = createCheckbox("Late Note Transparency");
        lateAlpha.onChange = (_) -> Settings.settings["CHART_lateAlpha"].value = lateAlpha.selected;
        lateAlpha.selected = Settings.get("CHART_lateAlpha");

        // show measures
        var showMeasures:CheckBox = createCheckbox("Show Measure Marks");
        showMeasures.selected = Settings.get("CHART_measureText");
        showMeasures.top = 25;

        showMeasures.onChange = (_) -> {
            Settings.settings["CHART_measureText"].value = showMeasures.selected;
            parent.measures.visible = showMeasures.selected;
        }

        // beat indicators
        var beatIndicators:CheckBox = createCheckbox("Show Beat Indicators (flashing!)");
        beatIndicators.selected = Settings.get("CHART_beatIndices");
        beatIndicators.top = 50;

        beatIndicators.onChange = (_) -> {
            Settings.settings["CHART_beatIndices"].value = beatIndicators.selected;
            parent.beatIndicators.visible = beatIndicators.selected;
        }

        // time overlay
        var timeOverlay:CheckBox = createCheckbox("Show Time Overlay");
        timeOverlay.selected = Settings.get("CHART_timeOverlay");
        timeOverlay.top = 75;

        timeOverlay.onChange = (_) -> {
            Settings.settings["CHART_timeOverlay"].value = timeOverlay.selected;
            parent.overlay.visible = parent.musicText.visible = parent.timeBar.visible = timeOverlay.selected;
        }

        // receptors
        var showReceptors:CheckBox = createCheckbox("Show Receptors");
        showReceptors.selected = Settings.get("CHART_receptors");
        showReceptors.top = 100;

        showReceptors.onChange = (_) -> {
            Settings.settings["CHART_receptors"].value = showReceptors.selected;
            parent.receptors.visible = showReceptors.selected;
        }

        var staticGlow:CheckBox = createCheckbox("Receptors Hold Static Glow");
        staticGlow.selected = Settings.get("CHART_rStaticGlow");
        staticGlow.top = 125;

        staticGlow.onChange = (_) -> Settings.settings["CHART_rStaticGlow"].value = staticGlow.selected;

        // strumline snap
        var strumlineSnap:CheckBox = createCheckbox("Strumline Scroll Snap");
        strumlineSnap.selected = Settings.get("CHART_strumlineSnap");
        strumlineSnap.top = 150;

        strumlineSnap.onChange = (_) -> Settings.settings["CHART_strumlineSnap"].value = strumlineSnap.selected;

        page.addComponent(lateAlpha);
        page.addComponent(showMeasures);
        page.addComponent(beatIndicators);
        page.addComponent(timeOverlay);
        page.addComponent(showReceptors);
        page.addComponent(staticGlow);
        page.addComponent(strumlineSnap);
    }

    inline function createMetaPage():Void {
        var oldBeats:Int = Conductor.beatsPerMeasure;
        var oldSteps:Int = Conductor.stepsPerBeat;
        var oldBPM:Float = parent.chart.meta.bpm;

        var page:Box = createPage("Meta");

        // time signature
        var signature:Label = createText('Time Signature: ${Conductor.getSignature()}\n(beats per measure / steps per beat)');
        signature.left = 5;

        var beatsPerMeasure:NumberStepper = createNumStepper();
        beatsPerMeasure.left = 5;
        beatsPerMeasure.top = 25;

        var stepsPerBeat:NumberStepper = createNumStepper();
        stepsPerBeat.left = 95;
        stepsPerBeat.top = 25;

        beatsPerMeasure.value = oldBeats;
        beatsPerMeasure.onChange = (_) -> {
            var val:Float = beatsPerMeasure.value;
            if (!(val is Int))
                beatsPerMeasure.value = Math.floor(val);

            Conductor.beatsPerMeasure = beatsPerMeasure.value;
            parent.chart.meta.beatsPerMeasure = Conductor.beatsPerMeasure;
            beatsChanged = (Conductor.beatsPerMeasure != oldBeats);

            signature.text = 'Time Signature: ${Conductor.getSignature()}\n(beats per measure / steps per beat)';
        };

        stepsPerBeat.value = oldSteps;
        stepsPerBeat.onChange = (_) -> {
            var val:Float = stepsPerBeat.value;
            if (!(val is Int))
                stepsPerBeat.value = Math.floor(val);

            Conductor.stepsPerBeat = stepsPerBeat.value;
            parent.chart.meta.stepsPerBeat = Conductor.stepsPerBeat;
            stepsChanged = (Conductor.stepsPerBeat != oldSteps);

            signature.text = 'Time Signature: ${Conductor.getSignature()}\n(beats per measure / steps per beat)';
        };

        // bpm
        var bpmText:Label = createText("BPM");
        bpmText.left = 5;
        bpmText.top = 65;

        var bpmStepper:NumberStepper = createNumStepper();
        bpmStepper.left = 5;
        bpmStepper.top = 80;

        bpmStepper.value = parent.chart.meta.bpm;
        bpmStepper.onChange = (_) -> {
            parent.chart.meta.bpm = bpmStepper.pos;
            bpmChanged = (parent.chart.meta.bpm != oldBPM);
        };

        page.addComponent(signature);
        page.addComponent(beatsPerMeasure);
        page.addComponent(stepsPerBeat);
        page.addComponent(bpmText);
        page.addComponent(bpmStepper);
    }

    inline function createEventPage():Void {
        var propStorage:Array<Property> = [];

        var page:Box = createPage("Events");

        var description:Label = createText("");
        description.customStyle.textAlign = "right";

        var eventDropdown:DropDown = new DropDown();
        eventDropdown.width = FlxG.width * 0.15;

        var grid:PropertyGrid = new PropertyGrid();
        grid.width = 300;
        grid.height = 250;
        grid.includeInLayout = false;
        grid.left = menu.width - 325;
        grid.top = menu.height - 300;

        var argumentsEditor:PropertyGroup = new PropertyGroup();
        argumentsEditor.text = "Arguments";
        grid.addComponent(argumentsEditor);

        eventDropdown.onChange = (_) -> {
            var event:EventDetails = parent.eventList.get(eventDropdown.value);

            // if we already have a selected event, change the event
            var selectedEvent = parent.selectedEvent;
            if (selectedEvent != null && selectedEvent.data.event != event.name) {
                selectedEvent.data.event = event.name;
                selectedEvent.display = (event.display ?? event.name);

                if (event.arguments != null)
                    selectedEvent.data.arguments = [for (a in event.arguments) a.defaultValue];
                else
                    selectedEvent.data.arguments = null;
            }

            description.text = event.description ?? "No description.";
            description.validateNow();
            description.left = menu.width - description.width - 15;

            // rebuild the arguments editor
            while (propStorage.length > 0)
                argumentsEditor.removeComponent(propStorage.pop());

            if (event.arguments != null) {
                for (arg in event.arguments) {
                    var propIndex:Int = event.arguments.indexOf(arg);
                    var typeLower:String = arg.type.toLowerCase();

                    var prop:Property = new Property();
                    prop.label = arg.name;
                    prop.type = switch (typeLower) {
                        case "string": (arg.valueList == null) ? "text" : "list";
                        case "bool": "boolean";
                        default: typeLower;
                    };

                    if (prop.type == "list")
                        for (entry in arg.valueList)
                            prop.dataSource.add(entry);

                    prop.onChange = (_) -> {
                        var val:Dynamic = prop.value;
                        if (prop.type == "text") {
                            var str:String = cast prop.value;
                            if (str.length < 1 || str == "null")
                                val = null;
                        }
                        else if (typeLower == "int" && prop.value is Float && !(prop.value is Int))
                            val = prop.value = Math.floor(prop.value);

                        if (selectedEvent != null)
                            selectedEvent.data.arguments[propIndex] = val;

                        parent.defaultArgs[propIndex] = val;
                    }

                    // if there is a selected event, get the value from it, otherwise use default values
                    if (selectedEvent != null && selectedEvent.data.event == event.name)
                        prop.value = selectedEvent?.data.arguments[propIndex] ?? parent.defaultArgs[propIndex];
                    else
                        prop.value = parent.defaultArgs[propIndex] ?? event.arguments[propIndex].defaultValue;

                    argumentsEditor.addComponent(prop);
                    propStorage.push(prop);
                }
            }

            if (selectedEvent == null) {
                parent.defaultArgs = [for (prop in propStorage) prop.value];
                parent.currentEvent = event;
            }
        }

        for (event in parent.eventList)
            eventDropdown.dataSource.add(event.display ?? event.name);

        var currentEvent:EventDetails = parent.currentEvent;
        if (parent.selectedEvent != null) {
            for (event in parent.eventList) {
                if (event.name == parent.selectedEvent.data.event) {
                    currentEvent = event;
                    break;
                }
            }
        }

        eventDropdown.value = currentEvent.display ?? currentEvent.name;

        page.addComponent(eventDropdown);
        page.addComponent(description);
        page.addComponent(grid);
    }

    inline function createSavePage():Void {
        var page:Box = createPage("Save");

        var saveChart:Button = createButton("Save Chart");
        saveChart.onClick = (_) -> Tools.saveData('${parent.difficulty.toLowerCase()}.json', Json.stringify(parent.chart));

        var saveMeta:Button = createButton("Save Song Metadata");
        saveMeta.onClick = (_) -> Tools.saveData("meta.json", Json.stringify(parent.chart.meta));
        saveMeta.top = 25;

        var saveEvents:Button = createButton("Save Events");
        saveEvents.onClick = (_) -> Tools.saveData("events.json", Json.stringify(parent.chart.events));
        saveEvents.top = 50;

        var autoSave:Button = createButton("Load Autosave");
        autoSave.onClick = (_) -> parent.loadAutoSave();
        autoSave.top = 75;

        page.addComponent(saveChart);
        page.addComponent(saveMeta);
        page.addComponent(saveEvents);
        page.addComponent(autoSave);
    }

    inline function createSavePrefs():Void {
        var savePrefs:Button = createButton("Save Preferences");
        savePrefs.includeInLayout = false;
        savePrefs.top = menu.top + menu.height + 5;
        savePrefs.left = menu.left;

        var autoSave:CheckBox = createCheckbox("Auto Save Preferences");
        autoSave.includeInLayout = false;
        autoSave.top = savePrefs.top + 2.5;
        autoSave.left = menu.left + 155;

        savePrefs.disabled = Settings.get("CHART_autoSave");
        savePrefs.alpha = (savePrefs.disabled) ? 0.5 : 1;
        autoSave.selected = savePrefs.disabled;

        autoSave.onChange = (_) -> {
            savePrefs.disabled = autoSave.selected;
            savePrefs.alpha = (savePrefs.disabled) ? 0.5 : 1;
            Settings.settings["CHART_autoSave"].value = autoSave.selected;
        }
        savePrefs.onClick = (_) -> Settings.save();

        add(savePrefs);
        add(autoSave);
    }

    // TODO: seperate those into classes, this should do it for now

    inline function createPage(text:String):Box {
        var page:Box = new Box();
        page.percentWidth = page.percentHeight = 100;
        page.text = text;
        menu.addComponent(page);
        return page;
    }

    inline function createText(label:String):Label {
        var text:Label = new Label();
        applyStyle(text.customStyle);
        text.includeInLayout = false;
        text.text = label;
        return text;
    }

    inline function createCheckbox(text:String):CheckBox {
        var checkbox:CheckBox = new CheckBox();
        applyStyle(checkbox.customStyle);
        checkbox.includeInLayout = false;
        checkbox.text = text;
        return checkbox;
    }

    inline function createButton(text:String):Button {
        var button:Button = new Button();
        applyStyle(button.customStyle, FlxColor.BLACK);
        button.includeInLayout = false;
        button.text = text;
        return button;
    }

    inline function createNumStepper():NumberStepper {
        var stepper:NumberStepper = new NumberStepper();
        applyStyle(stepper.customStyle, FlxColor.BLACK);
        stepper.includeInLayout = false;
        stepper.autoCorrect = true;
        stepper.min = 1;
        return stepper;
    }

    inline static function applyStyle(s:haxe.ui.styles.Style, color:FlxColor = FlxColor.WHITE):Void {
        s.fontName = Assets.font("vcr");
        s.color = color;
        s.fontSize = 12;
    }
}
