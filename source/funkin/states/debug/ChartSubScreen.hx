package funkin.states.debug;

import flixel.FlxSubState;
import haxe.ui.components.*;
import haxe.ui.containers.*;

import funkin.music.EventManager.EventDetails;
import tjson.TJSON as Json;

class ChartSubScreen extends FlxSubState {
    var parent:ChartEditor;
    var menu:TabView;

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

        menu.styleSheet = new haxe.ui.styles.StyleSheet();
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
        createEventPage();
        createSavePage();
    }

    override function update(elapsed:Float):Void {
        if (FlxG.keys.justPressed.SEVEN) {
            close();
            return;
        }

        super.update(elapsed);
    }

    override function destroy():Void {
        Settings.save();
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
        metronomeSlider.pos = Settings.get("CHART_metronomeVolume") * 100;
        metronomeSlider.includeInLayout = false;
        metronomeSlider.top = 20;

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
        hitsoundSlider.pos = Settings.get("CHART_hitsoundVolume") * 100;
        hitsoundSlider.includeInLayout = false;
        hitsoundSlider.top = 60;

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

        page.addComponent(lateAlpha);
        page.addComponent(showMeasures);
        page.addComponent(timeOverlay);
        page.addComponent(showReceptors);
        page.addComponent(staticGlow);
    }

    inline function createEventPage():Void {
        var page:Box = createPage("Events");

        var description:Label = createText("");
        description.customStyle.textAlign = "right";

        var eventDropdown:DropDown = new DropDown();
        eventDropdown.width = FlxG.width * 0.15;

        eventDropdown.onChange = (_) -> {
            var event:EventDetails = parent.eventList.get(eventDropdown.value);

            if (parent.selectedEvent != null) {
                parent.selectedEvent.data.event = event.name;
                parent.selectedEvent.updateText(event.display ?? event.name, []);
            }

            description.text = event.description ?? "No description.";
            description.validateNow();
            description.left = menu.width - description.width - 15;

            parent.currentEvent = event;
        }

        for (event in parent.eventList)
            eventDropdown.dataSource.add(event.display ?? event.name);

        eventDropdown.value = parent.currentEvent.display ?? parent.currentEvent.name;

        page.addComponent(eventDropdown);
        page.addComponent(description);
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

    inline static function applyStyle(s:haxe.ui.styles.Style, color:FlxColor = FlxColor.WHITE):Void {
        s.fontName = AssetHelper.font("vcr");
        s.color = color;
        s.fontSize = 12;
    }
}