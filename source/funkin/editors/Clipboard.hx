package funkin.editors;

class Clipboard<V> extends FlxBasic {
    var items:Array<V> = [];

    public function new():Void {
        super();
        active = visible = false;
    }

    public function register(item:V):Void {
        items.push(item);
    }

    public function clear():Void {
        items.splice(0, items.length);
    }

    public function get():Array<V> {
        return items.copy();
    }

    override function destroy():Void {
        items = null;
        super.destroy();
    }
}
