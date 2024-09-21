package funkin.gameplay.events;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

/**
 * Change scroll speed event. Changes the strumline scroll speeds, either progressively or instantly.
 */
@:build(funkin.core.macros.SongEventMacro.build({
    type: "change scroll speed",
    name: "Change Scroll Speed",
    arguments: [
        {name: "New Speed", type: "Float", tempValue: "1"},
        {name: "Duration", type: "Float", tempValue: "0", unit: "s"},
        {
            name: "Ease", type: "List", tempValue: "Linear",
            list: ["Linear", "Quad", "Cube", "Quart", "Quint", "Smooth Step", "Smoother Step", "Sine", "Bounce", "Circ", "Expo", "Back", "Elastic"]
        },
        {name: "Ease Mode", type: "List", tempValue: "In", list: ["In", "Out", "In/Out"]}
    ]
}))
class ChangeScrollSpeedEvent extends SongEvent {
    override function execute(_):Void {
        for (strumline in game.playField.strumLines) {
            if (duration > 0)
                FlxTween.tween(strumline, {scrollSpeed: newSpeed}, duration, {ease: resolveEase(ease, easeMode)});
            else
                strumline.scrollSpeed = newSpeed;
        }
    }

    inline function resolveEase(ease:String, mode:String):EaseFunction {
        if (ease == null)
            return FlxEase.linear;

        if (mode == null)
            mode = "In";

        if (mode.contains("/"))
            mode = mode.replace("/", " ");
        
        var easeField:String = Tools.camelCase(ease.trim() + " " + mode.trim());
        var easeMethod:Dynamic = Reflect.field(FlxEase, easeField);

        return (easeMethod == null || !Reflect.isFunction(easeMethod)) ? FlxEase.linear : cast easeMethod;
    }
}
