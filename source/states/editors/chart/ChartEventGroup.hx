package states.editors.chart;

import flixel.text.FlxText;
import flixel.group.FlxGroup;
import globals.ChartFormat.ChartEvent;
import states.editors.SelectionHelper.SelectableSprite;

class ChartEventGroup extends FlxTypedGroup<EventSprite> {
    override function update(elapsed:Float):Void {
        forEachAlive((event) -> {
            if (Math.abs(event.data.time - Conductor.self.time) <= 2000)
                event.update(elapsed);
        });
    }
}

class EventSprite extends SelectableSprite {
    public var data:ChartEvent;
    public var rect:FlxSprite;
    public var text:FlxText;

    var undoTime:Float = 0;
    
    public function new():Void {
        super();

        loadGraphic(Assets.image("ui/debug/event_icon"));
        setGraphicSize(ChartEditor.checkerSize, ChartEditor.checkerSize);
        updateHitbox();

        rect = new FlxSprite();
        rect.makeRect(ChartEditor.checkerSize, ChartEditor.checkerSize, 0x860051FF, false, "charteditor_evrect");
        rect.visible = false;

        text = new FlxText();
        text.setFormat(Assets.font("vcr"), 12, FlxColor.WHITE, RIGHT);

        var editor:ChartEditor = cast FlxG.state;
        var bound:Float = editor.checkerboard.x - ChartEditor.checkerSize - ChartEditor.separatorWidth;
        dragBound.set(bound, bound);
        x = bound;
    }

    override function update(elapsed:Float):Void {
        var editor:ChartEditor = cast FlxG.state;

        alpha = text.alpha = (data.time < Conductor.self.time && editor.hasLateAlpha) ? ChartEditor.lateAlpha : 1;
        color = text.color = (FlxG.mouse.overlaps(this)) ? ChartEditor.hoverColor : FlxColor.WHITE;

        #if FLX_DEBUG
		flixel.FlxBasic.activeCount++;
		#end
    }

    override function onDrag():Void {
        var editor:ChartEditor = cast FlxG.state;
        y = FlxMath.bound(y, 0, editor.checkerboard.bottom - height);
        data.time = ChartEditor.getTimeFromY(y);
    }

    override function onSelect():Void {
        // once again we're removing the event so we don't have to sort the array each frames
        // (required for bpm changes)
        cast(FlxG.state, ChartEditor).chart.events.remove(data);

        // store value for undo
        undoTime = data.time;
    }

    override function onRelease():Void {
        var editor:ChartEditor = cast FlxG.state;

        if (!FlxG.keys.pressed.SHIFT) {
            y = ChartEditor.roundPos(y);
            data.time = ChartEditor.getTimeFromY(y);
        }

        editor.eventDrags.push({ref: data, time: data.time, oldTime: undoTime});

        editor.requestSortEvents = true;
        editor.chart.events.push(data);
    }

    override function draw():Void {
        var displayText:String = data.event;
        if (data.arguments != null)
            displayText += '\nArguments: ${data.arguments.join(", ")}';

        text.text = displayText;
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
        data = null;

        super.destroy();
    }
}
