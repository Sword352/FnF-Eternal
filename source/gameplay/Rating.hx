package gameplay;

class Rating {
    public var name:String;
    public var rank:String;
    public var image:String;

    public var scoreIncrement:Float = 0;
    public var healthIncrement:Float = 0.023;
    public var accuracyMod:Float = 0;
    public var hitWindow:Float = 0;

    public var hits:Int = 0;
    public var missThreshold:Int = 0;

    public var displaySplash:Bool;
    public var displayCombo:Bool;

    public function new(name:String = "sick"):Void {
        this.name = name;
        reset();            
    }

    public function reset():Void {
        scoreIncrement = 350;
        accuracyMod = 1;
        hitWindow = 45;

        image = "sick";
        rank = "SFC";

        displaySplash = true;
        displayCombo = true;

        missThreshold = 1;
        hits = 0;
    }

    public inline function destroy():Void {
        name = rank = image = null;
    }

    public static function getDefaultList():Array<Rating> {
        var list:Array<Rating> = [new Rating()];

        var good:Rating = new Rating("good");
        good.displaySplash = false;
        good.scoreIncrement = 200;
        good.missThreshold = 1;
        good.accuracyMod = 0.7;
        good.hitWindow = 90;
        good.image = "good";
        good.rank = "GFC";
        list.push(good);

        var bad:Rating = new Rating("bad");
        bad.healthIncrement /= 2;
        bad.displaySplash = false;
        bad.scoreIncrement = 100;
        bad.missThreshold = 1;
        bad.accuracyMod = 0.3;
        bad.hitWindow = 125;
        bad.image = "bad";
        list.push(bad);

        var shit:Rating = new Rating("shit");
        shit.healthIncrement = -shit.healthIncrement / 2;
        shit.displaySplash = false;
        shit.scoreIncrement = 50;
        shit.missThreshold = 1;
        shit.accuracyMod = 0;
        shit.hitWindow = 140;
        shit.image = "shit";
        list.push(shit);

        return list;
    }
}
