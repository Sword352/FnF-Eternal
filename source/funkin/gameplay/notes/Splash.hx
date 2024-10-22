package funkin.gameplay.notes;

import funkin.data.NoteSkin;
import funkin.objects.OffsetSprite;

/**
 * Sprite object which displays a splash during gameplay.
 */
class Splash extends OffsetSprite {
    /**
     * Noteskin of this splash.
     */
    public var skin(default, set):String;

    /**
     * Maximum animation variation for this splash sprite.
     */
    public var maxVariation:Int = 2;

    /**
     * Minimum animation rate.
     */
    public var minSpeed:Float = 0.8;

    /**
     * Maximum animation rate.
     */
    public var maxSpeed:Float = 1.2;

    /**
     * Creates a new `Splash`.
     * @param skin Noteskin for this splash.
     */
    public function new(skin:String = "default"):Void {
        super();
        this.skin = skin;

        animation.finishCallback = (_) -> kill();
    }

    override function update(elapsed:Float):Void {
        animation.update(elapsed);

        #if FLX_DEBUG
        FlxBasic.activeCount++;
        #end
    }

    /**
     * Start displaying this note splash.
     * @param direction Direction that should be displayed.
     */
    public function pop(direction:Int):Void {
        var anim:String = Note.directions[direction] + "-" + FlxG.random.int(1, maxVariation);
        animation.timeScale = FlxG.random.float(minSpeed, maxSpeed);

        playAnimation(anim, true);
        updateHitbox();

        offset.set(width * 0.3, height * 0.3);
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        skin = null;
        super.destroy();
    }

    function set_skin(v:String):String {
        if (v != null) {
            switch (v) {
                case "default":
                    // default noteskin
                    frames = Paths.atlas("game/splashes");

                    var animationArray:Array<String> = ["down", "up", "left", "right"];

                    for (i in 0...2) {
                        var index:Int = (i + 1);
                        for (anim in animationArray) {
                            var name:String = '${anim}-${index}';
                            animation.addByPrefix(name, 'splash${index} ${anim}', 24, false);
                        }
                    }

                    antialiasing = FlxSprite.defaultAntialiasing;
                    flipX = flipY = false;

                    maxVariation = 2;
                    minSpeed = 0.8;
                    maxSpeed = 1.2;
                    alpha = 0.6;

                    scale.set(1, 1);
                    pop(0);
                default:
                    // softcoded noteskin
                    var config:NoteSkinConfig = NoteSkin.get(v);
                    if (config == null || config.splash == null)
                        return set_skin("default");

                    var skinData:SplashConfig = config.splash;
                    NoteSkin.applyGenericSkin(this, skinData, "left-1");

                    if (skinData.speedVariation != null) {
                        minSpeed = skinData.speedVariation[0] ?? 0.8;
                        maxSpeed = skinData.speedVariation[1] ?? 1.2;
                    }

                    maxVariation = skinData.maxVariation ?? 2;
                    alpha = skinData.alpha ?? 0.6;
            }

            animation.finish();
        }

        return skin = v;
    }
}
