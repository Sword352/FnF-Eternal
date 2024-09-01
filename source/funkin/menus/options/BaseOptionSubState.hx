package funkin.menus.options;

import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.menus.options.items.BaseOptionItem;

class BaseOptionSubState extends MusicBeatSubState {
    var optionsGroup:FlxTypedGroup<BaseOptionItem<Any>>;
    var currentSelection:Int = 0;
    var count:Int = 0;

    public function new():Void {
        super();
        optionsGroup = new FlxTypedGroup<BaseOptionItem<Any>>();
    }

    public function addOption(option:BaseOptionItem<Any>):Void {
        optionsGroup.add(option);
        option.ID = count++;
    }

    override function create():Void {
        super.create();

        initStateScripts();
        scripts.call("onCreate");

        add(optionsGroup);
        changeSelection();

        scripts.call("onCreatePost");
    }

    override function update(elapsed:Float):Void {
        scripts.call("onUpdate", elapsed);
        superUpdate(elapsed);
        scripts.call("onUpdatePost", elapsed);
    }

    function superUpdate(elapsed:Float):Void {
        super.update(elapsed);

        if (optionsGroup.length > 1 && controls.anyJustPressed(["up", "down"]))
            changeSelection((controls.lastAction == "up") ? -1 : 1);

        if (controls.justPressed("back"))
            leave();
    }

    function changeSelection(i:Int = 0):Void {
        currentSelection = FlxMath.wrap(currentSelection + i, 0, optionsGroup.length - 1);

        for (item in optionsGroup) {
            item.alpha = (item.ID == currentSelection) ? 1 : 0.6;
            item.target = item.ID - currentSelection;
        }

        if (i != 0)
            FlxG.sound.play(Assets.sound("scrollMenu"));
    }

    inline function leave():Void {
        FlxG.sound.play(Assets.sound("cancelMenu"));
        OptionsManager.save();
        close();
    }
}
