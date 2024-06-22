package funkin.editors;

import flixel.FlxBasic;

// extend flxbasic so it's automatically destroyed
class UndoList<V> extends FlxBasic {
    // cap to avoid array overflowing
    static var max:Int = 250;

    var undos:Array<V> = [];
    var redos:Array<V> = [];

    public function new():Void {
        super();
        active = visible = false;
    }

    public function register(entry:V):Void {
        undos.push(entry);
        filter(undos);
    }

    public function undo():V {
        var undo:V = undos.pop();
        if (undo != null) {
            redos.push(undo);
            filter(redos);
        }   
        return undo;
    }

    public function redo():V {
        var redo:V = redos.pop();
        if (redo != null) register(redo);
        return redo;
    }

    public function clear():Void {
        undos.splice(0, undos.length);
        redos.splice(0, redos.length);
    }

    inline function filter(arr:Array<V>):Void {
        while (arr.length > max) arr.shift();
    }

    override function destroy():Void {
        undos = null;
        redos = null;
        super.destroy();
    }
}
