package funkin.objects.stages;

import flixel.util.FlxAxes;

import flixel.addons.display.FlxBackdrop;
import funkin.objects.sprites.DancingSprite;

#if ENGINE_SCRIPTING
import eternal.core.scripting.HScript;
#end

import funkin.states.PlayState;

typedef StageData = {
    var ?hideSpectator:Bool;

    var ?playerPosition:Array<Float>;
    var ?spectatorPosition:Array<Float>;
    var ?opponentPosition:Array<Float>;
    var ?ratingPosition:Array<Float>;

    var ?playerCameraOffset:Array<Float>;
    var ?spectatorCameraOffset:Array<Float>;
    var ?opponentCameraOffset:Array<Float>;

    var ?cameraZoom:Float;
    var ?hudZoom:Float;
    var ?cameraSpeed:Float;

    var ?objects:Array<StageObject>;
}

typedef StageObject = {
    var ?name:String; // optional identifier to access the sprite

    var ?image:String;
    var ?library:String;
    var ?type:String; // sparrow, packer... etc
    var ?layer:String; // foreground / spectator
    var ?rectGraphic:Array<Dynamic>; // makeGraphic()

    // backdrop stuff
    var ?backdrop:Bool;
    var ?repeatAxes:String;
    var ?spacing:Array<Float>;
    var ?velocity:Array<Float>;

    var ?animations:Array<YAMLAnimation>;
    var ?animationSize:Array<Int>; // used to support animations without atlas
    var ?animationSpeed:Float;

    var ?danceAnimations:Array<String>;
    var ?danceBeat:Float;
    
    var ?position:Array<Float>; // x and y values
    var ?scrollFactor:Array<Float>;
    var ?parallax:Array<Float>; // same as scrollFactor

    var ?alpha:Float;
    var ?color:Dynamic;
    var ?blend:String;

    var ?scale:Array<Float>;
    var ?antialiasing:Bool;
    var ?flip:Array<Bool>;
}

// Only meant to be used in PlayState!
class SoftcodedStage extends BaseStage {
    public var stage(default, null):String = "";

    #if ENGINE_SCRIPTING
    public var script(default, null):HScript;
    #end

    public var sprites:Map<String, FlxSprite> = [];
    
    private var playerPosition:Array<Float>;
    private var spectatorPosition:Array<Float>;
    private var opponentPosition:Array<Float>;
    private var playerCameraOffset:Array<Float>;
    private var spectatorCameraOffset:Array<Float>;
    private var opponentCameraOffset:Array<Float>;
    private var ratingPosition:Array<Float>;
    private var showSpectator:Bool = true;

    private var foregroundSprites:Array<FlxSprite> = [];
    private var spectatorFrontSprites:Array<FlxSprite> = [];
    private var dancingSprites:Array<DancingSprite> = [];
    
    public function new(state:PlayState, stage:String):Void {
        this.stage = stage;
        super(state);
    }

