package funkin.objects;

import flixel.addons.display.FlxBackdrop;

/**
 * Starlight background displayed in the boot screen.
 */
class StarlightBackground extends FlxBackdrop {
    /**
     * Time elapsed since this object has been added to a group.
     */
    var _elapsedTime:Float = 0;

    /**
     * Creates a new `StarlightBackground`.
     */
    public function new():Void {
        super(Paths.image("menus/boot_bg"), X);
    }

    override function update(elapsed:Float):Void {
        _elapsedTime += elapsed;
        alpha = 0.4 + 0.4 * Math.abs(Math.sin(_elapsedTime * 0.5));

        x -= 5 * elapsed;

        #if FLX_DEBUG
        FlxBasic.activeCount++;
        #end
    }
}
