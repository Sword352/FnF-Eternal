package eternal.ui;

import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup.FlxSpriteGroup;

import haxe.ui.components.NumberStepper;
import funkin.states.debug.ChartEditor.DebugNote;

class NoteViewer extends FlxSpriteGroup {
    public var noteToView:DebugNote;

    var container:FlxSprite;
    var note:FlxSprite;
    var infos:FlxText;

    var lengthStepper:NumberStepper;
    var _ignoreStepperCallback:Bool = true;

    public function new(x:Float = 0, y:Float = 0):Void {
        super(x, y);

        container = new FlxSprite();
        container.loadGraphic(AssetHelper.image("ui/debug/noteView"));
        container.alpha = 0.6;
        add(container);

        note = new FlxSprite();
        note.loadGraphic(AssetHelper.image("ui/debug/NoteGrid"), true, 161, 161);
        note.animation.add("note", [0, 1, 2, 3], 0);
        note.animation.play("note", true);

        note.scale.set(0.75, 0.75);
        note.updateHitbox();

        note.setPosition((container.width - note.width) * 0.5, container.height * 0.20);
        add(note);

        infos = new FlxText(container.width * 0.25, container.height * 0.45);
        infos.setFormat(AssetHelper.font("vcr"), 12, FlxColor.BLACK);
        add(infos);

        lengthStepper = new NumberStepper();
        lengthStepper.customStyle.fontName = AssetHelper.font("vcr");
        lengthStepper.customStyle.color = FlxColor.BLACK;
        lengthStepper.customStyle.fontSize = 12;

        lengthStepper.autoCorrect = true;
        lengthStepper.min = 0;

        lengthStepper.onChange = (_) -> {
            if (_ignoreStepperCallback)
                return;

            noteToView.length = lengthStepper.pos;
            noteToView.data.length = Conductor.stepCrochet * noteToView.length;
        }

        lengthStepper.left = infos.x;
        lengthStepper.top = infos.y + 50;

        // workaround to fix the stepper being funky (temporary)
        FlxG.state.memberAdded.add(addStepper);

        view(null);
    }

    override function update(elapsed:Float):Void {
        infos.text = 
        'Direction: ${noteToView.data.direction}\n'
        + 'Strumline: ${noteToView.data.strumline}\n'
        + 'Length: ${noteToView.data.length}'
        ;
    }

    public function view(note:DebugNote):Void {
        lengthStepper.hidden   = (note == null);
        lengthStepper.disabled = (note == null);
        lengthStepper.active   = (note != null);
        visible = active       = (note != null);

        noteToView = note;
        if (note == null)
            return;

        this.note.animation.curAnim.curFrame = noteToView.data.direction;

        _ignoreStepperCallback = true;
        lengthStepper.pos = noteToView.length;
        _ignoreStepperCallback = false;
    }

    override function destroy():Void {
        // FlxG.state.remove(lengthStepper, true);
        lengthStepper = FlxDestroyUtil.destroy(lengthStepper);
        super.destroy();
    }

    private function addStepper(obj:flixel.FlxBasic):Void {
        if (obj != this)
            return;

        FlxG.state.insert(FlxG.state.members.indexOf(this) + 1, lengthStepper);
        FlxG.state.memberAdded.remove(addStepper);
    }
}