package funkin.ui;

import flixel.math.FlxRect;
import flixel.group.FlxSpriteGroup;
import funkin.objects.OffsetSprite;

/**
 * Basic health bar object.
 */
class HealthBar extends FlxSpriteGroup {
    /**
     * How much the opponent side is clipped, ranging from 0 to 1.
     */
    public var percent(default, set):Float = 0.5;

    /**
     * Color for the player side.
     */
    public var playerColor(get, set):FlxColor;

    /**
     * Color for the opponent side.
     */
    public var opponentColor(get, set):FlxColor;

    /**
     * Player side for this health bar.
     */
    public var playerSide:FlxSprite;

    /**
     * Opponent side for this health bar.
     */
    public var opponentSide:FlxSprite;

    /**
     * Creates a new `HealthBar`.
     * @param playerColor Color for the player side.
     * @param opponentColor Color for the opponent side.
     */
    public function new(playerColor:FlxColor = FlxColor.WHITE, opponentColor:FlxColor = FlxColor.WHITE):Void {
        super();

        playerSide = new HealthBarSide();
        playerSide.loadGraphic(Assets.image('ui/gameplay/healthBar'));
        playerSide.color = playerColor;
        add(playerSide);

        opponentSide = new HealthBarSide();
        opponentSide.loadGraphic(playerSide.graphic);
        opponentSide.color = opponentColor;
        add(opponentSide);

        opponentSide.clipRect = FlxRect.get(0, 0, opponentSide.frameWidth * percent, opponentSide.height);
        x = (FlxG.width - opponentSide.width) / 2;

        moves = false;
    }

    /**
     * Updates the opponent side's clipping.
     * @param percent How much the opponent side is clipped, ranging from 0 to 1.
     */
    public function updateClip(percent:Float):Void {
        opponentSide.clipRect.width = (opponentSide.frameWidth * percent);
        opponentSide.clipRect = opponentSide.clipRect;
    }

    function set_percent(v:Float):Float {
        percent = v;
        updateClip(v);
        return v;
    }

    inline function set_opponentColor(v:FlxColor):FlxColor {
        if (opponentSide != null)
            opponentSide.color = v;

        return v;
    }

    inline function set_playerColor(v:FlxColor):FlxColor {
        if (playerSide != null)
            playerSide.color = v;

        return v;
    }

    inline function get_opponentColor():FlxColor {
        return opponentSide?.color ?? 0;
    }

    inline function get_playerColor():FlxColor {
        return playerSide?.color ?? 0;
    }
}

/**
 * Sprite class used for health bar sides, used to make clipping smoother.
 * Unrounds clipRect for smoother results.
 */
private class HealthBarSide extends OffsetSprite {
    override function set_clipRect(v:FlxRect):FlxRect {
        clipRect = v;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

        return v;
    }
}
