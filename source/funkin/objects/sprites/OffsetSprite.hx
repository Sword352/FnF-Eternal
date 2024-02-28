package funkin.objects.sprites;

class OffsetSprite extends FlxSprite {
    public var animationOffsets:Map<String, Array<Float>> = [];

    inline public function addOffset(animation:String, x:Float = 0, y:Float = 0):Array<Float>
        return animationOffsets[animation] = [x, y];

    public function playAnimation(name:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void {
        animation.play(name, force, reversed, frame);

        var offsetArray:Array<Float> = animationOffsets.get(animation.name) ?? [0, 0];
        offset.set(offsetArray[0], offsetArray[1]);
    }

    override public function destroy():Void {
        animationOffsets = null;
        super.destroy();
    }
}
