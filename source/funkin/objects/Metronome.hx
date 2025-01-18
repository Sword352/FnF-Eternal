package funkin.objects;

import flixel.sound.FlxSound;

/**
 * A "tick" sound repeating each beat.
 */
class Metronome extends FlxSound {
    /**
     * Conductor this `Metronome` will listen to.
     */
    public var conductor:Conductor = Conductor.self;

    /**
     * After how many beats this `Metronome` repeats.
     */
    public var frequency:Float = 1;

    /**
     * Holds the last passed beat.
     */
    public var lastBeat:Int = 0;

    /**
     * Creates a new `Metronome` instance.
     */
    public function new():Void {
        super();
        loadEmbedded(Paths.sound("editors/metronome"));
        active = true;
    }

    override function update(elapsed:Float):Void {
        var beat:Int = Math.floor(conductor.getBeatAt(conductor.audioTime) / frequency);

        if (beat != lastBeat) {
            lastBeat = beat;
            play(true);
        }

        #if FLX_DEBUG
        FlxBasic.activeCount++;
        #end
    }

    override function stopped(?_):Void {
        var wasActive:Bool = active;
        super.stopped(_);
        active = wasActive;
    }

    override function set_volume(v:Float):Float {
        active = (v > 0);
        return super.set_volume(v);
    }
}
