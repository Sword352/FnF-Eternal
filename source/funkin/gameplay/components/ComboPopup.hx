package funkin.gameplay.components;

import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.group.FlxSpriteGroup;
import funkin.objects.OffsetSprite;

/**
 * Sprite group which displays ratings and combo numbers.
 */
class ComboPopup extends FlxSpriteGroup {
    /**
     * How many rating frames are available.
     */
    public var ratingCount:Int = 4;

    /**
     * Whether to simplify combo numbers and display the actual value rather than adding extra zeros.
     */
    public var simplifyNumbers:Bool = Options.simplifyComboNum;

    /**
     * Whether to allow sprites to stack.
     */
    public var spriteStack:Bool = !Options.noComboStack;

    /**
     * Suffix for the sprite assets.
     */
    public var style:String = null;

    /**
     * Rating sprites group.
     */
    public var ratings:FlxTypedSpriteGroup<RatingSprite>;

    /**
     * Combo numbers group.
     */
    public var combos:FlxTypedSpriteGroup<ComboNumber>;

    /**
     * Creates a new `ComboPopup` group.
     * @param ratingCount How many rating frames are available.
     * @param style Suffix for the sprite assets.
     */
    public function new(ratingCount:Int = 4, style:String = null):Void {
        super();

        this.ratingCount = ratingCount;
        this.style = style;

        ratings = new FlxTypedSpriteGroup<RatingSprite>();
        add(ratings);

        combos = new FlxTypedSpriteGroup<ComboNumber>();
        add(combos);
    }

    /**
     * Displays a rating sprite.
     * @param rating Rating to display.
     */
    public function displayRating(rating:Rating):Void {
        if (!spriteStack)
            ratings.forEachAlive(killStack);

        var sprite:RatingSprite = ratings.recycle(RatingSprite, ratingConstructor);
        sprite.rating = rating.name;
        sprite.screenCenter();

        // temporary workaround
        // TODO: remove this when sprite group cameras are fixed
        sprite.cameras = cameras;

        ratings.sort(sortSprites, 1);
    }

    /**
     * Displays combo numbers based on the provided combo amount.
     * @param combo Combo amount.
     */
    public function displayCombo(combo:Int):Void {
        var comboString:String = Std.string(combo);

        if (!simplifyNumbers)
            comboString = comboString.lpad("0", 3);

        if (!spriteStack)
            combos.forEachAlive(killStack);

        for (i in 0...comboString.length) {
            var sprite:ComboNumber = combos.recycle(ComboNumber, comboConstructor);
            sprite.number = comboString.charAt(i);
            sprite.screenCenter();

            sprite.x += 50 * (i + 1);
            sprite.y += 120;

            // temporary workaround
            // TODO: remove this when sprite group cameras are fixed
            sprite.cameras = cameras;
        }

        combos.sort(sortSprites, 1);
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        style = null;
        super.destroy();
    }

    inline function ratingConstructor():RatingSprite {
        return new RatingSprite(ratingCount, style);
    }

    inline function comboConstructor():ComboNumber {
        return new ComboNumber(style);
    }

    inline function killStack(sprite:BasicSprite):Void {
        sprite.kill();
    }

    inline function sortSprites(_:Int, a:BasicSprite, b:BasicSprite):Int {
        return Std.int(a.startTime - b.startTime);
    }
}

/**
 * Rating sprite object.
 */
class RatingSprite extends BasicSprite {
    /**
     * Rating this sprite represents.
     */
    public var rating(get, set):String;

    /**
     * Creates a new `RatingSprite`.
     * @param division How much should the spritesheet be split into.
     * @param style Style for this sprite.
     */
    public function new(division:Int = 5, style:String = null):Void {
        super();
        acceleration.y = 750;
        loadAnimations(division, style ?? "");
        setProps();
    }

