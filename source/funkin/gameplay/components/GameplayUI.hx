package funkin.gameplay.components;

import flixel.text.FlxText;
import funkin.ui.HealthIcon;
import funkin.ui.HealthBar;
import flixel.group.FlxSpriteGroup;
import funkin.gameplay.components.Rating.Rank;

/**
 * Sprite group containing each UI elements present in gameplay.
 */
class GameplayUI extends FlxSpriteGroup {
    /**
     * Displayed score text.
     */
    public var score:FlxText;

    /**
     * Displayed misses text.
     */
    public var misses:FlxText;

    /**
     * Displayed accuracy text.
     */
    public var accuracy:FlxText;

    /**
     * Health bar element.
     */
    public var healthBar:HealthBar;

    /**
     * Player icon.
     */
    public var playerIcon:HealthIcon;

    /**
     * Opponent icon.
     */
    public var opponentIcon:HealthIcon;

    /**
     * Smoothed health value.
     */
    var displayedHealth:Float = 1;

    /**
     * Creates a new `GameplayUI`.
     */
    public function new():Void {
        super();

        healthBar = new HealthBar(PlayState.self.player?.healthBarColor ?? 0xFF66FF33, PlayState.self.opponent?.healthBarColor ?? 0xFFFF0000);
        healthBar.y = FlxG.height * (Options.downscroll ? 0.1 : 0.86);
        add(healthBar);

        playerIcon = new HealthIcon(0, 0, PlayState.self.player?.healthIcon ?? HealthIcon.DEFAULT_ICON);
        playerIcon.y = healthBar.y - (playerIcon.height / 2);
        playerIcon.state = NEUTRAL;
        playerIcon.flipX = true;
        playerIcon.health = 50;
        add(playerIcon);

        opponentIcon = new HealthIcon(0, 0, PlayState.self.opponent?.healthIcon ?? HealthIcon.DEFAULT_ICON);
        opponentIcon.y = healthBar.y - (opponentIcon.height / 2);
        opponentIcon.state = NEUTRAL;
        opponentIcon.health = 50;
        add(opponentIcon);

        // TODO: find better text rendering tools
        // FlxBitmapText doesn't run well with outlines,
        // so we're using FlxTexts for now
        score = new FlxText(healthBar.x + 50, healthBar.y + healthBar.height + 25, healthBar.width / 3);
        score.setFormat(Assets.font("vcr"), 19);
        score.fieldHeight = 30;
        add(score);

        accuracy = new FlxText(healthBar.x + healthBar.width - 200, score.y, 150);
        accuracy.setFormat(score.font, 19, RIGHT);
        accuracy.fieldHeight = 30;
        add(accuracy);

        misses = new FlxText(healthBar.x + (healthBar.width - score.fieldWidth) / 2, score.y, score.fieldWidth);
        misses.setFormat(score.font, 19, CENTER);
        misses.fieldHeight = 30;
        add(misses);

        score.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        accuracy.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        misses.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        //

        updateScore();
        updateAccuracy();
        updateMisses();
    }

    /**
     * Update behaviour.
     */
    override function update(elapsed:Float):Void {
        displayedHealth = Tools.lerp(displayedHealth, PlayState.self.stats.health, 12);

        healthBar.percent = 1 - displayedHealth / 2;
        opponentIcon.health = 100 - displayedHealth * 50;
        playerIcon.health = displayedHealth * 50;

        super.update(elapsed);

        playerIcon.x = healthBar.x + healthBar.width * healthBar.percent - 20;
        opponentIcon.x = healthBar.x + healthBar.width * healthBar.percent - opponentIcon.width + 20;
    }

    /**
     * Updates the score text.
     */
    public function updateScore():Void {
        score.text = "Score: " + Math.fround(PlayState.self.score);
        score.color = (PlayState.self.score < 0 ? FlxColor.RED : FlxColor.WHITE);
    }

    /**
     * Updates the misses text.
     */
    public function updateMisses():Void {
        misses.text = "Misses: " + PlayState.self.misses;
    }

    /**
     * Updates the accuracy text.
     */
    public function updateAccuracy():Void {
        accuracy.clearFormats();

        if (PlayState.self.botplay) {
            accuracy.text = "Botplay";
            return;
        }
        
        if (PlayState.self.accuracyNotes == 0) {
            accuracy.text = "N/A";
            return;
        }
        
        var text:String = Std.string(PlayState.self.stats.accuracy) + "%";
        var rank:Rank = PlayState.self.stats.getRank();

        if (rank != null) {
            text += " [" + rank.name + "]";
            accuracy.addFormat(rank.format, text.indexOf("[") + 1, text.indexOf("]"));
        }
        
        accuracy.text = text;
    }

    /**
     * Makes the icons bops.
     */
    public function iconBops():Void {
        playerIcon.bop();
        opponentIcon.bop();
    }
}
