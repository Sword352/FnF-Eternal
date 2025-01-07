package funkin.ui;

/**
 * The spinning circle sprite displayed in loading screens.
 */
class SpinningCircle extends FlxSprite {
    /**
     * How fast this sprite should fade.
     */
    public var fadeSpeed:Float = 5;

    /**
     * Callback fired once the fade has been completed.
     */
    var _onComplete:Void->Void;

    /**
     * Internal flag which determines whether this sprite is fading in.
     */
    var _isFadingIn:Bool = false;

    /**
     * Creates a new `SpinningCircle`.
     */
    public function new():Void {
        super(0, 0, Paths.image("menus/loading_circle"));
        scale.set(0.5, 0.5);
        updateHitbox();

        setPosition(FlxG.width - width - 10, FlxG.height - height - 10);
        alpha = 0;
    }

    /**
     * Starts a fade animation with a complete callback.
     * @param speed How fast the fade animation will be.
     * @param fadeIn Whether to fade in or out.
     * @param onComplete Complete callback.
     */
    public function fade(speed:Float = 5, fadeIn:Bool, onComplete:Void->Void):Void {
        fadeSpeed = (fadeIn ? speed : -speed);
        _onComplete = onComplete;
        _isFadingIn = fadeIn;
    }

    override function update(elapsed:Float):Void {
        alpha += fadeSpeed * elapsed;
        angle += 45 * elapsed;

        if (_onComplete != null) {
            if ((_isFadingIn && alpha == 1) || (!_isFadingIn && alpha == 0)) {
                _onComplete();
                _onComplete = null;
            }
        }

        #if FLX_DEBUG
        FlxBasic.activeCount++;
        #end
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        _onComplete = null;
        super.destroy();
    }
}
