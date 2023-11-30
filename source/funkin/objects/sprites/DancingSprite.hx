package funkin.objects.sprites;

import flixel.system.FlxAssets.FlxGraphicAsset;

class DancingSprite extends OffsetSprite {
    public var danceAnimations:Array<String> = [];
    public var currentDance:Int = 0;
    public var beat:Float = 1;

    public function new(x:Float = 0, y:Float = 0, ?simpleGraphic:FlxGraphicAsset):Void {
        super(x, y, simpleGraphic);
        danceAnimations = [];
    }

    public function dance(currentBeat:Int, forced:Bool = false):Void {
        if (currentBeat % beat == 0)
            forceDance(forced);
    }

    public function forceDance(forced:Bool = false):Void {
        playAnimation(danceAnimations[currentDance], forced);
        currentDance = FlxMath.wrap(currentDance + 1, 0, danceAnimations.length - 1);
    }

    override function destroy():Void {
        super.destroy();
        danceAnimations = null;
    }
}