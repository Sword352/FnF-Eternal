package funkin.gameplay.stages;

import funkin.objects.OffsetSprite;
import funkin.objects.DancingSprite;
import funkin.data.StageData;

class SoftcodedStage extends Stage {
    public var stage(default, null):String;
    public var spriteByName:Map<String, FlxSprite> = [];
    public var script:Script;

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

        var data:StageData = Tools.parseYAML(FileTools.getContent(path));
        if (data == null) {
            trace('Error loading stage data "${stage}"!');
            return;
        }

        var scriptPath:String = Assets.script(basePath);
        if (FileTools.exists(scriptPath)) {
            script = Script.load(scriptPath);
            script.set("this", this);

            game.scripts.add(script);
            script.call("onStageCreation");
        }

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
            if (FileTools.exists(path)) game.scripts.load(path);
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
                script?.set(obj.name, sprite);
                spriteByName.set(obj.name, sprite);
            }
        }

        script?.call("onStageCreationPost");
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

            if (playerCam != null) {
                player.cameraOffsets.x += playerCam[0];
                player.cameraOffsets.y += playerCam[1];
            }
        }

        if (opponent != null && opponent != spectator) {
            opponent.setPosition(opponentPos[0], opponentPos[1]);

            if (opponentCam != null) {
                opponent.cameraOffsets.x += opponentCam[0];
                opponent.cameraOffsets.y += opponentCam[1];
            }
        }

        if (spectator != null) {
            spectator.setPosition(spectatorPos[0], spectatorPos[1]);
            spectator.visible = showSpectator;

            if (spectatorCam != null) {
                spectator.cameraOffsets.x += spectatorCam[0];
                spectator.cameraOffsets.y += spectatorCam[1];
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

        script = null;
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