    override function create():Void {
        var basePath:String = 'data/stages/${stage}';

        var path:String = AssetHelper.yaml(basePath);
        if (!FileTools.exists(path) || FileTools.isDirectory(path)) {
            if (stage != null && stage.length > 0)
                trace('Stage file ${stage}.yaml is missing!');
            setDefaults();
            return;
        }

        var data:StageData = Tools.parseYAML(FileTools.getContent(path));
        if (data == null) {
            trace('Error loading stage data!');
            setDefaults();
            return;
        }

        #if ENGINE_SCRIPTING
        var scriptPath:String = AssetHelper.getPath(basePath, SCRIPT);
        if (FileTools.exists(scriptPath)) {
            script = new HScript(scriptPath, false);
            PlayState.current.addScript(script);

            script.set("this", this);
            script.call("onStageSetup");
        }
        #end

        PlayState.current.cameraSpeed = data.cameraSpeed ?? 3;
        PlayState.current.cameraZoom = data.cameraZoom ?? 1;
        PlayState.current.hudZoom = data.hudZoom ?? 1;

        PlayState.current.camGame.zoom = PlayState.current.cameraZoom;
        PlayState.current.camHUD.zoom = PlayState.current.hudZoom;
        
        if (data.playerPosition != null)
            playerPosition = arrayCheck(data.playerPosition);
        else playerPosition = [800, 0];

        if (data.spectatorPosition != null)
            spectatorPosition = arrayCheck(data.spectatorPosition);
        else spectatorPosition = [600, 0];

        if (data.opponentPosition != null)
            opponentPosition = arrayCheck(data.opponentPosition);
        else opponentPosition = [350, 0];

        if (data.ratingPosition != null)
            ratingPosition = arrayCheck(data.ratingPosition);
        else ratingPosition = [500, 0];

        if (data.hideSpectator != null)
            showSpectator = !data.hideSpectator;

        playerCameraOffset = arrayCheck(data.playerCameraOffset);
        opponentCameraOffset = arrayCheck(data.opponentCameraOffset);
        spectatorCameraOffset = arrayCheck(data.spectatorCameraOffset);

        // no need to loop if there is no objects
        if (data.objects == null || data.objects.length < 1)
            return;

        for (obj in data.objects) {
            var sprite:FlxSprite = null;

            if (obj.danceAnimations != null && obj.danceAnimations.length > 0) {
                if (obj.danceBeat == null)
                    obj.danceBeat = 1;

                var dancingSprite = new DancingSprite();
                dancingSprite.beat = obj.danceBeat;
                dancingSprite.danceAnimations = obj.danceAnimations;
                dancingSprites.push(dancingSprite);
                sprite = dancingSprite;
            }
            else if (obj.backdrop != null && obj.backdrop) {
                var repeatAxes:FlxAxes = switch ((obj.repeatAxes ?? "").toLowerCase().trim()) {
                    case "x": X;
                    case "y": Y;
                    default: XY;
                }

                obj.spacing = arrayCheck(obj.spacing);
                sprite = new FlxBackdrop(null, repeatAxes, obj.spacing[0], obj.spacing[1]);
            }
            else
                sprite = new OffsetSprite();

            switch ((obj.type ?? "").toLowerCase().trim()) {
                case "sparrow":
                    sprite.frames = AssetHelper.getSparrowAtlas(obj.image, obj.library);
                case "packer":
                    sprite.frames = AssetHelper.getPackerAtlas(obj.image, obj.library);
                case "aseprite":
                    sprite.frames = AssetHelper.getAseAtlas(obj.image, obj.library);
                case "rect":
                    sprite.makeGraphic(obj.rectGraphic[0], obj.rectGraphic[1], Tools.getColor(obj.rectGraphic[2]));
                default:
                    if (obj.animationSize != null && obj.animationSize.length > 1)
                        sprite.loadGraphic(AssetHelper.image(obj.image, obj.library), true, obj.animationSize[0], obj.animationSize[1]);
                    else
                        sprite.loadGraphic(AssetHelper.image(obj.image, obj.library));
            }

            if (obj.animations != null)
                Tools.addYamlAnimations(sprite, obj.animations);

            if (obj.animationSpeed != null)
                sprite.animation.timeScale = obj.animationSpeed;

            if (obj.color != null)
                sprite.color = Tools.getColor(obj.color);

            if (obj.blend != null)
                sprite.blend = obj.blend;

            obj.position = arrayCheck(obj.position);
            sprite.setPosition(obj.position[0], obj.position[1]);

            obj.scale = arrayCheck(obj.scale, 1);
            if (obj.scale[0] != 1 || obj.scale[1] != 1) {
                sprite.scale.set(obj.scale[0], obj.scale[1]);
                sprite.updateHitbox();
            }

            if (obj.scrollFactor == null && obj.parallax != null && obj.parallax.length > 0)
                obj.scrollFactor = obj.parallax;

            if (obj.scrollFactor != null && obj.scrollFactor.length > 0) {
                while (obj.scrollFactor.length < 2)
                    obj.scrollFactor.push(1);
                sprite.scrollFactor.set(obj.scrollFactor[0], obj.scrollFactor[1]);
            }

            if (obj.flip != null) {
                while (obj.flip.length < 2)
                    obj.flip.push(false);

                sprite.flipX = obj.flip[0];
                sprite.flipY = obj.flip[1];
            }

            if (obj.alpha != null)
                sprite.alpha = obj.alpha;

            if (obj.antialiasing != null)
                sprite.antialiasing = obj.antialiasing;

            if (obj.velocity != null) {
                while (obj.velocity.length < 3)
                    obj.velocity.push(0);

                sprite.velocity.set(obj.velocity[0], obj.velocity[1]);
                sprite.angularVelocity = obj.velocity[2];
            }

            switch ((obj.layer ?? "").toLowerCase().trim()) {
                case "foreground" | "fg":
                    foregroundSprites.push(sprite);
                case "spectator" | "front-spectator" | "spectator-front":
                    spectatorFrontSprites.push(sprite);
                default:
                    add(sprite);
            }

            if (obj.animations != null) {
                if (sprite is OffsetSprite)
                    cast(sprite, OffsetSprite).playAnimation(obj.animations[0].name, true);
                else
                    sprite.animation.play(obj.animations[0].name, true);

                sprite.animation.finish();
            }

            if (obj.name != null) {
                #if ENGINE_SCRIPTING
                script?.set(obj.name, sprite);
                #end
                sprites.set(obj.name, sprite);
            }
        }

        #if ENGINE_SCRIPTING
        script?.call("onStageSetupPost");
        #end
    }

