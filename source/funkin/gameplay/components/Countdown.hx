package funkin.gameplay.components;

import flixel.FlxState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxBasic;

/**
 * Countdown object which executes the countdown in gameplay.
 */
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
     * Callback fired on countdown tick.
     */
    public var onTick:Int->Void = null;

    /**
     * Callback fired when the countdown finishes.
     */
    public var onFinish:Void->Void = null;

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

        while (Conductor.self.time - startTime >= Conductor.self.crochet * (currentTick + 1))
            tick(++currentTick);

        super.update(elapsed);
    }

    /**
     * Starts the countdown.
     */
    public function start():Void {
        // avoids division by 0 and invalid frames
        var frames:Int = (totalTicks > 1 ? totalTicks - 1 : totalTicks);
        var graphic = Assets.image(asset);

        sprite = new FlxSprite();
        sprite.loadGraphic(graphic, true, graphic.width, Math.floor(graphic.height / frames));
        sprite.animation.add("countdown", [for (i in 0...frames) i], 0);
        sprite.animation.play("countdown");
        sprite.cameras = cameras;
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

        var event:CountdownEvent = null;
        var force:Bool = true;

        var suffix:String = (tick == totalTicks ? "Go" : Std.string(totalTicks - tick));
        var sound:String = 'gameplay/intro${suffix}';
        var spriteFrame:Int = tick - 2;

        if (PlayState.self != null) {
            sound += PlayState.self.stage?.uiStyle ?? "";
            force = false;

            event = PlayState.self.scripts.dispatchEvent("onCountdownTick", Events.get(CountdownEvent).setup(TICK, tick, null, sound, spriteFrame));
            if (event.cancelled) return;

            spriteFrame = event.spriteFrame;
            sound = event.soundAsset;
        }

        if (onTick != null)
            onTick(tick);

        #if DISCORD_RPC
        if (force || event.changePresence)
            DiscordPresence.presence.state = suffix + (tick == totalTicks ? '!' : '...');
        #end

        if (PlayState.self != null && event.allowBeatEvents)
            PlayState.self.gameDance(tick - 1 + (totalTicks % 2));

        if (spriteFrame != -1)
            sprite.animation.frameIndex = spriteFrame;

        if (sound != null)
            FlxG.sound.play(Assets.sound(sound));

        sprite.alpha = (spriteFrame == -1 ? 0 : 1);
        sprite.screenCenter();

        if ((force || event.allowTween) && spriteFrame != -1)
            FlxTween.tween(sprite, {y: (sprite.y -= 50) + 100, alpha: 0}, Conductor.self.crochet * 0.95 / 1000, {ease: FlxEase.smootherStepInOut});
    }

    /**
     * Countdown end behaviour.
     */
    function finish():Void {
        if (onFinish != null)
            onFinish();

        parent.remove(this, true);
        parent.remove(sprite, true);

        sprite.destroy();
        destroy();
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        onFinish = null;
        onTick = null;

        sprite = null;
        parent = null;
        asset = null;

        super.destroy();
    }
}
