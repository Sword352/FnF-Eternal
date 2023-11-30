package funkin.objects.stages;

import eternal.ChartFormat.ChartEvent;
import flixel.FlxBasic;
import flixel.FlxState;
    
class BaseStage extends FlxBasic {
    public var state(default, null):FlxState;
    private var storedObjects:Array<FlxBasic> = [];
    
    public function new(state:FlxState):Void {
        super();
        this.state = state;
        create();
    }

    public function create():Void {}
    override function update(elapsed:Float):Void {}
    
    public function createPost():Void {}
    public function updatePost(elapsed:Float):Void {}

    public function stepHit(currentStep:Int):Void {}
    public function beatHit(currentBeat:Int):Void {}
    public function measureHit(currentMeasure:Int):Void {}

    // PlayState related
    public function onSongStart():Void {}
    public function onSongEnd():Void {}
    public function onCountdownTick(loop:Int):Void {}
    public function onEventTrigger(event:ChartEvent):Void {}
    public function onEventPreload(event:ChartEvent):Void {}

    public function add(obj:FlxBasic):FlxBasic {
        state.add(obj);
        if (!storedObjects.contains(obj))
            storedObjects.push(obj);
        return obj;
    }

    public function insert(pos:Int, obj:FlxBasic):FlxBasic {
        state.insert(pos, obj);
        if (!storedObjects.contains(obj))
            storedObjects.push(obj);
        return obj;
    }

    public function remove(obj:FlxBasic, splice:Bool = false):FlxBasic {
        state.remove(obj, splice);
        if (splice && storedObjects.contains(obj))
            storedObjects.remove(obj);
        return obj;
    }

    public function hide():Void {
        if (storedObjects == null)
            return;

        for (obj in storedObjects)
            obj.visible = false;
    }

    public function show():Void {
        if (storedObjects == null)
            return;

        for (obj in storedObjects)
            obj.visible = true;
    }

    public function removeAll():Void {
        if (storedObjects == null)
            return;

        while (storedObjects.length > 0)
            remove(storedObjects.shift(), true);
    }

    public function destroyAll():Void {
        if (storedObjects == null)
            return;

        while (storedObjects.length > 0)
            remove(storedObjects.shift(), true).destroy();
    }
    
    override function kill():Void {
        hide();
        super.kill();
    }

    override function revive():Void {
        super.revive();
        show();
    }
    
    override function destroy():Void {
        destroyAll();
        
        storedObjects = null;
        state = null;

        super.destroy();
    }
}
