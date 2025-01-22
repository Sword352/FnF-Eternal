package funkin.menus.options;

import flixel.text.FlxText;
import flixel.group.FlxSpriteContainer;
import funkin.objects.SolidSprite;
import funkin.objects.Metronome;
import funkin.ui.Alphabet;

/**
 * Substate in which the user can modify their audio offset preference.
 */
class OffsetCalibrationOverlay extends MusicBeatSubState {
    /**
     * Holds the mesured offsets to calculate the average offset.
     */
    var mesuredOffsets:Array<Float> = [];

    /**
     * Value used to limit inputs under certain circumstances,
     * mainly to avoid interferences.
     */
    var inputLimiter:Float = 0.1;

    /**
     * Holds the user's audio offset without quantization.
     * Used to maintain input responsivness despite quantizing the preference.
     */
    var unquantizedOffset:Float = Options.audioOffset;

    /**
     * Holds the last beat time to calculate the offset when the user presses the enter key.
     */
    var lastBeat:Float = 0;

    var display:CalibratorDisplay;
    var userOffsetText:Alphabet;
    var estimationText:FlxText;
    var metronome:Metronome;

    override function create():Void {
        FlxG.sound.music.fadeOut(0.25);

        conductor = new Conductor();
        conductor.interpolate = true;
        conductor.active = false;
        add(conductor);

        metronome = new Metronome();
        metronome.conductor = conductor;
        metronome.active = false;
        add(metronome);

        display = new CalibratorDisplay();
        display.conductor = conductor;
        add(display);

        var header:Alphabet = new Alphabet(0, 10);
        header.scale.set(0.95, 0.95);
        header.text = "Offset Calibration";
        header.screenCenter(X);
        add(header);

        userOffsetText = new Alphabet(display.x, display.y + display.height + 10);
        userOffsetText.scale.set(0.5, 0.5);
        updateOffsetText();
        add(userOffsetText);

        var font:String = Paths.font("lato");

        var instructions:FlxText = new FlxText(0, display.y + 25);
        instructions.setFormat(font, 20, CENTER);
        instructions.text = "Press Enter to start the calibration test.\nTap along with the beat at any point.\nThe test will end after 16 ticks.";
        instructions.centerHorizontallyTo(display);
        instructions.active = false;
        add(instructions);

        estimationText = new FlxText(0, display.y + display.height - 75);
        estimationText.setFormat(font, 18, CENTER);
        estimationText.active = false;
        add(estimationText);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if (inputLimiter > 0) {
            inputLimiter = Math.max(inputLimiter - elapsed, 0);
        }

        if (conductor.rawTime - lastBeat >= conductor.beatLength) {
            lastBeat += conductor.beatLength;
            // end the metronome early as audio shouldn't be affected by offset
            if (lastBeat >= conductor.beatLength * 16) {
                metronome.active = false;
            }
        }

        if (conductor.active && conductor.time >= conductor.beatLength * 16) {
            stopCalibration();
        }

        if (inputLimiter == 0 && FlxG.keys.justPressed.ENTER) {
            if (conductor.active) {
                registerOffset(MathTools.quantizeToNearest(conductor.time - lastBeat, 0.1));
            } else {
                startCalibration();
            }
        }

        if (controls.pressed("left"))
            incrementOffset(-elapsed);

        if (controls.pressed("right"))
            incrementOffset(elapsed);

        if (controls.justPressed("back"))
            close();
    }

    function startCalibration():Void {
        display.clearOffsetStrips();
        mesuredOffsets.resize(0);
        conductor.active = true;
        metronome.active = true;
        metronome.lastBeat = 0;
        lastBeat = 0;
    }

    function stopCalibration():Void {
        conductor.active = false;
        conductor.time = 0;
        inputLimiter = 0.1;
    }

    function incrementOffset(elapsed:Float):Void {
        var increment:Float = 10 * elapsed;

        if (FlxG.keys.pressed.SHIFT)
            increment *= 5;
        else if (FlxG.keys.pressed.CONTROL)
            increment /= 5;

        unquantizedOffset = Math.max(unquantizedOffset + increment, 0);
        Options.audioOffset = MathTools.quantizeToNearest(unquantizedOffset, 0.1);
        updateOffsetText();   
    }

    function updateOffsetText():Void {
        userOffsetText.text = "< " + Options.audioOffset + "ms >";
    }

    function registerOffset(offset:Float):Void {
        display.addOffsetStrip();
        mesuredOffsets.push(offset);

        var average:Float = MathTools.quantizeToNearest(MathTools.average(mesuredOffsets), 0.1);
        estimationText.text = "Average: " + average + "ms";
        estimationText.screenCenter(X);
    }

    override function close():Void {
        FlxG.sound.music.fadeOut(0.25, 1);
        OptionsManager.save();
        super.close();
    }

    override function destroy():Void {
        mesuredOffsets = null;
        userOffsetText = null;
        estimationText = null;
        metronome = null;
        display = null;
        super.destroy();
    }
}

/**
 * Displays the calibrator which helps the user finding their offset.
 */
class CalibratorDisplay extends FlxSpriteContainer {
    /**
     * Conductor this `CalibratorDisplay` will listen to.
     */
    public var conductor:Conductor;

    var userOffsets:FlxTypedSpriteContainer<SolidSprite>;
    var conductorStrip:SolidSprite;
    var middleStrip:SolidSprite;

    /**
     * Creates a new `CalibratorDisplay` instance.
     */
    public function new():Void {
        super();

        var background:SolidSprite = new SolidSprite(0, 0, FlxG.width * 0.75, FlxG.height * 0.65);
        background.color = FlxColor.BLACK;
        background.alpha = 0.5;
        add(background);

        middleStrip = new SolidSprite(0, 0, background.width - 20, 2);
        middleStrip.color = 0x3C3B4F;
        middleStrip.centerTo(background);
        add(middleStrip);

        conductorStrip = new SolidSprite(0, 0, 5, 200);
        conductorStrip.color = 0x404141;
        conductorStrip.centerVerticallyTo(background);
        add(conductorStrip);

        for (i in 0...8) {
            var sprite:SolidSprite = new SolidSprite(0, 0, 20, 20);
            sprite.color = FlxColor.WHITE;
            sprite.angle = 45;
            add(sprite);

            sprite.x = middleStrip.x + (middleStrip.width - sprite.width) * ((i + 1) / 8);
            sprite.centerVerticallyTo(background);
        }

        userOffsets = new FlxTypedSpriteContainer();
        add(userOffsets);

        screenCenter();
    }

    override function update(elapsed:Float):Void {
        var progress:Float = Math.max(conductor.decBeat, 0) % 8 / 8;
        conductorStrip.x = middleStrip.x + (middleStrip.width - conductorStrip.width) * progress;

        #if FLX_DEBUG
        FlxBasic.activeCount++;
        #end
    }

    /**
     * Adds a strip representing the user's key press in the timeline.
     */
    public function addOffsetStrip():Void {
        userOffsets.recycle(offsetStripConstructor).x = conductorStrip.x;
    }

    /**
     * Kills every user strips.
     */
    public function clearOffsetStrips():Void {
        userOffsets.group.killMembers();
    }

    override function destroy():Void {
        conductorStrip = null;
        middleStrip = null;
        userOffsets = null;
        conductor = null;
        super.destroy();
    }

    function offsetStripConstructor():SolidSprite {
        var strip:SolidSprite = new SolidSprite(0, 0, 5, 150);
        strip.color = 0x2FB5C7;
        strip.screenCenter(Y);
        return strip;
    }
}
