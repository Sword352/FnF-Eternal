package funkin.gameplay.notes;

import funkin.data.NoteSkin;
import funkin.objects.OffsetSprite;

class Receptor extends OffsetSprite {
    public static final mainAnimations:Array<String> = ["static", "press", "confirm"];

    public var direction:Int = 0;
    public var parentStrumline:StrumLine;

    public var skin(default, set):String;
    public var centeredOffsets:Bool = true;

    public var animTimer:Float = -1;

    public function new(direction:Int = 0, skin:String = "default"):Void {
        super();

        this.direction = direction;
        this.skin = skin;

        animation.finishCallback = (name) -> {
            if (parentStrumline != null && name.startsWith("confirm"))
                animTimer = Conductor.self.time;
        };
    }

    override function update(elapsed:Float):Void {
        if (animTimer != -1 && (Conductor.self.time - animTimer) >= 100) {
            var anim:String = "static";

            if (parentStrumline != null && !parentStrumline.cpu && parentStrumline.heldKeys[direction])
                anim = "press";

            playAnimation(anim, true);
        }

        super.update(elapsed);
    }

    override public function playAnimation(name:String, force:Bool = false, reversed:Bool = false, frame = 0):Void {
        animTimer = -1;

        if (mainAnimations.contains(name))
            name += ' ${Note.directions[direction]}';

        super.playAnimation(name, force, reversed, frame);

        if (centeredOffsets) {
            centerOrigin();
            centerOffsets();
        }
    }

    override function destroy():Void {
        skin = null;
        parentStrumline = null;
        super.destroy();
    }

    function set_skin(v:String):String {
        if (v != null) {
            switch (v) {
                // case "name" to hardcode your noteskins
                case "default":
                    // default noteskin
                    frames = Assets.getSparrowAtlas("notes/receptors");

                    var dir:String = Note.directions[direction];
                    for (anim in mainAnimations) {
                        animation.addByPrefix('${anim} ${dir}', '${dir} ${anim}', 24, false);
                    }

                    playAnimation("static", true);

                    scale.set(0.7, 0.7);
                    updateHitbox();

                    centeredOffsets = true;
                    centerOffsets();

                    antialiasing = FlxSprite.defaultAntialiasing;
                    flipX = flipY = false;
                default:
                    // softcoded noteskin
                    var config:NoteSkinConfig = NoteSkin.get(v);
                    if (config == null || config.receptor == null)
                        return set_skin("default");

                    var skinData:ReceptorConfig = config.receptor;
                    var dir:String = Note.directions[direction];

                    NoteSkin.applyGenericSkin(this, skinData, "static " + dir, dir);
                    centeredOffsets = skinData.centeredOffsets ?? false;
            }
        }

        return skin = v;
    }
}
