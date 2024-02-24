package eternal.core.crash;

#if ENGINE_CRASH_HANDLER
import flixel.FlxCamera;
import flixel.FlxSubState;

import flixel.text.FlxText;
import flixel.math.FlxRect;
import flixel.tweens.FlxTween;

import eternal.ui.ScrollBar;
import funkin.states.menus.MainMenu;

class CrashScreen extends FlxSubState {
    var questionMark:FlxSprite;
    var callstack:FlxText;

    var rotateSine:Float = 0;
    var cam:FlxCamera;

    override function create():Void {
        super.create();

        cam = new FlxCamera();
        cam.bgColor = FlxColor.BLACK;
        cam.bgColor.alphaFloat = 0.8;
        FlxG.cameras.add(cam, false);
        cameras = [cam];

        var boyfriend:FlxSprite = new FlxSprite(0, FlxG.height);
        boyfriend.frames = Assets.getSparrowAtlas("menus/exceptions/crash");
        boyfriend.animation.addByPrefix("idle", "rescaled", 24);
        boyfriend.animation.play("idle");
        boyfriend.setGraphicSize(0, FlxG.height * 0.5);
        boyfriend.updateHitbox();
        boyfriend.y -= boyfriend.height;
        add(boyfriend);

        questionMark = new FlxSprite(boyfriend.width, boyfriend.y - 10, Assets.image("menus/questionMark"));
        questionMark.x -= questionMark.width;
        questionMark.color = FlxColor.RED;
        add(questionMark);

        callstack = new FlxText(0, 0, 0, CrashHandler.lastReport.callstack);
        callstack.setFormat(Assets.font("vcr"), 32, FlxColor.WHITE, CENTER);
        callstack.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        callstack.resizeText();
        add(callstack);

        var topText:FlxText = new FlxText(0, 75, 0, '<>Error:<> ' + CrashHandler.lastReport.exception);
        topText.setFormat(callstack.font, 44);
        topText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        topText.resizeText();
        add(topText);
        
        topText.applyMarkup(topText.text, [new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.RED), "<>")]);
        callstack.screenCenter(Y);
        topText.screenCenter(X);

        var fullBottomText:String = #if sys 'Saved crash log to "${CrashHandler.lastReport.crashLog}"\n' #else "" #end ;
        fullBottomText += "Press SPACE to open the github repository page in your browser\n";
        fullBottomText += "Press ENTER to go back to the main menu";
        #if sys fullBottomText += "\nPress ESCAPE to close the game"; #end

        var bottomText:FlxText = new FlxText();
        bottomText.setFormat(callstack.font, 16, FlxColor.WHITE, CENTER);
        bottomText.text = fullBottomText;
        add(bottomText);

        bottomText.y = FlxG.height - bottomText.height - 10;
        bottomText.screenCenter(X);

        var callstackTop:Float = topText.y + topText.height + 20;
        var hugeCallstack:Bool = (callstack.y <= callstackTop);

        callstack.clipRect = FlxRect.get(0, 0, callstack.width, ((hugeCallstack) ? ((bottomText.y - callstackTop) - 10) : callstack.height));
        callstack.y = (FlxG.height - callstack.clipRect.height) * 0.5;
        callstack.screenCenter(X);

        var howToBeFunny:FlxText = new FlxText(0, topText.y - 10, 0, CrashHandler.getNextQuote());
        howToBeFunny.setFormat(callstack.font, 22);
        howToBeFunny.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        howToBeFunny.resizeText();
        howToBeFunny.screenCenter(X);
        howToBeFunny.y -= howToBeFunny.height;
        add(howToBeFunny);

        if (hugeCallstack) {
            var scrollBar:ScrollBar = new ScrollBar(FlxG.width - 80);
            scrollBar.onPercentChange = (v) -> {
                callstack.clipRect.y = (callstack.height - callstack.clipRect.height) * v;
                callstack.y = ((FlxG.height - callstack.clipRect.height) * 0.5) - callstack.clipRect.y;
                callstack.clipRect = callstack.clipRect;
            };
            scrollBar.cameras = cameras; // fixes hovering issue
            add(scrollBar);
        }

        camera.alpha = 0;
        FlxTween.tween(camera, {alpha: 1}, 0.25);

        FlxG.sound.play(Assets.sound("error"));
        FlxG.mouse.visible = true;
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
            FlxG.switchState(MainMenu.new);

        questionMark.angle = 5 * FlxMath.fastSin(rotateSine += elapsed * 1.25);
        super.update(elapsed);
    }

    override function destroy():Void {
        FlxG.mouse.visible = false;
        super.destroy();
    }
}
#end