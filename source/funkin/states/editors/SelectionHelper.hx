package funkin.states.editors;

import flixel.FlxBasic;
import flixel.math.FlxPoint;
import haxe.ui.core.Screen;

using flixel.util.FlxColorTransformUtil;

class SelectionHelper extends FlxBasic {
    // connect a hover box to the selector
    public var hoverBox:HoverBox;

    public var dragging:Bool = false;
    public var selection:Array<SelectableSprite> = [];
    public var onRelease:Void->Void = null;

    var clickPoint:FlxPoint = FlxPoint.get();

    /**
     * NOTE: make sure to add this before the hover box for normal behaviour.
     */
    public function new(hoverBox:HoverBox = null):Void {
        super();
        this.hoverBox = hoverBox;
        visible = false;
    }

    public function register(sprite:SelectableSprite):Void {
        sprite.selected = true;
        selection.push(sprite);
    }

    public function unregister(sprite:SelectableSprite):Void {
        if (!sprite.selected) return;

        sprite.selected = false;
        sprite.dragging = false;
        selection.remove(sprite);
    }

    override function update(elapsed:Float):Void {
        if (selection.length == 0) return;

        // check if one object is overlapped on click
        if (!dragging && FlxG.mouse.justPressed) {
            // first loop to see if a sprite is being clicked
            for (spr in selection) {
                if (FlxG.mouse.overlaps(spr)) {
                    dragging = true;
                    break;
                }
            }

            if (!dragging) {
                if (!Screen.instance.hasComponentUnderPoint(FlxG.mouse.screenX, FlxG.mouse.screenY)) reset();
                return;
            }

            for (spr in selection) {
                spr.startingPos.set(spr.x, spr.y);
                spr.dragging = true;
                spr.onSelect();
            }

            clickPoint.set(FlxG.mouse.x, FlxG.mouse.y);
            setBoxActive(false);
        }
        
        if (dragging) {
            for (spr in selection) {
                // note to self: dont use mouse delta x/y. this makes the movement smoother and more natural
                spr.x = FlxMath.bound(spr.startingPos.x + (FlxG.mouse.x - clickPoint.x), spr.dragBound.x, spr.dragBound.y);
                spr.y = spr.startingPos.y + (FlxG.mouse.y - clickPoint.y);
                spr.onDrag();

                if (FlxG.mouse.justReleased) {
                    spr.dragging = false;
                    spr.onRelease();
                }
            }

            if (FlxG.mouse.justReleased) {
                if (onRelease != null) onRelease();
                setDragging(false);
            }
        }
    }

    public function unselectAll():Void {
        while (selection.length != 0) {
            var spr:SelectableSprite = selection.pop();
            if (dragging) spr.onRelease(); // in case the user is dragging
            unregister(spr);
        }

        setDragging(false);
    }

    function reset():Void {
        while (selection.length != 0) {
            var sprite:SelectableSprite = selection.pop();
            sprite.selected = false;
            sprite.dragging = false;
        }

        setDragging(false);
    }

    inline function setDragging(dragging:Bool):Void {
        this.dragging = dragging;
        setBoxActive(!dragging);
    }

    inline function setBoxActive(active:Bool):Void {
        if (hoverBox != null) hoverBox.active = active;
    }

    override function destroy():Void {
        clickPoint = FlxDestroyUtil.put(clickPoint);
        selection = null;
        hoverBox = null;
        super.destroy();
    }
}

// base class for selectable sprites
class SelectableSprite extends FlxSprite {
    // handled by SelectionHelper
    public var startingPos:FlxPoint = FlxPoint.get();
    public var dragging:Bool = false;
    public var selected:Bool = false;
    //

    // used by class extensions
    public var dragBound:FlxPoint = FlxPoint.get(0, FlxG.width);

    public function onSelect():Void {}
    public function onRelease():Void {}
    public function onDrag():Void {}

    function updateColor(selected:Bool):Void {
        var offset:Float = (selected ? 75 : 0);
        colorTransform.setOffsets(offset, offset, offset, 0);
    }
    //

    override function draw():Void {
        updateColor(selected);
        super.draw();
        updateColor(false);
    }

    override function destroy():Void {
        startingPos = FlxDestroyUtil.put(startingPos);
        dragBound = FlxDestroyUtil.put(dragBound);
        super.destroy();
    }
}
