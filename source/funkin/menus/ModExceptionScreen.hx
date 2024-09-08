package funkin.menus;

import flixel.FlxState;
import flixel.text.FlxText;

class ModExceptionScreen extends FlxState {
    override function create():Void {
        Tools.stopAllSounds();

        super.create();

        var background:FlxSprite = new FlxSprite();
        background.loadGraphic(Assets.image("menus/exceptions/no-mods"));
        background.setGraphicSize(FlxG.width, FlxG.height);
        background.updateHitbox();
        background.alpha = 0.4;
        add(background);

        var warningText = new FlxText();
        warningText.setFormat(Assets.font("vcr"), 33, FlxColor.WHITE, CENTER);

        var message:String = "Uh oh, looks like no mods has been found!\n";
        message += "Please install mods before opening the game.\n\n";
        message += "Press R to refresh the mod list.\n";
        message += "Press ESCAPE to leave the game.\n";
        message += "\nIf this message still appears with mods, or a problem occurs,\n";
        message += "consider making a issue in the github repository\n";
        message += "by pressing ENTER!";
        warningText.text = message;

        warningText.screenCenter();
        add(warningText);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if (FlxG.keys.justPressed.ENTER)
            FlxG.openURL(Tools.githubURL);

        if (FlxG.keys.justPressed.ESCAPE) {
            #if DISCORD_RPC
            DiscordRPC.self.shutdown();
            #end
            Sys.exit(0);
        }

        if (FlxG.keys.justPressed.R) {
            Mods.refreshMods();
            if (Mods.mods.length > 0) {
                Transition.skipNextTransIn = TitleScreen.firstTime;
                FlxG.switchState((TitleScreen.firstTime) ? TitleScreen.new : MainMenu.new);
            }
        }
    }
}
