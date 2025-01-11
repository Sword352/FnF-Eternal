package funkin.ui;

import flixel.FlxState;
import flixel.tweens.FlxEase;
import flixel.group.FlxContainer;
import flixel.group.FlxSpriteContainer;
import flixel.util.FlxSignal;
import flixel.util.FlxGradient;

/**
 * Object which performs transition animations in the game.
 * By default, an instance of this class is added into the flixel plugin manager 
 * to display transitions when switching states.
 */
class Transition extends FlxContainer {
    /**
     * Signal dispatched when a transition ends.
     * Note that every listener added to this signal are only fired once.
     */
    public static final onComplete:FlxSignal = new FlxSignal();

    /**
     * Whether to skip the next transition animation of mode `OUT`.
     */
    public static var skipNextTransOut:Bool = false;

    /**
     * Whether to skip the next transition animation of mode `IN`.
     */
    public static var skipNextTransIn:Bool = false;

    /**
     * Skips the next `IN` and `OUT` transition animations.
     */
    public static inline function skip():Void {
        skipNextTransOut = skipNextTransIn = true;
    }

    /**
     * Visuals displayed during the transition.
     */
    var display:TransitionDisplay;

    /**
     * Progress of the transition, ranging from 0 to 1.
     */
    var progress:Float = 0;

    /**
     * Creates a new `Transition` instance.
     */
    public function new():Void {
        super();

        // containers doesn't seems to be sharing cameras with their childs, yet
        cameras = [];

        display = new TransitionDisplay();
        display.cameras = cameras;
        add(display);

        visible = false;
        active = false;

        FlxG.signals.postStateSwitch.add(onPostStateSwitch);
    }

    override function update(elapsed:Float):Void {
        var smoothedProgress:Float = FlxEase.smoothStepInOut(progress += elapsed / 0.4);

        display.y = camera.viewMarginTop + switch (display.displayMode) {
            case IN:
                FlxMath.lerp(0, display.height, smoothedProgress);
            case OUT:
                FlxMath.lerp(-display.height, 0, smoothedProgress);
        }

        if (progress >= 1)
            onFinish();

        #if FLX_DEBUG
        FlxBasic.activeCount++;
        #end
    }

    /**
     * Starts a transition animation.
     * @param mode Transition mode for the animation. Can either be `IN` or `OUT`.
     */
    public function start(mode:TransitionMode):Void {
        // draw on top of everything
        camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];

        display.adjustToCamera();
        display.displayMode = mode;

        // make sure it's offscreen
        display.y = camera.viewMarginBottom;

        // start the transition
        progress = 0;
        visible = true;
        active = true;
    }

    function onFinish():Void {
        // leave a chance for the transition to be rendered before hiding
        FlxG.signals.postDraw.addOnce(onPostDraw);

        onComplete.dispatch();
        onComplete.removeAll();

        active = false;
        progress = 0;
    }

    function onPostDraw():Void {
        visible = false;
    }

    function onPostStateSwitch():Void {
        if (!skipNextTransIn)
            start(IN);

        skipNextTransIn = false;
    }

    override function destroy():Void {
        FlxG.signals.postStateSwitch.remove(onPostStateSwitch);
        display = null;
        super.destroy();
    }
}

/**
 * Visuals displayed during a transition animation.
 */
class TransitionDisplay extends FlxSpriteContainer {
    /**
     * Determines the position of the visuals.
     * In `IN` mode, the gradient is placed above the fill.
     * In `OUT` mode, the gradient is placed next to the fill.
     */
    public var displayMode(default, set):TransitionMode = IN;

    var gradient:FlxSprite;
    var fill:FlxSprite;

    /**
     * Creates a new `TransitionDisplay` instance.
     */
    public function new():Void {
        super();

        fill = new FlxSprite();
        fill.makeRect(FlxG.width, FlxG.height, FlxColor.BLACK);
        fill.graphic.persist = true;
        add(fill);

        gradient = FlxGradient.createGradientFlxSprite(1, 250, [FlxColor.BLACK, FlxColor.TRANSPARENT]);
        gradient.graphic.persist = true;
        gradient.scale.x = FlxG.width;
        gradient.updateHitbox();
        add(gradient);

        scrollFactor.set();
    }

    /**
     * Updates the visuals to be consistent with the current camera zoom.
     */
    public function adjustToCamera():Void {
        fill.scale.set(FlxG.width / camera.zoom, FlxG.height / camera.zoom);
        fill.updateHitbox();

        gradient.scale.set(fill.scale.x, 1 / camera.zoom);
        gradient.updateHitbox();

        x = camera.viewMarginX;
    }

    override function destroy():Void {
        gradient.graphic.persist = false;
        gradient = null;

        fill.graphic.persist = false;
        fill = null;

        super.destroy();
    }

    function set_displayMode(v:TransitionMode):TransitionMode {
        gradient.y = y + FlxMath.lerp(-gradient.height, fill.height, v);
        gradient.flipY = (v == IN);
        return displayMode = v;
    }
}

/**
 * A state able to perform a transition animation before switching states.
 */
class TransitionableState extends FlxState {
    /**
     * Transition object associated with this state.
     */
    public var transition:Transition = FlxG.plugins.get(Transition);

    /**
     * Method called by flixel to switch states.
     * @param onOutroComplete Function responsible of switching states.
     */
    override function startOutro(onOutroComplete:Void->Void):Void {
        if (transition == null) {
            onOutroComplete();
            return;
        }

        if (Transition.skipNextTransOut) {
            Transition.skipNextTransOut = false;
            onOutroComplete();
            return;
        }

        Transition.onComplete.add(onOutroComplete);
        transition.start(OUT);
    }

    override function destroy():Void {
        transition = null;
        super.destroy();
    }
}

/**
 * Mode for a transition animation.
 */
enum abstract TransitionMode(Int) from Int to Int {
    /**
     * The transition is moving out of the screen.
     */
    var IN;

    /**
     * The transition is moving into the screen.
     */
    var OUT;
}
