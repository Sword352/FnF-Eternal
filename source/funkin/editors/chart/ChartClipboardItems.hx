package funkin.editors.chart;

enum ChartClipboardItems {
    Note(conductorDiff:Float, direction:Int, strumline:Int, length:Float, type:String);
    Event(event:String, conductorDiff:Float, arguments:Array<Any>);
}
