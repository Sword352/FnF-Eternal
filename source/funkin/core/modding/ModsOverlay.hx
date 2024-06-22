package funkin.core.modding;

#if ENGINE_MODDING
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.group.FlxSpriteGroup;
import haxe.ui.components.VerticalScroll;
import funkin.ui.Alphabet;

var ROW:Int = 6;
var PADDING_X:Float = 55;
var SPACING_Y:Float = 250;

class ModsOverlay extends MusicBeatSubState {
    public var selectedMod(default, set):ModItem;
    public var mods:ModItems;

    public var tooltip:Tooltip;
    public var scrollBar:ScrollBar;
    public var buttons:Buttons;
    public var infos:ModInfos;

    var stopInputs:Bool = false;
    var _camera:FlxCamera;

    override function create():Void {
        super.create();

        _camera = new FlxCamera();
        FlxG.cameras.add(_camera, false);

        _camera.bgColor = FlxColor.BLACK;
        _camera.bgColor.alphaFloat = 0.6;
        cameras = [_camera];

        FlxG.mouse.useSystemCursor = false;
        FlxG.mouse.visible = true;

        var text:Alphabet = new Alphabet(0, 10, "Mods", false);
        text.forEach((c) -> c.colorTransform.color = FlxColor.WHITE);
        text.screenCenter(X);
        add(text);

        var engineVer:FlxText = new FlxText(PADDING_X, 50);
        engineVer.setFormat(Assets.font("vcr"), 16);
        engineVer.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.25);
        engineVer.text = 'Engine Version: ${Tools.gameVersion}';
        add(engineVer);

        add(scrollBar = new ScrollBar());
        add(infos = new ModInfos());
        add(buttons = new Buttons());
        add(mods = new ModItems());
        add(tooltip = new Tooltip());

        refreshScrollBar();
        scrollBar.onChange = (_) -> {
            mods.row = scrollBar.pos;
        };
    }
    
    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if (controls.justPressed("back") && !stopInputs)
            close();
    }

    override function close():Void {
        if (selectedMod != null) {
            selectedMod.unselect();
            return;
        }

        Tools.stopMusic();
        FlxG.mouse.visible = false;
        stopInputs = true;

        FlxG.sound.play(Assets.sound("cancelMenu"));
        Transition.skipNextTransOut = true;

        camera.fade(FlxColor.BLACK, 0.25, false, () -> {
            Mods.sortList();
            FlxTimer.wait(0.2, FlxG.resetState);
            Mods.saveEnabledMods();
        });
    }

    public function refreshScrollBar():Void {
        scrollBar.max = Math.floor(mods.countLiving() / ROW) - 1;
        scrollBar.hidden = (scrollBar.max < 2);
    }

    function set_selectedMod(v:ModItem) {
        mods.forEachAlive((mod) -> mod.visible = mod.active = (v == null || v == mod));
        scrollBar.hidden = (v != null || scrollBar.max < 2);
        buttons.visible = buttons.active = (v == null);

        if (v == null) {
            infos.visible = infos.active = false;
        }
        else {
            infos.show(v); 
        }

        return selectedMod = v;
    }
}

class ModItems extends FlxTypedSpriteGroup<ModItem> {
    public var sortAfter:Bool = false;
    public var row:Float = 0;

    public function new():Void {
        super();
        addItems();
    }

    override function update(elapsed:Float):Void {
        var parent:ModsOverlay = cast FlxG.state.subState;

        // changing the bar's pos should change the row too
        if (FlxG.mouse.wheel != 0 && parent.selectedMod == null)
            parent.scrollBar.pos -= FlxG.mouse.wheel * 0.25;

        for (item in members) {
            if (!item.exists || !item.alive || !item.active) continue;

            item.update(elapsed);

            if (parent.selectedMod == null) {
                if (!item.dragging) {
                    var index:Int = members.indexOf(item);
                    item.x = Tools.lerp(item.x, PADDING_X + 200 * (index % ROW), 12);
                    item.y = Tools.lerp(item.y, 150 + SPACING_Y * (Math.floor(index / ROW) - row), 12);
                }

                item.updateClipRect();
            }
            else if (parent.selectedMod == item) {
                item.x = Tools.lerp(item.x, PADDING_X, 12);
                item.y = Tools.lerp(item.y, (FlxG.height - item.background.height) * 0.5, 12);
            }
        }

        if (sortAfter) {
            sortAfter = false;
            sortItems();
        }
    }

