package eternal.ui;

class HelpButton extends FlxSprite {
    public var onClick:Void->Void = null;

    public var flickerDuration:Float = 0.2;
    public var flickerCount:Float = 2;

    var flickerTmr:Float = 0;
    var flickerDly:Float = 0;

    public function new():Void {
        super();

        loadGraphic(AssetHelper.image("ui/debug/question_marks"), true, 179, 179);
        animation.add("mark", [0, 1], 0);
        animation.play("mark");

        scale.set(0.35, 0.35);
        updateHitbox();
        alpha = 0.6;

        setPosition(5, FlxG.height - height - 5);
    }

    override function update(elapsed:Float):Void {
        var hovered:Bool = FlxG.mouse.overlaps(this, camera);

        if (hovered && FlxG.mouse.justPressed && flickerTmr <= 0) {
            flickerTmr = flickerDuration;
            // flicker();
        }

        var animate:Bool = (flickerTmr > 0 || hovered);

        if (flickerTmr > 0) {
            flickerTmr -= elapsed;
            flickerDly += elapsed;
    
            if (flickerDly >= (flickerDuration / flickerCount)) {
                flickerDly = 0;
                flicker();
            }
    
            if (flickerTmr <= 0) {
                if (onClick != null)
                    onClick();

                animate = hovered;
                flickerTmr = 0;
            }
        }
        else
            animation.curAnim.curFrame = (hovered) ? 1 : 0;

        alpha = Tools.lerp(alpha, (animate) ? 1 : 0.6, 6);

        scale.x = scale.y = Tools.lerp(scale.x, (animate) ? 0.4 : 0.35, 3);
        updateHitbox();

        y = FlxG.height - height - 5;
    }

    inline function flicker():Void {
        animation.curAnim.curFrame = (animation.curAnim.curFrame + 1) % animation.curAnim.numFrames;
    }

    override function destroy():Void {
        onClick = null;
        super.destroy();
    }
}