package funkin.objects;

import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

class Alphabet extends FlxTypedSpriteGroup<AlphaGlyph> {
    public var text(default, set):String;
    public var bold(default, set):Bool;

    public var distance:FlxPoint = FlxPoint.get(20, 140);
    public var spacing:FlxPoint = FlxPoint.get(28, 60);

    public var menuItem:Bool = false;
    public var lerpSpeed:Float = 12;
    public var target:Float = 0;

    public function new(x:Float = 0, y:Float = 0, text:String = "", bold:Bool = true):Void {
        super(x, y);

        this.bold = bold;
        this.text = text;
    }

    override function update(elapsed:Float):Void {
        if (menuItem) {
            x = Tools.lerp(x, getTargetX(), lerpSpeed);
            y = Tools.lerp(y, getTargetY(), lerpSpeed);
        }

        super.update(elapsed);
    }

    public inline function snapToPosition():Void
        setPosition(getTargetX(), getTargetY());

    public inline function doIntro():Void {
        x = -(width * target);
        y = getTargetY();
    }

    public inline function getTargetX():Float {
        return distance.x * target + 90;
    }

    public inline function getTargetY():Float {
        return (FlxG.height * 0.45) + (target * distance.y);
    }

    // fix for getting width and height, skips killed characters
    override function findMinXHelper():Float {
        var value:Float = Math.POSITIVE_INFINITY;
        for (member in _sprites) {
            if (member == null || !member.exists)
                continue;

            var minX:Float = member.x;
            if (minX < value) value = minX;
        }
        return value;
    }

    override function findMaxXHelper():Float {
        var value:Float = Math.NEGATIVE_INFINITY;
        for (member in _sprites) {
            if (member == null || !member.exists)
                continue;

            var maxX:Float = member.x + member.width;
            if (maxX > value) value = maxX;
        }
        return value;
    }

    override function findMinYHelper():Float {
        var value:Float = Math.POSITIVE_INFINITY;
        for (member in _sprites) {
            if (member == null || !member.exists)
                continue;

            var minY:Float = member.y;
            if (minY < value) value = minY;
        }
        return value;
    }

    override function findMaxYHelper():Float {
        var value:Float = Math.NEGATIVE_INFINITY;
        for (member in _sprites) {
            if (member == null || !member.exists)
                continue;

            var maxY:Float = member.y + member.height;
            if (maxY > value) value = maxY;
        }
        return value;
    }
    //

    function set_text(v:String):String {
        if (v == null) v = "null";
        group.killMembers();

        if (v.length < 1)
            return text = v;

        var xPos:Float = 0;
        var yPos:Float = 0;

        for (character in v.split("")) {
            switch (character) {
                case '\n':
                    xPos = 0;
                    yPos += spacing.y * scale.y;
                case ' ':
                    xPos += spacing.x * scale.x;
                default:
                    var newCharacter:AlphaGlyph = recycle(AlphaGlyph);
                    newCharacter.setPosition(xPos, yPos);
                    newCharacter.setup(character, bold);

                    newCharacter.scale.set(scale.x, scale.y);
                    newCharacter.updateHitbox();
        
                    xPos += newCharacter.width + 3;
                    add(newCharacter);
            }
        }

        return text = v;
    }

    function set_bold(v:Bool):Bool {
        if (members != null && bold != v && members.length > 0)
            forEachAlive((c) -> c.refresh(v));

        return bold = v;
    }

    override function destroy():Void {
        distance = FlxDestroyUtil.put(distance);
        spacing = FlxDestroyUtil.put(spacing);

        super.destroy();
    }
}

class AlphaGlyph extends FlxSprite {
    var lastChar:String;

    public function new():Void {
        super(x, y);
        frames = Assets.getSparrowAtlas("ui/alphabet");
    }

    public inline function refresh(bold:Bool):Void {
        setup(lastChar, bold);
        updateHitbox();
    }

    public function setup(character:String, bold:Bool):Void {
        lastChar = character;

        var finalChar:String = character;
        var let:Bool = ~/[a-zA-Z]/g.match(character);
        var num:Bool = ~/[0-9]/g.match(character);

        if (let || num) {
            var upper:String = character.toUpperCase();
            var lower:String = character.toLowerCase();

            if (bold)
                finalChar = upper + " bold";
            else if (character != lower)
                finalChar = upper + " capital";
            else {
                if (num)
                    finalChar = upper + "0";
                else
                    finalChar = lower + " lowercase";
            }
        }

        var anim:String = resolvePrefix(finalChar);
        if (!animation.exists(anim)) animation.addByPrefix(anim, anim, 24);
        animation.play(anim, true);
    }

    override function updateHitbox():Void {
        super.updateHitbox();
        
        switch (lastChar) {
            case "g", "p", "q", "y" if (!animation.name.contains("bold") && animation.name.contains("lowercase")):
                offset.y -= ((70 - frameHeight) * scale.y + (height * 0.3));
            case "+", "-", "×", "=", "~":
                offset.y -= (70 - frameHeight) * (scale.y * 0.5);
            case "*", "^", "“", "”", "'":
                offset.y += height * 0.25;
            default:
                offset.y -= (70 - frameHeight) * scale.y;
        }
    }

    override function destroy():Void {
        lastChar = null;
        super.destroy();
    }

    inline static function resolvePrefix(character:String):String {
        return switch (character) {
            case "'": "apostraphie";
            case ",": "comma";
            case "“": "start parentheses";
            case "”": "end parentheses";
            case "/": "forward slash";
            case "!": "exclamation point";
            case "?": "question mark";
            case ".": "period";

            case "←": "left arrow";
            case "↓": "down arrow";
            case "↑": "up arrow";
            case "→": "right arrow";
            case "¤": "angry faic";
            case "×": "multiply x";
            case "♥": "heart";

            default: character;
        }
    }
}
