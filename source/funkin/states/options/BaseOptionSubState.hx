package funkin.states.options;

import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.objects.options.BaseOptionItem;

class BaseOptionSubState extends MusicBeatSubState {
    var optionsGroup:FlxTypedGroup<BaseOptionItem<Any>>;
    var currentSelection:Int = 0;

    var allowInputs:Bool = true;

    public function new():Void {
        super();
        optionsGroup = new FlxTypedGroup<BaseOptionItem<Any>>();
    }

    public function addOption(option:BaseOptionItem<Any>):Void {
        optionsGroup.add(option);
        option.ID = optionsGroup.members.indexOf(option);
    }

    override function create():Void {
        super.create();

        #if ENGINE_SCRIPTING
        initStateScript();
        hxsCall("onCreate");
        #end

        add(optionsGroup);
        changeSelection();

        #if ENGINE_SCRIPTING
        hxsCall("onCreatePost");
        #end
    }

    override function update(elapsed:Float):Void {
        #if ENGINE_SCRIPTING
        hxsCall("onUpdate", [elapsed]);
        #end

        super.update(elapsed);

        if (allowInputs && optionsGroup.length > 1 && controls.anyJustPressed(["up", "down"]))
            changeSelection((controls.lastAction == "up") ? -1 : 1);

        if (allowInputs && controls.justPressed("back")) {
            allowInputs = false;
            close();
        }

        #if ENGINE_SCRIPTING
        hxsCall("onUpdatePost", [elapsed]);
        #end
    }

    private function changeSelection(i:Int = 0):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onSelectionChange", [i]))
            return;
        #end

        currentSelection = FlxMath.wrap(currentSelection + i, 0, optionsGroup.length - 1);

        for (item in optionsGroup) {
            item.target = optionsGroup.members.indexOf(item) - currentSelection;
            item.alpha = (item.ID == currentSelection) ? 1 : 0.6;
        }

        if (i != 0)
            FlxG.sound.play(Assets.sound("scrollMenu"));

        #if ENGINE_SCRIPTING
        hxsCall("onSelectionChangePost", [i]);
        #end
    }

    override function close():Void {
        Settings.save();
        super.close();
    }
}