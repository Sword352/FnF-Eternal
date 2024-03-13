package funkin.states;

import flixel.FlxState;
import flixel.FlxSubState;

import flixel.FlxCamera;
import flixel.tweens.FlxEase;

import flixel.util.FlxSignal;
import flixel.util.FlxGradient;

class Transition {
    public static final onComplete:FlxSignal = new FlxSignal();
    public static var noPersistentUpdate:Bool = false;
    public static var skipNextTransOut:Bool = false;
    public static var skipNextTransIn:Bool = false;
    public static var openOnSubState:Bool = false;
}

class TransitionState extends FlxState {
    override function create():Void {
        super.create();

        if (!Transition.skipNextTransIn)
            openTransition(new TransitionSubState(IN));
        Transition.skipNextTransIn = false;
    }

    override function startOutro(onOutroComplete:() -> Void):Void {
        if (Transition.skipNextTransOut) {
            Transition.skipNextTransOut = false;
            onOutroComplete();
            return;
        }

        if (subState != null && subState is TransitionSubState)
            cast(subState, TransitionSubState).reset(OUT);
        else
            openTransition(new TransitionSubState(OUT));

        Transition.onComplete.add(onOutroComplete);
    }

    inline function openTransition(transition:TransitionSubState):Void {
        var parent:FlxState = this;

        if (Transition.openOnSubState)
            while (parent.subState != null)
                parent = parent.subState;

        Transition.openOnSubState = false;
        parent.openSubState(transition);
    }
}

class TransitionSubState extends FlxSubState {
    public var type:TransitionType;

    var cam:FlxCamera;

    var gradient:FlxSprite;
    var rect:FlxSprite;

    var scale:Float = 0;
    var _wasUpdating:Bool;

    public function new(type:TransitionType = IN):Void {
        this.type = type;
        super();
    }

    override function create():Void {
        super.create();

        _wasUpdating = _parentState.persistentUpdate;
        _parentState.persistentUpdate = !Transition.noPersistentUpdate;
        Transition.noPersistentUpdate = false;

        cam = new FlxCamera();
        cam.bgColor.alpha = 0;
        cameras = [cam];
        FlxG.cameras.add(cam, false);

        rect = new FlxSprite();
        rect.makeRect(FlxG.width, FlxG.height + 100, FlxColor.BLACK);
        rect.y = -rect.height;
        add(rect);

        gradient = FlxGradient.createGradientFlxSprite(1, 200, [FlxColor.BLACK, FlxColor.BLACK, FlxColor.TRANSPARENT]);
        gradient.flipY = (type == IN);
        gradient.y = -gradient.height;
        gradient.scale.x = FlxG.width;
        gradient.updateHitbox();
        gradient.screenCenter(X);
        add(gradient);
    }

    override function update(elapsed:Float):Void {
        var animScale:Float = FlxEase.smoothStepInOut(scale += elapsed * 2);

        switch (type) {
            case IN:
                rect.y = (FlxG.height + gradient.height) * animScale;
                gradient.y = rect.y - gradient.height * 0.5;
            case OUT:
                gradient.y = FlxMath.lerp(-gradient.height, FlxG.height, animScale);
                rect.y = gradient.y - rect.height + gradient.height * 0.5;
        }

        if (scale >= 1)
            finish();
    }

    // reset and re-use the transition
    public function reset(type:TransitionType):Void {
        this.type = type;
        gradient.flipY = (type == IN);
        scale = 0;
    }

    inline function finish():Void {
        Transition.onComplete.dispatch();
        Transition.onComplete.removeAll();

        if (type == IN) {
            if (cam != null)
                FlxG.cameras.remove(cam);
            FlxG.state.persistentUpdate = _wasUpdating;
            close();
        }
    }
}

enum abstract TransitionType(String) from String to String {
    var IN = "in";
    var OUT = "out";
}
