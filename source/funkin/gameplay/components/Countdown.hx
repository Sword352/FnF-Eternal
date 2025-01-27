package funkin.gameplay.components;

import flixel.FlxState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSignal;

/**
 * Countdown object which executes the countdown in gameplay.
 * This object dispatches the following event(s):
 * - `GameEvents.COUNTDOWN_TICK`
 */
@:build(funkin.core.macros.ScriptMacros.buildEventDispatcher())
class Countdown extends FlxBasic {
    /**
     * Displayed countdown sprite.
     */
    public var sprite:FlxSprite;

    /**
     * Current countdown tick.
     */
    public var currentTick:Int = 0;

    /**
     * Total amount of ticks.
     */
    public var totalTicks:Int = 0;

    /**
     * Image asset for the countdown sprite.
     */
    public var asset:String = null;

    /**
     * Suffix for sound assets.
     */
    public var soundSuffix:String = null;

    /**
     * Conductor this countdown will listen to.
     */
    public var conductor:Conductor = Conductor.self;

    /**
     * Signal dispatched when a countdown tick starts.
     */
    public var onTick:FlxTypedSignal<Int->Void> = new FlxTypedSignal();

    /**
     * Signal dispatched when the countdown finishes.
     */
    public var onFinish:FlxSignal = new FlxSignal();

    /**
     * Holds the position of the conductor at the time the `start` method is called.
     */
    var startTime:Float = -1;

    /**
     * Parent state.
     */
    var parent:FlxState;

    /**
     * Creates a new `Countdown`.
     * @param parent Parent state.
     */
    public function new(?parent:FlxState):Void {
        super();
        this.parent = parent ?? FlxG.state;
        visible = false;
    }

    override function update(elapsed:Float):Void {
        if (startTime == -1) return;

        while (conductor.audioTime - startTime >= conductor.beatLength * (currentTick + 1))
            tick(++currentTick);

        #if FLX_DEBUG
        FlxBasic.activeCount++;
        #end
    }

    /**
     * Starts the countdown.
     */
    public function start():Void {
        // avoids division by 0 and invalid frames
        var frames:Int = (totalTicks > 1 ? totalTicks - 1 : totalTicks);
        var graphic = Paths.image(asset);

        sprite = new FlxSprite();
        sprite.loadGraphic(graphic, true, graphic.width, Math.floor(graphic.height / frames));
        sprite.animation.add("countdown", [for (i in 0...frames) i], 0);
        sprite.animation.play("countdown");
        sprite.cameras = cameras;
        sprite.active = false;
        parent.add(sprite);

        startTime = conductor.audioTime;
        sprite.alpha = 0;
    }
  
    function tick(tick:Int):Void {
        if (tick > totalTicks) {
            finish();
            return;
        }

        var suffix:String = (tick == totalTicks ? "Go" : Std.string(totalTicks - tick));
        var sound:String = 'gameplay/intro${suffix}';
        var spriteFrame:Int = tick - 2;

        if (soundSuffix != null)
            sound += soundSuffix;

        var event:CountdownTickEvent = dispatchEvent(GameEvents.COUNTDOWN_TICK, new CountdownTickEvent(tick, sound, spriteFrame));
        if (event.cancelled) return;

        spriteFrame = event.spriteFrame;
        sound = event.soundAsset;

        onTick.dispatch(tick);

        if (sound != null)
            FlxG.sound.play(Paths.sound(sound));

        if (spriteFrame != -1)
            AudioSynchronizer.schedule(displaySprite.bind(spriteFrame));
    }

    function displaySprite(frame:Int):Void {
        sprite.animation.frameIndex = frame;
        sprite.alpha = 1;
        
        sprite.screenCenter();
        sprite.y -= 50;

        FlxTween.tween(sprite, {y: sprite.y + 100, alpha: 0}, conductor.beatLength / conductor.rate * 0.95 / 1000, {ease: FlxEase.smootherStepInOut});
    }

    function finish():Void {
        onFinish.dispatch();
        AudioSynchronizer.schedule(removeSelf);

        // prevents countdown from dispatching more ticks if the audio offset is high
        active = false;
    }

    function removeSelf():Void {
        parent.remove(this, true);
        parent.remove(sprite, true);

        sprite.destroy();
        destroy();
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        onFinish = cast FlxDestroyUtil.destroy(onFinish);
        onTick = cast FlxDestroyUtil.destroy(onTick);

        soundSuffix = null;
        conductor = null;
        sprite = null;
        parent = null;
        asset = null;

        super.destroy();
    }
}
