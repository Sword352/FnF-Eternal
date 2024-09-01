package funkin.gameplay.notes;

import funkin.objects.TiledSprite;

/**
 * Object which displays a hold trail behind a sustain note.
 */
class Sustain extends TiledSprite {
    /**
     * Parent note.
     */
    public var parent(default, set):Note;

    /**
     * Creates a new `Sustain`.
     * @param parent Parent note.
     */
    public function new(parent:Note):Void {
        super();
        this.parent = parent;
    }

    override function update(elapsed:Float):Void {
        this.x = parent.x + (parent.width - width) * 0.5;
        this.y = parent.y + parent.height * 0.5;

        // we're making the sustain a bit longer here so it ends properly when it's about to be behind the receptor.
        // TODO: this causes visual innacuracies, maybe find a better solution?
        var receptor:Receptor = parent.parentStrumline.getReceptor(parent.direction);
        height = (parent.length * parent.scrollSpeed) + (receptor.height * 0.5);

        if (parent.downscroll)
            this.y -= height;

        super.update(elapsed);
    }

    /**
     * Reloads this `Sustain`'s frames, scale and such.
     */
    function refreshVisuals():Void {
        var dir:String = Note.directions[parent.direction];

        frames = parent.frames;
        animation.copyFrom(parent.animation);
        animation.play(dir + " hold", true);
        setTail(dir + " tail");

        scale.set(parent.scale.x, parent.scale.y);
        updateHitbox();

        flipY = parent.flipY;
        if (parent.downscroll)
            flipY = !flipY;

        antialiasing = parent.antialiasing;
        alpha = parent.sustainAlpha;
        flipX = parent.flipX;
    }

    override function kill():Void {
        clipRegion = FlxDestroyUtil.put(clipRegion);
        super.kill();
    }

    override function destroy():Void {
        parent = null;
        super.destroy();
    }

    function set_parent(v:Note):Note {
        parent = v;

        if (v != null)
            refreshVisuals();

        return v;
    }
}
