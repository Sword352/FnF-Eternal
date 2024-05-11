package states.substates;

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

    #if ENGINE_SCRIPTING
    var overrideCode:Bool = false;
    #end

    override function create():Void {
        super.create();

        #if ENGINE_SCRIPTING
        initStateScripts();
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

        if (FlxG.keys.justPressed.ENTER) {
            resetScore();
            close();
        }

        if (FlxG.keys.justPressed.BACKSPACE)
            close();

        rotateSine += elapsed * 2;
        text.angle = 5 * FlxMath.fastSin(rotateSine);
        text.y -= FlxMath.fastCos(rotateSine * 1.5);

        #if ENGINE_SCRIPTING
        hxsCall("onUpdatePost", [elapsed]);
        #end
    }

    function resetScore():Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onAccept"))
            return;
        #end

        for (rawName in songs) {
            var song:String = '${rawName}-${difficulty}';
            if (story) song += "_story";

            /*
            #if ENGINE_MODDING
            song = Mods.currentMod.id + "_" + song;
            #end
            */

            HighScore.scoreMap.set(song, HighScore.defaultMeasure);
        }

        HighScore.save();

        if (onReset != null)
            onReset();

        #if ENGINE_SCRIPTING
        hxsCall("onAcceptPost");
        #end
    }

    override function destroy():Void {
        songs = null;
        difficulty = null;
        display = null;
        onReset = null;
        super.destroy();
    }
}
