package funkin.objects.ui;

import flixel.math.FlxRect;
import flixel.group.FlxSpriteGroup;

class HealthBar extends FlxSpriteGroup {
    public var pt(default, set):Float = 0.5;
    public var percent(get, set):Float;

    public var playerColor(get, set):FlxColor;
    public var oppColor(get, set):FlxColor;

    public var playerSide:FlxSprite;
    public var oppSide:FlxSprite;

    public function new(playerColor:FlxColor = FlxColor.WHITE, oppColor:FlxColor = FlxColor.WHITE):Void {
        super();

        playerSide = new FlxSprite();
        playerSide.loadGraphic(Assets.image('ui/gameplay/healthBar'));
        playerSide.color = playerColor;
        add(playerSide);

        oppSide = new FlxSprite();
        oppSide.loadGraphic(playerSide.graphic);
        oppSide.color = oppColor;
        add(oppSide);

        oppSide.clipRect = FlxRect.get(0, 0, oppSide.frameWidth * pt, oppSide.height);
        x = (FlxG.width - oppSide.width) * 0.5;
        
        moves = false;
    }

    public inline function updateClip(pt:Float):Void {
        oppSide.clipRect.width = (oppSide.frameWidth * pt);
        oppSide.clipRect = oppSide.clipRect;
    }

    inline function set_pt(v:Float):Float {
        updateClip(v);
        return pt = v;
    }

    inline function set_percent(v:Float):Float {
        pt = (v * 0.01);
        return v;
    }

    inline function get_percent():Float
        return pt * 100;

    inline function set_oppColor(v:FlxColor):FlxColor {
        if (oppSide != null)
            oppSide.color = v;

        return v;
    }

    inline function set_playerColor(v:FlxColor):FlxColor {
        if (playerSide != null)
            playerSide.color = v;

        return v;
    }

    inline function get_oppColor():FlxColor
        return oppSide?.color ?? 0;

    inline function get_playerColor():FlxColor
        return playerSide?.color ?? 0;
}