package funkin.gameplay.components;

import flixel.tweens.FlxEase;
import flixel.group.FlxSpriteContainer;
import funkin.objects.OffsetSprite;

/**
 * Sprite container displaying a judgement sprite and combo numbers.
 */
class JudgementDisplay extends FlxSpriteContainer {
    /**
     * Judgement sprite.
     */
    public var judgement:JudgementSprite;

    /**
     * Combo numbers.
     */
    public var combos:FlxTypedSpriteContainer<ComboNumber>;

    /**
     * Vertical padding of the sprites.
     */
    static final PADDING:Float = 20;

    /**
     * Creates a new `JudgementDisplay` instance.
     * @param style Suffix for the sprite assets.
     */
    public function new(style:String = null):Void {
        super();

        judgement = new JudgementSprite(style);
        judgement.kill();
        add(judgement);

        combos = new FlxTypedSpriteContainer<ComboNumber>();
        add(combos);

        // if you need more than 5, you're probably a masochist
        for (i in 0...5) {
            combos.add(new ComboNumber(style)).kill();
        }
    }

    /**
     * Displays a judgement.
     * @param name Judgement to display.
     */
    public function displayJudgement(name:String):Void {
        judgement.revive();
        judgement.judgement = name;
        judgement.screenCenter();
        judgement.y -= PADDING;
        judgement.intendedY = judgement.y;
    }

    /**
     * Displays a combo.
     * @param combo Combo to display.
     */
    public function displayCombo(combo:Int):Void {
        combos.group.killMembers();

        var comboString:String = Std.string(combo);
        
        for (i in 0...comboString.length) {
            var sprite:ComboNumber = combos.recycle();
            sprite.x = FlxG.width * 0.5 + 40 * (i - (comboString.length / 2));
            sprite.intendedY = FlxG.height * 0.5 + PADDING;
            sprite.number = comboString.charAt(i);
        }
    }

    override function destroy():Void {
        judgement = null;
        combos = null;
        super.destroy();
    }
}

class JudgementSprite extends BasicSprite {
    /**
     * Judgement this sprite displays.
     */
    public var judgement(get, set):String;

    /**
     * Creates a new `JudgementSprite` instance.
     * @param style Style for this sprite.
     */
    public function new(style:String = null):Void {
        super();
        loadAnimations(style ?? "");
    }

    function loadAnimations(style:String):Void {
        var graphic = Paths.image("game/judgements" + style);
        loadGraphic(graphic, true, graphic.width, Math.floor(graphic.height / 5));

        animation.add("mad", [0], 0);
        animation.add("sick", [1], 0);
        animation.add("good", [2], 0);
        animation.add("bad", [3], 0);
        animation.add("awful", [4], 0);

        animation.play("mad");
        scale.set(0.55, 0.55);
        updateHitbox();
    }

    function get_judgement():String {
        return animation.name;
    }

    function set_judgement(v:String):String {
        if (judgement != v) {
            animation.name = v;
            updateHitbox();
        }

        return v;
    }
}

class ComboNumber extends BasicSprite {
    /**
     * Number this sprite dislays.
     */
    public var number(get, set):String;

    /**
     * Creates a new `ComboNumber` instance.
     * @param style Style for this sprite.
     */
    public function new(style:String = null):Void {
        super();
        loadAnimations(style ?? "");
    }

    function loadAnimations(style:String):Void {
        var graphic = Paths.image("game/combo-numbers" + style);
        loadGraphic(graphic, true, Math.floor(graphic.width / 5), Math.floor(graphic.height / 2));

        for (i in 0...10)
            animation.add(Std.string(i), [i], 0);

        animation.play("0");
        scale.set(0.4, 0.4);
        updateHitbox();
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

private class BasicSprite extends OffsetSprite {
    /**
     * The initial Y position of this sprite.
     */
    public var intendedY:Float = 0;

    /**
     * How long sprites are going to be displayed, in milliseconds.
     */
    static final DISPLAY_TIME:Float = 150;

    var elapsedTime:Float = 0;

    override function update(elapsed:Float):Void {
        #if FLX_DEBUG
        FlxBasic.activeCount++;
        #end

        elapsedTime += elapsed * 1000;

        if (elapsedTime <= DISPLAY_TIME) {
            y = intendedY + 10 * FlxEase.smootherStepInOut(elapsedTime / DISPLAY_TIME);
        } else {
            alpha = 1 - (elapsedTime - DISPLAY_TIME) / DISPLAY_TIME;
            if (alpha <= 0) return kill();
        }

        if (animation.curAnim.frameRate > 0 && animation.curAnim.frames.length > 1)
            animation.update(elapsed);
    }

    override function revive():Void {
        super.revive();
        elapsedTime = 0;
        alpha = 1;
    }
}
