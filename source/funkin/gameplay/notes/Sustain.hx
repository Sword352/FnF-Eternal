package funkin.gameplay.notes;

import flixel.FlxCamera;
import flixel.math.FlxRect;
import funkin.objects.TiledSprite;
import funkin.objects.OffsetSprite;

class Sustain extends TiledSprite {
    public var parent(default, set):Note;
    public var tail:Tail = new Tail();

    public function new(parent:Note):Void {
        super(null, 0, 0, false, true);
        this.parent = parent;
    }

    override function update(elapsed:Float):Void {
        if (tail.exists && tail.active)
            tail.update(elapsed);

        if (!parent.overrideSustain)
            updateSustain();

        super.update(elapsed);
    }

    override function draw():Void {
        super.draw();

        if (tail.exists && tail.visible)
            tail.draw();
    }

    override function kill():Void {
        tail.clipRect = FlxDestroyUtil.put(tail.clipRect);
        tail.kill();

        clipRect = FlxDestroyUtil.put(clipRect);
        super.kill();
    }

    override function revive():Void {
        tail.revive();
        super.revive();
    }

    override function destroy():Void {
        tail = FlxDestroyUtil.destroy(tail);
        parent = null;

        super.destroy();
    }

    function updateSustain():Void {
        // absify the height so small sustains won't have negative heights.
        var finalHeight:Float = Math.abs((parent.length * parent.scrollSpeed) - tail.height);

        // quantize the sustain, useful for noteskins with patterns
        if (parent.quantizeSustain)  {
            var tileHeight:Float = graphic.height * scale.y;
            finalHeight = Math.fround(finalHeight / tileHeight) * tileHeight;
        }

        height = finalHeight;

        setPosition(parent.x + ((parent.width - width) * 0.5), parent.y + (parent.height * 0.5));
        if (parent.downscroll) y -= height;

        tail.setPosition(x, y + (parent.downscroll ? -tail.height : height));

        var flip:Bool = parent.downscroll;
        if (parent.flipY) flip = !flip;
        flipY = flip;
    }

    public function reloadGraphic():Void {
        var dir:String = Note.directions[parent.direction];

        frames = parent.frames;
        animation.copyFrom(parent.animation);
        animation.play(dir + " hold", true);
        loadFrame(frame ?? parent.frame);

        tail.frames = parent.frames;
        tail.animation.copyFrom(parent.animation);
        tail.animation.play(dir + " tail", true);

        scale.set(parent.scale.x, parent.scale.y);
        tail.scale.set(scale.x, scale.y);
        updateHitbox();

        antialiasing = parent.antialiasing;
        alpha = parent.sustainAlpha;
        flipX = parent.flipX;
    }

    override function updateHitbox():Void {
        width = graphic.width * scale.x;
        tail.updateHitbox();
        origin.set();
    }

    function set_parent(v:Note):Note {
        parent = v;

        if (v != null)
            reloadGraphic();

        return v;
    }

    override function set_antialiasing(v:Bool):Bool {
        if (tail != null) tail.antialiasing = v;
        return super.set_antialiasing(v);
    }

    override function set_alpha(v:Float):Float {
        if (tail != null) tail.alpha = v;
        return super.set_alpha(v);
    }

    override function set_flipX(v:Bool):Bool {
        if (tail != null) tail.flipX = v;
        return super.set_flipX(v);
    }

    override function set_flipY(v:Bool):Bool {
        if (tail != null) tail.flipY = v;
        return super.set_flipY(v);
    }

    override function set_cameras(v:Array<FlxCamera>):Array<FlxCamera> {
        if (tail != null) tail.cameras = v;
        return super.set_cameras(v);
    }

    override function set_camera(v:FlxCamera):FlxCamera {
        if (tail != null) tail.camera = v;
        return super.set_camera(v);
    }
}

class Tail extends OffsetSprite {
    // avoids rounding effect (shoutout to Ne_Eo)
    override function set_clipRect(v:FlxRect):FlxRect {
        clipRect = v;

        if (frames != null)
			frame = frames.frames[animation.frameIndex];
        
        return v;
    }
}
