package funkin.gameplay.notes;

import flixel.math.FlxRect;
import funkin.objects.OffsetSprite;
import funkin.data.ChartFormat.ChartNote;
import funkin.data.NoteSkin;

/**
 * Sprite object which represents a gameplay note.
 */
class Note extends OffsetSprite {
    /**
     * List of builtin notetypes.
     */
    public static final defaultTypes:Array<String> = ["Alt Animation"];

    /**
     * Array containing each note direction as a string.
     */
    public static final directions:Array<String> = ["left", "down", "up", "right"];

    /**
     * Determines how much early or late a note can be hit.
     */
    public static var hitRegion(get, never):Float;

    /**
     * Determines how much pixels a millisecond represents.
     */
    public static var pixelPerMs(get, never):Float;

    static function get_hitRegion():Float
        return 180 * Conductor.self.rate;

    static function get_pixelPerMs():Float
        return 0.45 / Conductor.self.rate;

    /**
     * Position of this note in the song.
     */
    public var time:Float = 0;

    /**
     * Determines this note's direction, ranging from 0 to 3 by default.
     */
    public var direction:Int = 0;

    /**
     * Hold length of this note.
     */
    public var length(default, set):Float = 0;

    /**
     * Notetype of this note.
     */
    public var type(default, set):String;

    /**
     * Noteskin of this note.
     */
    public var skin(default, set):String;

    /**
     * Represents this note's current state.
     */
    public var state(default, set):NoteState;

    /**
     * Determines whether this note has been hit, based on `state`.
     */
    public var beenHit(get, never):Bool;

    /**
     * Determines whether this note has been missed, based on `state`.
     */
    public var missed(get, never):Bool;

    /**
     * Determines whether we should no longer hold this note.
     */
    public var finishedHold:Bool = false;

    /**
     * Determines the amount of health gained each second by holding this note.
     */
    public var holdHealth:Float;

    /**
     * Stores the elapsed time since this note hasn't been held.
     * The hold note is invalidated if this exceeds 1 second.
     */
    public var unheldTime:Float;

    /**
     * Child sustain for this note, if it is holdable.
     */
    public var sustain(default, set):Sustain;
    
    /**
     * Determines the opacity of the sustain trail.
     */
    public var sustainAlpha:Float = 1;

    /**
     * Defines this note's parent strumline.
     */
    public var strumLine(default, set):StrumLine;
    
    /**
     * Defines the receptor this note should visually follow.
     */
    public var targetReceptor:Receptor;

    /**
     * Determines whether this note should be killed if it is extremely late.
     */
    public var lateKill:Bool = true;

    /**
     * Suffix to append when playing character animations.
     */
    public var animSuffix:String;

    /**
     * Creates a new `Note`.
     * @param time Initial time.
     * @param direction Initial direction.
     * @param type Initial type.
     * @param skin Initial noteskin.
     */
    public function new(time:Float = 0, direction:Int = 0, type:String = null, skin:String = "default"):Void {
        super();

        this.time = time;
        this.direction = direction;
        this.type = type;
        this.skin = skin;
    }

    /**
     * Setups this note from a `ChartNote`.
     * @param data `ChartNote` entry
     * @return `this`
     */
    public inline function setupData(data:ChartNote):Note {
        return setup(data.time, data.direction, data.length, data.type);
    }

    /**
     * Reset this note's properties, making it ready to use for recycling.
     * @param time Time for this note.
     * @param direction Direction for this note.
     * @param length Hold length for this note.
     * @param type Note type for this note.
     * @return `this`
     */
    public function setup(time:Float, direction:Int, length:Float, type:String):Note {
        this.time = time + Options.noteOffset;
        this.direction = direction;
        this.length = length;
        this.type = type;

        state = NONE;
        visible = true;

        finishedHold = false;
        unheldTime = 0;
        holdHealth = 0;
        alpha = 1;

        playAnimation(directions[direction], true);
        updateHitbox();
        
        return this;
    }

