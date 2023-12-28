package funkin.states.menus;

import funkin.objects.ui.Alphabet;
import funkin.objects.sprites.DancingSprite;

import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;

typedef TitleSprite = {
    var ?name:String;

    var ?image:String;
    var ?type:String;
    var ?library:String;

    var ?animations:Array<YAMLAnimation>;
    var ?animationSize:Array<Int>;
    var ?animationSpeed:Float;

    var ?danceAnimations:Array<String>;
    var ?danceBeat:Float;
    
    var ?position:Array<Float>;
    var ?alpha:Float;
    var ?scale:Array<Float>;
    var ?antialiasing:Bool;
    var ?flip:Array<Bool>;
}

typedef TitleSequence = {
    var ?step:Int;
    var ?beat:Int;
    var ?action:String;
    var ?arguments:Array<Dynamic>;
}

class TitleScreen extends MusicBeatState {
    var preRenderSprites:FlxSpriteGroup;
    var postRenderSprites:FlxSpriteGroup;
    var spritesGroup:FlxSpriteGroup;

    var alphabetGroup:FlxTypedGroup<Alphabet>;

    var pressEnterSprite:FlxSprite;
    var ngSprite:FlxSprite;

    var beatSequences:Array<TitleSequence>;
    var stepSequences:Array<TitleSequence>;
    var randomText:Array<String>;

    var allowInputs:Bool = true;
    var skippedIntro:Bool;

    #if ENGINE_SCRIPTING
    var overrideCode:Bool;
    #end

    public static var firstTime:Bool = true;

    override function create():Void {
        super.create();

        #if ENGINE_DISCORD_RPC
        DiscordPresence.presence.details = "Title Screen";
        #end

        #if ENGINE_SCRIPTING
        initStateScript();
        hxsCall("onCreate");

        if (overrideCode) {
            hxsCall("onCreatePost");
            return;
        }
        #end

        // initialize elements
        spritesGroup = new FlxSpriteGroup();
        add(spritesGroup);

        if (firstTime) {
            preRenderSprites = new FlxSpriteGroup();
            add(preRenderSprites);

            ngSprite = new FlxSprite();
            ngSprite.scale.set(0.75, 0.75);
            ngSprite.updateHitbox();
            ngSprite.visible = false;

            alphabetGroup = new FlxTypedGroup<Alphabet>();
        }

        postRenderSprites = new FlxSpriteGroup();
        
        if (alphabetGroup != null)
            add(alphabetGroup);

        pressEnterSprite = new FlxSprite(100, FlxG.height * 0.8);
        pressEnterSprite.frames = Assets.getSparrowAtlas("menus/title/titleEnter");
        pressEnterSprite.animation.addByPrefix("normal", "Press Enter To Begin", 24);
        pressEnterSprite.animation.addByPrefix("pressed", "ENTER PRESSED", 24);
        pressEnterSprite.animation.play("normal");
        pressEnterSprite.updateHitbox();

        // load data
        var path:String = Assets.yaml("data/titlescreen");
        if (FileTools.exists(path))
            setupFromData(Tools.parseYAML(FileTools.getContent(path)));
        else
            defaultSetup();

        // post setup
        if (ngSprite != null)
            preRenderSprites?.add(ngSprite);
        postRenderSprites.add(pressEnterSprite);

        Conductor.music = FlxG.sound.music;
        FlxG.sound.music.onComplete = Conductor.resetPreviousPosition;

        if (!firstTime) {
            clearSequences();
            skipIntro();
        }

        firstTime = false;

        #if ENGINE_SCRIPTING
        hxsCall("onCreatePost");
        #end
    }

    override function update(elapsed:Float):Void {
        #if ENGINE_SCRIPTING
        hxsCall("onUpdate", [elapsed]);
        super.update(elapsed);

        if (overrideCode) {
            hxsCall("onUpdatePost", [elapsed]);
            return;
        }
        #else
        super.update(elapsed);
        #end

        if (allowInputs && controls.justPressed("accept"))
            accept();

        #if ENGINE_SCRIPTING
        hxsCall("onUpdatePost", [elapsed]);
        #end
    }

