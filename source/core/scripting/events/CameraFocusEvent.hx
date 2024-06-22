package core.scripting.events;

#if ENGINE_SCRIPTING
import gameplay.Character;

/**
 * Event dispatched whenever the camera focus is going to be changed in gameplay.
 */
class CameraFocusEvent extends ScriptEvent {
    /**
     * Character to focus on.
     */
    @:eventConstructor public var character:Character;

    override function destroy():Void {
        character = null;
    }
}
#end
