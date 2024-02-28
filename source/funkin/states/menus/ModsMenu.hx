package funkin.states.menus;

import flixel.FlxCamera;
import flixel.text.FlxText;
import funkin.objects.sprites.CheckerboardBG;

import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;

import eternal.core.Mods.Mod;

#if ENGINE_MODDING
class ModsMenu extends MusicBeatSubState {
    public var itemGroup:FlxTypedGroup<ModItem>;
    public var exitToTitle:Bool = false;
    public var currentSelection:Int = 0;

    var checkerBackdrop:CheckerboardBG;
    var background:FlxSprite;
    var modText:FlxText;
    var bar:FlxSprite;

    var cam:FlxCamera;
    var allowInputs:Bool = true;

    #if ENGINE_SCRIPTING
    var overrideCode:Bool;
    #end

    override function create():Void {
        Mods.refreshMods();

        if (Mods.mods.length < 1) {
            close();
            return;
        }

        super.create();

        cam = new FlxCamera();
        cam.bgColor = FlxColor.BLACK;
        cam.bgColor.alpha = 0;
        cameras = [cam];
        FlxG.cameras.add(cam);

        #if ENGINE_SCRIPTING
        initStateScript();
        hxsCall("onCreate");

        if (overrideCode) {
            hxsCall("onCreatePost");
            return;
        }
        #end

        background = new FlxSprite();
        background.makeRect(FlxG.width, FlxG.height, FlxColor.BLACK);
        background.alpha = 0.6;
        add(background);

        checkerBackdrop = new CheckerboardBG(200, 200, FlxColor.WHITE, FlxColor.TRANSPARENT);
        checkerBackdrop.velocity.x = 50;
        checkerBackdrop.alpha = 0.15;
        add(checkerBackdrop);

        bar = new FlxSprite();
        bar.makeRect(FlxG.width, 75, FlxColor.BLACK);
        bar.alpha = 0.6;
        add(bar);

        modText = new FlxText();
        modText.setFormat(Assets.font("vcr"), 54, FlxColor.WHITE, CENTER);
        modText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
        updateModText();
        add(modText);

        itemGroup = new FlxTypedGroup<ModItem>();
        add(itemGroup);

        for (mod in Mods.mods) {
            Assets.currentDirectory = '${Mods.MODS_PATH}${mod.folder}/';
            itemGroup.add(new ModItem(mod));
        }

        Assets.currentDirectory = '${Mods.MODS_PATH}${Mods.currentMod.folder}/';

        currentSelection = Mods.mods.indexOf(Mods.currentMod);
        persistentUpdate = true;
        changeSelection();

        #if ENGINE_SCRIPTING
        hxsCall("onCreatePost");
        #end
    }

    override function update(elapsed:Float):Void {
        #if ENGINE_SCRIPTING
        hxsCall("onUpdate", [elapsed]);
        super.update(elapsed);

        if (overrideCode) {
            hxsCall("onUpdatePost", [elapsed]);
            return;
        }
        #else
        super.update(elapsed);
        #end

        if (allowInputs) {
            if (controls.anyJustPressed(["left", "right"]))
                changeSelection((controls.lastAction == "left") ? -1 : 1);

            if (controls.justPressed("accept")) {
                allowInputs = false;
                openSubState(new ModsMenuSubScreen(Mods.mods[currentSelection]));
                persistentUpdate = true;
            }

            if (controls.justPressed("back")) {
                allowInputs = false;
                FlxG.sound.play(Assets.sound("cancelMenu"));

                if (exitToTitle) {
                    Tools.stopMusic();
                    goToTitleScreen();
                }
                else close();
            }
        }

        #if ENGINE_SCRIPTING
        hxsCall("onUpdatePost", [elapsed]);
        #end
    }

    function changeSelection(i:Int = 0):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onSelectionChange", [i]))
            return;
        #end

        if (i != 0)
            FlxG.sound.play(Assets.sound("scrollMenu"));

        currentSelection = FlxMath.wrap(currentSelection + i, 0, Mods.mods.length - 1);
        itemGroup.forEach((i) -> i.target = itemGroup.members.indexOf(i) - currentSelection);

        #if ENGINE_SCRIPTING
        hxsCall("onSelectionChangePost", [i]);
        #end
    }

    inline function goToTitleScreen():Void {
        Transition.skipNextTransIn = Transition.skipNextTransOut = true;
        TitleScreen.firstTime = true;

        camera.fade(FlxColor.BLACK, 0.5, false, () -> {
            FlxG.state.persistentDraw = false;
            FlxG.switchState(TitleScreen.new);
        });
    }

    public function updateModText():Void {
        modText.text = 'CURRENT MOD: ${Mods.currentMod.title}';

        modText.size = 54;
        modText.resizeText();

        modText.y = bar.height / 4;
        modText.screenCenter(X);
    }

    override function closeSubState():Void {
        super.closeSubState();
        allowInputs = true;
    }

    override function destroy():Void {
        super.destroy();

        if (cam != null)
            FlxG.cameras.remove(cam);
    }
}

class ModsMenuSubScreen extends MusicBeatSubState {
    var background:FlxSprite;
    var icon:FlxSprite;

    var modName:FlxText;
    var modDescription:FlxText;

    var licenseText:FlxText;
    var apiText:FlxText;

    var confirmText:FlxText;

