package funkin.editors.chart;

import haxe.ui.components.*;
import haxe.ui.containers.VBox;
import haxe.ui.backend.flixel.UIRuntimeSubState;
import funkin.ui.HealthIcon;

@:xml('
<vbox width="100%" height="100%" style="background-color: black; opacity: 0.6;">
    <panel text="Edit Metadata" width="65%" height="85%" style="top: 54px; background-color: #2c2e31; opacity: 1;" id="vboxContainer" horizontalAlign="center" >
        <style>
            .dropdown.charDrop {
                width: 150px;
                height: 35px;
            }

            .number-stepper, .textfield {
                font-name: "assets/fonts/dm-sans.ttf";
                font-size: 12px;
            }
        </style>

        <hbox width="100%" height="100%">
            <vbox width="31%" height="100%" style="spacing: 10px;">
                <vbox width="150" height="225" horizontalAlign="right" style="spacing: 25px;">
                    <vbox >
                        <label text="Opponent" />
                        <dropdown text="Opponent" id="oppDrop" styleName="charDrop" searchable="true" searchPrompt="..." />
                    </vbox>

                    <vbox >
                        <label text="Spectator" />
                        <dropdown text="Opponent" id="specDrop" styleName="charDrop" searchable="true" searchPrompt="..." />
                    </vbox>

                    <vbox >
                        <label text="Player" />
                        <dropdown text="Opponent" id="plrDrop" styleName="charDrop" searchable="true" searchPrompt="..." />
                    </vbox>
                </vbox>

                <vbox style="padding-left: 2px; spacing: 10px;">
                    <rule />
                    <hbox >
                        <label text="Stage" verticalAlign="center" />
                        <dropdown text="Stage" id="stageDrop" width="210" height="25" searchable="true" searchPrompt="..." />
                    </hbox>
                </vbox>
            </vbox>

            <spacer width="19%" />

            <vbox height="100%">
                <vertical-rule width="15" height="100%" horizontalAlign="center" verticalAlign="center" />
            </vbox>

            <vbox width="50%" height="50%" style="spacing: 5px;">
                <hbox width="77%" height="30%" style="spacing: 15px;" horizontalAlign="right">
                    <vbox height="100%">
                        <label text="BPM" horizontalAlign="center" />
                        <number-stepper id="bpmStepper" min="1" horizontalAlign="center" />
                    </vbox>
                    <vbox height="100%">
                        <label text="Scroll Speed" horizontalAlign="center" />
                        <number-stepper id="scrollSpeed" horizontalAlign="center" />
                    </vbox>
                    <vbox height="100%">
                        <label text="Time Signature" horizontalAlign="center" />
                        <hbox >
                            <number-stepper id="tsBpm" width="50" height="29" value="4" min="1" />
                            <label text="/" style="padding-left: 2px;" verticalAlign="center" />
                            <number-stepper id="tsSpb" width="50" height="29" value="4" min="1" />
                        </hbox>
                    </vbox>
                </hbox>

                <vbox width="100%" height="20%" >
                    <label text="Instrumental" horizontalAlign="right" />
                    <textfield text="Inst.ogg" horizontalAlign="right" />
                </vbox>

                <!--
                <vbox width="100%" height="100%" >
                    <label text="Voices" horizontalAlign="right" />
                </vbox>
                -->
            </vbox>
        </hbox>
    </panel>
</vbox>
')
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

    function getList(from:String):Array<String> {
        var list:Array<String> = [];
        
        Assets.invoke((source) -> {
            if (!source.exists('data/${from}'))
                return;

            var entries:Array<String> = source.readDirectory('data/${from}');
            for (entry in entries) {
                var formatted:String = entry.substring(0, entry.lastIndexOf("."));
                if (!list.contains(formatted)) list.push(formatted);
            }
        });

        return list;
    }
}

@:structInit private class StringWrapper {
    public var text:String;
    public function new(text:String):Void {
        this.text = text;
    }
}
