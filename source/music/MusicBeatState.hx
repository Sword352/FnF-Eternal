package music;

import flixel.FlxSubState;
import core.scripting.ScriptableState;

class MusicBeatState extends ScriptableState {
    public var conductor(default, set):Conductor;
    public var controls:Controls = Controls.global;

    override function create():Void {
        super.create();
        conductor = Conductor.self;
    }

    override function onSubStateOpen(subState:FlxSubState):Void {
        if (conductor != null)
            conductor.active = (subState is TransitionSubState && !Transition.noPersistentUpdate);

        super.onSubStateOpen(subState);
    }

    override function onSubStateClose(subState:FlxSubState):Void {
        if (conductor != null)
            conductor.active = true;

        super.onSubStateClose(subState);
    }

    override function destroy():Void {
        controls = null;
        conductor = null;
        super.destroy();
    }

    public function stepHit(step:Int):Void {
        scripts.call("onStepHit", [step]);
    }

    public function beatHit(beat:Int):Void {
        scripts.call("onBeatHit", [beat]);
    }

    public function measureHit(measure:Int):Void {
        scripts.call("onMeasureHit", [measure]);
    }

    function set_conductor(v:Conductor):Conductor {
        if (conductor != null) {
            conductor.onStep.remove(stepHit);
            conductor.onMeasure.remove(measureHit);
            conductor.onBeat.remove(beatHit);

            #if FLX_DEBUG
            unregisterFromDebugger(conductor);
            #end
        }

        if (v != null) {
            v.onStep.add(stepHit);
            v.onMeasure.add(measureHit);
            v.onBeat.add(beatHit);

            #if FLX_DEBUG
            registerToDebugger(v);
            #end
        }

        return conductor = v;
    }

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
}

class MusicBeatSubState extends ScriptableSubState {
    public var conductor(default, set):Conductor;
    public var controls:Controls = Controls.global;

    public function new():Void {
        super();
        conductor = Conductor.self;
    }

    public function stepHit(step:Int):Void {
        scripts.call("onStepHit", [step]);
    }

    public function beatHit(beat:Int):Void {
        scripts.call("onBeatHit", [beat]);
    }

    public function measureHit(measure:Int):Void {
        scripts.call("onMeasureHit", [measure]);
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
