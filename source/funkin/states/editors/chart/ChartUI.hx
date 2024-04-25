package funkin.states.editors.chart;

import haxe.ui.core.Component;
import haxe.ui.components.*;
import haxe.ui.components.popups.ColorPickerPopup;
import haxe.ui.containers.menus.*;
import haxe.ui.notifications.*;
import haxe.ui.events.*;

import haxe.ui.backend.flixel.UIRuntimeFragment;
import haxe.ui.containers.dialogs.CollapsibleDialog;

import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;

import funkin.gameplay.EventManager;
import funkin.globals.ChartFormat;
import funkin.globals.ChartLoader;
import haxe.Json;

@:build(haxe.ui.RuntimeComponentBuilder.build("assets/data/chartEditor.xml"))
class ChartUI extends UIRuntimeFragment {
    public var eventsOpened:Bool = false;

    var parent(get, never):ChartEditor;
    inline function get_parent():ChartEditor
        return cast FlxG.state;

    var menuBar:MenuBar;
    var helpMenu:Menu;
    var pbMenu:Menu;

    var hitsoundItem:MenuItem;
    var hitsoundSlider:HorizontalSlider;

    var metronomeItem:MenuItem;
    var metronomeSlider:HorizontalSlider;

    var pbItem:MenuItem;
    var pbSlider:HorizontalSlider;
    var muteInst:CheckBox;

    var playItem1:MenuItem;
    var playItem2:MenuItem;
    var playItem3:MenuItem;
    var playItem4:MenuItem;
    var playTestItem:MenuItem;

    var saveChart:MenuItem;
    var saveEvents:MenuItem;
    var saveMeta:MenuItem;

    var runAutosave:MenuItem;
    var autoSave:MenuItem;

    var copyItem:MenuItem;
    var pasteItem:MenuItem;
    var undoItem:MenuItem;
    var redoItem:MenuItem;
    var undoRecursive:MenuItem;
    var redoRecursive:MenuItem;
    var editMeta:MenuItem;

    var saveChart_noGameplay:MenuItem;
    var saveMeta_noGameplay:MenuItem;
    var saveChart_notesOnly:MenuItem;
    var saveChart_noEvents:MenuItem;

    var viewEvents:MenuItem;
    var viewPrefs:MenuItem;

    var noteTypeMenu:Menu;
    var beatSnapMenu:Menu;

    var prefDialog:PreferenceDialog;
    var eventDialog:EventDialog;

    /*
    @:bind(menuBar, UIEvent.BEFORE_CLOSE)
    function menuBar_beforeClose(event:UIEvent):Void {
        if (haxe.ui.core.Screen.instance.hasComponentUnderPoint(FlxG.mouse.screenX, FlxG.mouse.screenY, Slider))
            event.cancel();
    }
    */

    @:bind(helpMenu, MouseEvent.CLICK)
    function helpMenu_click():Void {
        parent.openHelpPage();
    }

    // SAVE COMPONENTS

    @:bind(saveEvents, MouseEvent.CLICK)
    function saveEvents_click():Void {
        saveFile("events.json", "events", Json.stringify(parent.chart.events));
    }

    @:bind(saveChart, MouseEvent.CLICK)
    function saveChart_click():Void {
        saveFile('${parent.difficulty.toLowerCase()}.json', "chart", Json.stringify(parent.chart.toStruct()));
    }

    @:bind(saveMeta, MouseEvent.CLICK)
    function saveMeta_click():Void {
        // if gameplay info wasn't null by default, refresh it
        if (parent.chart.meta.gameplayInfo != null)
            parent.chart.meta.gameplayInfo = parent.chart.gameplayInfo;
        
        saveFile("meta.json", "meta", Json.stringify(ChartLoader.exportMeta(parent.chart.meta), "\t"));
    }

    @:bind(saveChart_notesOnly, MouseEvent.CLICK)
    function saveChart_notesOnly_click():Void {
        var chart:ChartJson = parent.chart.toStruct();
        Reflect.deleteField(chart, "gameplayInfo");
        Reflect.deleteField(chart, "events");
        saveFile('${parent.difficulty.toLowerCase()}.json', "chart", Json.stringify(chart));
    }

