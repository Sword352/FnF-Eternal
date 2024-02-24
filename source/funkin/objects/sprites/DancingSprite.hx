package funkin.objects.sprites;

class DancingSprite extends OffsetSprite {
    public var danceAnimations:Array<String> = [];
    public var currentDance:Int = 0;
    public var beat:Float = 1;

    public function dance(currentBeat:Int, forced:Bool = false):Void {
        if (currentBeat % beat == 0)
            forceDance(forced);
    }

    public function forceDance(forced:Bool = false):Void {
        playAnimation(danceAnimations[currentDance], forced);
        currentDance = (currentDance + 1) % danceAnimations.length;
    }

    override function destroy():Void {
        danceAnimations = null;
        super.destroy();
    }
}