package funkin.gameplay;

import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxStringUtil;
import flixel.group.FlxSpriteGroup;

import funkin.objects.HealthBar;
import funkin.objects.HealthIcon;

class GameplayUI extends FlxSpriteGroup {
    public var smoothHealth:Bool = Options.smoothHealth;
    public var scoreDivider:String = "   ";
    public var healthDisplay:Float = 1;
    public var iconSpacing:Float = 20;

    public var scoreText:FlxText;
    public var timeDisplay:FlxText;

    public var healthBar:HealthBar;
    public var iconP1:HealthIcon;
    public var iconP2:HealthIcon;

    var game(get, never):PlayState;
    inline function get_game():PlayState
        return PlayState.current;

    var visualHealth:Float = 1;

    public function new():Void {
        super();

        healthBar = new HealthBar(game.player?.healthBarColor ?? 0xFF66FF33, game.opponent?.healthBarColor ?? 0xFFFF0000);
        add(healthBar);

        iconP1 = new HealthIcon(0, 0, game.player?.healthIcon ?? HealthIcon.DEFAULT_ICON);
        iconP1.state = NEUTRAL;
        iconP1.bopping = true;
        iconP1.flipX = true;
        iconP1.health = 50;
        add(iconP1);

        iconP2 = new HealthIcon(0, 0, game.opponent?.healthIcon ?? HealthIcon.DEFAULT_ICON);
        iconP2.state = NEUTRAL;
        iconP2.bopping = true;
        iconP2.health = 50;
        add(iconP2);

        scoreText = new FlxText(0, 0, FlxG.width);
        scoreText.setFormat(Assets.font("vcr"), 19, FlxColor.WHITE, CENTER);
        scoreText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        add(scoreText);

        scoreText.text = 'Score: ?${scoreDivider}Misses: 0${scoreDivider}Accuracy: N/A';

        if (Options.timeMark != NONE) {
            timeDisplay = new FlxText(0, 0, FlxG.width);
            timeDisplay.setFormat(scoreText.font, 22, FlxColor.WHITE, CENTER);
            timeDisplay.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.6);
            add(timeDisplay);
        }

        repositionUI(Options.downscroll);
    }

    override function update(elapsed:Float):Void {
        // update health bar
        if (smoothHealth)
            visualHealth = Tools.lerp(visualHealth, healthDisplay, 12);
        else
            visualHealth = healthDisplay;

        healthBar.pt = (1 - (visualHealth * 0.5));
        iconP1.health = (healthDisplay * 50);
        iconP2.health = 100 - iconP1.health;

        super.update(elapsed);

        var healthBarPos:Float = healthBar.x + healthBar.oppSide.clipRect.width;
        iconP2.x = healthBarPos - iconP2.width + iconSpacing;
        iconP1.x = healthBarPos - iconSpacing;

        // update time display
        if (timeDisplay?.alpha > 0 && game.music.playing) {
            var length:Float = game.music.instrumental.length;
            var time:Float = game.music.instrumental.time;

            var base:String = switch (Options.timeMark) {
                case FULL: FlxStringUtil.formatTime(time * 0.001) + " / " + FlxStringUtil.formatTime(length * 0.001);
                case ELAPSED_TIME: FlxStringUtil.formatTime(time * 0.001);
                default: FlxStringUtil.formatTime((length - time) * 0.001); // = LEFT_TIME
            }

            timeDisplay.text = "- " + base + " -";
        }
    }

    public inline function updateScoreText():Void {
        if (!game.playerStrumline.cpu) {
            var rank:String = game.rank;
            var text:String = 'Score: ${game.score}' + scoreDivider + 'Misses: ${game.misses}' + scoreDivider + 'Accuracy: ${game.accuracyDisplay}%';
            if (rank?.length > 0) text += scoreDivider + rank;
            scoreText.text = text;
        }
        else scoreText.text = "[ BOTPLAY ]";
    }

    public inline function repositionUI(downscroll:Bool = false):Void {
        healthBar.y = FlxG.height * ((downscroll) ? 0.1 : 0.875);
        scoreText.y = healthBar.y + 50;

        iconP1.y = healthBar.y - (iconP1.height * 0.5);
        iconP2.y = healthBar.y - (iconP2.height * 0.5);

        if (timeDisplay != null)
            timeDisplay.y = (downscroll ? FlxG.height * 0.95 : 25);
    }

    public inline function onSongStart():Void {
        if (timeDisplay == null) return;

        timeDisplay.alpha = 0;
        FlxTween.tween(timeDisplay, {alpha: 1}, 0.35);
    }

    public inline function beatHit():Void {
        iconP1.bop();
        iconP2.bop();
    }

    override function destroy():Void {
        scoreDivider = null;
        super.destroy();
    }
}
