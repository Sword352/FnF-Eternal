package funkin.states.debug;

import flixel.FlxSubState;

import haxe.ui.components.*;
import haxe.ui.containers.*;
import haxe.ui.containers.properties.*;
import haxe.ui.styles.StyleSheet;

import funkin.music.EventManager.EventDetails;
import tjson.TJSON as Json;

class ChartSubScreen extends FlxSubState {
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
            font-name: ${AssetHelper.font("vcr")};
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
        add(menu);

        createAudioPage();
        createVisualPage();
        createMetaPage();
        createEventPage();
        createSavePage();
        createSavePrefs();
    }

    override function update(elapsed:Float):Void {
        if (FlxG.keys.justPressed.SEVEN) {
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

        // apparently cpp cannot do math from "dynamic" values??
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

        // time overlay
        var timeOverlay:CheckBox = createCheckbox("Show Time Overlay");
        timeOverlay.selected = Settings.get("CHART_timeOverlay");
        timeOverlay.top = 50;

        timeOverlay.onChange = (_) -> {
            Settings.settings["CHART_timeOverlay"].value = timeOverlay.selected;
            parent.overlay.visible = parent.musicText.visible = parent.timeBar.visible = timeOverlay.selected;
        }

        // receptors
        var showReceptors:CheckBox = createCheckbox("Show Receptors");
        showReceptors.selected = Settings.get("CHART_receptors");
        showReceptors.top = 75;

        showReceptors.onChange = (_) -> {
            Settings.settings["CHART_receptors"].value = showReceptors.selected;
            parent.receptors.visible = showReceptors.selected;
        }

        var staticGlow:CheckBox = createCheckbox("Receptors Hold Static Glow");
        staticGlow.selected = Settings.get("CHART_rStaticGlow");
        staticGlow.top = 100;

        staticGlow.onChange = (_) -> Settings.settings["CHART_rStaticGlow"].value = staticGlow.selected;

        // checker alpha
        var checkerAlpha:HorizontalSlider = new HorizontalSlider();
        checkerAlpha.includeInLayout = false;
        checkerAlpha.left = 250;
        checkerAlpha.top = 10;

        checkerAlpha.min = 0;
        checkerAlpha.max = 100;
        checkerAlpha.step = 1;

        var val:Float = Settings.get("CHART_checkerAlpha");
        checkerAlpha.value = val * 100;

        var cAlphaText:Label = createText('Checkerboard Opacity (${checkerAlpha.pos}%)');
        cAlphaText.left = 255;

        checkerAlpha.onChange = (_) -> {
            var alpha:Float = checkerAlpha.pos / 100;

            cAlphaText.text = 'Checkerboard Opacity (${checkerAlpha.pos}%)';

            Settings.settings["CHART_checkerAlpha"].value = alpha;
            parent.checkerboard.alpha = alpha;
        };

        page.addComponent(lateAlpha);
        page.addComponent(showMeasures);
        page.addComponent(timeOverlay);
        page.addComponent(showReceptors);
        page.addComponent(staticGlow);
        page.addComponent(checkerAlpha);
        page.addComponent(cAlphaText);
    }

    inline function createMetaPage():Void {
        var oldBeats:Int = Conductor.beatsPerMeasure;
        var oldSteps:Int = Conductor.stepsPerBeat;
        var oldBPM:Float = parent.chart.bpm;

        var page:Box = createPage("Meta");

        // time signature
        var signature:Label = createText('Time Signature: ${Conductor.timeSignatureSTR}\n(beats per measure / steps per beat)');
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
            if (val is Float && !(val is Int))
                beatsPerMeasure.value = Math.floor(val);
        
            Conductor.beatsPerMeasure = beatsPerMeasure.value;
            parent.chart.meta.beatsPerMeasure = Conductor.beatsPerMeasure;
            beatsChanged = (Conductor.beatsPerMeasure != oldBeats);
        
            signature.text = 'Time Signature: ${Conductor.timeSignatureSTR}\n(beats per measure / steps per beat)';
        };
        
        stepsPerBeat.value = oldSteps;
        stepsPerBeat.onChange = (_) -> {
            var val:Float = stepsPerBeat.value;
            if (val is Float && !(val is Int))
                stepsPerBeat.value = Math.floor(val);
        
            Conductor.stepsPerBeat = stepsPerBeat.value;
            Conductor.stepCrochet = Conductor.crochet / Conductor.stepsPerBeat;
        
            parent.chart.meta.stepsPerBeat = Conductor.stepsPerBeat;
            stepsChanged = (Conductor.stepsPerBeat != oldSteps);
        
            signature.text = 'Time Signature: ${Conductor.timeSignatureSTR}\n(beats per measure / steps per beat)';
        };

        // bpm
        var bpmText:Label = createText("BPM");
        bpmText.left = 5;
        bpmText.top = 65;

        var bpmStepper:NumberStepper = createNumStepper();
        bpmStepper.left = 5;
        bpmStepper.top = 80;

        bpmStepper.value = parent.chart.bpm;
        bpmStepper.onChange = (_) -> {
            parent.chart.bpm = bpmStepper.pos;
            bpmChanged = (parent.chart.bpm != oldBPM);
            trace(bpmChanged);
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

        /*
        eventDropdown.styleSheet = new StyleSheet();
        eventDropdown.styleSheet.parse('
        .eventDropDown .listview .item-renderer:selected {
            font-name: ${AssetHelper.font("vcr")};
        }
        ');
        eventDropdown.handlerStyleNames = "eventDropDown";
        */

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

            var selectedEvent = parent.selectedEvent;
            if (selectedEvent != null && selectedEvent.data.event != event.name) {
                selectedEvent.data.event = event.name;
                selectedEvent.display = (event.display ?? event.name);
                selectedEvent.data.arguments = [for (a in event.arguments) a.defaultValue];
            }

            description.text = event.description ?? "No description.";
            description.validateNow();
            description.left = menu.width - description.width - 15;
            
            // rebuild the arguments editor
            while (propStorage.length > 0)
                argumentsEditor.removeComponent(propStorage.shift());

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
                    if (prop.type == "text" && cast(prop.value, String).length < 1)
                        val = null;
                    else if (typeLower == "int" && prop.value is Float && !(prop.value is Int))
                        val = prop.value = Math.floor(prop.value);

                    if (selectedEvent != null)
                        selectedEvent.data.arguments[propIndex] = val;
                    parent.defaultArgs[propIndex] = val;
                }

                if (parent.currentEvent.name == event.name)
                    prop.value = selectedEvent?.data.arguments[propIndex] ?? parent.defaultArgs[propIndex];
                else
                    prop.value = event.arguments[propIndex].defaultValue;

                argumentsEditor.addComponent(prop);
                propStorage.push(prop);
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
        saveChart.onClick = (_) -> Tools.saveData('${parent.difficulty.toLowerCase()}.json', Json.encode(parent.chart, null, false));

        var saveMeta:Button = createButton("Save Song Metadata");
        saveMeta.onClick = (_) -> Tools.saveData("meta.json", Json.encode(parent.chart.meta, null, false));
        saveMeta.top = 25;

        var saveEvents:Button = createButton("Save Events");
        saveEvents.onClick = (_) -> Tools.saveData("events.json", Json.encode(parent.chart.events, null, false));
        saveEvents.top = 50;

        page.addComponent(saveChart);
        page.addComponent(saveMeta);
        page.addComponent(saveEvents);
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
        s.fontName = AssetHelper.font("vcr");
        s.color = color;
        s.fontSize = 12;
    }
}