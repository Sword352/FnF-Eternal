package gameplay.stages;

import objects.OffsetSprite;
import objects.DancingSprite;

#if ENGINE_SCRIPTING
import core.scripting.HScript;
#end

typedef StageConfig = {
    var ?cameraSpeed:Float;
    var ?camBeatZoom:Float;
    var ?hudBeatZoom:Float;
    var ?camBeat:Float;

    var ?cameraZoom:Float;
    var ?hudZoom:Float;

    var ?playerPos:Array<Float>;
    var ?spectatorPos:Array<Float>;
    var ?opponentPos:Array<Float>;
    var ?ratingPos:Array<Float>;

    var ?playerCam:Array<Float>;
    var ?spectatorCam:Array<Float>;
    var ?opponentCam:Array<Float>;

    var ?uiStyle:String;
    var ?hideSpectator:Bool;

    var ?sprites:Array<StageSprite>;
}

typedef StageSprite = {
    var ?name:String; // optional identifier to access the sprite
    var ?image:String;
    var ?library:String;

    var ?type:String; // sparrow, packer... etc
    var ?layer:String; // foreground / spectator
    var ?rectGraphic:Array<Dynamic>; // makeGraphic()

    var ?animations:Array<YAMLAnimation>;
    var ?animationSpeed:Float;
    var ?frameRect:Array<Int>;

    var ?danceSteps:Array<String>;
    var ?danceBeat:Float;

    var ?position:Array<Float>;
    var ?parallax:Array<Float>; // scrollFactor

    var ?antialiasing:Bool;
    var ?color:Dynamic;
    var ?blend:String;
    var ?alpha:Float;

    var ?scale:Array<Float>;
    var ?flip:Array<Bool>;
}

class SoftcodedStage extends Stage {
    public var stage(default, null):String;
    public var spriteByName:Map<String, FlxSprite> = [];

    #if ENGINE_SCRIPTING
    public var script:HScript;
    #end

    var spectatorPos:Array<Float> = [600, 0];
    var opponentPos:Array<Float> = [350, 0];
    var playerPos:Array<Float> = [800, 0];
    var ratingPos:Array<Float> = [500, 0];

    var spectatorCam:Array<Float> = null;
    var opponentCam:Array<Float> = null;
    var playerCam:Array<Float> = null;

    var dancingSprites:Array<DancingSprite> = [];
    var spectatorLayer:Array<FlxSprite> = [];
    var fgSprites:Array<FlxSprite> = [];

    var showSpectator:Bool = true;

    public function new(stage:String):Void {
        this.stage = stage;
        super();
    }

    override function create():Void {
        if (stage.length == 0) return;

        var basePath:String = 'data/stages/${stage}';
        var path:String = Assets.yaml(basePath);

        if (!FileTools.exists(path) || FileTools.isDirectory(path)) {
            trace('Could not find stage "${stage}"!');
            return;
        }

        var data:StageConfig = Tools.parseYAML(FileTools.getContent(path));
        if (data == null) {
            trace('Error loading stage data "${stage}"!');
            return;
        }

        #if ENGINE_SCRIPTING
        var scriptPath:String = Assets.script(basePath);
        if (FileTools.exists(scriptPath)) {
            script = new HScript(scriptPath);
            script.set("this", this);

            game.addScript(script);
            script.call("onStageCreation");
        }
        #end

        if (data.cameraSpeed != null) camSpeed = data.cameraSpeed;
        if (data.cameraZoom != null) camZoom = data.cameraZoom;
        if (data.hudZoom != null) hudZoom = data.hudZoom;

        if (data.camBeatZoom != null) gameBeatBump = data.camBeatZoom;
        if (data.hudBeatZoom != null) hudBeatBump = data.hudBeatZoom;
        if (data.camBeat != null) camBumpInterval = data.camBeat;

        if (data.playerPos != null) playerPos = arrayCheck(data.playerPos);
        if (data.spectatorPos != null) spectatorPos = arrayCheck(data.spectatorPos);
        if (data.opponentPos != null) opponentPos = arrayCheck(data.opponentPos);
        if (data.ratingPos != null) ratingPos = arrayCheck(data.ratingPos);

        if (data.playerCam != null) playerCam = arrayCheck(data.playerCam);
        if (data.spectatorCam != null) spectatorCam = arrayCheck(data.spectatorCam);
        if (data.opponentCam != null) opponentCam = arrayCheck(data.opponentCam);

        if (data.hideSpectator != null) showSpectator = !data.hideSpectator;

        if (data.uiStyle != null) {
            // ui style script
            var path:String = Assets.script('scripts/uiStyles/${data.uiStyle}');
            if (FileTools.exists(path)) game.loadScript(path);

            uiStyle = "-" + data.uiStyle;
        }

        if (data.sprites == null) return;

        for (obj in data.sprites) {
            var sprite:DancingSprite = new DancingSprite();

            if (obj.danceSteps != null) {
                sprite.danceSteps = obj.danceSteps;
                sprite.beat = obj.danceBeat ?? 1;
                dancingSprites.push(sprite);
            }

            switch ((obj.type ?? "").toLowerCase().trim()) {
                case "rect": sprite.makeGraphic(obj.rectGraphic[0], obj.rectGraphic[1], Tools.getColor(obj.rectGraphic[2]));
                case "sparrow": sprite.frames = Assets.getSparrowAtlas(obj.image, obj.library);
                case "packer": sprite.frames = Assets.getPackerAtlas(obj.image, obj.library);
                case "aseprite": sprite.frames = Assets.getAseAtlas(obj.image, obj.library);
                default:
                    if (obj.frameRect != null)
                        sprite.loadGraphic(Assets.image(obj.image, obj.library), true, obj.frameRect[0], obj.frameRect[1]);
                    else
                        sprite.loadGraphic(Assets.image(obj.image, obj.library));
            }

            if (obj.antialiasing != null) sprite.antialiasing = obj.antialiasing;
            if (obj.color != null) sprite.color = Tools.getColor(obj.color);
            if (obj.alpha != null) sprite.alpha = obj.alpha;
            if (obj.blend != null) sprite.blend = obj.blend;

            if (obj.position != null) sprite.setPosition(obj.position[0] ?? 0, obj.position[1] ?? 0);
            if (obj.parallax != null) sprite.scrollFactor.set(obj.parallax[0] ?? 0, obj.parallax[1] ?? 0);

            if (obj.scale != null) {
                sprite.scale.set(obj.scale[0] ?? 1, obj.scale[1] ?? 1);
                sprite.updateHitbox();
            }

            if (obj.flip != null) {
                sprite.flipX = obj.flip[0] ?? false;
                sprite.flipY = obj.flip[1] ?? false;
            }

            switch ((obj.layer ?? "").toLowerCase().trim()) {
                case "foreground" | "fg":
                    fgSprites.push(sprite);
                case "spectator" | "front-spectator" | "spectator-front":
                    spectatorLayer.push(sprite);
                default:
                    add(sprite);
            }

            if (obj.animations != null)
                Tools.addYamlAnimations(sprite, obj.animations);

            if (obj.animationSpeed != null)
                sprite.animation.timeScale = obj.animationSpeed;

            if (obj.name != null) {
                #if ENGINE_SCRIPTING
                script?.set(obj.name, sprite);
                #end

                spriteByName.set(obj.name, sprite);
            }
        }

        #if ENGINE_SCRIPTING
        script?.call("onStageCreationPost");
        #end
    }