    var allowInputs:Bool = false;
    var modReference:Mod;

    #if ENGINE_SCRIPTING
    var overrideCode:Bool;
    #end

    public function new(mod:Mod):Void {
        super();
        this.modReference = mod;
    }

    override function create():Void {
        super.create();

        #if ENGINE_SCRIPTING
        initStateScript();
        hxsCall("onCreate");

        if (overrideCode) {
            hxsCall("onCreatePost");
            return;
        }
        #end

        background = new FlxSprite();
        background.makeRect(FlxG.width, FlxG.height, FlxColor.BLACK);
        background.alpha = 0;
        add(background);

        var sub:ModsMenu = cast _parentState;
        icon = new FlxSprite(20, 20, sub.itemGroup.members[sub.currentSelection].frames.parent);
        icon.alpha = 0;
        add(icon);

        modName = new FlxText();
        modName.setFormat(Assets.font("vcr"), 45);
        modName.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        modName.text = modReference.title;
        modName.setPosition(FlxG.width - modName.width - 90, 50);
        add(modName);

        modDescription = new FlxText();
        modDescription.setFormat(modName.font, 25, FlxColor.WHITE, RIGHT);
        modDescription.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        modDescription.text = modReference.description ?? "No description provided.";
        modDescription.setPosition(FlxG.width - modDescription.width - 90, 150);
        add(modDescription);

        apiText = new FlxText();
        apiText.setFormat(modName.font, 25);
        apiText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        apiText.text = 'API STATUS: ';
        add(apiText);

        var apiStatus:ModApiState = modReference.getApiState();

        if (apiStatus.isOutdated()) {
            apiText.text += '<>${apiStatus.getHandle()}<>\nREQUIRE: ${modReference.apiVersion}';
            apiText.text += '\nHAVE: ${Tools.gameVersion}';
            apiText.text += '\n<>Play at your own risk.<>';
            apiText.applyMarkup(apiText.text, [new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.RED), '<>')]);
        }
        else
            apiText.text += apiStatus.getHandle();

        apiText.setPosition(icon.x + 5, icon.y + icon.height * 1.25);

        licenseText = new FlxText();
        licenseText.setFormat(modName.font, 25);
        licenseText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        licenseText.text = (modReference.license == null) ? "No license" : 'Licensed under: ${modReference.license}';
        licenseText.setPosition(apiText.x, apiText.y + apiText.height);
        add(licenseText);

        confirmText = new FlxText();
        confirmText.setFormat(modName.font, 50);
        confirmText.setBorderStyle(OUTLINE, FlxColor.BLACK, 4);
        confirmText.y = FlxG.height - 100;
        updateConfirmText();
        add(confirmText);

        FlxTween.tween(background, {alpha: 0.6}, 0.25, {onComplete: (_) -> allowInputs = true});
        FlxTween.tween(icon, {alpha: 1}, 0.15);

        #if ENGINE_SCRIPTING
        hxsCall("onCreatePost");
        #end
    }

    override function update(elapsed:Float):Void {
        #if ENGINE_SCRIPTING
        hxsCall("onUpdate", [elapsed]);
        super.update(elapsed);

        if (overrideCode) {
            hxsCall("onUpdatePost", [elapsed]);
            return;
        }
        #else
        super.update(elapsed);
        #end

        if (allowInputs) {
            if (controls.justPressed("back"))
                close();

            if (Mods.currentMod != modReference && controls.justPressed("accept"))
                accept();
        }

        #if ENGINE_SCRIPTING
        hxsCall("onUpdatePost", [elapsed]);
        #end
    }

    inline function accept():Void {
        Mods.loadMod(modReference.folder);
        FlxG.save.data.lastMod = modReference.id;
        FlxG.save.flush();

        var modMenu:ModsMenu = cast _parentState;
        modMenu.exitToTitle = modReference.restartGame;
        modMenu.updateModText();

        updateConfirmText();
        FlxG.sound.play(Assets.sound("confirmMenu"));
    }

    inline function updateConfirmText():Void {
        if (Mods.currentMod == modReference) {
            confirmText.text = "ENABLED";
            confirmText.color = FlxColor.LIME;
        } else {
            confirmText.text = "PRESS ACCEPT TO ENABLE";
            confirmText.color = FlxColor.WHITE;
        }

        confirmText.screenCenter(X);
    }

    override function destroy():Void {
        super.destroy();
        modReference = null;
    }
}

class ModItem extends FlxSprite {
    public var target:Int = 0;

    public function new(mod:Mod):Void {
        super();

        target = Mods.mods.indexOf(mod);

        var possibleIcon:String = Assets.getPath("pack", IMAGE);
        if (FileTools.exists(possibleIcon))
            loadGraphic(Assets.getGraphic('pack', null, 'icon_${mod.id}'));
        else
            loadGraphic(Assets.image('menus/questionMark'));

        screenCenter(Y);
    }

    override function update(elapsed:Float):Void {
        var val:Float = (target == 0) ? 1 : 0.6;

        x = Tools.lerp(x, ((FlxG.width - width) / 2) + (target * 240), 10);
        alpha = Tools.lerp(alpha, val, 10);

        scale.set(Tools.lerp(scale.x, val, 10), Tools.lerp(scale.y, val, 10));
        updateHitbox();
        offset.set();
    }
}
#end
