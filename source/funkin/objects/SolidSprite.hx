package funkin.objects;

import flixel.graphics.FlxGraphic;

/**
 * A sprite displaying a rectangle graphic.
 * Unlike `makeGraphic`, the displayed graphic is fully flexible
 * and can change size and/or color using the `width`, `height` and `color` properties.
 */
class SolidSprite extends FlxSprite {
    /**
     * Creates a new `SolidSprite` instance.
     * @param x Initial x position.
     * @param y Initial y position.
     * @param width Initial width.
     * @param height Initial height.
     */
    public function new(x:Float = 0, y:Float = 0, width:Float = 100, height:Float = 100):Void {
        super(x, y);
        loadGraphic(getSolidGraphic());
        setSize(width, height);
        updateHitbox();
    }

    function getSolidGraphic():FlxGraphic {
        var output:FlxGraphic = FlxG.bitmap.get("solidsprite");

        if (output == null) {
            output = FlxGraphic.fromRectangle(1, 1, FlxColor.WHITE, "solidsprite");
            output.persist = true;
        }

        return output;
    }

    override function set_width(v:Float):Float {
        if (scale != null) scale.x = v;
        return super.set_width(v);
    }

    override function set_height(v:Float):Float {
        if (scale != null) scale.y = v;
        return super.set_height(v);
    }
}
