package funkin.objects.sprites;

import flixel.math.FlxRect;
import flixel.graphics.frames.FlxFrame;
import flixel.addons.display.FlxTiledSprite;

// FlxTiledSprite extension with scaling support, partial clipRect support and a fix to make tiles smoother
// original by RapperGF and EliteMasterEric

class TiledSprite extends FlxTiledSprite {
    override function updateVerticesData():Void {
        if (graphic == null) return;

        var frame:FlxFrame = graphic.imageFrame.frame;
        var scaledSizeX:Float = frame.sourceSize.x * scale.x;
        var scaledSizeY:Float = frame.sourceSize.y * scale.y;

        graphicVisible = true;

        if (repeatX) {
            /*
            var rectX:Float = (clipRect?.x ?? 0.0);

            var rectWidth:Float = rectX + width;
		    if (clipRect != null) rectWidth = FlxMath.bound(rectWidth, clipRect.x, clipRect.x + clipRect.width);
            */

            vertices[0] = vertices[6] = 0.0;
            vertices[2] = vertices[4] = width;

            uvtData[0] = uvtData[6] = -scrollX / scaledSizeX;
            uvtData[2] = uvtData[4] = uvtData[0] + width / scaledSizeX;
        } else {
            /*
            var rectX:Float = FlxMath.bound(scrollX, 0, width);
		    if (clipRect != null) rectX += clipRect.x;

            var rectWidth:Float = FlxMath.bound(scrollX + scaledSizeX, 0, width);
            if (clipRect != null) rectWidth = FlxMath.bound(rectWidth, clipRect.x, clipRect.x + clipRect.width);
            */

            vertices[0] = vertices[6] = FlxMath.bound(scrollX, 0, width);
            vertices[2] = vertices[4] = FlxMath.bound(scrollX + scaledSizeX, 0, width);

            if (vertices[2] - vertices[0] <= 0) {
                graphicVisible = false;
                return;
            }

            uvtData[0] = uvtData[6] = -scrollX / scaledSizeX;
            uvtData[2] = uvtData[4] = uvtData[0] + width / scaledSizeX;
        }

        if (repeatY) {
            var rectY:Float = (clipRect?.y ?? 0.0);

            var rectHeight:Float = rectY + height;
            if (clipRect != null) rectHeight = FlxMath.bound(rectHeight, clipRect.y, clipRect.y + Math.max(clipRect.height, 0));

            vertices[1] = vertices[3] = rectY;
            vertices[5] = vertices[7] = rectHeight;

            uvtData[1] = uvtData[3] = ((rectY - scrollY) / scaledSizeY);
            uvtData[5] = uvtData[7] = (uvtData[1] * scaledSizeY + (rectHeight - rectY)) / scaledSizeY;
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
}
