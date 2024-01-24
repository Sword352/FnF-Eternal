package funkin.objects.notes;

import flixel.tweens.*;

import flixel.util.FlxAxes;
import flixel.util.FlxSignal;

import flixel.group.FlxGroup.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;

class StrumLine extends FlxGroup {
   public var x(default, set):Float = 0;
   public var y(default, set):Float = 0;

   public var receptors(default, null):FlxTypedGroup<Receptor>;
   public var splashes(default, null):FlxTypedGroup<Splash>;
   public var notes(default, null):FlxTypedGroup<Note>;
   
   public var receptorSpacing(default, set):Float = 112;

   public var downscroll(get, set):Bool;
   public var scrollSpeed:Float = 1;
   public var scrollMult:Float = 1;

   public var characters:Array<Character> = [];
   public var skin(default, set):String;

   public var holdKeys:Array<Bool> = [false, false, false, false];
   public var cpu:Bool = false;

   public var onNoteHit(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();
   public var onHold(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();
   public var onMiss(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

   var removeNextFrame:Array<Note> = [];
   var notesToRemove:Array<Note> = [];
   var lastStep:Int = 0; // used for base game behaviour

   public function new(x:Float = 0, y:Float = 0, cpu:Bool = false, skin:String = "default"):Void {
      super();
      
      this.x = x;
      this.y = y;

      this.cpu = cpu;
      this.skin = skin;
      
      receptors = new FlxTypedGroup<Receptor>();
      add(receptors);

      if (!Settings.get("disable note splashes") && !cpu)
         initSplashes();

      notes = new FlxTypedGroup<Note>();
      add(notes);

      for (i in 0...4) {
         var receptor:Receptor = new Receptor(i, skin);
         receptor.setPosition(x + (receptorSpacing * (i - 2)), y);
         receptors.add(receptor);
      }
   }
   
   override public function update(elapsed:Float):Void {
      while (removeNextFrame.length > 0)
         removeNote(removeNextFrame.shift());

      notes.forEachAlive((note) -> {
         var receptor:Receptor = receptors.members[note.direction];

         note.follow(receptor);

         if (cpu && note.canBeHit) {
            note.goodHit = true;
            onNoteHit.dispatch(note);

            receptor.playAnimation("confirm", true);
            singCharacters(note);

            hitNote(note);
         }

         if (!cpu && note.late && !note.missed && !note.goodHit)
            miss(note);

         if (note.missed && !note.isSustainNote && note.killIfMissed && Conductor.time > (note.time + (((300 / note.scrollSpeed) / Conductor.playbackRate) + note.lateKillOffset)))
            notesToRemove.push(note);

         if (note.isSustainNote && (note.goodHit || note.missed)) {
            if (note.autoClipSustain)
               note.clipSustainTail(receptor);

            if (lastStep != Conductor.currentStep) {
               if (cpu || holdKeys[note.direction]) {
                  receptor.playAnimation("confirm", true);
                  singCharacters(note);
                  onHold.dispatch(note);
               }
               else
                  onMiss.dispatch(note);
            }

            if (note.holdProgress >= note.length)
               removeNextFrame.push(note);
         }
      });

      super.update(elapsed);

      while (notesToRemove.length > 0)
         removeNote(notesToRemove.shift());

      if (cpu) {
         receptors.forEachAlive((receptor) -> {
            if (receptor.animation.curAnim.name.startsWith("confirm") && receptor.animation.curAnim.finished)
               receptor.playAnimation("static", true);
         });
      }

      lastStep = Conductor.currentStep;
   }

   override function draw():Void {
      notes.forEachExists((note) -> {
         if (note.isSustainNote && note.sustain.visible && note.holdBehindStrum)
            note.sustain.draw();
      });

      super.draw();
   }

   public function addNote(note:Note):Void {
      note.parentStrumline = this;
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
            resizeLength(note);
         note.baseVisible = false;
      }
      else
         notesToRemove.push(note);
   }

   inline function miss(note:Note):Void {
      if (note.isSustainNote) {
         note.baseVisible = false;
         resizeLength(note);
      }
      else 
         note.alphaMult = note.lateAlpha;

      note.missed = true;
      onMiss.dispatch(note);
   }

   // incase the player hits the note early or late
   inline function resizeLength(note:Note):Void {
      note.length += (note.time - Conductor.time);
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
         if (!note.isSustainNote || note.baseVisible || character.animation.name != character.singAnimations[note.direction] || !Settings.get("disable hold stutter"))
            character.sing(note.direction, note.animSuffix);
         else
            character.holdTime = 0;

         character.currentDance = 0;
      }
   }

   public function tweenReceptors(delay:Float = 0.5, dirDelay:Float = 0.2):Void {
      if (receptors == null)
         return;

      for (receptor in receptors) {
         receptor.alpha = 0;
         receptor.y -= 10;
         FlxTween.tween(receptor, {y: receptor.y + 10, alpha: 1}, 1, {
            ease: FlxEase.circOut,
            startDelay: delay + (dirDelay * receptor.direction)
         });
      }
   }

   public function initSplashes(cache:Bool = true):Void {
      splashes = new FlxTypedGroup<Splash>();
      add(splashes);

      if (cache)
         cacheSplash();
   }

   public inline function cacheSplash():Void {
      var cachedSplash:Splash = new Splash(skin);
      splashes.add(cachedSplash);
      cachedSplash.kill();
   }

   public function popSplash(direction:Int):Void {
      if (splashes == null)
         return;

      var splash:Splash = splashes.recycle(Splash, () -> new Splash(skin));
      var receptor:Receptor = receptors.members[direction];
      splash.setPosition(receptor.x, receptor.y);
      splash.pop(direction);
   }

   inline function setReceptorsX(x:Float):Void {
      if (receptors != null)
         receptors.forEach((r) -> r.x = x + (receptorSpacing * (r.direction - 2)));
   }

   override function destroy():Void {
      notesToRemove = null;
      removeNextFrame = null;

      characters = null;
      holdKeys = null;
      skin = null;

      onMiss = cast FlxDestroyUtil.destroy(onMiss);
      onHold = cast FlxDestroyUtil.destroy(onHold);
      onNoteHit = cast FlxDestroyUtil.destroy(onNoteHit);

      super.destroy();
   }

   function set_x(v:Float):Float {
      setReceptorsX(v);
      return x = v;
   }

   function set_y(v:Float):Float {
      if (receptors != null)
         receptors.forEach((r) -> r.y = v);
      return y = v;
   }

   function set_skin(v:String):String {
      if (v != null) {
         if (receptors != null)
            receptors.forEach((r) -> r.skin = v);

         receptorSpacing = ((v == "default") ? 112 : (eternal.NoteSkin.get(v)?.receptor?.spacing ?? 112));
      }

      return skin = v;
   }

   function set_receptorSpacing(v:Float):Float {
      receptorSpacing = v;
      setReceptorsX(this.x);
      return v;
   }

   function set_downscroll(v:Bool):Bool {
      if ((v && scrollMult > 0) || (!v && scrollMult < 0))
         scrollMult *= -1;   
      return v;
   }

   inline function get_downscroll():Bool
      return scrollMult < 0;

   inline static function sortNotes(a:Note, b:Note):Int {
      return Std.int(a.time - b.time);
   }
}
