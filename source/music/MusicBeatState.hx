package music;

#if !ENGINE_SCRIPTING
import flixel.FlxSubState as SubState;
import states.TransitionState as State;
#else
import core.scripting.ScriptableState as State;
import core.scripting.ScriptableState.ScriptableSubState as SubState;
#end

class MusicBeatState extends State {
    public var conductor(default, set):Conductor;
    public var controls:Controls = Controls.global;

    override function create():Void {
        super.create();
        conductor = Conductor.self;
    }

    override function openSubState(subState:flixel.FlxSubState):Void {
        if (conductor != null)
            conductor.active = (subState is TransitionSubState && !Transition.noPersistentUpdate);

        super.openSubState(subState);
    }

    override function closeSubState():Void {
        if (conductor != null)
            conductor.active = true;

        super.closeSubState();
    }

    override function destroy():Void {
        controls = null;
        conductor = null;
        super.destroy();
    }

    #if ENGINE_SCRIPTING
    public function stepHit(step:Int):Void        hxsCall("onStepHit", [step]);
    public function beatHit(beat:Int):Void        hxsCall("onBeatHit", [beat]);
    public function measureHit(measure:Int):Void  hxsCall("onMeasureHit", [measure]);
    #else
    public function stepHit(step:Int):Void {}
    public function beatHit(beat:Int):Void {}
    public function measureHit(measure:Int):Void {}
    #end

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

class MusicBeatSubState extends SubState {
    public var conductor(default, set):Conductor;
    public var controls:Controls = Controls.global;

    public function new():Void {
        super();
        conductor = Conductor.self;
    }

    #if ENGINE_SCRIPTING
    public function stepHit(step:Int):Void        hxsCall("onStepHit", [step]);
    public function beatHit(beat:Int):Void        hxsCall("onBeatHit", [beat]);
    public function measureHit(measure:Int):Void  hxsCall("onMeasureHit", [measure]);
    #else
    public function stepHit(step:Int):Void {}
    public function beatHit(beat:Int):Void {}
    public function measureHit(measure:Int):Void {}
    #end

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
