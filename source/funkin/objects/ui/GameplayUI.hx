package funkin.objects.ui;

import flixel.ui.FlxBar;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;

import flixel.util.FlxStringUtil;

class GameplayUI extends FlxSpriteGroup {
    public var smoothHealth:Bool = Settings.get("smooth health bar");
    public var scoreDivider:String = " / ";
    public var iconSpacing:Float = 26;
    public var healthDisplay:Float = 1;

    public var scoreText:FlxText;
    public var botplayMark:FlxText;

    public var healthBar:FlxBar;
    public var healthBarBG:FlxSprite;

    public var iconPlayer:HealthIcon;
    public var iconOpponent:HealthIcon;

    public var timer:FlxText;

    var botplayAlpha:Float = 0;
    var healthLerp:Float = 1;

    public function new():Void {
        super();
        scrollFactor.set();

        healthBarBG = new FlxSprite();
	    healthBarBG.loadGraphic(AssetHelper.image('ui/gameplay/healthBar'));
        healthBarBG.screenCenter(X);
	    add(healthBarBG);

        var opponentHealthColor:FlxColor = (PlayState.current.opponent == null) ? 0xFFFF0000: Tools.getColor(PlayState.current.opponent.data.healthBarColor);
        var playerHealthColor:FlxColor = (PlayState.current.player == null) ? 0xFF66FF33 : Tools.getColor(PlayState.current.player.data.healthBarColor);

        healthBar = new FlxBar(healthBarBG.x + 4, 0, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8));
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
        scoreText.text = 'Score: ?${scoreDivider}Misses: 0${scoreDivider}Accuracy: N/A';
        scoreText.screenCenter(X);
        add(scoreText);

        botplayMark = new FlxText();
        botplayMark.setFormat(scoreText.font, 34, FlxColor.WHITE, CENTER);
        botplayMark.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.25);
        botplayMark.text = "BOTPLAY";
        botplayMark.screenCenter(X);
        botplayMark.visible = false;
        add(botplayMark);

        timer = new FlxText();
        timer.setFormat(scoreText.font, 30, FlxColor.WHITE);
        timer.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
        timer.visible = (Settings.get("timer type") != "none");
        add(timer);
        
	    repositionElements(Settings.get("downscroll"));
    }
    
    override function update(elapsed:Float):Void {
        super.update(elapsed);
        
        // update health bar
	    if (smoothHealth)
            healthLerp = FlxMath.lerp(healthLerp, healthDisplay, FlxMath.bound(elapsed * 12, 0, 1));
	    else
            healthLerp = healthDisplay;

        var multHealth:Float = healthDisplay * 50;
        iconOpponent.health = 100 - multHealth;
        iconPlayer.health = multHealth;
        healthBar.percent = multHealth;

        var healthBarPos:Float = healthBar.x + healthBar.width * (1 - healthLerp * 0.5);
        iconOpponent.x = healthBarPos - (iconOpponent.width - iconSpacing);
        iconPlayer.x = healthBarPos - iconSpacing;

        // update timer
        var music = PlayState.current.music.instrumental;

        if (timer.visible && music.playing) {
            timer.text = switch (Settings.get("timer type")) {
                case "full": FlxStringUtil.formatTime(music.time * 0.001) + " / " + FlxStringUtil.formatTime(music.length * 0.001);
                default: FlxStringUtil.formatTime((music.length - music.time) * 0.001);
            }
            timer.screenCenter(X);
        }

        // update botplay mark
        if (botplayMark.visible) {
            botplayAlpha += elapsed;
            botplayMark.alpha = 1 - Math.sin(botplayAlpha * Math.PI);
        }
    }

    inline public function updateScoreText():Void {
        var text:String =
            'Score: ${PlayState.current.score}' + scoreDivider
            + 'Misses: ${PlayState.current.misses}' + scoreDivider
            + 'Accuracy: ${PlayState.current.accuracyDisplay}%'
        ;

        var rank:String = PlayState.getRank(PlayState.current);

        if (rank != null && rank.length > 0)
            text += scoreDivider + rank;

        scoreText.text = text;
        scoreText.screenCenter(X);
    }

    inline public function showBotplayMark(show:Bool = true):Void {
        if (!show)
            botplayAlpha = 1;
        botplayMark.visible = show;
    }

    inline public function tweenTimer():Void {
        timer.alpha = 0;
        flixel.tweens.FlxTween.tween(timer, {alpha: 0.7}, 0.35);
    }
    
    inline public function repositionElements(downscroll:Bool = false):Void {
	    healthBarBG.y = FlxG.height * ((downscroll) ? 0.075 : 0.875);
	    healthBar.y = healthBarBG.y + 4;
	    
	    scoreText.y = healthBarBG.y + 50;

        botplayMark.y = FlxG.height * ((downscroll) ? 0.9 : 0.1);
        timer.y = FlxG.height * ((downscroll) ? 0.95 : 0.05);
	    
	    iconPlayer.y = healthBar.y - iconPlayer.frameHeight / 2;
	    iconOpponent.y = healthBar.y - iconOpponent.frameHeight / 2;
    }

    inline public function beatHit():Void {
	    iconPlayer.bop();
	    iconOpponent.bop();
    }

    override function destroy():Void {
        scoreDivider = null;
        super.destroy();
    }
}