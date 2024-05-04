package funkin.states.options.items;

class IntOptionItem extends BaseOptionItem<Int> {
    public var minValue:Null<Int> = null;
    public var maxValue:Null<Int> = null;
    public var steps:Int = 1;

    var value:Int;

    public function new(title:String, ?optionField:String):Void {
        super(title, optionField);

        value = Reflect.getProperty(Options, option);
        updateText();
    }

    override function updateValue(mult:Int) {
        value += steps * mult;

        if (minValue != null && maxValue != null)
            value = FlxMath.wrap(value, minValue, maxValue);

        saveValue(value);
    }

    override function updateText():Void {
        valueText.text = Std.string(value);
        repositionValueText();
    }
}