    @:bind(saveChart_noGameplay, MouseEvent.CLICK)
    function saveChart_noGameplay_click():Void {
        var chart:ChartJson = parent.chart.toStruct();
        Reflect.deleteField(chart, "gameplayInfo");
        saveFile('${parent.difficulty.toLowerCase()}.json', "chart", Json.stringify(chart));
    }

    @:bind(saveChart_noEvents, MouseEvent.CLICK)
    function saveChart_noEvents_click():Void {
        var chart:ChartJson = parent.chart.toStruct();
        Reflect.deleteField(chart, "events");
        saveFile('${parent.difficulty.toLowerCase()}.json', "chart", Json.stringify(chart));
    }

    @:bind(saveMeta_noGameplay, MouseEvent.CLICK)
    function saveMeta_noGameplay_click():Void {
        var meta:SongMeta = ChartLoader.exportMeta(parent.chart.meta);
        Reflect.deleteField(meta, "gameplayInfo");
        saveFile("meta.json", "meta", Json.stringify(meta, "\t"));
    }

    @:bind(runAutosave, MouseEvent.CLICK)
    function runAutosave_click():Void {
        parent.autoSave();
    }

    @:bind(autoSave, MouseEvent.CLICK)
    function autoSave_click():Void {
        parent.skipUpdate = true;
        parent.loadAutoSave();
    }

    // EDIT COMPONENTS

    @:bind(copyItem, MouseEvent.CLICK)
    function copyItem_click():Void {
        parent.clipboardCopy();
    }

    @:bind(pasteItem, MouseEvent.CLICK)
    function pasteItem_click():Void {
        parent.clipboardPaste();
    }

    @:bind(undoItem, MouseEvent.CLICK)
    function undoItem_click():Void {
        parent.undo();
    }

    @:bind(redoItem, MouseEvent.CLICK)
    function redoItem_click():Void {
        parent.redo();
    }

    @:bind(undoRecursive, MouseEvent.CLICK)
    function undoRecursive_click():Void {
        parent.undo(true);
    }

    @:bind(redoRecursive, MouseEvent.CLICK)
    function redoRecursive_click():Void {
        parent.redo(true);
    }

    @:bind(editMeta, MouseEvent.CLICK)
    function editMeta_click():Void {
        parent.openSubState(new MetadataScreen());
    }

    // VIEW COMPONENTS

    @:bind(viewEvents, MouseEvent.CLICK)
    function viewEvents_click():Void {
        eventDialog.left = 20;
        eventDialog.top = 45;

        viewEvents.disabled = true;
        eventDialog.showDialog(false);

        eventsOpened = true;
    }

    @:bind(viewPrefs, MouseEvent.CLICK)
    function viewPrefs_click():Void {
        prefDialog.left = 20;
        prefDialog.top = 170;

        viewPrefs.disabled = true;
        prefDialog.showDialog(false);
    }

    // AUDIO COMPONENTS

    @:bind(pbSlider, UIEvent.CHANGE)
    function pbSlider_change():Void {
        Settings.settings["CHART_pitch"].value = pbSlider.pos;
        pbItem.text = 'Playback Rate (${pbSlider.pos})';
        parent.music.pitch = pbSlider.pos;
    }

    @:bind(hitsoundSlider, UIEvent.CHANGE)
    function hitsoundSlider_change():Void {
        Settings.settings["CHART_hitsoundVolume"].value = parent.hitsoundVolume = hitsoundSlider.pos;
        hitsoundItem.text = 'Hitsound Volume (${hitsoundSlider.pos * 100}%)';
    }

    @:bind(metronomeSlider, UIEvent.CHANGE)
    function metronomeSlider_change():Void {
        Settings.settings["CHART_metronomeVolume"].value = parent.metronome.volume = metronomeSlider.pos;
        metronomeItem.text = 'Metronome Volume (${metronomeSlider.pos * 100}%)';
    }

