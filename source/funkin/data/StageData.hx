package funkin.data;

typedef StageData = {
    var ?cameraSpeed:Float;
    var ?camBeatZoom:Float;
    var ?hudBeatZoom:Float;
    var ?camBeat:Float;

    var ?cameraZoom:Float;
    var ?hudZoom:Float;

    var ?playerPos:Array<Float>;
    var ?spectatorPos:Array<Float>;
    var ?opponentPos:Array<Float>;
    
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
