package funkin;

import flixel.FlxSubState;
import funkin.core.scripting.ScriptableState;

/**
 * This object dispatches the following event(s):
 * - `Events.STEP_HIT`
 * - `Events.BEAT_HIT`
 * - `Events.MEASURE_HIT`
 */
class MusicBeatState extends ScriptableState {
    public var conductor(default, set):Conductor;
    public var controls:Controls = Controls.global;

    override function create():Void {
        super.create();
        conductor = Conductor.self;
    }

    override function onSubStateOpen(subState:FlxSubState):Void {
        if (conductor == null) return;
        conductor.active = false;
    }

    override function onSubStateClose(subState:FlxSubState):Void {
        if (conductor == null) return;
        conductor.active = true;
    }

    override function destroy():Void {
        controls = null;
        conductor = null;
        super.destroy();
    }

    public function stepHit(step:Int):Void {
        dispatchEvent(Events.STEP_HIT, step);
    }

    public function beatHit(beat:Int):Void {
        dispatchEvent(Events.BEAT_HIT, beat);
    }

    public function measureHit(measure:Int):Void {
        dispatchEvent(Events.MEASURE_HIT, measure);
    }

    function set_conductor(v:Conductor):Conductor {
        if (conductor != null) {
            conductor.onStep.remove(stepHit);
            conductor.onMeasure.remove(measureHit);
            conductor.onBeat.remove(beatHit);

            /*
            #if FLX_DEBUG
            unregisterFromDebugger(conductor);
            #end
            */
        }

        if (v != null) {
            v.onStep.add(stepHit);
            v.onMeasure.add(measureHit);
            v.onBeat.add(beatHit);

            /*
            #if FLX_DEBUG
            registerToDebugger(v);
            #end
            */
        }

        return conductor = v;
    }

    // these negatively affects performance and memory usage a lot...
    /*
    #if FLX_DEBUG
    inline function registerToDebugger(conductor:Conductor):Void {
        FlxG.watch.add(conductor, "time", "C. Time");
        FlxG.watch.add(conductor, "bpm", "BPM");
        FlxG.watch.addFunction("Time Signature", conductor.getSignature);
        FlxG.watch.add(conductor, "step", "Step");
        FlxG.watch.add(conductor, "beat", "Beat");
        FlxG.watch.add(conductor, "measure", "Measure");
    }

    inline function unregisterFromDebugger(conductor:Conductor):Void {
        FlxG.watch.remove(conductor, "time");
        FlxG.watch.remove(conductor, "bpm");
        FlxG.watch.removeFunction("Time Signature");
        FlxG.watch.remove(conductor, "step");
        FlxG.watch.remove(conductor, "beat");
        FlxG.watch.remove(conductor, "measure");
    }
    #end
    */
    //
}

/**
 * This object dispatches the following event(s):
 * - `Events.STEP_HIT`
 * - `Events.BEAT_HIT`
 * - `Events.MEASURE_HIT`
 */
class MusicBeatSubState extends ScriptableSubState {
    public var conductor(default, set):Conductor;
    public var controls:Controls = Controls.global;

    public function new():Void {
        super();
        conductor = Conductor.self;
    }

    public function stepHit(step:Int):Void {
        dispatchEvent(Events.STEP_HIT, step);
    }

    public function beatHit(beat:Int):Void {
        dispatchEvent(Events.BEAT_HIT, beat);
    }

    public function measureHit(measure:Int):Void {
        dispatchEvent(Events.MEASURE_HIT, measure);
    }

    override public function destroy():Void {
        controls = null;
        conductor = null;
        super.destroy();
    }
    
    function set_conductor(v:Conductor):Conductor {
        if (conductor != null) {
            conductor.onStep.remove(stepHit);
            conductor.onMeasure.remove(measureHit);
            conductor.onBeat.remove(beatHit);
        }

        if (v != null) {
            v.onStep.add(stepHit);
            v.onMeasure.add(measureHit);
            v.onBeat.add(beatHit);
        }

        return conductor = v;
    }
}
