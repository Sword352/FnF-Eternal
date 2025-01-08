package funkin.editors;

import flixel.math.FlxRect;
import haxe.ui.core.Screen;

class HoverBox extends FlxSprite {
    public var enabled(get, never):Bool;
    public var onRelease:Void->Void;

    // used to check for "negative" scale (see updateHitbox)
    var negativeX:Bool = false;
    var negativeY:Bool = false;

    public function new():Void {
        super(-1);
        makeGraphic(1, 1);
        visible = false;
        alpha = 0.45;
    }

    override function update(elapsed:Float):Void {
        if (FlxG.mouse.justPressed && !Screen.instance.hasComponentUnderPoint(FlxG.mouse.viewX, FlxG.mouse.viewY)) {
            setPosition(FlxG.mouse.x, FlxG.mouse.y);
            visible = true;
        }

        if (!visible) return;

        if (FlxG.mouse.justReleased)
            release();
        else {
            scale.set(FlxG.mouse.x - x, FlxG.mouse.y - y);
            updateHitbox();
        }
    }

    override function updateHitbox():Void {
        negativeX = scale.x < 0;
        negativeY = scale.y < 0;
        scale.x = Math.abs(scale.x);
        scale.y = Math.abs(scale.y);

        super.updateHitbox();

        // using offset since base updateHitbox absify the scale for both width and height
        // and flixel complains about negative width and height (not gonna override both setters for safety)
        if (negativeX) offset.x += width;
        if (negativeY) offset.y += height;
    }

    function release():Void {
        // check for scale because why calling when we haven't seen the box in the first place
        if (onRelease != null && scale.x > 0 && scale.y > 0)
            onRelease();

        visible = false;
        x = -1;
    }

    public function contains(spr:FlxSprite):Bool {
        var hoverZone:FlxRect = getHoverZone();
        var output:Bool =
            spr.x < hoverZone.x + hoverZone.width
            && spr.x + spr.width > hoverZone.x
            && spr.y < hoverZone.y + hoverZone.height
            && spr.y + spr.height > hoverZone.y;
        
        hoverZone.put();
        return output;
    }

    public function getHoverZone():FlxRect {
        return FlxRect.get(
            negativeX ? (x - scale.x) : x,
            negativeY ? (y - scale.y) : y,
            scale.x, scale.y
        );
    }

    function get_enabled():Bool {
        return visible && scale.x > 0 && scale.y > 0;
    }
}
