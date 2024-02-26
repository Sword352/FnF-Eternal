package eternal.core.scripting;

class CancellableCall {
    public var cancelled:Bool = false;

    public function new():Void {}

    public function cancel():Void
        cancelled = true;
}