    public function addItems():Void {
        for (mod in Mods.mods) {
            recycle(ModItem, () -> new ModItem(this)).setup(mod);
        }

        sortItems();
    }

    public function sortItems():Void {
        group.members.sort((a, b) -> {
            if (!a.reference.enabled || !a.exists) return 1;
            if (!b.reference.enabled || !b.exists) return -1;
            return Mods.sortByPriority(a.reference, b.reference);
        });

        for (i in 0...members.length) {
            var object:ModItem = members[i];

            var mod:ModStructure = object.reference;
            mod.priority = (mod.enabled ? i : -1);

            if (mod.enabled)
                object.updatePriorityText();
        }
    }
}

class ModItem extends Group<FlxSprite> {
    public var reference:ModStructure;
    public var dragging:Bool = false;

    public var background:FlxSprite;
    public var enabledButton:FlxSprite;
    public var priority:Alphabet;

    public var warningIcon:FlxSprite;
    public var infoIcon:FlxSprite;
    public var icon:FlxSprite;

    var warningTooltip:String = null;
    var dragPoint:FlxPoint = FlxPoint.get();
    var startPos:FlxPoint = FlxPoint.get();

    var parentState(get, never):ModsOverlay;
    var parentGroup:ModItems;

    inline function get_parentState():ModsOverlay
        return cast FlxG.state.subState;

    public function new(parent:ModItems):Void {
        super();

        this.parentGroup = parent;

        background = new FlxSprite();
        background.makeGraphic(150, 200, FlxColor.GRAY, false, "modoverlay_bg");
        background.alpha = 0.7;
        add(background);

        icon = new FlxSprite();
        add(icon);

        warningIcon = new FlxSprite(5, 5);
        warningIcon.loadGraphic(Assets.image("ui/debug/notification_warning"));
        warningIcon.setGraphicSize(30);
        warningIcon.updateHitbox();
        add(warningIcon);

        infoIcon = new FlxSprite(background.width - 5, 5);
        infoIcon.loadGraphic(Assets.image("ui/debug/notification_info"));
        infoIcon.setGraphicSize(25);
        infoIcon.updateHitbox();
        infoIcon.x -= infoIcon.width;
        add(infoIcon);

        enabledButton = new FlxSprite();
        enabledButton.frames = Assets.getSparrowAtlas("menus/mods/on_off");
        enabledButton.animation.addByPrefix("off", "off", 24);
        enabledButton.animation.addByPrefix("on", "on", 24);
        enabledButton.animation.play("on");
        enabledButton.setGraphicSize(30);
        enabledButton.updateHitbox();
        enabledButton.x = background.width - enabledButton.width - 10;
        enabledButton.y = background.height - enabledButton.height - 10;
        add(enabledButton);

        priority = new Alphabet(5, 0, "", false);
        priority.scale.set(0.35, 0.35);
        add(priority);

        clipRect = FlxRect.get(0, 0, background.width, background.height);
    }

    override function update(elapsed:Float):Void {
        if (FlxG.mouse.justPressed && parentState.selectedMod == null) {
            if (mouseOverlaps(enabledButton)) enableMod(!reference.enabled);
            else if (mouseOverlaps(infoIcon)) select();
            else if (mouseOverlaps(this) && reference.enabled) startDrag();
        }

        updateVisuals();

        if (dragging)
            updateDrag();

        if (parentState.selectedMod == null)
            updateTooltip();

        if (priority.visible)
            priority.update(elapsed);

        enabledButton.update(elapsed);
    }

