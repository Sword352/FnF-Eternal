package funkin.objects.options;

class FloatOptionItem extends BaseOptionItem<Float> {
    public var maxValue:Null<Float> = null;
    public var minValue:Null<Float> = null;

    public var precision:Int = 2;
    public var steps:Float = 1;

    var value:Float;

    public function new(option:String):Void {
        super(option);

        value = Settings.get(option);
        updateText();
    }

    override function updateValue(mult:Int) {
        value += steps * mult;

        if (minValue != null && maxValue != null) {
            if (value > maxValue)
                value = minValue;
            else if (value < minValue)
                value = maxValue;
        }

        value = FlxMath.roundDecimal(value, precision);
        saveValue(value);
    }

    override function updateText():Void {
        valueText.text = Std.string(value);
        repositionValueText();
    }
}