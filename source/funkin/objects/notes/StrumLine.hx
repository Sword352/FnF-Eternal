package funkin.objects.notes;

import flixel.tweens.*;

import flixel.util.FlxAxes;
import flixel.math.FlxRect;
import flixel.util.FlxSignal;

import flixel.group.FlxGroup.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;

class StrumLine extends FlxGroup {
   public var x(default, set):Float = 0;
   public var y(default, set):Float = 0;

   public var receptors(default, null):FlxTypedGroup<Receptor>;
   public var splashes(default, null):FlxTypedGroup<Splash>;
   public var notes(default, null):FlxTypedGroup<Note>;

   public var downscroll(get, set):Bool;

   public var scrollSpeed:Float = 1;
   public var scrollMult:Float = 1;

   public var characters:Array<Character> = [];

   public var holdKeys:Array<Bool> = [false, false, false, false];
   public var cpu:Bool = false;

   public var onNoteHit(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();
   public var onHold(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();
   public var onMiss(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

   var notesToRemove:Array<Note> = [];
   var holdTmr:Float = 0; // used for base game behaviour

   public function new(x:Float = 0, y:Float = 0, cpu:Bool = false):Void {
      super();
      
      this.x = x;
      this.y = y;
      this.cpu = cpu;
      
      receptors = new FlxTypedGroup<Receptor>();
      add(receptors);

      if (!Settings.get("disable note splashes") && !cpu)
         initSplashes();

      notes = new FlxTypedGroup<Note>();
      add(notes);

      for (i in 0...4) {
         var receptor:Receptor = new Receptor(i);
         receptor.setPosition(x + (Note.globalWidth * (i - 2)), y);
         receptors.add(receptor);
      }
   }
   
   override public function update(elapsed:Float):Void {
      if (holdTmr >= Conductor.stepCrochet)
         holdTmr = 0;
      else
         holdTmr += elapsed * 1000;

      notes.forEachAlive((note) -> {
         var receptor:Receptor = receptors.members[note.direction];

         var speed:Float = Math.abs(((note.followSpeed) ? (receptor.scrollSpeed ?? scrollSpeed) : note.scrollSpeed) * 0.45);
         var mult:Float = (note.followSpeed) ? (receptor.scrollMult ?? scrollMult) : note.scrollMult;

         note.distance = mult * -((Conductor.position - note.time) * speed);

         if (note.isSustainNote) {
            note.sustain.scrollSpeed = speed * Math.abs(mult);
            if (note.flipSustain)
               note.sustain.downscroll = note.sustain.flipY = mult < 0;
         }

         if (note.followX)
            note.x = receptor.x + note.offsetX;

         if (note.followY) {
            note.y = receptor.y + note.offsetY;
            if (!note.isSustainNote || note.baseVisible)
               note.y += note.distance;
         }

         if (cpu && !note.goodHit && !note.missed && Conductor.position - note.time >= 0) {
            note.goodHit = true;
            onNoteHit.dispatch(note);

            receptor.playAnimation("confirm", true);
            singCharacters(note);

            hitNote(note);
         }

         if (!cpu && note.late && !note.missed && !note.goodHit) {
            if (note.isSustainNote)
               holdMiss(note);
            else
               miss(note);
         }

         if (note.missed && !note.isSustainNote && ((mult > 0 && note.y < -note.height) || (mult < 0 && note.y > FlxG.height)))
            notesToRemove.push(note);

         if (note.isSustainNote && (note.goodHit || (!cpu && note.missed))) {
            note.sustain.length -= elapsed * 1000;
            clipSustainTail(note, note.sustain.flipY);

            if (holdTmr >= Conductor.stepCrochet) {
               if (cpu || holdKeys[note.direction]) {
                  receptor.playAnimation("confirm", true);
                  singCharacters(note);
                  onHold.dispatch(note);
               }
               else
                  onMiss.dispatch(note);
            }

            if (note.sustain.length <= 0)
               notesToRemove.push(note);
         }
      });

      super.update(elapsed);

      while (notesToRemove.length > 0)
         removeNote(notesToRemove.shift());

      if (cpu) {
         receptors.forEachAlive((receptor) -> {
            if (receptor.animation.curAnim.name == "confirm" && receptor.animation.curAnim.finished)
               receptor.playAnimation("static", true);
         });
      }
   }

   public function addNote(note:Note):Void {      
      notes.add(note);
      if (notes.members.length > 1)
         notes.members.sort(sortNotes);
   }

   public function removeNote(note:Note):Void {
      notes.remove(note, true);
      note.destroy();
   }

   public function hitNote(note:Note):Void {
      if (note.isSustainNote) {
         if (!cpu)
            note.sustain.length += note.time - Conductor.position; // incase the player hits the note early/lately
         note.baseVisible = false;
      }
      else
         notesToRemove.push(note);
   }

   function miss(note:Note):Void {
      note.missed = true;
      note.alpha = 0.3;
      onMiss.dispatch(note);
   }

   function holdMiss(note:Note):Void {
      note.missed = true;
      note.baseVisible = false;
      note.sustain.length += note.time - Conductor.position;
      onMiss.dispatch(note);
   }

   function clipSustainTail(note:Note, downscroll:Bool = false):Void {
      var receptor:Receptor = receptors.members[note.direction];
      var tail:FlxSprite = note.sustain.tail;

      var receptorCenter:Float = receptor.y + (receptor.height * 0.5);

      if ((downscroll && tail.y - tail.offset.y * tail.scale.y + tail.height < receptorCenter)
         || (!downscroll && tail.y + tail.offset.y * tail.scale.y > receptorCenter))
         return;

      var clipRect:FlxRect = (tail.clipRect ?? FlxRect.get()).set();
      clipRect.width = (downscroll) ? tail.frameWidth : tail.width / tail.scale.x;

      if (downscroll) {
         clipRect.height = (receptorCenter - tail.y) / tail.scale.y;
         clipRect.y = tail.frameHeight - clipRect.height;
      }
      else {
         clipRect.y = (receptorCenter - tail.y) / tail.scale.y;
			clipRect.height = (tail.height / tail.scale.y) - clipRect.y;
      }

      tail.clipRect = clipRect;
   }

   public function setPosition(x:Float = 0, y:Float = 0):StrumLine {
      this.x = x;
      this.y = y;
      return this;
   }

   public function screenCenter(axes:FlxAxes = XY):StrumLine {
      if (axes.x)
         x = FlxG.width * 0.5;
      if (axes.y)
         y = FlxG.height * 0.5;
      return this;
   }

   public function singCharacters(note:Note):Void {
      for (character in characters) {
         if ((note.isSustainNote && note.baseVisible) 
            || (!note.isSustainNote || !Settings.get("disable hold stutter") || character.animation.name != character.singAnimations[note.direction]))
            character.sing(note.direction, note.animSuffix);
         else
            character.holdTime = 0;

         character.currentDance = 0;
      }
   }

   public function tweenReceptors():Void {
      if (receptors == null)
         return;

      for (receptor in receptors) {
         receptor.alpha = 0;
         receptor.y -= 10;
         FlxTween.tween(receptor, {y: receptor.y + 10, alpha: 1}, 1, {
            ease: FlxEase.circOut,
            startDelay: 0.5 + (0.2 * receptor.direction)
         });
      }
   }

   public function initSplashes(cache:Bool = true):Void {
      splashes = new FlxTypedGroup<Splash>();
      add(splashes);

      if (cache) {
         var cachedSplash:Splash = new Splash();
         splashes.add(cachedSplash);
         cachedSplash.kill();
      }
   }

   public function popSplash(direction:Int):Void {
      if (splashes == null)
         return;

      var splash:Splash = splashes.recycle(Splash);
      var receptor:Receptor = receptors.members[direction];
      splash.setPosition(receptor.x, receptor.y);
      splash.pop(direction);
   }

   override function destroy():Void {
      super.destroy();

      onMiss = cast FlxDestroyUtil.destroy(onMiss);
      onHold = cast FlxDestroyUtil.destroy(onHold);
      onNoteHit = cast FlxDestroyUtil.destroy(onNoteHit);

      characters = null;
      holdKeys = null;

      notesToRemove = null;
   }

   function set_x(v:Float):Float {
      if (receptors != null)
         receptors.forEach((r) -> r.x = v + (Note.globalWidth * (r.direction - 2)));
      return x = v;
   }

   function set_y(v:Float):Float {
      if (receptors != null)
         receptors.forEach((r) -> r.y = v);
      return y = v;
   }

   function set_downscroll(v:Bool):Bool {
      if ((v && scrollMult > 0) || (!v && scrollMult < 0))
         scrollMult *= -1;   
      return v;
   }

   inline function get_downscroll():Bool
      return scrollMult < 0;

   // Sorting function
   inline function sortNotes(a:Note, b:Note):Int {
      return Std.int(a.time - b.time);
   }
}