    public function enableMod(enable:Bool):Void {
        reference.enabled = enable;
        priority.visible = reference.enabled;
        parentGroup.sortAfter = true;

        enabledButton.animation.play(reference.enabled ? "on" : "off", true);

        if (priority.visible)
            updatePriorityText();
    }

    public function select():Void {
        parentState.selectedMod = this;
        parentState.tooltip.deactivate();

        infoIcon.visible = false;
        enabledButton.visible = false;
        priority.visible = false;

        clipRect = null;
    }

    public function unselect():Void {
        infoIcon.visible = true;
        priority.visible = reference.enabled;
        enabledButton.visible = true;

        clipRect = FlxRect.get(0, 0, 150, 200);
        parentState.selectedMod = null;
    }

    public function setup(mod:ModStructure):Void {
        this.reference = mod;

        var modState:ModVersionState = mod.getVersionState();

        var iconPath:String = mod.assetStructure.getPath("meta", IMAGE);
        var iconBitmap:FlxGraphicAsset = mod.assetStructure.createBitmapData(iconPath);

        if (iconBitmap == null)
            iconBitmap = Assets.image("menus/questionMark");

        icon.loadGraphic(iconBitmap);
        icon.setGraphicSize(0, 100);
        icon.updateHitbox();

        enabledButton.animation.play(reference.enabled ? "on" : "off");
        warningIcon.alpha = (modState != UPDATED ? 1 : 0);
        priority.visible = reference.enabled;

        if (warningIcon.alpha > 0) {
            warningTooltip = "Warning: " + switch (modState) {
                case OUTDATED_BUILD: "this build is outdated!";
                default: "this mod is outdated!"; // = OUTDATED_MOD
            };
            warningTooltip += '\n(Requires v${mod.apiVersion})';
        }

        if (priority.visible)
            updatePriorityText();

        setPosition();
    }

    public function updatePriorityText():Void {
        priority.text = Std.string(reference.priority + 1);
        priority.y = y + background.height - priority.height - 12;
    }

    public function updateClipRect():Void {
        clipRect.y = Math.max(150 - y, 0);
        clipRect.height = background.height - clipRect.y;
        clipRect = clipRect;
    }

    inline function startDrag():Void {
        dragPoint.set(FlxG.mouse.x, FlxG.mouse.y);
        startPos.set(x, y);
        dragging = true;
    }

    inline function updateDrag():Void {
        x = startPos.x + (FlxG.mouse.x - dragPoint.x);
        y = startPos.y + (FlxG.mouse.y - dragPoint.y);

        var div:Float = SPACING_Y * 0.75;

        var xIndex:Int = Math.round(Math.max(x - PADDING_X, 0) / 175);
        var yIndex:Int = Math.round(Math.max(y - 150 + div * parentGroup.row, 0) / div);

        if (xIndex > ROW) xIndex = ROW;

        if (x - PADDING_X <= -PADDING_X * 0.5) {
            // nasty workaround
            var excepted:Int = yIndex * ROW;

            if (reference.priority != excepted) {
                for (i in excepted...parentGroup.members.length) {
                    var mod:ModStructure = parentGroup.members[i].reference;
                    if (mod.priority == -1) break;
                    mod.priority++;
                }

                reference.priority = excepted;
                parentGroup.sortAfter = true;
                // updatePriorityText();
            }
        }
        else {
            var priority:Int = xIndex + yIndex * ROW;
            if (reference.priority != priority) {
                reference.priority = priority;
                parentGroup.sortAfter = true;
                // updatePriorityText();
            }
        }

        if (FlxG.mouse.released)
            dragging = false;
    }

    inline function updateTooltip():Void {
        if (parentState.tooltip.enabled) return;

        if (mouseOverlaps(icon))
            parentState.tooltip.activate(icon, reference.title);
        else if (mouseOverlaps(infoIcon))
            parentState.tooltip.activate(infoIcon, "View details");
        else if (warningIcon.alpha > 0 && mouseOverlaps(warningIcon))
            parentState.tooltip.activate(warningIcon, warningTooltip, FlxColor.YELLOW);
    }

