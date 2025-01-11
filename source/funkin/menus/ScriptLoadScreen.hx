package funkin.menus;

import flixel.text.FlxText;
import funkin.ui.LoadingText;
import funkin.ui.SpinningCircle;
import funkin.objects.StarlightBackground;
import flixel.util.typeLimit.NextState;

/**
 * Screen displayed at the boot of the game to load every scripts.
 */
class ScriptLoadScreen extends ScriptLoadOverlay {
    var loadingText:LoadingText;
    var progressText:FlxText;
    var doneText:FlxText;

    override function create():Void {
        // don't display the transition since this is the boot screen
        Transition.skipNextTransIn = true;

        // no need for a background color
        bgColor.alphaFloat = 0;

        add(new StarlightBackground());

        spinningCircle = new SpinningCircle();
        add(spinningCircle);

        var textFont:String = Paths.font("lato");

        loadingText = new LoadingText(10);
        loadingText.setFormat(textFont, 32);
        loadingText.text = "Loading scripts";
        loadingText.cacheSize();
        add(loadingText);

        progressText = new FlxText(10);
        progressText.setFormat(textFont, 28);
        progressText.active = false;
        progressText.text = "?";
        add(progressText);

        doneText = new FlxText();
        doneText.setFormat(textFont, 32);
        doneText.visible = false;
        doneText.active = false;
        doneText.text = "Done!";
        add(doneText);

        var logo:FlxSprite = new FlxSprite(0, 75, Paths.image("menus/logo"));
        logo.scale.set(0.85, 0.85);
        logo.updateHitbox();
        logo.screenCenter(X);
        logo.active = false;
        add(logo);

        progressText.fieldWidth = 150;
        progressText.fieldHeight = progressText.height;

        loadingText.y = FlxG.height - loadingText.height - 10;
        progressText.y = loadingText.y - loadingText.height;
        doneText.setPosition(loadingText.x, loadingText.y);

        Script.loadFromDirectory("").onProgress(onProgress).onComplete(onComplete);
    }

    function onProgress(progress:Int, total:Int):Void {
        progressText.text = progress + "/" + total;
    }
    
    override function onComplete(scripts:Array<Script>):Void {
        loadingText.visible = false;
        loadingText.active = false;
        doneText.visible = true;

        super.onComplete(scripts);
    }

    override function destroy():Void {
        progressText = null;
        loadingText = null;
        doneText = null;
        super.destroy();
    }
}

/**
 * Substate responsible of reloading scripts.
 */
class ScriptLoadOverlay extends ScriptableState.ScriptableSubState {
    /**
     * State to switch to once scripts have been reloaded.
     * If null, the current state will be reset.
     */
    public var targetState:NextState = null;

    var spinningCircle:SpinningCircle;

    /**
     * Opens the overlay on top of the current state if no substate is opened.
     */
    public static function open():Void {
        if (!Std.isOfType(FlxG.state, ScriptLoadScreen) && FlxG.state.subState == null)
            FlxG.state.openSubState(new ScriptLoadOverlay());
    }

    /**
     * Creates a new `ScriptLoadOverlay`.
     * @param targetState State to switch to once scripts have been reloaded. If null, the current state will be reset.
     */
    public function new(?targetState:NextState):Void {
        var backgroundColor:FlxColor = FlxColor.BLACK;
        backgroundColor.alphaFloat = 0.7;

        this.targetState = targetState;
        super(backgroundColor);
    }

    override function create():Void {
        spinningCircle = new SpinningCircle();
        spinningCircle.scrollFactor.set();
        add(spinningCircle);

        // makes sure the background renders on top of the state
        _bgSprite.cameras = cameras;

        ScriptManager.reset();
        Script.loadFromDirectory("").onComplete(onComplete);
    }

    /**
     * Method called once scripts have been reloaded.
     * @param scripts Loaded scripts.
     */
    function onComplete(scripts:Array<Script>):Void {
        spinningCircle.fade(false, switchState);
        ScriptManager.register(scripts);
    }

    function switchState():Void {
        if (this != FlxG.state) {
            // only set this flag to true if this substate hasn't been opened as a state
            // since this is not a TransitionableState
            Transition.skipNextTransOut = true;
        }

        if (targetState != null)
            FlxG.switchState(targetState);
        else
            FlxG.resetState();
    }

    override function destroy():Void {
        spinningCircle = null;
        targetState = null;
        super.destroy();
    }
}