    @:bind(muteInst, UIEvent.CHANGE)
    function muteInst_change():Void {
        Settings.settings["CHART_muteInst"].value = muteInst.selected;
        parent.music.instrumental.volume = (muteInst.selected) ? 0 : 1;
    }

    // PLAYTEST COMPONENTS

    @:bind(playItem1, MouseEvent.CLICK)
    function playItem1_click():Void {
        parent.goToPlayState();
    }

    @:bind(playItem2, MouseEvent.CLICK)
    function playItem2_click():Void {
        parent.goToPlayState(true);
    }

    @:bind(playItem3, MouseEvent.CLICK)
    function playItem3_click():Void {
        parent.playTest();
    }

    @:bind(playItem4, MouseEvent.CLICK)
    function playItem4_click():Void {
        parent.playTest(true);
    }

    @:bind(playTestItem, MouseEvent.CLICK)
    function playTestItem_click():Void {
        parent.openSubState(new PlayTestScreen());
    }

    //

    override function onReady():Void {
        pbSlider.pos = cast Settings.get("CHART_pitch");
        pbItem.text = 'Playback Rate (${pbSlider.pos})';

        hitsoundSlider.pos = cast Settings.get("CHART_hitsoundVolume");
        hitsoundItem.text = 'Hitsound Volume (${hitsoundSlider.pos * 100}%)';

        metronomeSlider.pos = cast Settings.get("CHART_metronomeVolume");
        metronomeItem.text = 'Metronome Volume (${metronomeSlider.pos * 100}%)';

        muteInst.selected = Settings.get("CHART_muteInst");

        // manually create menu items for voices
        if (parent.chart.gameplayInfo.voices != null) {
            for (i in 0...parent.chart.gameplayInfo.voices.length) {    
                var checkbox:CheckBox = new CheckBox();
                checkbox.selected = (parent.music.vocals[i].volume < 1);
                checkbox.onChange = (_) -> {
                    parent.music.vocals[i].volume = (checkbox.selected ? 0 : 1);
                };
                
                var item:MenuItem = new MenuItem();
                item.text = 'Mute Voice "${parent.chart.gameplayInfo.voices[i]}"';
                item.addComponent(checkbox);
                pbMenu.addComponent(item);
            }
        }

        // manually create items for notetypes
        var allNoteTypes:Array<String> = ["Default"];

        for (i in 0...parent.noteTypes.length) {
            allNoteTypes.push('${i + 1}. ${parent.noteTypes[i]}');
        }

        for (type in allNoteTypes) {
            var noteType:String = (type == "Default" ? null : type.substring(type.indexOf(".") + 2));

            var item:MenuItem = new MenuItem();
            item.text = type;

            var optionBox:OptionBox = new OptionBox();
            optionBox.componentGroup = "notetype_optionboxes";
            optionBox.selected = (type == "Default");

            item.onClick = (_) -> {
                if (parent.selectedNote != null) {
                    if (noteType != null) parent.selectedNote.changeText(parent.noteTypes.indexOf(noteType));
                    parent.selectedNote.data.type = noteType;
                }

                parent.currentNoteType = noteType;
                optionBox.selected = true;
            }

            item.addComponent(optionBox);
            noteTypeMenu.addComponent(item);
        }

        // manually create items for beat snap
        var snaps:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 94, 192];

        for (snap in snaps) {
            var item:MenuItem = new MenuItem();

            var text:String = '${snap}X';
            if (snap == 16) text += " (Default)";
            item.text = text;

            var optionBox:OptionBox = new OptionBox();
            optionBox.componentGroup = "beatsnap_optionboxes";
            optionBox.selected = (snap == parent.beatSnap);

            item.onClick = (_) -> {
                parent.beatSnap = snap;
                parent.preferences.beatSnap = snap;
                optionBox.selected = true;
            }

            item.addComponent(optionBox);
            beatSnapMenu.addComponent(item);
        }
        //

        prefDialog = new PreferenceDialog();
        prefDialog.onDialogClosed = (_) -> viewPrefs.disabled = false;
        prefDialog.destroyOnClose = false;

