package funkin.gameplay.notes;

import funkin.data.NoteSkin;
import funkin.objects.OffsetSprite;

class HoldCover extends OffsetSprite {
    public var skin(default, set):String;
    public var parent:Note;

    public function new(skin:String = "default"):Void {
        super();
        this.skin = skin;

        animation.finishCallback = (name) -> {
            if (name.endsWith("-start"))
                playAnimation(Note.directions[parent.direction], true);
            else if (name.endsWith("-end"))
                kill();
        };
    }

    public function start(note:Note):Void {
        this.parent = note;
        playAnimation(Note.directions[note.direction] + "-start", true);
    }

    override function update(elapsed:Float):Void {
        if (Conductor.self.time >= parent.time + parent.length) {
            if (parent.parentStrumline.cpu || !parent.perfectHold)
                kill();
            else if (!animation.name.endsWith("-end"))
                playAnimation(Note.directions[parent.direction] + "-end", true);
        }

        super.update(elapsed);
    }

    override function destroy():Void {
        skin = null;
        parent = null;
        super.destroy();
    }

    function set_skin(v:String):String {
        if (v != null) {
            switch (v) {
                case "default":
                    frames = Assets.getSparrowAtlas("notes/holds");

                    var colors:Array<String> = ["Purple", "Blue", "Green", "Red"];
                    for (i in 0...colors.length) {
                        var color:String = colors[i];
                        var direction:String = Note.directions[i];

                        animation.addByPrefix(direction + "-start", "holdCoverStart" + color, 24, false);
                        animation.addByPrefix(direction + "-end", "holdCoverEnd" + color, 24, false);
                        animation.addByPrefix(direction, "holdCover" + color + "0", 24);

                        offsets.add(direction + "-start", 12, -43);
                        offsets.add(direction + "-end", 12, -43);
                        offsets.add(direction, 12, -43);
                    }

                    playAnimation("left", true);
                    updateHitbox();
                default:
                    var config:NoteSkinConfig = NoteSkin.get(v);
                    if (config == null || config.holdCover == null)
                        return set_skin("default");

                    NoteSkin.applyGenericSkin(this, config.holdCover, "left");
            }
        }

        return skin = v;
    }
}
