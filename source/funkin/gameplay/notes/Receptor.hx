package funkin.gameplay.notes;

import funkin.data.NoteSkin;
import funkin.objects.OffsetSprite;

/**
 * Receptor object.
 */
class Receptor extends OffsetSprite {
    /**
     * Direction for this receptor.
     */
    public var direction:Int = 0;

    /**
     * Noteskin for this receptor.
     */
    public var skin(default, set):String;

    /**
     * Parent strumline.
     */
    public var strumLine:StrumLine;

    /**
     * Current animation hold time.
     */
    public var holdTime:Float = -1;

    /**
     * Creates a new `Receptor`.
     * @param direction Direction for this receptor.
     * @param skin Noteskin for this receptor.
     */
    public function new(direction:Int = 0, skin:String = "default"):Void {
        super();

        this.direction = direction;
        this.skin = skin;

        animation.onFinish.add(onAnimationFinished);
    }

    /**
     * Update behaviour.
     */
    override function update(elapsed:Float):Void {
        if (holdTime >= 0) {
            holdTime -= elapsed;
            if (holdTime < 0)
                finishHolding();
        }

        animation.update(elapsed);

        #if FLX_DEBUG
        FlxBasic.activeCount++;
        #end
    }

    /**
     * Plays an animation.
     * @param name Animation name.
     * @param force Whether to force the animation to be played.
     * @param reversed Whether to play the animation backward.
     * @param frame Start frame.
     */
    override function playAnimation(name:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void {
        super.playAnimation(name + " " + Note.directions[direction], force, reversed, frame);
        centerOffsets();
        centerOrigin();

        this.active = (animation.curAnim.frameRate > 0 && animation.curAnim.frames.length > 1);
        holdTime = -1;
    }

    /**
     * Method called when an animation finishes.
     */
    function onAnimationFinished(name:String):Void {
        if (!name.startsWith("confirm"))
            return;

        holdTime = (strumLine.cpu ? 0.05 : 0.125);
    }

    /**
     * Method called once this receptor is done holding.
     */
    function finishHolding():Void {
        playAnimation(strumLine.heldKeys[direction] ? "press" : "static", true);
        holdTime = -1;
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        skin = null;
        strumLine = null;
        super.destroy();
    }

    function set_skin(v:String):String {
        if (v != null) {
            switch (v) {
                case "default":
                    // default noteskin
                    frames = Paths.atlas("game/notes");

                    var dir:String = Note.directions[direction];
                    animation.addByPrefix("static " + dir, '${dir} static', 24, false);
                    animation.addByPrefix("confirm " + dir, '${dir} confirm', 24, false);
                    animation.addByPrefix("press " + dir, '${dir} press', 24, false);

                    playAnimation("static", true);
                    scale.set(0.7, 0.7);
                    updateHitbox();
                    centerOffsets();

                    antialiasing = FlxSprite.defaultAntialiasing;
                    flipX = flipY = false;
                default:
                    // softcoded noteskin
                    var config:NoteSkinConfig = NoteSkin.get(v);
                    if (config == null || config.receptor == null)
                        return set_skin("default");

                    var skinData:ReceptorConfig = config.receptor;
                    var dir:String = Note.directions[direction];

                    NoteSkin.applyGenericSkin(this, skinData, "static", dir);
            }
        }

        return skin = v;
    }
}