    /**
     * Internal method which loads animations for this sprite.
     */
    function loadAnimations(division:Int, style:String):Void {
        var graphic = Assets.image("game/ratings" + style);
        loadGraphic(graphic, true, graphic.width, Math.floor(graphic.height / division));

        animation.add("mad", [0], 0);
        animation.add("sick", [1], 0);
        animation.add("good", [2], 0);
        animation.add("bad", [3], 0);
        animation.add("awful", [4], 0);

        animation.play("sick");
        scale.set(0.65, 0.65);
        updateHitbox();
    }

    /**
     * Method which resets bunch of properties for recycling.
     */
    override function setProps():Void {
        super.setProps();

        // velocity changes over time, so we have to reset it back to it's original value
        velocity.y = -250;
    }

    function get_rating():String {
        return animation.name;
    }

    function set_rating(v:String):String {
        if (rating != v) {
            animation.name = v;
            updateHitbox();
        }

        return v;
    }
}

/**
 * Combo number sprite object.
 */
class ComboNumber extends BasicSprite {
    /**
     * Number this combo sprite represents, as a string.
     */
    public var number(get, set):String;

    /**
     * Creates a new `ComboNumber`.
     * @param style Style for this sprite.
     */
    public function new(style:String = null):Void {
        super();
        originalScale.set(0.45, 0.45);
        loadAnimations(style ?? "");
        setProps();
    }

    /**
     * Internal method which loads animations for this sprite.
     */
    function loadAnimations(style:String):Void {
        var graphic = Assets.image("game/combo-numbers" + style);
        loadGraphic(graphic, true, Math.floor(graphic.width / 5), Math.floor(graphic.height / 2));

        for (i in 0...10)
            animation.add(Std.string(i), [i], 0);

        animation.play("0");
        scale.set(0.45, 0.45);
        updateHitbox();
    }

    /**
     * Method which resets bunch of properties for recycling.
     */
    override function setProps():Void {
        super.setProps();
        velocity.set(FlxG.random.float(-5, 5), FlxG.random.float(-180, -220));
        acceleration.y = FlxG.random.float(500, 525);
        delay *= 1.5;
    }

    function get_number():String {
        return animation.name;
    }

    function set_number(v:String):String {
        if (number != v) {
            animation.name = v;
            updateHitbox();
        }

        return v;
    }
}

/**
 * Basic sprite class for both ratings and combos.
 */
private class BasicSprite extends OffsetSprite {
    /**
     * Original sprite scale.
     */
    public var originalScale:FlxPoint = FlxPoint.get(0.65, 0.65);

    /**
     * Scale tweening intensity.
     */
    public var scaleDiff:Float = 0.2;

    /**
     * Current position in the song when this sprite spawned.
     */
    public var startTime:Float = -1;

    /**
     * Duration in milliseconds to fade out.
     */
    public var duration:Float = 200;

    /**
     * Delay to wait in milliseconds before fading out.
     */
    public var delay:Float = -1;

    /**
     * Update behaviour.
     */
    override function update(elapsed:Float):Void {
        var progress:Float = Conductor.self.time - startTime - delay;
        alpha = 1 - Math.max(progress, 0) / duration;

        var scaleSubtract:Float = 0;
        scale.copyFrom(originalScale);

        if (progress >= 0)
            scaleSubtract = scaleDiff * FlxEase.smootherStepInOut(progress / duration);
        else
            scaleSubtract = (scaleDiff / 2) * (Math.min(0, progress + delay * 0.75) / -delay);

        scale.subtract(scaleSubtract, scaleSubtract);

        if (progress >= duration)
            return kill();

        elapsed *= Conductor.self.rate;
        updateMotion(elapsed);

        if (animation.curAnim.frameRate > 0 && animation.curAnim.frames.length > 1)
            animation.update(elapsed);

        #if FLX_DEBUG
        FlxBasic.activeCount++;
        #end
    }

    /**
     * Revives this sprite.
     */
    override function revive():Void {
        super.revive();
        setProps();
    }

    /**
     * Method which resets bunch of properties for recycling.
     */
    function setProps():Void {
        scale.copyFrom(originalScale);
        startTime = Conductor.self.time;
        delay = Conductor.self.crotchet;
        alpha = 1;
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        originalScale = FlxDestroyUtil.put(originalScale);
        super.destroy();
    }
}
