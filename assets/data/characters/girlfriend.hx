import flixel.FlxSprite;
import funkin.core.scripting.Events;
import funkin.gameplay.components.Character;

class Girlfriend extends Character {
    public function new():Void {
        super(0, 0, "girlfriend");
        game.addEventListener(Events.CREATE_POST, onCreatePost);
    }

    function onCreatePost():Void {
        var speakers:FlxSprite = new FlxSprite();
        speakers.frames = frames;
        speakers.animation.addByPrefix("speakers", "speakers", 24, false);
        speakers.animation.play("speakers");
        speakers.animation.finish();
    
        speakers.x = x - width * 0.65;
        speakers.y = y + height * 0.7;
        
        game.conductor.onBeat.add((_) -> speakers.animation.play("speakers"));
        game.insert(game.members.indexOf(this), speakers);
    }
}
