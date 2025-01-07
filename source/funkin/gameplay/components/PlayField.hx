package funkin.gameplay.components;

import flixel.text.FlxText;
import funkin.ui.HealthBar;
import funkin.ui.HealthIcon;
import flixel.group.FlxGroup;
import funkin.gameplay.notes.*;
import funkin.gameplay.components.Rating.Rank;

/**
 * Group containing the notefield and each UI elements present in gameplay.
 */
class PlayField extends FlxGroup {
    /**
     * Text displaying the game score.
     */
    public var score:FlxText;

    /**
     * Text displaying the amount of misses.
     */
    public var misses:FlxText;

    /**
     * Text displaying the song accuracy.
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
     * Combo popup group for this playfield.
     */
    public var comboPopup:ComboPopup;

    /**
     * Notespawner object for this playfield.
     */
    public var noteSpawner:NoteSpawner;

    /**
     * Strumline group for this playfield.
     */
    public var strumLines:FlxTypedGroup<StrumLine>;

    /**
     * Opponent strumline.
     */
    public var opponentStrumLine:StrumLine;

    /**
     * Player strumline.
     */
    public var playerStrumLine:StrumLine;

    /**
     * Determines whether botplay is on.
     */
    public var botplay(get, set):Bool;

    /**
     * Determines whether player inputs are disabled.
     */
    public var inactiveInputs(get, set):Bool;

    /**
     * Smoothed health value.
     */
    var displayedHealth:Float = 0.5;

    /**
     * Creates a new `PlayField`.
     */
    public function new():Void {
        super();

        var game:PlayState = PlayState.self;

        var playerNoteSkin:String = game.player?.noteSkin ?? PlayState.song.getNoteskin(PLAYER);
        var opponentNoteSkin:String = game.opponent?.noteSkin ?? PlayState.song.getNoteskin(OPPONENT);

        comboPopup = new ComboPopup(game.stats.ratings.length, game.stage?.uiStyle);
        comboPopup.camera = game.camHUD;
        add(comboPopup);

        strumLines = new FlxTypedGroup<StrumLine>();
        strumLines.active = false;
        add(strumLines);

        opponentStrumLine = new GameStrumLine(FlxG.width * 0.25, 50, true, opponentNoteSkin);
        opponentStrumLine.scrollSpeed = PlayState.song.gameplayInfo.scrollSpeed;
        opponentStrumLine.addCharacter(game.opponent);
        strumLines.add(opponentStrumLine);

        playerStrumLine = new GameStrumLine(FlxG.width * 0.75, 50, false, playerNoteSkin);
        playerStrumLine.scrollSpeed = PlayState.song.gameplayInfo.scrollSpeed;
        playerStrumLine.addCharacter(game.player);
        playerStrumLine.owner = PLAYER;
        strumLines.add(playerStrumLine);

        noteSpawner = new NoteSpawner(strumLines.members, game.startTime);
        noteSpawner.active = false;
        add(noteSpawner);

        if (Options.downscroll)
            playerStrumLine.y = opponentStrumLine.y = FlxG.height * 0.8;

        if (Options.centeredStrumline) {
            playerStrumLine.x = FlxG.width / 2;
            opponentStrumLine.visible = false;
        }

        healthBar = new HealthBar(game.player?.healthBarColor ?? 0xFF66FF33, game.opponent?.healthBarColor ?? 0xFFFF0000);
        healthBar.y = FlxG.height * (Options.downscroll ? 0.1 : 0.86);
        healthBar.active = false;
        add(healthBar);

        playerIcon = new HealthIcon(0, 0, game.player?.healthIcon ?? HealthIcon.DEFAULT_ICON);
        playerIcon.y = healthBar.y - (playerIcon.height / 2);
        playerIcon.state = NEUTRAL;
        playerIcon.flipX = true;
        playerIcon.health = 50;
        add(playerIcon);

        opponentIcon = new HealthIcon(0, 0, game.opponent?.healthIcon ?? HealthIcon.DEFAULT_ICON);
        opponentIcon.y = healthBar.y - (opponentIcon.height / 2);
        opponentIcon.state = NEUTRAL;
        opponentIcon.health = 50;
        add(opponentIcon);

        // TODO: find better text rendering tools
        // FlxBitmapText doesn't run well with outlines,
        // so we're using FlxTexts for now
        score = new FlxText(healthBar.x + 50, healthBar.y + healthBar.height + 25, healthBar.width / 3);
        score.setFormat(Paths.font("vcr"), 19);
        score.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        score.fieldHeight = 30;
        score.active = false;
        add(score);

        accuracy = new FlxText(healthBar.x + healthBar.width - 200, score.y, 150);
        accuracy.setFormat(score.font, 19, RIGHT);
        accuracy.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        accuracy.fieldHeight = 30;
        accuracy.active = false;
        add(accuracy);

        misses = new FlxText(healthBar.x + (healthBar.width - score.fieldWidth) / 2, score.y, score.fieldWidth);
        misses.setFormat(score.font, 19, CENTER);
        misses.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        misses.fieldHeight = 30;
        misses.active = false;
        add(misses);
        //

        updateScore();
        updateAccuracy();
        updateMisses();
    }

