package funkin.objects.ui;

import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

class Alphabet extends FlxTypedSpriteGroup<AlphabetCharacter> {
    public var text(default, set):String;
    public var bold(default, set):Bool;

    public var distance(default, null):FlxPoint;
    public var spacing(default, null):FlxPoint;

    public var menuItem:Bool = false;
    public var lerpSpeed:Float = 12;
    public var target:Float = 0;

    public var spriteTrackers:Map<FlxSprite, AlphabetTrackerPosition>;

    public function new(x:Float = 0, y:Float = 0, text:String = "", bold:Bool = true):Void {
        super(x, y);

        distance = FlxPoint.get(20, 140);
        spacing = FlxPoint.get(28, 60);

        spriteTrackers = [];

        this.bold = bold;
        this.text = text;
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if (menuItem) {
            x = Tools.lerp(x, getTargetX(), lerpSpeed);
            y = Tools.lerp(y, getTargetY(), lerpSpeed);
        }

        for (spr => type in spriteTrackers) {
            spr.y = y;
            switch (type) {
                case LEFT: spr.x = x - 150;
                case RIGHT: spr.x = x + width + 10;
                case CENTER: spr.x = x + (width * 0.5);
            }
        }
    }

    public function snapToPosition():Void
        setPosition(getTargetX(), getTargetY());

    public function doIntro():Void {
        x = -(width * target);
        y = getTargetY();
    }

    inline public function getTargetX():Float {
        return ((target * distance.x) + 90);
    }

    inline public function getTargetY():Float {
        return (((FlxG.height - spacing.y) * 0.5) + (target * distance.y));
    }

    override function destroy():Void {
        super.destroy();

        distance = FlxDestroyUtil.put(distance);
        spacing = FlxDestroyUtil.put(spacing);

        spriteTrackers?.clear();
        spriteTrackers = null;
    }

    override function findMinXHelper():Float {
        var value:Float = Math.POSITIVE_INFINITY;
        for (member in _sprites) {
            if (member == null || !member.exists)
                continue;
                
            var minX:Float = member.x;                
            if (minX < value)
                value = minX;
        }
        return value;
    }

    override function findMaxXHelper():Float {
        var value:Float = Math.NEGATIVE_INFINITY;
		for (member in _sprites) {
			if (member == null || !member.exists)
				continue;
			
			var maxX:Float = member.x + member.width;
			if (maxX > value)
				value = maxX;
		}
		return value;
    }

    override function findMinYHelper():Float {
        var value:Float = Math.POSITIVE_INFINITY;
        for (member in _sprites) {
            if (member == null || !member.exists)
                continue;
                
            var minY:Float = member.y;
            if (minY < value)
                value = minY;
        }
        return value;
    }

    override function findMaxYHelper():Float {
        var value:Float = Math.NEGATIVE_INFINITY;
        for (member in _sprites) {
            if (member == null || !member.exists)
                continue;
                
            var maxY:Float = member.y + member.height;                
            if (maxY > value)
                value = maxY;
        }
        return value;
    }

    function set_text(v:String):String {
        if (v == null)
            v = "null";

        if (text != null && ((bold && v.toLowerCase() == text.toLowerCase()) || text == v))
            return v;

        group.killMembers();

        if (v.length < 1)
            return text = v;

        var xPos:Float = 0;
        var yPos:Float = 0;
        var recycled:Bool = true;

        for (character in v.split("")) {
            if (character == '\n') {
                xPos = 0;
                yPos += spacing.y * scale.y;
                continue;
            }
            else if (character == " ") {
                xPos += spacing.x * scale.x;
                continue;
            }
      
            recycled = true;

            var newCharacter:AlphabetCharacter = recycle(AlphabetCharacter, () -> {
                recycled = false;
                new AlphabetCharacter(xPos, yPos, character, bold);
            });

            if (recycled) {
                newCharacter.setup(character, bold);
                newCharacter.setPosition(xPos, yPos);
            }

            newCharacter.scale.set(scale.x, scale.y);
            newCharacter.updateHitbox();

            xPos += newCharacter.width + 3;
            add(newCharacter);
        }

        return text = v;
    }

    function set_bold(v:Bool):Bool {        
        if (bold != v)
            forEach((c) -> c.setup(c.character, v));
        return bold = v;
    }
}

class AlphabetCharacter extends FlxSprite {
    public var character(default, null):String = "";

    public function new(x:Float, y:Float, character:String, bold:Bool = false):Void {
        super(x, y);
        frames = AssetHelper.getSparrowAtlas("ui/alphabet");
        setup(character, bold);
    }

    public function setup(letter:String, bold:Bool):Void {
        var finalLetter:String = letter;

        var let:Bool = ~/[a-z-A-Z]/g.match(letter);
        var num:Bool = ~/[0-9]/g.match(letter);

        if (let || num) {
            var upper:String = letter.toUpperCase();
            var lower:String = letter.toLowerCase();

            if (bold)
                finalLetter = upper + " bold";
            else if (letter != lower)
                finalLetter = upper + " capital";
            else {
                if (num)
                    finalLetter = upper + "0";
                else
                    finalLetter = lower + " lowercase";
            }
        }

        var prefix:String = resolvePrefix(finalLetter);

        if (!animation.exists(prefix))
            animation.addByPrefix(prefix, prefix, 24);

        animation.play(prefix, true);
        updateHitbox();

        this.character = letter;
    }

    override function updateHitbox():Void {
        super.updateHitbox();
        centerOffsets(true);
    }

    override function destroy():Void {
        super.destroy();
        character = null;
    }

    inline public static function resolvePrefix(character:String):String {
        // some prefixes seems to be wrong??
        return switch character {
            case "'": "apostraphie";
            case ",": "comma";
            case "(": "start parentheses";
            case ")": "end parentheses";
            case "!": "exclamation point";
            case "/": "forward slash";
            case ".": "period";
            case "?": "question mark";
            default: character;

            // TODO: implement symbols
            // "unused character": "symbol prefix"

            case "angry faic": "angry faic";
            case "heart": "heart";
            case "left arrow": "left arrow";
            case "right arrow": "right arrow";
            case "up arrow": "up arrow";
            case "multiply x": "multiply x";
        }
    }
}

enum abstract AlphabetTrackerPosition(String) from String to String {
    var LEFT = "left";
    var RIGHT = "right";
    var CENTER = "center";
}