package funkin.objects.stages;

import funkin.objects.sprites.DancingSprite;

#if ENGINE_SCRIPTING
import eternal.core.scripting.HScript;
#end

typedef StageData = {
    var ?cameraSpeed:Float;
    var ?cameraZoom:Float;
    var ?hudZoom:Float;

    var ?hideSpectator:Bool;

    // TODO: smaller field names, and rename objects to sprites
    var ?playerPosition:Array<Float>;
    var ?spectatorPosition:Array<Float>;
    var ?opponentPosition:Array<Float>;
    var ?ratingPosition:Array<Float>;

    var ?playerCameraOffset:Array<Float>;
    var ?spectatorCameraOffset:Array<Float>;
    var ?opponentCameraOffset:Array<Float>;

    var ?objects:Array<StageObject>;
}

// TODO: maybe add shader support for stage sprites?
typedef StageObject = {
    var ?name:String; // optional identifier to access the sprite
    var ?image:String;
    var ?library:String;

    var ?type:String; // sparrow, packer... etc
    var ?layer:String; // foreground / spectator
    var ?rectGraphic:Array<Dynamic>; // makeGraphic()

    var ?animations:Array<YAMLAnimation>;
    var ?animationSpeed:Float;
    var ?frameRect:Array<Int>;

    var ?danceAnimations:Array<String>;
    var ?danceBeat:Float;
    
    var ?position:Array<Float>;
    var ?parallax:Array<Float>; // same as scrollFactor
    var ?scrollFactor:Array<Float>;

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

    var spectatorPosition:Array<Float> = [600, 0];
    var opponentPosition:Array<Float> = [350, 0];
    var playerPosition:Array<Float> = [800, 0];
    var ratingPosition:Array<Float> = [500, 0];

    var spectatorCameraOffset:Array<Float> = null;
    var opponentCameraOffset:Array<Float> = null;
    var playerCameraOffset:Array<Float> = null;

    var dancingSprites:Array<DancingSprite> = [];
    var spectatorLayer:Array<FlxSprite> = [];
    var fgSprites:Array<FlxSprite> = [];

    var showSpectator:Bool = true;
    
    public function new(stage:String):Void {
        this.stage = stage;
        super();
    }

    override function create():Void {
        if (stage.length < 1)
            return;

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

        #if ENGINE_SCRIPTING
        var scriptPath:String = Assets.getPath(basePath, SCRIPT);
        if (FileTools.exists(scriptPath)) {
            script = new HScript(scriptPath);
            game.addScript(script);

            script.set("this", this);
            script.call("onStageSetup");
        }
        #end

        if (data.cameraSpeed != null)
            camSpeed = data.cameraSpeed;
        if (data.cameraZoom != null)
            camZoom = data.cameraZoom;
        if (data.hudZoom != null)
            hudZoom = data.hudZoom;
        
        if (data.playerPosition != null)
            playerPosition = arrayCheck(data.playerPosition);
        if (data.spectatorPosition != null)
            spectatorPosition = arrayCheck(data.spectatorPosition);
        if (data.opponentPosition != null)
            opponentPosition = arrayCheck(data.opponentPosition);
        if (data.ratingPosition != null)
            ratingPosition = arrayCheck(data.ratingPosition);

        if (data.playerCameraOffset != null)
            playerCameraOffset = arrayCheck(data.playerCameraOffset);
        if (data.spectatorCameraOffset != null)
            spectatorCameraOffset = arrayCheck(data.spectatorCameraOffset);
        if (data.opponentCameraOffset != null)
            opponentCameraOffset = arrayCheck(data.opponentCameraOffset);

        if (data.hideSpectator != null)
            showSpectator = !data.hideSpectator;

        // no need to loop if there is no objects
        if (data.objects == null || data.objects.length < 1)
            return;

        for (obj in data.objects) {
            var sprite:FlxSprite = null;

            if (obj.danceAnimations != null) {
                var dancingSprite = new DancingSprite();
                dancingSprite.danceAnimations = obj.danceAnimations;
                dancingSprite.beat = obj.danceBeat ?? 1;
                dancingSprites.push(dancingSprite);
                sprite = dancingSprite;
            }
            else
                sprite = new OffsetSprite();

            switch ((obj.type ?? "").toLowerCase().trim()) {
                case "sparrow":
                    sprite.frames = Assets.getSparrowAtlas(obj.image, obj.library);
                case "packer":
                    sprite.frames = Assets.getPackerAtlas(obj.image, obj.library);
                case "aseprite":
                    sprite.frames = Assets.getAseAtlas(obj.image, obj.library);
                case "rect":
                    sprite.makeGraphic(obj.rectGraphic[0], obj.rectGraphic[1], Tools.getColor(obj.rectGraphic[2]));
                default:
                    if (obj.frameRect != null)
                        sprite.loadGraphic(Assets.image(obj.image, obj.library), true, obj.frameRect[0], obj.frameRect[1]);
                    else
                        sprite.loadGraphic(Assets.image(obj.image, obj.library));
            }

            if (obj.animations != null)
                Tools.addYamlAnimations(sprite, obj.animations);

            if (obj.animationSpeed != null)
                sprite.animation.timeScale = obj.animationSpeed;

            if (obj.color != null)
                sprite.color = Tools.getColor(obj.color);

            if (obj.blend != null)
                sprite.blend = obj.blend;

            if (obj.position != null)
                sprite.setPosition(obj.position[0] ?? 0, obj.position[1] ?? 0);            

            if (obj.scale != null) {
                sprite.scale.set(obj.scale[0] ?? 1, obj.scale[1] ?? 1);
                sprite.updateHitbox();
            }

            var scrollFactor:Array<Float> = obj.scrollFactor ?? obj.parallax;
            if (scrollFactor != null)
                sprite.scrollFactor.set(scrollFactor[0] ?? 0, scrollFactor[1] ?? 0);

            if (obj.flip != null) {
                sprite.flipX = obj.flip[0] ?? false;
                sprite.flipY = obj.flip[1] ?? false;
            }

            if (obj.alpha != null)
                sprite.alpha = obj.alpha;

            if (obj.antialiasing != null)
                sprite.antialiasing = obj.antialiasing;

            switch ((obj.layer ?? "").toLowerCase().trim()) {
                case "foreground" | "fg":
                    fgSprites.push(sprite);
                case "spectator" | "front-spectator" | "spectator-front":
                    spectatorLayer.push(sprite);
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

                spriteByName.set(obj.name, sprite);
            }
        }

        #if ENGINE_SCRIPTING
        script?.call("onStageSetupPost");
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
            player.setPosition(playerPosition[0], playerPosition[1]);

            if (player.globalOffsets != null) {
                player.x += player.globalOffsets[0] ?? 0;
                player.y += player.globalOffsets[1] ?? 0;
            }

            if (playerCameraOffset != null) {
                if (player.cameraOffsets == null)
                    player.cameraOffsets = [0, 0];
                
                player.cameraOffsets[0] += playerCameraOffset[0];
                player.cameraOffsets[1] += playerCameraOffset[1];
            }
        }

        if (opponent != null && opponent != spectator) {
            opponent.setPosition(opponentPosition[0], opponentPosition[1]);

            if (opponent.globalOffsets != null) {
                opponent.x += opponent.globalOffsets[0] ?? 0;
                opponent.y += opponent.globalOffsets[1] ?? 0;
            }

            if (opponentCameraOffset != null) {
                if (opponent.cameraOffsets == null)
                    opponent.cameraOffsets = [0, 0];

                opponent.cameraOffsets[0] += opponentCameraOffset[0];
                opponent.cameraOffsets[1] += opponentCameraOffset[1];
            }
        }

        if (spectator != null) {
            spectator.setPosition(spectatorPosition[0], spectatorPosition[1]);
            spectator.visible = showSpectator;

            if (spectatorCameraOffset != null) {
                if (spectator.cameraOffsets == null)
                    spectator.cameraOffsets = [0, 0];
                
                spectator.cameraOffsets[0] += spectatorCameraOffset[0];
                spectator.cameraOffsets[1] += spectatorCameraOffset[1];
            }

            if (spectator.globalOffsets != null) {
                spectator.x += spectator.globalOffsets[0] ?? 0;
                spectator.y += spectator.globalOffsets[1] ?? 0;
            }
        }

        if (!Settings.get("judgements on user interface"))
            game.ratingSprites.setPosition(ratingPosition[0], ratingPosition[1]);
    }

    override function beatHit(currentBeat:Int):Void {
        for (spr in dancingSprites)
            spr.dance(currentBeat);
    }

    override function destroy():Void {
        spriteByName.clear();
        spriteByName = null;

        spectatorPosition = null;
        opponentPosition = null;
        playerPosition = null;
        ratingPosition = null;

        spectatorCameraOffset = null;
        opponentCameraOffset = null;
        playerCameraOffset = null;

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