    override function createPost():Void {
        for (spr in spectatorFrontSprites) {
            if (PlayState.current.spectator != null)
                insert(PlayState.current.members.indexOf(PlayState.current.spectator) + 1, spr);
            else
                add(spr);
        }

        for (spr in foregroundSprites)
            add(spr);

        if (PlayState.current.player != null) {
            PlayState.current.player.data.cameraOffsets[0] += playerCameraOffset[0];
            PlayState.current.player.data.cameraOffsets[1] += playerCameraOffset[1];
            PlayState.current.player.setPosition(playerPosition[0], playerPosition[1]);
        }

        if (PlayState.current.opponent != null) {
            PlayState.current.opponent.data.cameraOffsets[0] += opponentCameraOffset[0];
            PlayState.current.opponent.data.cameraOffsets[1] += opponentCameraOffset[1];
            PlayState.current.opponent.setPosition(opponentPosition[0], opponentPosition[1]);
        }

        if (PlayState.current.spectator != null) {
            PlayState.current.spectator.data.cameraOffsets[0] += spectatorCameraOffset[0];
            PlayState.current.spectator.data.cameraOffsets[1] += spectatorCameraOffset[1];
            PlayState.current.spectator.setPosition(spectatorPosition[0], spectatorPosition[1]);
            PlayState.current.spectator.visible = showSpectator;
        }

        if (!Settings.get("judgements on user interface")) {
            PlayState.current.ratingSprites.setPosition(ratingPosition[0], ratingPosition[1]);
            PlayState.current.comboSprites.setPosition(ratingPosition[0] + 40, ratingPosition[1] + 140);
        }
    }

    override function beatHit(currentBeat:Int):Void {
        for (spr in dancingSprites)
            spr.dance(currentBeat);
    }

    override function destroy():Void {
        super.destroy();

        sprites.clear();
        sprites = null;

        playerPosition = null;
        spectatorPosition = null;
        opponentPosition = null;
        ratingPosition = null;
        foregroundSprites = null;
        spectatorFrontSprites = null;
        dancingSprites = null;
        playerCameraOffset = null;
        spectatorCameraOffset = null;
        opponentCameraOffset = null;
        stage = null;

        #if ENGINE_SCRIPTING
        script = null;
        #end
    }

    private function setDefaults():Void {
        playerPosition = [800, 0];
        spectatorPosition = [600, 0];
        opponentPosition = [350, 0];
        ratingPosition = [500, 0];
        playerCameraOffset = spectatorCameraOffset = opponentCameraOffset = [0, 0];
    }

    inline static function arrayCheck(array:Array<Float>, defaultVal:Float = 0):Array<Float> {
        if (array == null)
            return [defaultVal, defaultVal];

        while (array.length < 2)
            array.push(defaultVal);
        return array;
    }
}
