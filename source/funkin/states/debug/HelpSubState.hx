package funkin.states.debug;

import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class HelpSubState extends FlxSubState {
    public var message:String = "Lorem ipsum dolor sit amet";
    public var bgAlpha:Float = 0.75;

    var background:FlxSprite;
    var text:FlxText;

    var allowInputs:Bool = true;

    public function new(?message:String):Void {
        super();

        if (message != null)
            this.message = message;
    }

    override function create():Void {
        super.create();

        background = new FlxSprite();
        background.makeRect(FlxG.width, FlxG.height, FlxColor.BLACK);
        background.alpha = 0;
        add(background);

        text = new FlxText(0, 0, 0, message);
        text.setFormat(Assets.font("vcr"), 32, FlxColor.WHITE, CENTER);
        text.resizeText(25);
        text.screenCenter(X);
        text.y = -text.height;
        text.alpha = 0;
        add(text);

        FlxTween.tween(background, {alpha: bgAlpha}, 0.25);
        FlxTween.tween(text, {alpha: 1, y: (FlxG.height - text.height) * 0.5}, 0.35, {startDelay: 0.25, ease: FlxEase.expoOut});
    }

    override function update(elapsed:Float):Void {
        if (FlxG.keys.justPressed.ESCAPE && allowInputs) {
            allowInputs = false;
            closeTweens();
        }

        super.update(elapsed);
    }

    inline function closeTweens():Void {
        FlxTween.completeTweensOf(background);
        FlxTween.completeTweensOf(text);

        FlxTween.tween(text, {y: text.y - 75, alpha: 0}, 0.25, {ease: FlxEase.expoOut});
        FlxTween.tween(background, {alpha: 0}, 0.35, {startDelay: 0.1, onComplete: (_) -> close()});
    }
}