    inline function updateVisuals():Void {
        var selected:Bool = (parentState.selectedMod == this);

        background.scale.x = Tools.lerp(background.scale.x, (background.frameWidth * (selected ? 1.5 : 1)) / background.frameWidth, 12);
        background.scale.y = Tools.lerp(background.scale.y, (selected ? FlxG.height - 200 : background.frameHeight) / background.frameHeight, 12);
        background.updateHitbox();

        icon.scale.x = icon.scale.y = Tools.lerp(icon.scale.y, (selected ? 200 : 100) / icon.frameHeight, 12);
        icon.updateHitbox();

        icon.centerToObject(background);
    }

    override function destroy():Void {
        dragPoint = FlxDestroyUtil.put(dragPoint);
        startPos = FlxDestroyUtil.put(startPos);

        warningTooltip = null;
        parentGroup = null;
        reference = null;

        super.destroy();
    }
}

class ModInfos extends Group<FlxSprite> {
    var title:Alphabet;
    var description:FlxText;
    var version:FlxText;
    var license:FlxText;
    var credits:ModCredits;
    var deps:FlxText;

    public function new():Void {
        super(PADDING_X + 255, 85);

        active = visible = false;

        title = new Alphabet(0, 0, "");
        title.scale.set(0.75, 0.75);
        add(title);

        version = new FlxText();
        version.setFormat(Assets.font("vcr"), 14);
        version.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        add(version);

        description = new FlxText();
        description.setFormat(version.font, 16);
        description.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        add(description);

        license = new FlxText();
        license.setFormat(version.font, 20);
        license.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        add(license);

        deps = new FlxText();
        deps.setFormat(version.font, 20);
        deps.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
        add(deps);

        credits = new ModCredits();
        add(credits);
    }

    override function update(elapsed:Float):Void {
        alpha = Tools.lerp(alpha, 1, 6);
        credits.update(elapsed);
        title.update(elapsed);
    }

    public function show(mod:ModItem):Void {
        var dependencies:Array<String> = mod.reference.dependencies;

        title.text = mod.reference.title ?? mod.reference.folder;
        description.text = mod.reference.description ?? "No description provided.";
        description.y = title.y + title.height + 15;
        credits.setup(mod);

        visible = true;
        active = true;
        alpha = 0;

        deps.visible = (dependencies != null && dependencies.length != 0);
        version.visible = (mod.reference.modVersion != null);
        license.visible = (mod.reference.license != null);

        if (deps.visible) {
            var foundDeps:Array<String> = [];
            var missingDeps:Array<String> = dependencies.copy();
            var text:String = 'Required dependencies:\n';

            for (mod in Mods.mods) {
                for (key in [mod.title, mod.id]) {
                    if (missingDeps.contains(key)) {
                        missingDeps.remove(key);
                        foundDeps.push(key);
                    }
                }
            }

            foundDeps.sort((a, b) -> dependencies.indexOf(a) - dependencies.indexOf(b));

            text += foundDeps.map(f -> "- " + f).join("\n");
            if (missingDeps.length != 0) {
                text += "\n\n<>MISSING DEPENDENCIES:\n";
                text += missingDeps.map(f -> "- " + f).join("\n") + "<>";
            }

            deps.text = text;
            deps.applyMarkup(deps.text, [new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.YELLOW), "<>")]);
            deps.y = FlxG.height - deps.height - 100;
        }

        if (license.visible) {
            license.text = 'Licensed under: ${mod.reference.license}';
            license.y = (deps.visible ? deps.y - license.height - 2 : FlxG.height - license.height - 100);
        }

        if (version.visible) {
            version.text = 'v${mod.reference.modVersion}';
            version.y = title.y + title.height - version.height;
            version.x = title.x + title.width + 5;
        }
    }
}

class ModCredits extends Group<CreditEntry> {
    var row:Float = 0;

