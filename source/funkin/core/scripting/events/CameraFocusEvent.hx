package funkin.core.scripting.events;

import funkin.gameplay.components.Character;

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
