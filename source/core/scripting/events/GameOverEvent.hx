package core.scripting.events;

import flixel.math.FlxPoint;

/**
 * Event dispatched whenever a game over happens in gameplay.
 */
class GameOverEvent extends ScriptEvent {
    /**
     * Game over character.
     */
    @:eventConstructor public var character:String;

    /**
     * Camera position.
     */
    @:eventConstructor public var position:FlxPoint;

    /**
     * Camera zoom.
     */
    @:eventConstructor public var zoom:Float;

    /**
     * Whether the gameplay state should still draw during the game over.
     */
    @:eventValue public var persistentDraw:Bool = false;

    /**
     * Whether to change the Discord rich presence on available platforms.
     */
    @:eventValue public var changePresence:Bool = true;

    /**
     * Whether the music should stop.
     */
    @:eventValue public var stopMusic:Bool = true;

    override function destroy():Void {
        character = null;
        position = null;
    }
}
