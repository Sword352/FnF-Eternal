package funkin.gameplay.components;

@:structInit
class Judgement implements IFlxDestroyable {
    /**
     * The default judgement preset.
     */
    public static final list:Array<Judgement> = [
        {name: "mad",   rank: new Rank("MFC", FlxColor.PINK), score: 450, health: 0.02, hitWindow: 22.5},
        {name: "sick",  rank: new Rank("SFC", FlxColor.CYAN)},
        {name: "good",  rank: new Rank("GFC", FlxColor.LIME), score: 150, accuracyMod: 0.85, hitWindow: 90,  displaySplash: false},
        {name: "bad",   score: 50,  health: 0.005,   accuracyMod: 0.3, hitWindow: 135, invalidateRank: true, displaySplash: false},
        {name: "awful", score: -25, health: -0.0075, accuracyMod: 0,   hitWindow: 175, invalidateRank: true, displaySplash: false, breakCombo: true}
    ];

    /**
     * Name for this judgement.
     */
    public var name:String;

    /**
     * Score amount the player gains from hitting this judgement.
     */
    @:optional public var score:Float = 300;

    /**
     * Health amount the player gains from hitting this judgement.
     */
    @:optional public var health:Float = 0.01;

    /**
     * Accuracy this judgement gives, ranging from 0 to 1.
     */
    @:optional public var accuracyMod:Float = 1;

    /**
     * Hit window not to exceed in order to obtain this judgement.
     */
    @:optional public var hitWindow:Float = 45;

    /**
     * Rank the game chooses if you don't exceed this judgement's `missThreshold`.
     */
    @:optional public var rank:Rank = null;

    /**
     * Miss amount not to exceed in order to get this judgement's `rank`.
     */
    @:optional public var missThreshold:Int = 1;

    /**
     * Whether to invalidate ranks if this judgement gets 1 hit or more.
     */
    @:optional public var invalidateRank:Bool = false;

    /**
     * Whether this judgement pops a splash.
     */
    @:optional public var displaySplash:Bool = true;

    /**
     * Whether this judgement breaks the combo.
     */
    @:optional public var breakCombo:Bool = false;

    /**
     * Returns a string representation of this judgement.
     */
    public function toString():String {
        return this.name;
    }

    /**
     * Clean up memory.
     */
    public function destroy():Void {
        rank = FlxDestroyUtil.destroy(rank);
        name = null;
    }
}
