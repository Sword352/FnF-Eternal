package funkin.objects;

class Rating {
    public var name:String;

    public var scoreIncrement:Null<Float>;
    public var accuracyMod:Null<Float>;
    public var hitWindow:Null<Float>;

    public var rank:String;
    public var hits:Null<Int>;
    public var missThreshold:Null<Int>;
    public var missExceed:Null<Int>;

    public var ratingGraphic:String;
    public var causesMiss:Null<Bool>;
    public var displayNoteSplash:Null<Bool>;
    public var displayCombo:Null<Bool>;

    public function new(?name:String):Void {
        reset();
        if (name != null)
            this.name = name;
    }

    public function copy(copyHits:Bool = false):Rating {
        var rating:Rating = new Rating(name);
        rating.scoreIncrement = scoreIncrement;
        rating.accuracyMod = accuracyMod;
        rating.hitWindow = hitWindow;
        rating.rank = rank;
        rating.ratingGraphic = ratingGraphic;
        rating.displayNoteSplash = displayNoteSplash;
        rating.displayCombo = displayCombo;
        rating.missThreshold = missThreshold;
        rating.missExceed = missExceed;
        rating.causesMiss = causesMiss;
        if (copyHits)
            rating.hits = hits;
        return rating;
    }

    public function reset():Void {
        name = "sick";
        scoreIncrement = 350;
        accuracyMod = 1;
        hitWindow = 40;
        ratingGraphic = "sick";
        rank = "SFC";
        displayNoteSplash = true;
        displayCombo = true;
        missThreshold = 1;
        missExceed = null;
        causesMiss = false;
        hits = 0;
    }

    public function destroy():Void {
        name = null;
        scoreIncrement = null;
        accuracyMod = null;
        hitWindow = null;
        ratingGraphic = null;
        rank = null;
        displayNoteSplash = null;
        displayCombo = null;
        missThreshold = null;
        missExceed = null;
        causesMiss = null;
        hits = null;
    }

    public static function getDefaultList():Array<Rating> {
        var list:Array<Rating> = [new Rating()];

        var good:Rating = new Rating("good");
        good.scoreIncrement = 200;
        good.accuracyMod = 0.7;
        good.hitWindow = 85;
        good.rank = "GFC";
        good.ratingGraphic = "good";
        good.displayNoteSplash = false;
        good.missThreshold = 1;
        list.push(good);

        var bad:Rating = new Rating("bad");
        bad.scoreIncrement = 100;
        bad.accuracyMod = 0.3;
        bad.hitWindow = 125;
        bad.ratingGraphic = "bad";
        bad.displayNoteSplash = false;
        bad.missThreshold = 1;
        list.push(bad);

        var shit:Rating = new Rating("shit");
        shit.scoreIncrement = 50;
        shit.accuracyMod = 0;
        shit.hitWindow = 140;
        shit.ratingGraphic = "shit";
        shit.displayNoteSplash = false;
        shit.missThreshold = 1;
        list.push(shit);

        return list;
    }
}
