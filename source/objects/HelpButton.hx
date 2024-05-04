package objects;

class HelpButton extends FlxSprite {
    public var onClick:Void->Void = null;

    public function new():Void {
        super(5, 0, Assets.image("ui/debug/question_mark"));
        scale.set(0.35, 0.35);
        updateHitbox();

        y = FlxG.height - height - 5;
        alpha = 0.6;
    }

    override function update(elapsed:Float):Void {
        var hovered:Bool = FlxG.mouse.overlaps(this, camera);
        if (hovered && FlxG.mouse.justPressed && onClick != null) onClick();
        alpha = Tools.lerp(alpha, (hovered) ? 1 : 0.6, 6);
    }

    override function destroy():Void {
        onClick = null;
        super.destroy();
    }
}
