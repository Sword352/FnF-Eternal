package funkin.states.debug.chart;

import flixel.text.FlxText;
import flixel.group.FlxGroup;
import funkin.globals.ChartFormat.ChartEvent;

class ChartEventGroup extends FlxTypedGroup<EventSprite> {
    override function update(elapsed:Float):Void {
        forEachAlive((event) -> {
            if (Math.abs(event.data.time - Conductor.time) <= 2000)
                event.update(elapsed);
        });
    }
}

class EventSprite extends FlxSprite {
    public var data:ChartEvent;
    public var display:String;
    public var rect:FlxSprite;
    public var text:FlxText;
    
    public function new():Void {
        super();

        loadGraphic(Assets.image("ui/debug/evt_ic"));
        setGraphicSize(ChartEditor.checkerSize, ChartEditor.checkerSize);
        updateHitbox();

        rect = new FlxSprite();
        rect.makeRect(ChartEditor.checkerSize, ChartEditor.checkerSize, 0x860051FF, false, "charteditor_evrect");
        rect.visible = false;

        text = new FlxText();
        text.setFormat(Assets.font("vcr"), 12, FlxColor.WHITE, RIGHT);
    }

    override function update(elapsed:Float):Void {
        alpha = text.alpha = (data.time < Conductor.time && Settings.get("CHART_lateAlpha")) ? ChartEditor.lateAlpha : 1;
        color = text.color = (FlxG.mouse.overlaps(this)) ? ChartEditor.hoverColor : FlxColor.WHITE;

        #if FLX_DEBUG
		flixel.FlxBasic.activeCount++;
		#end
    }

    override function draw():Void {
        var displayText:String = (display ?? data.event);
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
        display = null;
        data = null;

        super.destroy();
    }
}