package states.editors.chart;

import globals.ChartFormat;

enum ChartUndos {
    AddNote(data:ChartNote);
    RemoveNote(data:ChartNote);
    AddEvent(data:ChartEvent);
    RemoveEvent(data:ChartEvent);
    
    CopyObjects(notes:Array<ChartNote>, events:Array<ChartEvent>);
    RemoveObjects(notes:Array<ChartNote>, events:Array<ChartEvent>);
    ObjectDrag(notes:Array<NoteDragData>, events:Array<EventDragData>);
}

@:structInit class NoteDragData {
    public var ref:ChartNote;

    public var oldTime:Float;
    public var oldDir:Int;
    public var oldStl:Int;

    public var time:Float;
    public var dir:Int;
    public var str:Int;
}

@:structInit class EventDragData {
    public var ref:ChartEvent;
    public var oldTime:Float;
    public var time:Float;
}
