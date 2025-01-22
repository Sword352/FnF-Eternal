import funkin.gameplay.PlayState;
import funkin.core.scripting.Events;
import funkin.core.scripting.Events.GameEvents;
import funkin.core.scripting.Element.NoteTypeElement;
import funkin.gameplay.components.Character.AnimationState;

class AltAnimationNote extends NoteTypeElement {
    public function new():Void {
        super("Alt Animation");
    }

    override function onGameplayStart():Void {
        PlayState.self.addEventListener(Events.CREATE_POST, onCreatePost);
    }

    function onCreatePost():Void {
        game.playField.playerStrumLine.addEventListener(GameEvents.NOTE_HIT, onNoteHit);
        game.playField.opponentStrumLine.addEventListener(GameEvents.NOTE_HIT, onNoteHit);
    }

    function onNoteHit(event):Void {
        if (event.note.type == "Alt Animation") {
            event.characterSing = false;
            playAltAnim(event.note);
        }
    }

    function playAltAnim(note:Note):Void {
        for (character in note.strumLine.characters) {
            character.playSingAnim(note.direction, "-alt");

            if (!note.strumLine.cpu)
                character.animState = AnimationState.HOLDING;

            if (note.isHoldable())
                character.animDuration = note.length - Math.max(game.conductor.time - note.time, 0) + game.conductor.beatLength;
        }
    }
}
