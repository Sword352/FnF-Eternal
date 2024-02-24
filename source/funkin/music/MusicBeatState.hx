package funkin.music;

#if !ENGINE_SCRIPTING
import flixel.FlxSubState as SubState;
import funkin.states.TransitionState as State;
#else
import eternal.core.scripting.ScriptableState as State;
import eternal.core.scripting.ScriptableState.ScriptableSubState as SubState;
#end

class MusicBeatState extends State {
    var controls:Controls = Controls.globalControls;
    var activeConductor:Bool = true;

    override function create():Void {
        super.create();

        Conductor.onStep.add(stepHit);
        Conductor.onBeat.add(beatHit);
        Conductor.onMeasure.add(measureHit);

        #if debug
        // for debugging
        FlxG.watch.add(Conductor, "time", "C. Time");
        FlxG.watch.add(Conductor, "bpm", "BPM");
        FlxG.watch.addFunction("Time Signature", Conductor.getSignature);
        FlxG.watch.add(Conductor, "currentStep", "Current Step");
        FlxG.watch.add(Conductor, "currentBeat", "Current Beat");
        FlxG.watch.add(Conductor, "currentMeasure", "Current Measure");
        #end
    }

    override public function update(elapsed:Float):Void {
        if (activeConductor)
            updateConductor(elapsed);
        
        super.update(elapsed);
    }

    public function updateConductor(elapsed:Float):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onConductorUpdate", [elapsed]))
            return;
        #end

        Conductor.update(elapsed);
        
        #if ENGINE_SCRIPTING
        hxsCall("onConductorUpdatePost", [elapsed]);
        #end
    }

    public override function destroy():Void {
        #if debug
        FlxG.watch.remove(Conductor, "time");
        FlxG.watch.remove(Conductor, "bpm");
        FlxG.watch.removeFunction("Time Signature");
        FlxG.watch.remove(Conductor, "currentStep");
        FlxG.watch.remove(Conductor, "currentBeat");
        FlxG.watch.remove(Conductor, "currentMeasure");
        #end

        controls = null;

        super.destroy();
        Conductor.reset();
    }

    #if ENGINE_SCRIPTING
    public function stepHit(currentStep:Int):Void
        hxsCall("onStepHit", [currentStep]);

    public function beatHit(currentBeat:Int):Void
        hxsCall("onBeatHit", [currentBeat]);
    
    public function measureHit(currentMeasure:Int):Void
        hxsCall("onMeasureHit", [currentMeasure]);
    #else
    public function stepHit(currentStep:Int):Void {}
    public function beatHit(currentBeat:Int):Void {}
    public function measureHit(currentMeasure:Int):Void {}
    #end
}

class MusicBeatSubState extends SubState {
    var controls:Controls = Controls.globalControls;
    
    public function new():Void {
        super();

        Conductor.onStep.add(stepHit);
        Conductor.onBeat.add(beatHit);
        Conductor.onMeasure.add(measureHit);
    }

    public function updateConductor(elapsed:Float):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onConductorUpdate", [elapsed]))
            return;
        #end

        Conductor.update(elapsed);
        
        #if ENGINE_SCRIPTING
        hxsCall("onConductorUpdatePost", [elapsed]);
        #end
    }

    #if ENGINE_SCRIPTING
    public function stepHit(currentStep:Int):Void
        hxsCall("onStepHit", [currentStep]);

    public function beatHit(currentBeat:Int):Void
        hxsCall("onBeatHit", [currentBeat]);
    
    public function measureHit(currentMeasure:Int):Void
        hxsCall("onMeasureHit", [currentMeasure]);
    #else
    public function stepHit(currentStep:Int):Void {}
    public function beatHit(currentBeat:Int):Void {}
    public function measureHit(currentMeasure:Int):Void {}
    #end

    override public function destroy():Void {
        Conductor.onStep.remove(stepHit);
        Conductor.onBeat.remove(beatHit);
        Conductor.onMeasure.remove(measureHit);

        controls = null;
        
        super.destroy();
    }
}
