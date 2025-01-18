package funkin.utils;

import flixel.FlxObject;

/**
 * Utility class for working with `FlxObject`s.
 */
class FlxObjectTools {
    /**
     * Centers an `FlxObject` to another.
     * @param object Object to center.
     * @param target Object in which the other object will be centered to.
     * @return The centered object.
     */
    public static function centerTo(object:FlxObject, target:FlxObject):FlxObject {
        return centerVerticallyTo(centerHorizontallyTo(object, target), target);
    }

    /**
     * Vertically centers an `FlxObject` to another.
     * @param object Object to center.
     * @param target Object in which the other object will be centered to, vertically.
     * @return The centered object.
     */
    public static function centerVerticallyTo(object:FlxObject, target:FlxObject):FlxObject {
        object.y = target.y + (target.height - object.height) * 0.5;
        return object;
    }

    /**
     * Horizontally centers an `FlxObject` to another.
     * @param object Object to center.
     * @param target Object in which the other object will be centered to, horizontally.
     * @return FlxObject
     */
    public static function centerHorizontallyTo(object:FlxObject, target:FlxObject):FlxObject {
        object.x = target.x + (target.width - object.width) * 0.5;
        return object;
    }
}
