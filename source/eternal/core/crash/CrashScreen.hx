package eternal.core.crash;

#if ENGINE_CRASH_HANDLER
import flixel.FlxState;
import funkin.states.menus.MainMenu;

import flixel.text.FlxText;
import flixel.tweens.FlxTween;

class CrashScreen extends FlxState {
    var questionMark:FlxSprite;
    var rotateSine:Float = 0;
    var callstack:FlxText;

    var func:String;

    public function new(func:String):Void {
        super();
        this.func = func;
    }

    override function create():Void {
        super.create();

        questionMark = new FlxSprite();
        questionMark.loadGraphic(AssetHelper.image("menus/questionMark"));
        questionMark.color = FlxColor.RED;
        questionMark.scale.set(1.5, 1.5);
        questionMark.updateHitbox();
        questionMark.setPosition(FlxG.width - 150, 10);
        add(questionMark);

        var boyfriend:FlxSprite = new FlxSprite();
        boyfriend.loadGraphic(AssetHelper.image("menus/exceptions/crash"));
        boyfriend.setGraphicSize(0, FlxG.height / 2);
        boyfriend.updateHitbox();
        boyfriend.y = FlxG.height - boyfriend.height;
        add(boyfriend);

        callstack = new FlxText();
        callstack.setFormat(AssetHelper.font("vcr"), 32, FlxColor.WHITE, CENTER);
        callstack.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);

        callstack.text = CrashHandler.lastCallstack;
        callstack.resizeText();

        callstack.clipRect = flixel.math.FlxRect.get(0, 0, callstack.width, (callstack.height > 315) ? (callstack.height / 2 + 5) : callstack.height);
        callstack.setPosition((FlxG.width - callstack.width) / 2, (FlxG.height - callstack.clipRect.height) / 2);
        add(callstack);

        var topText:FlxText = new FlxText(0, 0, 0, CrashHandler.lastException);
        topText.setFormat(callstack.font, 44);
        topText.resizeText();
        
        topText.applyMarkup(topText.text, [new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.RED), "<>")]);
        topText.y = callstack.y - topText.height - 10;
        topText.screenCenter(X);
        add(topText);

        var fullBottomText:String = 'Called from: ${func}';

        #if sys
        fullBottomText += '\nSaved crash log to "${CrashHandler.lastCrashLog}"';
        #end
        
        fullBottomText += "\n\nTurn the mouse wheel to scroll the crash stack";
        fullBottomText += "\nPress SPACE to open the github repository page in your browser";
        fullBottomText += "\nPress ENTER to go back to the main menu";

        #if sys
        fullBottomText += "\nPress ESCAPE to close the game";
        #end

        var bottomText:FlxText = new FlxText();
        bottomText.setFormat(callstack.font, 16, FlxColor.WHITE, CENTER);
        bottomText.text = fullBottomText;
        bottomText.y = FlxG.height - bottomText.height - 10;
        bottomText.screenCenter(X);
        add(bottomText);

        var howToBeFunny:FlxText = new FlxText(0, 100, 0, CrashHandler.getNextQuote());
        howToBeFunny.setFormat(callstack.font, 22);
        howToBeFunny.resizeText();
        howToBeFunny.screenCenter(X);
        add(howToBeFunny);

        camera.alpha = 0;
        FlxTween.tween(camera, {alpha: 1}, 0.45);

        FlxG.sound.play(AssetHelper.sound("error"));
    }

    override function update(elapsed:Float):Void {
        #if sys
        if (FlxG.keys.justPressed.ESCAPE) {
            #if ENGINE_DISCORD_RPC
            DiscordPresence.shutdown();
            #end 
            Sys.exit(0);
        }
        #end

        if (FlxG.keys.justPressed.SPACE)
            FlxG.openURL(Tools.githubURL);

        if (FlxG.keys.justPressed.ENTER)
            FlxG.switchState(new MainMenu());

        if (FlxG.mouse.wheel != 0) {
            callstack.clipRect.y -= FlxG.mouse.wheel * 5;
            callstack.clipRect = callstack.clipRect;
            callstack.y = (FlxG.height - callstack.clipRect.height) / 2 - callstack.clipRect.y;
        }

        rotateSine += elapsed * 2;
        questionMark.angle = 10 * Math.sin(rotateSine);

        super.update(elapsed);
    }

    override function destroy():Void {
        func = null;
        super.destroy();
    }
}
#end