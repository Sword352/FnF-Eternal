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
     * Current position in the song when this countdown started.
     */
    public var startTime:Float = -1;

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
     * Signal dispatched when a countdown tick starts.
     */
    public var onTick:FlxTypedSignal<Int->Void> = new FlxTypedSignal();

    /**
     * Signal dispatched when the countdown finishes.
     */
    public var onFinish:FlxSignal = new FlxSignal();

    /**
     * Parent state.
     */
    var parent:FlxState;

    /**
     * Creates a new `Countdown`.
     * @param parent Parent state.
     */
    public function new(?parent:FlxState):Void {
        this.parent = parent ?? FlxG.state;
        super();
    }

    /**
     * Update behaviour.
     */
    override function update(elapsed:Float):Void {
        if (startTime == -1)
            return;

        while (Conductor.self.time - startTime >= Conductor.self.crotchet * (currentTick + 1))
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

        startTime = Conductor.self.time;
        sprite.alpha = 0;
    }

    /**
     * Countdown tick behaviour.
     * @param tick Current tick.
     * @param totalTicks Total ticks.
     */
    function tick(tick:Int):Void {
        if (tick > totalTicks) {
            finish();
            return;
        }

        var suffix:String = (tick == totalTicks ? "Go" : Std.string(totalTicks - tick));
        var sound:String = 'gameplay/intro${suffix}';
        var spriteFrame:Int = tick - 2;

        if (PlayState.self != null)
            sound += PlayState.self.stage?.uiStyle ?? "";

        var event:CountdownTickEvent = dispatchEvent(GameEvents.COUNTDOWN_TICK, new CountdownTickEvent(tick, sound, spriteFrame));
        if (event.cancelled) return;

        spriteFrame = event.spriteFrame;
        sound = event.soundAsset;

        onTick.dispatch(tick);

        if (PlayState.self != null)
            PlayState.self.gameDance(tick - 1 + (totalTicks % 2));

        if (spriteFrame != -1)
            sprite.animation.frameIndex = spriteFrame;

        if (sound != null)
            FlxG.sound.play(Paths.sound(sound));

        sprite.alpha = (spriteFrame == -1 ? 0 : 1);
        sprite.screenCenter();

        if (spriteFrame != -1)
            FlxTween.tween(sprite, {y: (sprite.y -= 50) + 100, alpha: 0}, Conductor.self.crotchet * 0.95 / 1000, {ease: FlxEase.smootherStepInOut});
    }

    /**
     * Countdown end behaviour.
     */
    function finish():Void {
        onFinish.dispatch();

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

        sprite = null;
        parent = null;
        asset = null;

        super.destroy();
    }
}