    override function createPost():Void {
        for (spr in spectatorLayer) {
            if (spectator != null)
                addInFront(spr, spectator);
            else
                add(spr);
        }

        for (spr in fgSprites)
            add(spr);

        if (player != null) {
            player.setPosition(playerPos[0], playerPos[1]);

            if (player.globalOffsets != null) {
                player.x -= player.globalOffsets[0] ?? 0;
                player.y -= player.globalOffsets[1] ?? 0;
            }

            if (playerCam != null) {
                if (player.cameraOffsets == null) player.cameraOffsets = [0, 0];
                player.cameraOffsets[0] += playerCam[0];
                player.cameraOffsets[1] += playerCam[1];
            }
        }

        if (opponent != null && opponent != spectator) {
            opponent.setPosition(opponentPos[0], opponentPos[1]);

            if (opponent.globalOffsets != null) {
                opponent.x -= opponent.globalOffsets[0] ?? 0;
                opponent.y -= opponent.globalOffsets[1] ?? 0;
            }

            if (opponentCam != null) {
                if (opponent.cameraOffsets == null) opponent.cameraOffsets = [0, 0];
                opponent.cameraOffsets[0] += opponentCam[0];
                opponent.cameraOffsets[1] += opponentCam[1];
            }
        }

        if (spectator != null) {
            spectator.setPosition(spectatorPos[0], spectatorPos[1]);
            spectator.visible = showSpectator;

            if (spectatorCam != null) {
                if (spectator.cameraOffsets == null) spectator.cameraOffsets = [0, 0];
                spectator.cameraOffsets[0] += spectatorCam[0];
                spectator.cameraOffsets[1] += spectatorCam[1];
            }

            if (spectator.globalOffsets != null) {
                spectator.x -= spectator.globalOffsets[0] ?? 0;
                spectator.y -= spectator.globalOffsets[1] ?? 0;
            }
        }

        if (!Options.uiJudgements)
            game.ratingSprites.setPosition(ratingPos[0], ratingPos[1]);
    }

    override function beatHit(beat:Int):Void {
        for (spr in dancingSprites)
            spr.dance(beat);
    }

    override function destroy():Void {
        spriteByName.clear();
        spriteByName = null;

        spectatorPos = null;
        opponentPos = null;
        playerPos = null;
        ratingPos = null;

        spectatorCam = null;
        opponentCam = null;
        playerCam = null;

        dancingSprites = null;
        spectatorLayer = null;
        fgSprites = null;

        #if ENGINE_SCRIPTING
        script = null;
        #end

        stage = null;

        super.destroy();
    }

    inline static function arrayCheck(array:Array<Float>, defaultVal:Float = 0):Array<Float> {
        if (array == null)
            return [defaultVal, defaultVal];

        while (array.length < 2)
            array.push(defaultVal);
        return array;
    }
}