        eventDialog = new EventDialog();
        eventDialog.onDialogClosed = (_) -> viewEvents.disabled = eventsOpened = false;
        eventDialog.destroyOnClose = false;
    }

    var fileReference:FileReference;

    function saveFile(file:String, handle:String, data:String):Void {
        fileReference = new FileReference();
        fileReference.addEventListener(Event.CANCEL, (_) -> {
            NotificationManager.instance.addNotification({
                title: "Info",
                body: 'Saving ${handle} has been cancelled.',
                type: NotificationType.Info
            });
            fileReference = null;
        });
        fileReference.addEventListener(Event.COMPLETE, (_) -> {
            NotificationManager.instance.addNotification({
                title: "Success",
                body: 'Successfully saved ${handle}.',
                type: NotificationType.Success
            });
            fileReference = null;
        });
        fileReference.addEventListener(IOErrorEvent.IO_ERROR, (event:IOErrorEvent) -> {
            NotificationManager.instance.addNotification({
                title: "Error",
                body: 'Failed saving ${handle} due to error: "${event.text}".',
                type: NotificationType.Error
            });
            fileReference = null;
        });
        fileReference.save(data.trim(), file);
    }

    public function refreshEvent():Void {
        eventDialog.refresh();
    }
}

@:xml('
<dialog title="Events" >
    <hbox horizontalAlign="center" >
        <label text="Event" verticalAlign="center" />
        <dropdown id="eventDropdown" />
    </hbox>

    <section-header text="Arguments" />
    <scrollview id="scrollView" style="max-height: 200px;" horizontalAlign="center" >
        <grid id="argContainer" />
    </scrollview>
</dialog>
')
class EventDialog extends CollapsibleDialog {
    var parent(get, never):ChartEditor;
    inline function get_parent():ChartEditor
        return cast FlxG.state;

    var skipCallback:Bool = false;

    public function new():Void {
        super();

        for (event in parent.eventList)
            eventDropdown.dataSource.add(event.name);

        eventDropdown.onChange = eventDropdown_onChange;
        eventDropdown.value = parent.currentEvent.name;
    }

    function eventDropdown_onChange(_):Void {
        if (skipCallback) {
            skipCallback = false;
            return;
        }
        
        parent.currentEvent = parent.eventList.get(eventDropdown.value);
        rebuildArguments();

        if (parent.currentEvent.arguments != null) {
            while (parent.eventArgs.length != 0) parent.eventArgs.pop();
            for (arg in parent.currentEvent.arguments) parent.eventArgs.push(arg.value);
        }
    
        if (parent.selectedEvent != null) {
            parent.selectedEvent.data.event = eventDropdown.value;
            parent.selectedEvent.data.arguments = parent.eventArgs.copy();
        }
    }

    function rebuildArguments(withValues:Bool = false):Void {
        var details:EventDetails = parent.eventList.get(parent.currentEvent.name);

        scrollView._height = null; // temporary until max-height gets fixed
        argContainer.removeAllComponents();

        if (details.arguments == null) return;

        for (i in 0...details.arguments.length) {
            var argument:EventArgument = details.arguments[i];

            var text:Label = new Label();
            text.verticalAlign = "center";
            text.text = argument.name;

            var value:Dynamic = (withValues ? parent.selectedEvent.data.arguments[i] : null);
            var comp:Component = buildComponent(argument, i, value);

            argContainer.addComponent(text);
            argContainer.addComponent(comp);
        }
    }

    inline function buildComponent(argument:EventArgument, loopIndex:Int, ?value:Dynamic):Component {
        var component:Component = null;

        switch (argument.type) {
            case STRING:
                var textField:TextField = new TextField();
                textField.text = value ?? argument.value ?? "";
                component = textField;
            case BOOL:
                var checkBox:CheckBox = new CheckBox();
                checkBox.selected = value ?? argument.value ?? false;
                component = checkBox;
            case FLOAT, INT, NUMBER:
                var stepper:NumberStepper = new NumberStepper();
                if (argument.step != null) stepper.step = argument.step;
                if (argument.min != null) stepper.min = argument.min;
                if (argument.max != null) stepper.max = argument.max;
                stepper.value = value ?? argument.value ?? 0;
                component = stepper;
            case COLOR:
                var colorPicker:ColorPickerPopup = new ColorPickerPopup();
                colorPicker.value = value ?? Tools.getColor(argument.value);
                component = colorPicker;
            case LIST:
                var dropdown:DropDown = new DropDown();
                for (value in argument.list) dropdown.dataSource.add(value);
                if (value != null) dropdown.value = value;
                component = dropdown;
        };

        component.onChange = (_) -> {
            parent.eventArgs[loopIndex] = component.value;

            if (parent.selectedEvent != null)
                parent.selectedEvent.data.arguments[loopIndex] = component.value;
        };

        return component;
    }

    public function refresh():Void {
        parent.currentEvent = parent.eventList.get(parent.selectedEvent.data.event);
        skipCallback = true;

        // do stuff on our own since .value and onChange are apparently unreliable?
        // TODO: figure out how and why, and eventually re-use onChange/value
        eventDropdown.value = parent.currentEvent.name;
        rebuildArguments(true);
        
        var args:Array<Any> = parent.selectedEvent.data.arguments;
        if (args != null) {
            while (parent.eventArgs.length != 0) parent.eventArgs.pop();
            for (arg in args) parent.eventArgs.push(arg);
        }
    }
}

@:xml('
<dialog title="Preferences" width="250" height="150" >
    <scrollview width="100%" height="100%" contentWidth="100%" >
        <vbox width="100%">
            <checkbox text="Late Note Transparency" id="lateNote" />
            <checkbox text="Strumline Scroll Snap" id="lineSnap" />
            <checkbox text="Show Measure Marks" id="measureMarks" />
            <checkbox text="Show Beat Indicators" id="beatIndices" />
            <checkbox text="Show Time Overlay" id="timeOverlay" />
            <checkbox text="Show Receptors" id="receptors" />
        </vbox>
    </scrollview>
</dialog>
')
class PreferenceDialog extends CollapsibleDialog {
    var parent(get, never):ChartEditor;
    inline function get_parent():ChartEditor
        return cast FlxG.state;

    public function new():Void {
        super();

        lateNote.selected = Settings.get("CHART_lateAlpha");
        lineSnap.selected = Settings.get("CHART_strumlineSnap");
        measureMarks.selected = Settings.get("CHART_measureMark");
        beatIndices.selected = Settings.get("CHART_beatIndices");
        timeOverlay.selected = Settings.get("CHART_timeOverlay");
        receptors.selected = Settings.get("CHART_receptors");
    }

    @:bind(lateNote, UIEvent.CHANGE)
    function lateNote_change(_):Void {
        Settings.settings["CHART_lateAlpha"].value = lateNote.selected;
    }

    @:bind(lineSnap, UIEvent.CHANGE)
    function lineSnap_change(_):Void {
        Settings.settings["CHART_strumlineSnap"].value = lineSnap.selected;
    }

    @:bind(measureMarks, UIEvent.CHANGE)
    function measureMarks_change(_):Void {
        Settings.settings["CHART_measureMark"].value = measureMarks.selected;
        parent.measureBackdrop.visible = measureMarks.selected;
    }

    @:bind(beatIndices, UIEvent.CHANGE)
    function beatIndices_change(_):Void {
        Settings.settings["CHART_beatIndices"].value = beatIndices.selected;
        parent.beatIndicators.visible = beatIndices.selected;
    }

    @:bind(timeOverlay, UIEvent.CHANGE)
    function timeOverlay_change(_):Void {
        parent.overlay.visible = parent.musicText.visible = timeOverlay.selected;
        parent.timeBar.hidden = parent.timeBar.disabled = !timeOverlay.selected;
        Settings.settings["CHART_timeOverlay"].value = timeOverlay.selected;
    }

    @:bind(receptors, UIEvent.CHANGE)
    function receptors_change(_):Void {
        Settings.settings["CHART_receptors"].value = receptors.selected;
        parent.receptors.visible = receptors.selected;
    }
}
