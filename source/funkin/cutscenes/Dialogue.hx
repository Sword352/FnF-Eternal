package funkin.cutscenes;

import funkin.objects.ui.Alphabet;

class Dialogue extends MusicBeatSubState {
    public var currentPage:Int = 0;
    public var onFinish:Void->Void;

    var pages:Array<DialoguePage>;
    var data:DialogueYAML;
    
    var text:Alphabet;

    public function new(data:DialogueYAML):Void {
        super();
        load(data);
    }

    public function load(data:DialogueYAML):Void {
        this.data = data;
        pages = data.pages;
    }

    override function create():Void {
        super.create();

        text = new Alphabet(0, FlxG.height * 0.8, "", false);
        text.scale.set(0.5, 0.5);
        add(text);

        goToNextPage();
    }

    public function goToNextPage(increment:Int = 0):Void {
        currentPage += increment;

        if (currentPage >= pages.length) {
            finish();
            return;
        }

        var currentChar:Int = 0;

        text.forEach((char) -> char.destroy());
        text.clear();

        text.text = pages[currentPage].text;

        new FlxTimer().start(0.025, (_) -> {
            text.members[currentChar].visible = true;
            currentChar++;
        }, text.length);
    }

    public function finish():Void {
        if (onFinish != null)
            onFinish();
    }
}

typedef DialogueYAML = {
    var pages:Array<DialoguePage>;

    var ?characters:Array<String>;
    var ?background:String;
    var ?box:String;

    var ?music:String;
    var ?speed:Float;
}

typedef DialoguePage = {
    var text:String;
    var ?speed:Float;

    var ?talking:String;
    var ?expression:String;
    var ?boxState:String;

    var ?sounds:Array<String>;
    var ?soundChance:Float;
}

typedef DialogueCharacter = {
    var image:String;
    var ?atlasType:String;

    var ?scale:Array<Float>;
    var ?antialiasing:Bool;

    var ?speed:Float;
    
    var ?sounds:Array<String>;
    var ?soundChance:Float;
}