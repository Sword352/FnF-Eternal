package funkin.objects.ui;

import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxStringUtil;

class GameplayUI extends FlxSpriteGroup {
    public var smoothHealth:Bool = Settings.get("smooth health bar");
    public var scoreDivider:String = " / ";
    public var healthDisplay:Float = 1;
    public var iconSpacing:Float = 26;

    public var scoreText:FlxText;
    public var timer:FlxText;

    public var healthBar:HealthBar;
    public var iconPlayer:HealthIcon;
    public var iconOpponent:HealthIcon;

    var game(get, never):PlayState;
    inline function get_game():PlayState
        return PlayState.current;

    var visualHealth:Float = 1;

    public function new():Void {
        super();

        healthBar = new HealthBar(game.player?.healthBarColor ?? 0xFF66FF33, game.opponent?.healthBarColor ?? 0xFFFF0000);
        add(healthBar);

        iconPlayer = new HealthIcon(0, 0, game.player?.healthIcon ?? HealthIcon.DEFAULT_ICON);
        iconPlayer.state = "neutral";
        iconPlayer.bopping = true;
        iconPlayer.flipX = true;
        iconPlayer.health = 50;
        add(iconPlayer);
        
        iconOpponent = new HealthIcon(0, 0, game.opponent?.healthIcon ?? HealthIcon.DEFAULT_ICON);
        iconOpponent.state = "neutral";
        iconOpponent.bopping = true;
        iconOpponent.health = 50;
        add(iconOpponent);

        scoreText = new FlxText();
        scoreText.setFormat(Assets.font("vcr"), 20, FlxColor.WHITE, CENTER);
	    scoreText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        scoreText.text = 'Score: ?${scoreDivider}Misses: 0${scoreDivider}Accuracy: N/A';
        scoreText.screenCenter(X);
        add(scoreText);

        if (Settings.get("timer type") != "none") {
            timer = new FlxText();
            timer.setFormat(scoreText.font, 30, FlxColor.WHITE);
            timer.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
            add(timer);
        }

	    reposUI(Settings.get("downscroll"));
    }
    
    override function update(elapsed:Float):Void {
        // update health bar
	    if (smoothHealth)
            visualHealth = Tools.lerp(visualHealth, healthDisplay, 12);
	    else
            visualHealth = healthDisplay;

        healthBar.pt = (1 - (visualHealth * 0.5));
        iconPlayer.health = (healthDisplay * 50);
        iconOpponent.health = 100 - iconPlayer.health;

        super.update(elapsed);

        var healthBarPos:Float = healthBar.x + healthBar.oppSide.clipRect.width;
        iconOpponent.x = healthBarPos - iconOpponent.width + iconSpacing;
        iconPlayer.x = healthBarPos - iconSpacing;

        // update timer
        if (timer?.visible && game.music.playing) {
            var length:Float = game.music.instrumental.length;
            var time:Float = game.music.instrumental.time;

            timer.text = switch (Settings.get("timer type")) {
                case "full": FlxStringUtil.formatTime(time * 0.001) + " / " + FlxStringUtil.formatTime(length * 0.001);
                default: FlxStringUtil.formatTime((length - time) * 0.001);
            }
            timer.screenCenter(X);
        }
    }

    public inline function updateScoreText():Void {
        if (!game.playerStrumline.cpu) {
            var text:String =
                'Score: ${game.score}' + scoreDivider
              + 'Misses: ${game.misses}' + scoreDivider
              + 'Accuracy: ${game.accuracyDisplay}%'
            ;

            var rank:String = PlayState.getRank(game);
            if (rank?.length > 0) text += scoreDivider + rank;

            scoreText.text = text;
        }
        else scoreText.text = "[ BOTPLAY ]";

        scoreText.screenCenter(X);
    }
    
    public inline function reposUI(downscroll:Bool = false):Void {
        healthBar.y = FlxG.height * ((downscroll) ? 0.1 : 0.875);
        scoreText.y = healthBar.y + 50;

        iconOpponent.y = healthBar.y - (iconOpponent.frameHeight / 2);
        iconPlayer.y = healthBar.y - (iconPlayer.frameHeight / 2);

        if (timer != null)
            timer.y = FlxG.height * ((downscroll) ? 0.95 : 0.05);
    }

    public inline function onSongStart():Void {
        if (timer == null)
            return;

        timer.alpha = 0;
        FlxTween.tween(timer, {alpha: 0.7}, 0.35);
    }

    public inline function beatHit():Void {
	    iconPlayer.bop();
	    iconOpponent.bop();
    }

    override function destroy():Void {
        scoreDivider = null;
        super.destroy();
    }
}