    /**
     * Returns whether the note is valid to be hit.
     * @return Bool
     */
    public inline function isHittable():Bool {
        return state == NONE && ((strumLine.cpu && time <= Conductor.self.time) || (!strumLine.cpu && Math.abs(time - Conductor.self.time) <= hitRegion));
    }

    /**
     * Returns whether the note is late.
     * @return Bool
     */
    public inline function isLate():Bool {
        return Conductor.self.time > (time + hitRegion);
    }

    /**
     * Returns whether this note can be held.
     * @return Bool
     */
    public inline function isHoldable():Bool {
        return length > 0;
    }

    /**
     * Returns whether this note is invalidated, meaning it can no longer be held.
     * @return Bool
     */
    public inline function isHoldWindowLate():Bool {
        return unheldTime > 1;
    }

    /**
     * Update behaviour.
     */
    override function update(elapsed:Float):Void {
        this.y = targetReceptor.y + (time - Conductor.self.time) * (strumLine.downscroll ? -1 : 1) * strumLine.scrollSpeed * pixelPerMs;

        if (isHoldable() && sustain.exists && sustain.active)
            sustain.update(elapsed);

        if (animation.curAnim.frameRate > 0 && animation.curAnim.frames.length > 1)
            animation.update(elapsed);

        #if FLX_DEBUG
        FlxBasic.activeCount++;
        #end
    }

    /**
     * Kills this `Note` for recycling.
     */
    override function kill():Void {
        if (sustain != null) {
            sustain.kill();
            sustain = null;
        }

        super.kill();
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        strumLine = null;
        sustain = null;
        skin = null;
        type = null;

        super.destroy();
    }

    // Getters and setters

    function set_length(v:Float):Float {
        return length = Math.max(v, 0);
    }

    function set_sustain(v:Sustain):Sustain {
        if (v != null)
            v.parent = this;

        return sustain = v;
    }

    function set_type(v:String):String {
        // reset notetype properties
        animSuffix = null;
        lateKill = true;

        if (v != null) {
            switch (v) {
                case "Alt Animation":
                    animSuffix = "-alt";
            }
        }

        return type = v;
    }

    function set_skin(v:String):String {
        if (v != null) {
            switch (v) {
                case "default":
                    // default noteskin
                    frames = Paths.atlas("game/notes");

                    for (dir in directions) {
                        animation.addByPrefix(dir, '${dir}0', 0);
                        animation.addByPrefix(dir + " hold", '${dir} hold piece', 0);
                        animation.addByPrefix(dir + " tail", '${dir} hold end', 0);
                    }

                    playAnimation(directions[direction], true);

                    scale.set(0.7, 0.7);
                    updateHitbox();

                    // make sure to reset some props for noteskin swapping.
                    antialiasing = FlxSprite.defaultAntialiasing;
                    flipX = flipY = false;
                    sustainAlpha = 1;
                default:
                    // softcoded noteskin
                    var config:NoteSkinConfig = NoteSkin.get(v);
                    if (config == null || config.note == null)
                        return set_skin("default");

                    var dir:String = directions[direction];
                    NoteSkin.applyGenericSkin(this, config.note, dir, dir);
                    sustainAlpha = config.note.sustainAlpha ?? 1;
            }
        }

        return skin = v;
    }

    function set_state(v:NoteState):NoteState {
        switch (v) {
            case BEEN_HIT:
                if (sustain != null && sustain.clipRegion == null)
                    sustain.clipRegion = FlxRect.get(0, 0, sustain.width, sustain.height);
            
            case _:
        }

        return state = v;
    }

    function set_strumLine(v:StrumLine):StrumLine {
        targetReceptor = v?.getReceptor(direction);
        x = targetReceptor?.x;
        return strumLine = v;
    }

    inline function get_beenHit():Bool {
        return state == BEEN_HIT;
    }

    inline function get_missed():Bool {
        return state == MISSED;
    }
}

/**
 * Represents a note's state.
 */
enum abstract NoteState(Int) from Int to Int {
    /**
     * The note is still hittable.
     */
    var NONE = -1;

    /**
     * The note has been hit.
     */
    var BEEN_HIT;

    /**
     * The note has been missed.
     */
    var MISSED;
}
