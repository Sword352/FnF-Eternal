package funkin.objects.sprites;

class RatingSprite extends OffsetSprite {
    var alphaTmr:Float;

    public function new():Void {
        super();
        setProps();
    }

    override function update(elapsed:Float):Void {
        alpha = 1 - (Math.max(alphaTmr += elapsed, 0) / (0.2 / Conductor.playbackRate));

        if (alpha <= 0) {
            kill();
            return;
        }

        super.update(elapsed);
    }

    override function revive():Void {
        super.revive();
        setProps();
    }
    
    function setProps():Void {
        var pb:Float = Conductor.playbackRate;

        velocity.set(-(FlxG.random.float(0, 10) * pb), -(FlxG.random.float(140, 175) * pb));
        acceleration.y = (600 * (pb * pb));

        if (Settings.get("reduced movements")) {
            acceleration.y *= 0.4;
            velocity.y *= 0.4;
        }

        alphaTmr = -((Conductor.crochet * 0.001) / pb);
        alpha = 1;
    }
}

class ComboSprite extends RatingSprite {
    override function setProps():Void {
        var pb:Float = Conductor.playbackRate;

        velocity.set(FlxG.random.float(-5, 5) * pb, -(FlxG.random.int(140, 160) * pb));
        acceleration.y = (FlxG.random.int(200, 300) * (pb * pb));

        if (Settings.get("reduced movements")) {
            acceleration.y *= 0.4;
            velocity.y *= 0.4;
        }

        alphaTmr = -((Conductor.crochet * 0.002) / pb);
        alpha = 1;
    }
}