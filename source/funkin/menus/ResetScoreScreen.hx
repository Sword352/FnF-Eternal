package funkin.menus;

import flixel.tweens.FlxTween;
import flixel.text.FlxText;

class ResetScoreScreen extends MusicBeatSubState {
    public var songs:Array<String>;
    public var difficulty:String;
    public var display:String;

    public var onReset:Void->Void = null;
    public var story:Bool = false;

    var background:FlxSprite;
    var instructions:FlxText;

    var text:FlxText;
    var rotateSine:Float = 0;

    override function create():Void {
        super.create();

        initStateScripts();
        scripts.call("onCreate");

        background = new FlxSprite();
        background.makeRect(FlxG.width, FlxG.height, FlxColor.BLACK);
        background.alpha = 0;
        add(background);

        text = new FlxText(0, 150);
        text.setFormat(Assets.font("vcr"), 32, FlxColor.WHITE, CENTER);
        text.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        text.text = 'RESET THE SCORE OF\n${display}?';
        text.screenCenter(X);
        text.alpha = 0;
        add(text);

        instructions = new FlxText();
        instructions.setFormat(text.font, 32, FlxColor.WHITE, CENTER);
        instructions.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        instructions.text = "[ENTER] Confirm\n[BCKSP] Decline";
        instructions.screenCenter(X);
        instructions.y = FlxG.height - instructions.height - 50;
        instructions.alpha = 0;
        add(instructions);

        FlxTween.tween(text, {alpha: 1}, 0.25);
        FlxTween.tween(instructions, {alpha: 1}, 0.25);
        FlxTween.tween(background, {alpha: 0.45}, 0.25);

        scripts.call("onCreatePost");
    }

    override function update(elapsed:Float):Void {
        scripts.call("onUpdate", [elapsed]);
        super.update(elapsed);

        if (FlxG.keys.justPressed.ENTER) {
            resetScore();
            close();
        }

        if (FlxG.keys.justPressed.BACKSPACE)
            close();

        rotateSine += elapsed * 2;
        text.angle = 5 * FlxMath.fastSin(rotateSine);
        text.y -= FlxMath.fastCos(rotateSine * 1.5);

        scripts.call("onUpdatePost", [elapsed]);
    }

    function resetScore():Void {
        if (scripts.quickEvent("onAccept").cancelled)
            return;

        for (rawName in songs) {
            var song:String = '${rawName}-${difficulty}';
            if (story) song += "_story";

            /*
            song = Mods.currentMod.id + "_" + song;
            */

            Scoring.self.deleteSession(song);
        }

        Scoring.self.save();

        if (onReset != null)
            onReset();
    }

    override function destroy():Void {
        songs = null;
        difficulty = null;
        display = null;
        onReset = null;
        super.destroy();
    }
}
