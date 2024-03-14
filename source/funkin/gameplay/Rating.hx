package funkin.gameplay;

class Rating {
    public var name:String;
    public var rank:String;
    public var image:String;

    public var scoreIncrement:Float = 0;
    public var accuracyMod:Float = 0;
    public var hitWindow:Float = 0;

    public var hits:Int = 0;
    public var missThreshold:Int = 0;

    public var causesMiss:Bool;
    public var displayNoteSplash:Bool;
    public var displayCombo:Bool;

    public function new(name:String = "sick"):Void {
        this.name = name;
        reset();            
    }

    public function copy(copyHits:Bool = false):Rating {
        var rating:Rating = new Rating(name);
        rating.displayNoteSplash = displayNoteSplash;
        rating.scoreIncrement = scoreIncrement;
        rating.missThreshold = missThreshold;
        rating.displayCombo = displayCombo;
        if (copyHits) rating.hits = hits;
        rating.accuracyMod = accuracyMod;
        rating.causesMiss = causesMiss;
        rating.hitWindow = hitWindow;
        rating.image = image;
        rating.rank = rank;
        return rating;
    }

    public function reset():Void {
        scoreIncrement = 350;
        accuracyMod = 1;
        hitWindow = 40;

        image = "sick";
        rank = "SFC";

        displayNoteSplash = true;
        displayCombo = true;
        causesMiss = false;

        missThreshold = 1;
        hits = 0;
    }

    public static function getDefaultList():Array<Rating> {
        var list:Array<Rating> = [new Rating()];

        var good:Rating = new Rating("good");
        good.displayNoteSplash = false;
        good.scoreIncrement = 200;
        good.missThreshold = 1;
        good.accuracyMod = 0.7;
        good.hitWindow = 85;
        good.image = "good";
        good.rank = "GFC";
        list.push(good);

        var bad:Rating = new Rating("bad");
        bad.displayNoteSplash = false;
        bad.scoreIncrement = 100;
        bad.missThreshold = 1;
        bad.accuracyMod = 0.3;
        bad.hitWindow = 125;
        bad.image = "bad";
        list.push(bad);

        var shit:Rating = new Rating("shit");
        shit.displayNoteSplash = false;
        shit.scoreIncrement = 50;
        shit.missThreshold = 1;
        shit.accuracyMod = 0;
        shit.hitWindow = 140;
        shit.image = "shit";
        list.push(shit);

        return list;
    }
}
