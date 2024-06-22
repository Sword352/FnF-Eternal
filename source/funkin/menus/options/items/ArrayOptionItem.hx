package funkin.menus.options.items;

class ArrayOptionItem<V> extends BaseOptionItem<Array<V>> {
    public var list:Array<V>;
    var currentSelection:Int = 0;

    public function new(title:String, list:Array<V>, ?optionField:String):Void {
        super(title, optionField);

        this.list = list;
        currentSelection = list.indexOf(Reflect.getProperty(Options, option));
        updateText();   
    }

    override function updateValue(mult:Int):Void {
        currentSelection = FlxMath.wrap(currentSelection + mult, 0, list.length - 1);
        saveValue(list[currentSelection]);
    }

    override function updateText():Void {
        valueText.text = Tools.capitalize(Std.string(list[currentSelection]));
        repositionValueText();
    }

    override function destroy():Void {
        list = null;
        super.destroy();
    }
}
