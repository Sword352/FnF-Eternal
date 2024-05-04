package states.editors.chart;

import haxe.ui.components.*;
import haxe.ui.containers.VBox;
import haxe.ui.backend.flixel.UIRuntimeSubState;
import objects.HealthIcon;

@:build(haxe.ui.RuntimeComponentBuilder.build("assets/data/metadataScreen.xml"))
class MetadataScreen extends UIRuntimeSubState {
    var parent(get, never):ChartEditor;
    inline function get_parent():ChartEditor
        return cast FlxG.state;

    var oppDrop:DropDown;
    var specDrop:DropDown;
    var plrDrop:DropDown;
    var stageDrop:DropDown;

    var bpmStepper:NumberStepper;
    var scrollSpeed:NumberStepper;

    // time signature - beats per measure, steps per beat
    var tsBpm:NumberStepper;
    var tsSpb:NumberStepper;

    var storedBPM:Float;
    var currentBPM:Int;
    var currentSPB:Int;
    var reloadBPM:Bool;
    var reloadSPB:Bool;
    
    var vboxContainer:VBox;

    var allowActions:Bool = false;

    //
    @:bind(bpmStepper, UIEvent.CHANGE)
    function bpmStepper_change():Void {
        if (!allowActions) return;
        parent.chart.gameplayInfo.bpm = bpmStepper.pos;
    }

    @:bind(scrollSpeed, UIEvent.CHANGE)
    function scrollSpeed_change():Void {
        if (!allowActions) return;
        parent.chart.gameplayInfo.scrollSpeed = scrollSpeed.pos;
    }

    @:bind(tsBpm, UIEvent.CHANGE)
    function tsBpm_change():Void {
        if (!allowActions) return;
        Conductor.self.beatsPerMeasure = parent.chart.gameplayInfo.beatsPerMeasure = Math.floor(tsBpm.pos);
        reloadBPM = (currentBPM != parent.chart.gameplayInfo.beatsPerMeasure);
    }

    @:bind(tsSpb, UIEvent.CHANGE)
    function tsSpb_change():Void {
        if (!allowActions) return;
        Conductor.self.stepsPerBeat = parent.chart.gameplayInfo.stepsPerBeat = Math.floor(tsSpb.pos);
        reloadSPB = (currentSPB != parent.chart.gameplayInfo.stepsPerBeat);
    }
    //

    override function onReady():Void {
        scrollSpeed.pos = parent.chart.gameplayInfo.scrollSpeed;
        bpmStepper.pos = parent.chart.gameplayInfo.bpm;

        currentBPM = parent.chart.gameplayInfo.beatsPerMeasure ?? 4;
        currentSPB = parent.chart.gameplayInfo.stepsPerBeat ?? 4;
        storedBPM = bpmStepper.pos;
        tsBpm.pos = currentBPM;
        tsSpb.pos = currentSPB;

        allowActions = true;

        var chars:Array<String> = [
            parent.chart.gameplayInfo.opponent,
            parent.chart.gameplayInfo.spectator,
            parent.chart.gameplayInfo.player,
        ];
        var icons:Array<HealthIcon> = [];

        for (i in 0...chars.length) {
            var char:String = chars[i];
            if (char == null) char = "face";

            var icon:HealthIcon = new HealthIcon(vboxContainer.left + 15, vboxContainer.top + 30 + 80 * i, ChartEditor.getIcon(char));
            icon.setGraphicSize(0, 75);
            icon.updateHitbox();

            icon.healthAnim = false;
            icons.push(icon);
            add(icon);
        }

        var characterList:Array<String> = getList("characters");
        var stageList:Array<String> = getList("stages");

        // workaround to fix dropdown searching with strings (temporary)
        var strings:Map<String, StringWrapper> = [];

        for (char in characterList) strings.set(char, {text: char});
        for (stage in stageList) strings.set(stage, {text: stage});
        strings.set("No Character", {text: "No Character"});
        strings.set("No Stage", {text: "No Stage"});

        if (characterList.length == 0) {
            oppDrop.text = specDrop.text = plrDrop.text = "No character found.";
            oppDrop.disabled = specDrop.disabled = plrDrop.disabled = true;
        }
        else {
            var drops = [oppDrop, specDrop, plrDrop];
            for (i in 0...drops.length) {
                var drop:DropDown = drops[i];

                for (char in characterList) drop.dataSource.add(strings.get(char));
                drop.dataSource.add(strings.get("No Character"));

                drop.selectedItem = chars[i] ?? "No Character";
                drop.onChange = (_) -> {
                    var string:StringWrapper = cast drop.selectedItem;

                    var character:String = string.text;
                    if (character == "No Character") character = null;

                    var icon:String = ChartEditor.getIcon(character);
                    var ref:HealthIcon = icons[i];

                    ref.changeIcon(icon);
                    ref.setGraphicSize(0, 75);
                    ref.updateHitbox();

                    switch (i) {
                        case 0:
                            parent.chart.gameplayInfo.opponent = character;
                            parent.opponentIcon.changeIcon(icon);
                            parent.opponentIcon.setGraphicSize(0, 100);
                            parent.opponentIcon.updateHitbox();
                        case 2:
                            parent.chart.gameplayInfo.player = character;
                            parent.playerIcon.changeIcon(icon);
                            parent.playerIcon.setGraphicSize(0, 100);
                            parent.playerIcon.updateHitbox();
                        case 1:
                            parent.chart.gameplayInfo.spectator = character;
                    }
                };
            }
        }

        if (stageList.length == 0) {
            stageDrop.text = "No stage found.";
            stageDrop.disabled = true;
        }
        else {
            for (stage in stageList) stageDrop.dataSource.add(strings.get(stage));
            stageDrop.dataSource.add(strings.get("No Stage"));

            stageDrop.selectedItem = parent.chart.gameplayInfo.stage ?? "No Stage";
            stageDrop.onChange = (_) -> {
                var string:StringWrapper = cast stageDrop.selectedItem;
                var stage:String = string.text;
                if (stage == "No Stage") stage = null;
                parent.chart.gameplayInfo.stage = stage;
            };
        }
    }

    override function update(elapsed:Float):Void {
        if (FlxG.keys.justPressed.ESCAPE) {
            close();
            return;
        }

        super.update(elapsed);
    }

    override function close():Void {
        // dont reload if the bpm is not the same, as it's done automatically
        if (storedBPM == parent.chart.gameplayInfo.bpm) {
            if (reloadSPB) {
                parent.checkerboard.refreshBeatSep();
                parent.reloadGrid();
            }
            else if (reloadBPM)
                parent.checkerboard.refreshMeasureSep();
        }

        super.close();
    }

    // used to return the lists from assets and mods
    inline function getList(from:String):Array<String> {
        var path:String = Assets.getPath('data/${from}', NONE);
        var pathDefault:String = 'assets/data/${from}';
        var list:Array<String> = [];

        if (pathDefault != path && FileTools.exists(pathDefault)) {
            for (entry in FileTools.readDirectory(pathDefault)) {
                var formatted:String = entry.substring(0, entry.lastIndexOf("."));
                if (!list.contains(formatted)) list.push(formatted);
            }
        }

        if (FileTools.exists(path)) {
            for (entry in FileTools.readDirectory(path)) {
                var formatted:String = entry.substring(0, entry.lastIndexOf("."));
                if (!list.contains(formatted)) list.push(formatted);
            }
        }

        return list;
    }
}

@:structInit private class StringWrapper {
    public var text:String;
    public function new(text:String):Void {
        this.text = text;
    }
}
