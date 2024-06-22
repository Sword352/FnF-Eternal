package funkin.objects;

import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.animation.FlxAnimationController;

/**
 * Sprite with the ability to have animation offsets.
 * They are used to compensate for the sprite's position, since it can be inconsistent when the animation changes.
 * 
 * Example usage:
 * ```
 * var sprite:OffsetSprite = new OffsetSprite();
 * sprite.offsets.add("myAnim", 10, 10);
 * sprite.animation.play("myAnim");
 * ```
 */
class OffsetSprite extends FlxSprite {
    /**
     * Animation offsets.
     */
    public var offsets(default, null):OffsetMapper;

    /**
     * Internal reference to the current animation offset.
     */
    @:allow(funkin.objects.OffsetSprite)
    var _offsetPoint:FlxPoint;

    override function initVars():Void {
        // create the offset mapper before anything else.
        offsets = new OffsetMapper();

        super.initVars();

        // destroy the old animation controller as it contains few references, and create the custom one.
        animation.destroy();
        animation = new AnimationController(this);
    }

    // this method is used by FlxSprite's draw method to get the sprite's position on screen. we're overriding it so it accounts for animation offsets.
    override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint {
        var output:FlxPoint = super.getScreenPosition(result, camera);

        if (_offsetPoint != null) {
            // also accounts for the angle property.
            output.subtract(
                (_offsetPoint.x * _cosAngle) - (_offsetPoint.y * _sinAngle),
                (_offsetPoint.y * _cosAngle) + (_offsetPoint.x * _sinAngle)
            );
        }

        return output;
    }

    /**
	 * Returns the screen position of this object without accounting for animation offsets.
	 * @param  result  Optional arg for the returning point
	 * @param  camera  The desired "screen" coordinate space. If `null`, `FlxG.camera` is used.
	 * @return The screen position of this object.
	 */
    public function getScreenCoords(?result:FlxPoint, ?camera:FlxCamera):FlxPoint {
        return super.getScreenPosition(result, camera);
    }

    /**
     * Plays an existing animation. If you call an animation that is already playing, it will be ignored.
     * @param name The string name of the animation you want to play.
     * @param force Whether to force the animation to restart.
     * @param reversed Whether to play animation backwards or not.
     * @param frame The frame number in the animation you want to start from. If a negative value is passed, a random frame is used
     */
    public function playAnimation(name:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void {
        animation.play(name, force, reversed, frame);
    }

    /**
     * Clean up memory.
     */
    override public function destroy():Void {
        if (offsets != null) {
            offsets.clear();
            offsets = null;
        }

        _offsetPoint = null;
        super.destroy();
    }
}

/**
 * Custom animation controller, made to apply animation offsets when calling `play`.
 */
private class AnimationController extends FlxAnimationController {
    var _parent:OffsetSprite;

    public function new(parent:OffsetSprite):Void {
        super(parent);
        _parent = parent;
    }

    override function play(animation:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void {
        super.play(animation, force, reversed, frame);
        _parent._offsetPoint = _parent.offsets.get(animation);
    }

    override function destroy():Void {
        _parent = null;
        super.destroy();
    }
}

/**
 * Simple interface to manipulate offsets.
 */
private abstract OffsetMapper(Map<String, FlxPoint>) {
    public function new():Void {
        this = [];
    }

    /**
     * Adds an animation offset.
     * @param animation The animation in which the offset will be applied to.
     * @param x Horizontal offset value.
     * @param y Vertical offset value.
     */
    public function add(animation:String, x:Float = 0, y:Float = 0):Void {
        addPoint(animation, FlxPoint.get(x, y));
    }

    /**
     * Adds an `FlxPoint` as animation offset.
     * @param animation The animation in which the offset will be applied to.
     * @param point The offset point.
     */
    public function addPoint(animation:String, point:FlxPoint):Void {
        this.set(animation, point);
    }

    /**
     * Returns the corresponding offset point for the passed animation if it exists, `null` otherwise.
     * @param animation The animation to find the offsets for.
     */
    public function get(animation:String):FlxPoint {
        return this.get(animation);
    }

    /**
     * Returns `true` if an offset point exists for the passed animation, `false` otherwise.
     * @param animation The animation to check
     */
    public function exists(animation:String):Bool {
        return this.exists(animation);
    }

    /**
     * Removes the animation offsets for the passed animation if it exists.
     * @param animation The animation to remove it's offsets for.
     * @return `true` if the offset point has been found and removed, `false` otherwise.
     */
    public function remove(animation:String):Bool {
        this.get(animation)?.put();
        return this.remove(animation);
    }

    /**
     * Removes all of the stored animation offsets.
     */
    public function clear():Void {
        for (key in this.keys())
            remove(key);
    }

    /**
     * Returns a list of animations which got offsets.
     */
    public function list():Array<String> {
        return [for (key in this.keys()) key];
    }
}
