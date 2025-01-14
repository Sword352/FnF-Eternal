package funkin.data;

import funkin.core.assets.Paths.AtlasAsset;

typedef CharacterData = {
    var image:AtlasAsset;
    var animations:Array<YAMLAnimation>;

    var ?antialiasing:Bool;
    var ?flip:Array<Bool>;
    var ?scale:Array<Float>;

    var ?singDuration:Float;
    var ?danceSteps:Array<String>;
    var ?danceBeat:Float;

    var ?cameraOffsets:Array<Float>;
    var ?globalOffsets:Array<Float>;

    var ?icon:String;
    var ?noteSkin:String;
    var ?healthBarColor:Dynamic;

    var ?gameOverChar:String;
    var ?gameOverData:GameOverData;
}
