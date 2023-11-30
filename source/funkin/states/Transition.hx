package funkin.states;

import flixel.FlxState;
import flixel.FlxSubState;

import flixel.FlxCamera;
import flixel.tweens.FlxTween;

import flixel.util.FlxSignal;
import flixel.util.FlxGradient;

class TransitionState extends FlxState {
    override function create():Void {
        super.create();
        openSubState(new TransitionSubState(OUT));
    }

    override function startOutro(onOutroComplete:() -> Void):Void {
        openSubState(new TransitionSubState(IN));
        TransitionSubState.onComplete.add(onOutroComplete);
    }
}

class TransitionSubState extends FlxSubState {
    public static final onComplete:FlxSignal = new FlxSignal();
    public static var skipNextTransOut:Bool = false;
    public static var skipNextTransIn:Bool = false;

    public var duration:Float = 0.35;

    var transitionCamera:FlxCamera;
    var type:TransitionType;

    var gradient:FlxSprite;
    var rect:FlxSprite;

    public function new(type:TransitionType = IN):Void {
        super();
        this.type = type;
    }

    override function create():Void {
        super.create();

        if (skipNextTransIn && type == IN) {
            skipNextTransIn = false;
            finish();
            return;
        }

        if (skipNextTransOut && type == OUT) {
            skipNextTransOut = false;
            finish();
            return;
        }

        transitionCamera = new FlxCamera();
        transitionCamera.bgColor.alpha = 0;
        cameras = [transitionCamera];
        FlxG.cameras.add(transitionCamera, false);

        rect = new FlxSprite();
        rect.makeRect(FlxG.width, FlxG.height * 1.2, FlxColor.BLACK);

        gradient = FlxGradient.createGradientFlxSprite(FlxG.width, 90, [FlxColor.BLACK, FlxColor.TRANSPARENT]);

        var top:Float = -(rect.height + gradient.height);
        var bottom:Float = FlxG.height - rect.height;
        
        rect.y = (type == IN) ? top : bottom;
        gradient.y = -gradient.height;

        add(rect);
        add(gradient);

        FlxTween.tween(rect, {y: (type == IN) ? bottom : top}, duration, {onComplete: (_) -> finish()});
    }

    override function update(elapsed:Float):Void {
        // the FlxTween update callback simply won't do the trick
        if (gradient != null)
            gradient.y = rect.y + rect.height - 5;
        super.update(elapsed);
    }

    inline function finish():Void {
        onComplete.dispatch();
        onComplete.removeAll();

        if (type == OUT) {
            if (transitionCamera != null)
                FlxG.cameras.remove(transitionCamera);

            FlxG.state.persistentUpdate = true;
            close();
        }
    }
}

enum abstract TransitionType(String) from String to String {
    var IN = "in";
    var OUT = "out";
}