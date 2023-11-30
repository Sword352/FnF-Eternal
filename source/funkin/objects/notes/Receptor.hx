package funkin.objects.notes;

class Receptor extends OffsetSprite {
    public var direction(default, set):Int;

    public var scrollSpeed:Null<Float> = null;
    public var scrollMult:Null<Float> = null;
    
    public function new(direction:Int = 0):Void {
        super();
        this.direction = direction;
    }

    public function load(direction:Int):Void {
        frames = AssetHelper.getSparrowAtlas("notes/receptors");

        for (anim in ["press", "static", "confirm"])
            animation.addByPrefix(anim, '${Note.directions[direction]} ${anim}', 24, false);

        playAnimation("static");

        scale.set(0.7, 0.7);
        updateHitbox();
        centerOffsets();
    }

    override public function playAnimation(name:String, force:Bool = false, reversed:Bool = false, frame = 0):Void {
        super.playAnimation(name, force, reversed, frame);
        centerOrigin();
        centerOffsets();
    }

    function set_direction(v:Int):Int {
        load(v);
        return direction = v;
    }
}
