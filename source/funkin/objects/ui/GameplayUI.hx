package funkin.objects.ui;

import flixel.ui.FlxBar;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;

import flixel.util.FlxStringUtil;

class GameplayUI extends FlxSpriteGroup {
    public var scoreText:FlxText;
    public var botplayText:FlxText;

    public var healthBar:FlxBar;
    public var healthBarBG:FlxSprite;

    public var iconPlayer:HealthIcon;
    public var iconOpponent:HealthIcon;

    public var timer:FlxText;

    public var smoothHealthBar:Bool = Settings.get("smooth health bar");
    public var healthDisplay:Float = 1;

    var botplayAlpha:Float = 0;
    var healthLerp:Float = 1;

    public function new():Void {
        super();
        scrollFactor.set();

        healthBarBG = new FlxSprite();
	    healthBarBG.loadGraphic(AssetHelper.image('ui/gameplay/healthBar'));
	    add(healthBarBG);

        var opponentHealthColor:FlxColor = (PlayState.current.opponent == null) ? 0xFFFF0000: Tools.getColor(PlayState.current.opponent.data.healthBarColor);
        var playerHealthColor:FlxColor = (PlayState.current.player == null) ? 0xFF66FF33 : Tools.getColor(PlayState.current.player.data.healthBarColor);

        healthBar = new FlxBar(0, 0, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8));
	    healthBar.createFilledBar(opponentHealthColor, playerHealthColor);
        healthBar.setRange(0, 100);
	    add(healthBar);

        iconPlayer = new HealthIcon(0, 0, PlayState.current.player?.data.icon ?? "face");
        iconPlayer.bopping = true;
        iconPlayer.flipX = true;
        iconPlayer.health = 50;
        iconPlayer.state = "neutral";
        add(iconPlayer);
        
        iconOpponent = new HealthIcon(0, 0, PlayState.current.opponent?.data.icon ?? "face");
        iconOpponent.bopping = true;
        iconOpponent.health = 50;
        iconOpponent.state = "neutral";
        add(iconOpponent);

        scoreText = new FlxText();
        scoreText.setFormat(AssetHelper.font("vcr"), 20, FlxColor.WHITE, CENTER);
	    scoreText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        scoreText.text = 'Score: ? / Misses: 0 / Accuracy: N/A';
        scoreText.screenCenter(X);
        add(scoreText);

        botplayText = new FlxText();
        botplayText.setFormat(scoreText.font, 34, FlxColor.WHITE, CENTER);
        botplayText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.25);
        botplayText.text = "BOTPLAY";
        botplayText.screenCenter(X);
        botplayText.visible = false;
        add(botplayText);

        timer = new FlxText();
        timer.setFormat(scoreText.font, 30, FlxColor.WHITE);
        timer.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
        timer.visible = (Settings.get("timer type") != "none");
        add(timer);
        
	    repositionElements(Settings.get("downscroll"));
    }
    
    override function update(elapsed:Float):Void {
        super.update(elapsed);

	    if (smoothHealthBar)
            healthLerp = FlxMath.lerp(healthLerp, healthDisplay, FlxMath.bound(elapsed * 12, 0, 1));
	    else
            healthLerp = healthDisplay;

        var healthBarPos:Float = healthBar.x + (healthBar.width * (1 - healthLerp * 0.5));
        iconOpponent.x = healthBarPos - iconOpponent.width + 13;
        iconPlayer.x = healthBarPos - 26;

        var multHealth:Float = healthDisplay * 50;
        iconOpponent.health = 100 - multHealth;
        iconPlayer.health = multHealth;
        healthBar.percent = multHealth;

        var music = PlayState.current.music.instrumental;

        if (timer.visible && music.playing) {
            timer.text = switch (Settings.get("timer type")) {
                case "full": FlxStringUtil.formatTime(music.time * 0.001) + " / " + FlxStringUtil.formatTime(music.length * 0.001);
                default: FlxStringUtil.formatTime((music.length - music.time) * 0.001);
            }
            timer.screenCenter(X);
        }

        if (botplayText.visible) {
            botplayAlpha += elapsed;
            botplayText.alpha = 1 - Math.sin(botplayAlpha * Math.PI);
        }
    }

    public function updateScoreText():Void {
        var text:String = 'Score: ${PlayState.current.score} / Misses: ${PlayState.current.misses} / Accuracy: ${PlayState.current.accuracyDisplay}%';
        var rank:String = PlayState.getRank(PlayState.current);

        if (rank != null && rank.length > 0)
            text += ' / ${rank}';

        scoreText.text = text;
        scoreText.screenCenter(X);
    }

    public function tweenTimer():Void {
        timer.alpha = 0;
        flixel.tweens.FlxTween.tween(timer, {alpha: 0.7}, 0.35);
    }
    
    public function repositionElements(downscroll:Bool = false):Void {
	    healthBarBG.y = FlxG.height * ((downscroll) ? 0.1 : 0.9);
	    healthBarBG.screenCenter(X);
	    healthBar.setPosition(healthBarBG.x + 4, healthBarBG.y + 4);
	    
	    scoreText.y = healthBarBG.y + 25;
	    scoreText.screenCenter(X);

        botplayText.y = FlxG.height * ((downscroll) ? 0.9 : 0.1);
        timer.y = FlxG.height * ((downscroll) ? 0.95 : 0.05);
	    
	    iconPlayer.y = healthBar.y - iconPlayer.frameHeight / 2;
	    iconOpponent.y = healthBar.y - iconOpponent.frameHeight / 2;
    }

    public function beatHit():Void {
	    iconPlayer.bop();
	    iconOpponent.bop();
    }
}