    override function update(elapsed:Float):Void {
        if (FlxG.mouse.wheel != 0) {
            var count:Int = countLiving();
            if (count > 3) row = FlxMath.bound(row - FlxG.mouse.wheel * 0.25, 0, count - 3);
        }

        forEachAlive((item) -> {
            item.y = Tools.lerp(item.y, y + 60 * (item.ID - row), 12);
            item.clipRect.set(0, 0, item.width);

            if (item.y >= y) {
                item.clipRect.height = item.height - Math.max(item.y + item.height - (y + 200), 0);
            }
            else {
                item.clipRect.y = y - item.y;
                item.clipRect.height = item.height - item.clipRect.y;
            }

            item.clipRect = item.clipRect;
        });
    }

    public function setup(mod:ModItem):Void {
        // can't directly use width/height as it accounts for killed members too
        var maxWidth:Float = 0;
        var totalHeight:Float = 0;

        group.killMembers();
        setPosition();
        row = 0;

        // TODO: fix issue where reloading credits may make them have an unexcepted position
        if (mod.reference.credits != null) {
            for (i in 0...mod.reference.credits.length) {
                var author:ModAuthor = mod.reference.credits[i];
                if (author.name == null) continue;

                var entry:CreditEntry = recycle(CreditEntry);
                entry.setPosition(0, 60 * i);
                entry.setup(author, mod);
                entry.ID = i;

                maxWidth = Math.max(maxWidth, entry.width);
                totalHeight += entry.height;
            }
        }

        x = FlxG.width - maxWidth - 50;
        y = FlxG.height - Math.min(totalHeight, 200) - 100;
    }
}

class CreditEntry extends Group<FlxSprite> {
    var name:FlxText;
    var icon:FlxSprite;
    var role:FlxText;

    public function new():Void {
        super();

        icon = new FlxSprite();
        add(icon);

        name = new FlxText();
        name.setFormat(Assets.font("vcr"), 16);
        name.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        add(name);

        role = new FlxText();
        role.setFormat(name.font, 14);
        role.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
        add(role);

        clipRect = FlxRect.get();
    }

    public function setup(author:ModAuthor, mod:ModItem):Void {
        var iconPath:String = mod.reference.assetStructure.getPath("images/menus/credits/" + (author.icon ?? author.name), IMAGE);
        var iconBitmap:FlxGraphicAsset = mod.reference.assetStructure.createBitmapData(iconPath);

        if (iconBitmap == null)
            iconBitmap = Assets.image("menus/questionMark");

        icon.loadGraphic(iconBitmap);
        icon.setGraphicSize(0, 50);
        icon.updateHitbox();

        name.text = author.name;
        name.x = icon.width + 5;

        role.visible = (author.role != null);

        if (role.visible) {
            role.x = name.x;
            role.y = y + name.height + 5;
            role.text = author.role;
        }
    }
}

class Buttons extends FlxSpriteGroup {
    var enableMods:FlxSprite;
    var disableMods:FlxSprite;
    var reloadMods:FlxSprite;

    var parent(get, never):ModsOverlay;
    inline function get_parent():ModsOverlay
        return cast FlxG.state.subState;

    public function new():Void {
        super(FlxG.width - 388, 5);

        enableMods = new FlxSprite(0, 0, Assets.image("menus/mods/enable"));
        enableMods.scale.set(0.75, 0.75);
        enableMods.updateHitbox();
        enableMods.ID = 0;
        add(enableMods);

        disableMods = new FlxSprite(100, 0, Assets.image("menus/mods/disable"));
        disableMods.scale.set(0.75, 0.75);
        disableMods.updateHitbox();
        disableMods.ID = 1;
        add(disableMods);

        reloadMods = new FlxSprite(200, 0, Assets.image("menus/mods/reload"));
        reloadMods.scale.set(0.75, 0.75);
        reloadMods.updateHitbox();
        reloadMods.ID = 2;
        add(reloadMods);
    }

