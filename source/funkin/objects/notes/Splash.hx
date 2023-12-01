package funkin.objects.notes;

class Splash extends OffsetSprite {
    public var timeScale:Float = 1;

    public function new():Void {
        super();

        frames = AssetHelper.getSparrowAtlas("notes/noteSplashes");

        var animationArray:Array<String> = ["down", "up", "left", "right"];
        for (i in 0...2) {
            var index:Int = i + 1;
            for (anim in animationArray) {
                var name:String = '${anim}-${index}';
                animation.addByPrefix('${anim}-${index}', 'splash${index} ${anim}', 24, false);
                animation.play(name);
                updateHitbox();
                addOffset(name, width * 0.3, height * 0.3);
            }
        }

        animation.finish();
        alpha = 0.6;
    }

    public function pop(direction:Int):Void {
        var anim:String = '${Note.directions[direction]}-${FlxG.random.int(1, 2)}';
        animation.getByName(anim).timeScale = timeScale * FlxG.random.float(0.8, 1.2);
        playAnimation(anim, true);
    }

    override function update(elapsed:Float):Void {
        if (animation.curAnim.finished)
            kill();

        super.update(elapsed);
    }
}