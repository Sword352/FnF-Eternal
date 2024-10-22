package funkin.gameplay.components;

import funkin.data.StageData;
import funkin.objects.Bopper;
import funkin.core.scripting.Script;
import flixel.group.FlxSpriteGroup;

/**
 * Object which allows for the creation of stages.
 * Stages can be made by providing data in YAML files in the `data/stages` folder.
 * Stage-specific logic can also be implemented by creating a script under the same path and file name.
 */
class Stage extends FlxSpriteGroup {
    /**
     * Sprite group containing sprites layered in front of characters.
     */
    public var frontLayer:FlxSpriteGroup;

    /**
     * Sprite group containing sprites layered in front of the spectator.
     */
    public var spectatorLayer:FlxSpriteGroup;

    /**
     * UI style for this stage.
     */
    public var uiStyle:String = "";
    
    /**
     * Array containing sprites reacting to the beat.
     */
    var dancingSprites:Array<Bopper> = [];

    /**
     * Player position.
     */
    var playerPos:Array<Float> = [800];

    /**
     * Player camera offsets.
     */
    var playerCam:Array<Float> = [];

    /**
     * Spectator position.
     */
    var spectatorPos:Array<Float> = [600];

    /**
     * Spectator camera offsets.
     */
    var spectatorCam:Array<Float> = [];

    /**
     * Opponent position.
     */
    var opponentPos:Array<Float> = [350];

    /**
     * Opponent camera offsets.
     */
    var opponentCam:Array<Float> = [];

    /**
     * Whether to hide the spectator.
     */
    var hideSpectator:Bool = false;

    /**
     * Reference to the stage script.
     */
    var script:Script;

    /**
     * Creates a new `Stage`.
     * @param stage Stage to build.
     */
    public function new(stage:String):Void {
        super();
        buildStage(stage);
    }

    /**
     * Handles stage creation.
     */
    function buildStage(stage:String):Void {
        var data:StageData = Paths.yaml('data/stages/${stage}');
        if (data == null) {
            trace('Could not find stage "${stage}"!');
            return;
        }

        script = PlayState.self.scripts.load('data/stages/${stage}');
        script?.call("onStageCreation");

        if (data.uiStyle != null) {
            PlayState.self.scripts.load('scripts/uiStyles/${data.uiStyle}');
            uiStyle = "-" + data.uiStyle;
        }

        if (data.cameraSpeed != null)
            PlayState.self.cameraSpeed = data.cameraSpeed;
        
        if (data.cameraZoom != null)
            PlayState.self.cameraZoom = PlayState.self.camGame.zoom = data.cameraZoom;

        if (data.hudZoom != null)
            PlayState.self.hudZoom = PlayState.self.camHUD.zoom = data.hudZoom;

        if (data.camBeatZoom != null)
            PlayState.self.gameBeatBump = data.camBeatZoom;
        
        if (data.hudBeatZoom != null)
            PlayState.self.hudBeatBump = data.hudBeatZoom;

        if (data.camBeat != null)
            PlayState.self.camBumpInterval = data.camBeat;

        playerPos = data.playerPos ?? playerPos;
        playerCam = data.playerCam ?? playerCam;
        
        spectatorPos = data.spectatorPos ?? spectatorPos;
        spectatorCam = data.spectatorCam ?? spectatorCam;

        opponentPos = data.opponentPos ?? opponentPos;
        opponentCam = data.opponentCam ?? opponentCam;

        hideSpectator = (data.hideSpectator != null ? data.hideSpectator : false);

        if (data.sprites != null)
            buildSprites(data.sprites);

        script?.call("onStageCreationPost");
    }