    override function update(elapsed:Float):Void {
        for (member in members) {
            var overlaps:Bool = FlxG.mouse.overlaps(member, FlxG.state.subState.camera);
            var colorOffset:Int = (overlaps ? 50 : 0);

            var lerp:Float = Tools.lerp(member.colorTransform.redOffset, colorOffset, 12);
            member.setColorTransform(1, 1, 1, 1, lerp, lerp, lerp);
 
            if (overlaps) {
                if (!parent.tooltip.enabled) parent.tooltip.activate(member, getTooltipFor(member));
                if (FlxG.mouse.justReleased) onClick(member);

                if (parent.tooltip.enabled && parent.tooltip.target == member && FlxG.mouse.pressed)
                    parent.tooltip.deactivate();
            }
        }
    }

    function onClick(sprite:FlxSprite):Void {
        switch (sprite.ID) {
            case 0:
                parent.mods.forEachAlive((mod) -> mod.enableMod(true));
            case 1:
                parent.mods.forEachAlive((mod) -> {
                    if (mod.reference.priority != 0)
                        mod.enableMod(false);
                });
            case 2:
                Mods.reload();
                parent.mods.forEachAlive((mod) -> mod.kill());
                parent.mods.addItems();
                parent.refreshScrollBar();
                parent.scrollBar.pos = 0;
        }
    }

    inline function getTooltipFor(sprite:FlxSprite):String {
        return switch (sprite.ID) {
            case 0: "Enable all mods";
            case 1: "Disable all mods";
            default: "Refresh mods";
        }
    }
}

class Tooltip extends FlxText {
    public var enabled:Bool = false;
    public var target:FlxSprite;

    public function new():Void {
        super();
        setFormat(Assets.font("vcr"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        visible = active = false;
        borderSize = 1.5;
    }

    override function update(elapsed:Float):Void {
        setPosition(FlxG.mouse.screenX + 15, FlxG.mouse.screenY - height * 0.75);
        if (!mouseOverlaps(target)) deactivate();
    }

    public function activate(sprite:FlxSprite, text:String, color:FlxColor = FlxColor.WHITE):Void {
        this.text = text;
        this.color = color;
        target = sprite;

        enabled = true;
        visible = true;
        active = true;
    }

    public function deactivate():Void {
        target = null;
        enabled = false;
        visible = false;
        active = false;
    }

    override function destroy():Void {
        target = null;
        super.destroy();
    }
}

// sprite group extension to account for scaling and re-use clipRects
class Group<T:FlxSprite> extends FlxTypedSpriteGroup<T> {
    override function set_clipRect(v:FlxRect):FlxRect {
        if (exists) {
            forEach((member) -> applyClipRect(member, v));
        }

        return clipRect = v;
    }

    inline function applyClipRect(sprite:T, rect:FlxRect):Void {
        if (rect == null)
            sprite.clipRect = null;
        else {
            var clipRect:FlxRect = (sprite.clipRect ?? FlxRect.get());

            clipRect.set(
                (rect.x - sprite.x + x) / sprite.scale.x,
                (rect.y - sprite.y + y) / sprite.scale.y,
                rect.width / sprite.scale.x,
                rect.height / sprite.scale.y
            );

            sprite.clipRect = clipRect;
        }
    }
}

class ScrollBar extends VerticalScroll {
    public function new():Void {
        super();

        var thumb = findComponent("scroll-thumb-button");
        thumb.customStyle.backgroundColor = FlxColor.GRAY;
        thumb.customStyle.width = 14;

        customStyle.backgroundColor = FlxColor.WHITE;
        customStyle.width = 15;

        height = FlxG.height * 0.75;
        top = (FlxG.height - height) * 0.5;

        left = FlxG.width - 40;
        thumbSize = 15;

        invalidateComponentStyle();
    }
}

function mouseOverlaps(sprite:FlxSprite):Bool {
    return FlxG.mouse.overlaps(sprite, FlxG.state.subState.camera) && (sprite.clipRect == null || FlxG.mouse.screenY >= sprite.y + sprite.clipRect.y * sprite.scale.y);
}
#end
