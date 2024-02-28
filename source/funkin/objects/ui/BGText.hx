package funkin.objects.ui;

import flixel.text.FlxText;

class BGText extends FlxText {
    public var automaticPosition:Bool = true;
    public var automaticScale:Bool = true;

    public var background(default, null):FlxSprite;

    public function new(x:Float = 0, y:Float = 0, ?text:String, size:Int = 8) {
        super(x, y, 0, text, size, false);

        background = new FlxSprite();
        background.makeGraphic(1, 1, FlxColor.BLACK);
    }

    override function draw():Void {
        if (automaticScale && (background.width != width || background.height != height)) {
            background.scale.set(width, height);
            background.updateHitbox();
        }

        if (automaticPosition)
            background.setPosition(x, y);

        background.cameras = cameras;
        background.draw();

        super.draw();
    }

    override function kill():Void {
        background.kill();
        super.kill();
    }

    override function revive():Void {
        background.revive();
        super.revive();
    }

    override function destroy():Void {
        background = FlxDestroyUtil.destroy(background);
        super.destroy();
    }
}
