package funkin.objects.sprites;

import flixel.math.FlxRect;
import flixel.graphics.frames.FlxFrame;
import flixel.addons.display.FlxTiledSprite;

/**
 * FlxTiledSprite extension with:
 * - A fix to make tiles smoother
 * - Scaling support
 * - Flipping support
 * - Partial clipRect support
 */

// some stuff are inspired from RapperGF and EliteMasterEric, shoutout to them
// and thanks lunarcleint for the scaling suggestion

// TODO: fix clipRect texture scrolling not working with flipY, and fix rendering to work with cam zooms less than 1

class TiledSprite extends FlxTiledSprite {
    override function updateVerticesData():Void {
        if (graphic == null) return;
        graphicVisible = true;

        var frame:FlxFrame = graphic.imageFrame.frame;
        var scaledSizeX:Float = frame.sourceSize.x * scale.x;
        var scaledSizeY:Float = frame.sourceSize.y * scale.y;
        var scrollOffsetX:Float = -scrollX / scaledSizeX;

        if (repeatX) {
            vertices[0] = vertices[6] = (flipX ? width : 0);
            vertices[2] = vertices[4] = (flipX ? 0 : width);

            uvtData[0] = uvtData[6] = scrollOffsetX;
            uvtData[2] = uvtData[4] = scrollOffsetX + (width / scaledSizeX);
        } else {
            var firstEdge:Float = FlxMath.bound(scrollX, 0, width);
            var secondEdge:Float = FlxMath.bound(scrollX + scaledSizeX, 0, width);

            vertices[0] = vertices[6] = (flipX ? secondEdge : firstEdge);
            vertices[2] = vertices[4] = (flipX ? firstEdge : secondEdge);

            if (secondEdge - firstEdge <= 0) {
                graphicVisible = false;
                return;
            }

            uvtData[0] = uvtData[6] = scrollOffsetX;
            uvtData[2] = uvtData[4] = scrollOffsetX + (width / scaledSizeX);
        }

        if (repeatY) {
            var rectY:Float = (clipRect?.y ?? 0);
            var rectHeight:Float = rectY + height;
            var scroll:Float = (rectY - scrollY) / scaledSizeY;

            if (clipRect != null)
                rectHeight = FlxMath.bound(rectHeight, clipRect.y, clipRect.y + Math.max(clipRect.height, 0));

            vertices[1] = vertices[3] = (flipY ? rectHeight : rectY);
            vertices[5] = vertices[7] = (flipY ? rectY : rectHeight);

            uvtData[1] = uvtData[3] = scroll;
            uvtData[5] = uvtData[7] = scroll + ((rectHeight - rectY) / scaledSizeY);
        } else {
            vertices[1] = vertices[3] = FlxMath.bound(scrollY, 0, height);
            vertices[5] = vertices[7] = FlxMath.bound(scrollY + scaledSizeY, 0, height);

            if (vertices[5] - vertices[1] <= 0) {
                graphicVisible = false;
                return;
            }

            uvtData[1] = uvtData[3] = (vertices[1] - scrollY) / scaledSizeY;
            uvtData[5] = uvtData[7] = uvtData[1] + (vertices[5] - vertices[1]) / scaledSizeY;
        }
    }

    override function set_clipRect(v:FlxRect):FlxRect {
        regen = true;
        return clipRect = v;
    }

    override function set_flipX(v:Bool):Bool {
        if (!regen) regen = (flipX != v);
        return flipX = v;
    }

    override function set_flipY(v:Bool):Bool {
        if (!regen) regen = (flipY != v);
        return flipY = v;
    }
}