    /**
     * Handles sprite creation.
     * @param sprites Sprites to create.
     */
    function buildSprites(sprites:Array<StageSprite>):Void {
        for (data in sprites) {
            var sprite:Bopper = new Bopper();

            switch ((data.layer ?? "").toLowerCase().trim()) {
                case "foreground":
                    if (frontLayer == null)
                        frontLayer = new FlxSpriteGroup();
                    frontLayer.add(sprite);
                case "spectator":
                    if (spectatorLayer == null)
                        spectatorLayer = new FlxSpriteGroup();
                    spectatorLayer.add(sprite);
                default:
                    add(sprite);
            }

            if (data.danceSteps != null) {
                sprite.danceInterval = data.danceBeat ?? 1;
                sprite.danceSteps = data.danceSteps;
                dancingSprites.push(sprite);
            }

            if (data.rectGraphic != null)
                sprite.makeGraphic(data.rectGraphic[0], data.rectGraphic[1], Tools.getColor(data.rectGraphic[2]));
            else if (data.frameRect != null)
                sprite.loadGraphic(Paths.image(data.image), true, data.frameRect[0], data.frameRect[1]);
            else
                sprite.frames = Paths.buildAtlas(data.image);

            if (data.color != null)
                sprite.color = Tools.getColor(data.color);

            if (data.antialiasing != null)
                sprite.antialiasing = data.antialiasing;

            if (data.alpha != null)
                sprite.alpha = data.alpha;

            if (data.blend != null)
                sprite.blend = data.blend;

            if (data.position != null)
                sprite.setPosition(data.position[0] ?? 0, data.position[1] ?? 0);
            
            if (data.parallax != null)
                sprite.scrollFactor.set(data.parallax[0] ?? 1, data.parallax[1] ?? 1);

            if (data.scale != null) {
                sprite.scale.set(data.scale[0] ?? 1, data.scale[1] ?? 1);
                sprite.updateHitbox();
            }

            if (data.flip != null) {
                sprite.flipX = data.flip[0] ?? false;
                sprite.flipY = data.flip[1] ?? false;
            }

            if (data.animations != null)
                Tools.addYamlAnimations(sprite, data.animations);

            if (data.animationSpeed != null)
                sprite.animation.timeScale = data.animationSpeed;

            if (data.name != null)
                script?.set(data.name, sprite);
        }
    }

    /**
     * Applies corresponding data to a character.
     * @param character Target character.
     * @param position World position for this character.
     * @param camOffsets Camera offsets for this character.
     */
    function applyCharacterData(character:Character, position:Array<Float>, camOffsets:Array<Float>):Void {
        if (character == null) return;

        character.setPosition(position[0] ?? 0, position[1] ?? 0);

        if (camOffsets != null) {
            character.cameraOffsets.x += camOffsets[0] ?? 0;
            character.cameraOffsets.y += camOffsets[1] ?? 0;
        }
    }

    /**
     * Method to call once characters are setup in gameplay.
     */
    public function postBuild():Void {
        var game:PlayState = PlayState.self;

        if (spectatorLayer != null) {
            if (game.spectator != null)
                game.insert(game.members.indexOf(game.spectator) + 1, spectatorLayer);
            else
                game.add(spectatorLayer);
        }

        if (frontLayer != null)
            game.add(frontLayer);

        applyCharacterData(game.player, playerPos, playerCam);
        applyCharacterData(game.spectator, spectatorPos, spectatorCam);

        if (game.opponent != null && game.opponent != game.spectator)
            applyCharacterData(game.opponent, opponentPos, opponentCam);

        if (game.spectator != null)
            game.spectator.visible = !hideSpectator;
    }

    /**
     * Makes stage elements react to the beat.
     * @param beat Current beat in the song.
     */
    public function dance(beat:Int):Void {
        for (sprite in dancingSprites)
            sprite.dance(beat);
    }

    /**
     * Clean up memory.
     */
    override function destroy():Void {
        playerPos = null;
        playerCam = null;
        spectatorPos = null;
        spectatorCam = null;
        opponentPos = null;
        opponentCam = null;

        dancingSprites = null;
        uiStyle = null;
        script = null;

        super.destroy();
    }
}