    override function beatHit(currentBeat:Int):Void {
        if (beatSequences != null)
            while (beatSequences.length > 0 && beatSequences[0].beat <= currentBeat)
                runSequence(beatSequences.shift());

        for (group in [spritesGroup, preRenderSprites, postRenderSprites]) {
            if (group == null || group.length < 1)
                continue;
            
            for (spr in group)
                if (spr is DancingSprite)
                    cast(spr, DancingSprite).dance(currentBeat, true);
        }

        super.beatHit(currentBeat);
    }

    override function stepHit(currentStep:Int):Void {
        if (stepSequences != null)
            while (stepSequences.length > 0 && stepSequences[0].step <= currentStep)
                runSequence(stepSequences.shift());

        super.stepHit(currentStep);
    }

    function accept():Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onAccept"))
            return;
        #end

        if (!skippedIntro) {
            clearSequences();
            skipIntro();
        }
        else {
            flash();
            allowInputs = false;

            pressEnterSprite.animation.play("pressed");
            FlxG.sound.play(Assets.sound("confirmMenu"));

            new FlxTimer().start(1, (_) -> FlxG.switchState(new MainMenu()));
        }

        #if ENGINE_SCRIPTING
        hxsCall("onAcceptPost");
        #end
    }

    function clearSequences():Void {
        if (beatSequences != null)
            while (beatSequences.length > 0)
                beatSequences.shift();

        if (stepSequences != null)
            while (stepSequences.length > 0)
                stepSequences.shift();
    }

    function runSequence(seq:TitleSequence):Void {
        switch (seq.action) {
            case "create text":
                clearAlphabets();
                for (text in seq.arguments)
                    createAlphabet(text);
            case "add text":
                for (text in seq.arguments)
                    createAlphabet(text);
            case "delete text":
                clearAlphabets();
            case "show logo":
                if (ngSprite == null)
                    return;

                if (alphabetGroup != null && alphabetGroup.countLiving() > 0) {
                    var lastAlphabet:Alphabet = alphabetGroup.getLast((alphabet) -> alphabet.exists);
                    ngSprite.y = lastAlphabet.y + lastAlphabet.height - (ngSprite.height * 0.15);
                }
                else
                    ngSprite.screenCenter(Y);
                ngSprite.visible = true;
            case "hide logo":
                if (ngSprite != null)
                    ngSprite.visible = false;
            case "skip intro":
                skipIntro();
            #if ENGINE_SCRIPTING
            case "call function":
                hxsCall(seq.arguments[0], seq.arguments[1]);
            #end
        }
    }

    function createAlphabet(text:String):Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onAlphabetCreate", [text]))
            return;
        #end

        if (text == "RandomText1")
            text = randomText[0];
        else if (text == "RandomText2")
            text = randomText[1];

        var alphabet:Alphabet = alphabetGroup.recycle(Alphabet);
        alphabet.text = text;
        alphabet.screenCenter(X);
        alphabet.y = (Math.max(alphabetGroup.countLiving() - 1, 0) * 60) + 200;
        alphabetGroup.add(alphabet);

        #if ENGINE_SCRIPTING
        hxsCall("onAlphabetCreatePost", [text]);
        #end
    }

    inline function clearAlphabets():Void {
        alphabetGroup.forEachAlive((i) -> i.kill());
    }

    function skipIntro():Void {
        #if ENGINE_SCRIPTING
        if (cancellableCall("onSkipIntro"))
            return;
        #end

        flash();
        skippedIntro = true;

        add(postRenderSprites);

        if (preRenderSprites != null) {
            remove(preRenderSprites, true);
            preRenderSprites.destroy();
            preRenderSprites = null;
        }

        if (alphabetGroup != null) {
            remove(alphabetGroup, true);
            alphabetGroup.destroy();
            alphabetGroup = null;
        }

        #if ENGINE_SCRIPTING
        hxsCall("onSkipIntroPost");
        #end
    }

    inline function flash():Void
        camera.flash((Settings.get("disable flashing lights")) ? FlxColor.BLACK : FlxColor.WHITE);

    function setupFromData(data:Dynamic):Void {
        if (data == null) {
            defaultSetup();
            return;
        }

        Conductor.bpm = (data.bpm == null) ? 102 : data.bpm;
        Tools.playMusicCheck((data.music == null) ? "freakyMenu" : data.music);

        filterSequences(data.sequences);
        randomText = (data.randomText == null) ? getDefaultRandomText() : FlxG.random.getObject(data.randomText);

        // To not make the post render blank at least
        if (data.sprites == null && data.postRenderSprites == null)
            addDefaultSprites();

        if (data.sprites != null)
            setupSprites(data.sprites, spritesGroup);
        if (data.preRenderSprites != null && preRenderSprites != null)
            setupSprites(data.preRenderSprites, preRenderSprites);
        if (data.postRenderSprites != null)
            setupSprites(data.postRenderSprites, postRenderSprites);

        ngSprite?.loadGraphic(Assets.image((data.logo == null) ? "menus/title/newgrounds_logo" : data.logo));
        ngSprite?.screenCenter(X);
    }

    function defaultSetup():Void {
        Conductor.bpm = 102;
        Tools.playMusicCheck("freakyMenu");

        beatSequences = getDefaultSequences();
        randomText = getDefaultRandomText();

        ngSprite?.loadGraphic(Assets.image("menus/title/newgrounds_logo"));
        ngSprite?.screenCenter(X);

        addDefaultSprites();
    }

    function filterSequences(seqs:Array<TitleSequence>):Void {
        if (seqs == null) {
            beatSequences = getDefaultSequences();
            return;
        }

        for (seq in seqs) {
            // Not enough informations provided, skip this sequence
            if ((seq.beat == null && seq.step == null) || seq.action == null)
                continue;

            if (seq.step != null) {
                if (stepSequences == null)
                    stepSequences = [];
                stepSequences.push(seq);
            }

            if (seq.beat != null) {
                if (beatSequences == null)
                    beatSequences = [];
                beatSequences.push(seq);
            }
        }

        if (stepSequences != null)
            stepSequences.sort((s1, s2) -> FlxSort.byValues(FlxSort.ASCENDING, s1.step, s2.step));
        if (beatSequences != null)
            beatSequences.sort((s1, s2) -> FlxSort.byValues(FlxSort.ASCENDING, s1.beat, s2.beat));
    }

    function setupSprites(sprites:Array<TitleSprite>, group:FlxSpriteGroup):Void {
        if (sprites == null || sprites.length < 1)
            return;

        for (data in sprites) {
            var sprite:OffsetSprite = null;

            if (data.danceAnimations != null && data.danceAnimations.length > 0) {
                var dancingSpr:DancingSprite = new DancingSprite();
                dancingSpr.danceAnimations = data.danceAnimations;
                dancingSpr.beat = data.danceBeat ?? 1;
                sprite = dancingSpr;
            }
            else
                sprite = new OffsetSprite();

            switch ((data.type ?? "").toLowerCase().trim()) {
                case "sparrow":
                    sprite.frames = Assets.getSparrowAtlas(data.image, data.library);
                case "packer":
                    sprite.frames = Assets.getPackerAtlas(data.image, data.library);
                case "aseprite":
                    sprite.frames = Assets.getAseAtlas(data.image, data.library);
                default:
                    var graphic = Assets.image(data.image, data.library);
                    if (data.animationSize != null && data.animationSize.length > 1)
                        sprite.loadGraphic(graphic, true, data.animationSize[0], data.animationSize[1]);
                    else
                        sprite.loadGraphic(graphic);
            }
 
            if (data.animationSpeed != null)
                sprite.animation.timeScale = data.animationSpeed;

            if (data.animations != null)
                Tools.addYamlAnimations(sprite, data.animations);

            if (data.scale != null) {
                while (data.scale.length < 2)
                    data.scale.push(1);

                sprite.scale.set(data.scale[0], data.scale[1]);
                sprite.updateHitbox();

                // apply animation offsets after hitbox update
                if (sprite.animation.curAnim != null) {
                    sprite.playAnimation(sprite.animation.curAnim.name, true);
                    sprite.animation.finish();
                }     
            }

            if (data.position != null) {
                while (data.position.length < 2)
                    data.position.push(0);
                sprite.setPosition(data.position[0], data.position[1]);
            }

            if (data.flip != null) {
                while (data.flip.length < 2)
                    data.flip.push(false);

                sprite.flipX = data.flip[0];
                sprite.flipY = data.flip[1];
            }

            if (data.alpha != null)
                sprite.alpha = data.alpha;

            if (data.antialiasing != null)
                sprite.antialiasing = data.antialiasing;

            group.add(sprite);

            #if ENGINE_SCRIPTING
            if (data.name != null)
                hxsSet(data.name, sprite);
            #end
        }
    }

    function addDefaultSprites():Void {
        var logo:DancingSprite = new DancingSprite(-150, -100);
        logo.frames = Assets.getSparrowAtlas("menus/title/logoBumpin");
        logo.animation.addByPrefix("bump", "logo bumpin", 24, false);
        logo.danceAnimations.push("bump");

        logo.forceDance();
        logo.animation.finish();
        logo.updateHitbox();

        postRenderSprites.add(logo);
        
        var girlfriend:DancingSprite = new DancingSprite(FlxG.width * 0.4, FlxG.height * 0.07);
        girlfriend.frames = Assets.getSparrowAtlas("menus/title/gfDanceTitle");
        girlfriend.animation.addByIndices("left", "gfDance", [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
        girlfriend.animation.addByIndices("right", "gfDance", [for (i in 15...30) i], "", 24, false);
        girlfriend.danceAnimations = ["left", "right"];

        girlfriend.forceDance();
        girlfriend.animation.finish();
        girlfriend.currentDance = 0;
        girlfriend.updateHitbox();
        
        postRenderSprites.add(girlfriend);
    }

    override function destroy():Void {
        FlxG.sound.music.onComplete = null;
        super.destroy();
    }

    static function getDefaultSequences():Array<TitleSequence> {
        return [
            {beat: 1, action: "create text", arguments: ["The eternal team"]},
            {beat: 3, action: "add text",    arguments: ["present"]},
            {beat: 4, action: "delete text"},
            {beat: 5, action: "create text", arguments: ["Not in association", "with"]},
            {beat: 7, action: "add text", arguments: ["newgrounds"]},
            {beat: 7, action: "show logo"},
            {beat: 8, action: "hide logo"},
            {beat: 8, action: "delete text"},
            {beat: 9, action: "create text", arguments: ["RandomText1"]},
            {beat: 11, action: "add text", arguments: ["RandomText2"]},
            {beat: 12, action: "delete text"},
            {beat: 13, action: "create text", arguments: ["friday night"]},
            {beat: 14, action: "add text", arguments: ["funkin"]},
            {beat: 15, action: "add text", arguments: ["eternal engine"]},
            {beat: 16, action: "skip intro"}
        ];
    }

    static function getDefaultRandomText():Array<String> {
        return FlxG.random.getObject([
            ["unholy was here", "bottom text"],
            ["azt is such", "a silly goober"],
            ["neez duts", "lmao"],
            ["funkin", "eternally"],
            ["psych engine fork", "i dont know what that is"],
            ["still waiting on week 8", "week 54 where you at"],
            ["mmm", "chez burgr"],
            ["his name isnt keith", "dumb eggy lol"],
            ["his name isnt evan", "silly tiktok"],
            ["hi", "bye"],
            ["lorem ipsum", "dolor sit amet"],
            ["insert", "quote"],
            ["rate five", "pls no blam"],
            ["rhythm gaming", "ultimate"],
            ["game of the year", "eternally"],
            ["you already know", "we really out here"],
            ["bonk", "get in the discord call"],
            ["im literally", "literally insane"],
            ["dont be a loner", "cover that boner"]
        ]);
    }
}