    /**
     * Update behaviour.
     */
    override function update(elapsed:Float):Void {
        noteSpawner.update(elapsed);
        strumLines.update(elapsed);

        displayedHealth = Tools.lerp(displayedHealth, PlayState.self.stats.health, 12);

        healthBar.percent = 1 - displayedHealth;
        opponentIcon.health = 100 - displayedHealth * 100;
        playerIcon.health = displayedHealth * 100;

        super.update(elapsed);

        var healthBarOrigin:Float = healthBar.x + healthBar.width * healthBar.percent;
        opponentIcon.x = healthBarOrigin - opponentIcon.width + 20;
        playerIcon.x = healthBarOrigin - 20;
    }

    /**
     * Displays a rating sprite.
     * @param rating Rating to display.
     */
    public inline function displayRating(rating:Rating):Void {
        comboPopup.displayRating(rating);
    }

    /**
     * Displays combo numbers based on the provided combo amount.
     * @param combo Combo amount.
     */
    public inline function displayCombo(combo:Int):Void {
        comboPopup.displayCombo(combo);
    }

    /**
     * Increments the current score amount.
     * @param score Amount of score to add.
     */
    public function incrementScore(score:Float):Void {
        PlayState.self.stats.score += score;
        updateScore();
    }

    /**
     * Increments the current misses amount.
     */
    public function incrementMisses():Void {
        PlayState.self.stats.misses++;
        updateMisses();
    }

    /**
     * Increments the current accuracy amount.
     * @param accuracy Accuracy value ranging from 0 to 1.
     */
    public function incrementAccuracy(accuracy:Float):Void {
        PlayState.self.stats.accuracyMod += accuracy;
        PlayState.self.stats.accuracyNotes++;
        updateAccuracy();
    }

    /**
     * Updates the score text.
     */
    public function updateScore():Void {
        score.text = "Score: " + Math.fround(PlayState.self.stats.score);
        score.color = (PlayState.self.stats.score < 0 ? FlxColor.RED : FlxColor.WHITE);
    }

    /**
     * Updates the misses text.
     */
    public function updateMisses():Void {
        misses.text = "Misses: " + PlayState.self.stats.misses;
    }

    /**
     * Updates the accuracy text.
     */
    public function updateAccuracy():Void {
        accuracy.clearFormats();

        if (botplay) {
            accuracy.text = "Botplay";
            return;
        }
        
        if (PlayState.self.stats.accuracyNotes == 0) {
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

    function get_botplay():Bool
        return playerStrumLine.cpu;

    function set_botplay(v:Bool):Bool {
        playerStrumLine.cpu = v;
        updateAccuracy();

        if (playerStrumLine.cpu)
            PlayState.self.validScore = false;
        
        return v;
    }

    function get_inactiveInputs():Bool
        return playerStrumLine.inactiveInputs;

    function set_inactiveInputs(v:Bool):Bool
        return playerStrumLine.inactiveInputs = v;
}
