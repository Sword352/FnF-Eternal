package funkin.states.options;

import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.objects.options.BaseOptionItem;

class BaseOptionSubState extends MusicBeatSubState {
    var optionsGroup:FlxTypedGroup<BaseOptionItem<Any>>;
    var currentSelection:Int = 0;

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

        if (optionsGroup.length > 1 && controls.anyJustPressed(["up", "down"])) changeSelection((controls.lastAction == "up") ? -1 : 1);
        if (controls.justPressed("back")) leave();

        #if ENGINE_SCRIPTING
        hxsCall("onUpdatePost", [elapsed]);
        #end
    }

    function changeSelection(i:Int = 0):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onSelectionChange", [i]))
            return;
        #end

        currentSelection = FlxMath.wrap(currentSelection + i, 0, optionsGroup.length - 1);

        for (item in optionsGroup) {
            item.alpha = (item.ID == currentSelection) ? 1 : 0.6;
            item.target = item.ID - currentSelection;
        }

        if (i != 0)
            FlxG.sound.play(Assets.sound("scrollMenu"));

        #if ENGINE_SCRIPTING
        hxsCall("onSelectionChangePost", [i]);
        #end
    }

    inline function leave():Void {
        FlxG.sound.play(Assets.sound("cancelMenu"));
        Settings.save();
        close();
    }
}
