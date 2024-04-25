package funkin.states.editors.chart;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.filters.BlurFilter;
import haxe.ui.events.UIEvent;
import haxe.ui.events.MouseEvent;
import haxe.ui.backend.flixel.UISubState;

@:xml('
<box width="100%" height="100%">
    <box verticalAlign="center" horizontalAlign="center" style="width: 195px; height: 150px; background-color: #3A3C3E; border-color: black; border-radius: 4px;">
        <vbox verticalAlign="center" horizontalAlign="center" style="spacing: 15px;">
            <section-header text="Options" />
            <grid>
                <checkbox text="Play from here" id="playHere" />
                <label text="(+SHIFT)" horizontalAlign="right" />
                <checkbox text="Play as opponent" id="playAsOpp" />
                <label text="(+P)" horizontalAlign="right" />
            </grid>
            <vbox width="100%" style="spacing: 7px;">
                <rule />
                <button horizontalAlign="center" text="Play" id="playBtn" />
            </vbox>
        </vbox>
    </box>
</box>
')
class PlayTestScreen extends UISubState {
    static var playHereSelected:Bool = false;
    static var playAsOppSelected:Bool = false;

    var parent(get, never):ChartEditor;
    inline function get_parent():ChartEditor
        return cast FlxG.state;

    var tweens:Array<FlxTween> = [];
    var background:FlxSprite;
    var blur:BlurFilter;

    override function create():Void {
        super.create();

        background = new FlxSprite();
        background.makeRect(FlxG.width, FlxG.height, FlxColor.BLACK, false, "charteditor_substatebg");
        background.alpha = 0;
        insert(0, background);

        blur = new BlurFilter();
        parent.camera.filters = parent.miniMap.filters = [blur];

        blur.blurX = blur.blurY = 0;
        tweens.push(FlxTween.num(0, 4, 0.35, null, (v) -> {
            blur.blurX = blur.blurY = v;
            background.alpha = 0.15 * v; // 0.6
        }));

        parent.substateCam.zoom = 0.2;
        tweens.push(FlxTween.tween(parent.substateCam, {zoom: 1}, 0.25, {ease: FlxEase.expoOut}));
    }

    override function update(elapsed:Float):Void {
        if (FlxG.keys.justPressed.ESCAPE) close();

        background.scale.set(FlxG.width / camera.zoom, FlxG.height / camera.zoom);
        super.update(elapsed);
    }

    override function onReady():Void {
        playAsOpp.selected = playAsOppSelected;
        playHere.selected = playHereSelected;
    }

    @:bind(playBtn, MouseEvent.CLICK)
    function playBtn_click(_):Void {
        parent.playTest(playHere.selected, playAsOpp.selected);
    }

    override function destroy():Void {
        for (tween in tweens)
            if (!tween.finished)
                tween.cancel();

        blur = null;
        parent.camera.filters = null;
        parent.miniMap.filters = null;
        tweens = null;

        playAsOppSelected = playAsOpp.selected;
        playHereSelected = playHere.selected;
        parent.substateCam.zoom = 1;

        super.destroy();
    }
}
