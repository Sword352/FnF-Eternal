package funkin.objects.notes;

import flixel.FlxCamera;
import flixel.math.FlxRect;
import funkin.objects.sprites.TiledSprite;

import eternal.NoteSkin;

class Note extends OffsetSprite {
   public static final directions:Array<String> = ["left", "down", "up", "right"];

   public static var safeZoneOffset(get, never):Float;
   inline static function get_safeZoneOffset():Float
      return 166.66 * Conductor.playbackRate;

   public var goodHit:Bool = false;
   public var missed:Bool = false;

   public var canBeHit(get, default):Bool = false;
   public var late(get, default):Bool = false;

   public var time:Float = 0;
   public var direction:Int = 0;

   public var parentStrumline:StrumLine;
   public var strumline:Int = 0;

   public var length(default, set):Float = 0;
   public var holdProgress(get, never):Float;
   public var initialLength:Float = 0;

   public var sustain(default, null):Sustain;
   public var isSustainNote(get, never):Bool;
   public var sustainDecrease(get, default):Float = 0;

   public var type(default, set):String = "";
   public var skin(default, set):String;
   public var animSuffix:String;

   public var followX:Bool = true;
   public var followY:Bool = true;
   public var followAlpha:Bool = true;
   public var followSpeed:Bool = true;

   public var offsetX:Float = 0;
   public var offsetY:Float = 0;
   public var spawnTimeOffset:Float = 0;

   public var alphaMult:Float = 1;
   public var lateAlpha:Float = 0.3;
   public var sustainAlpha:Float = 0.6;

   public var holdBehindStrum:Bool = Settings.get("hold notes behind receptors");
   public var baseVisible:Bool = true;

   public var autoDistance:Bool = true;
   public var autoClipSustain:Bool = true;
   public var flipSustain:Bool = true;
   public var overrideSustain:Bool = false;

   public var scrollMult(get, default):Float = ((Settings.get("downscroll")) ? -1 : 1);
   public var scrollSpeed(get, default):Float = 1;
   public var distance(get, default):Float = 0;

   public var downscroll(get, never):Bool;

   // not really useful in gameplay, just a helper boolean
   public var checked:Bool = false;

   public function new(time:Float = 0, direction:Int = 0, skin:String = "default"):Void {
      super();

      this.time = time;
      this.direction = direction;
      this.skin = skin;

      resetPosition();
      moves = false;
   }

   public function follow(receptor:FlxSprite):Void {
      if (followX)
         x = receptor.x + offsetX;

      if (followY) {
         y = receptor.y + offsetY;
         if (!isSustainNote || baseVisible)
            y += distance;
      }

      if (followAlpha) {
         alpha = receptor.alpha * alphaMult;
         if (isSustainNote)
            sustain.alpha = alpha - (1 - sustainAlpha);
      }
   }

   public function clipSustainTail(receptor:FlxSprite):Void {
      var receptorCenter:Float = receptor.y + (receptor.height * 0.5);
      var tail:FlxSprite = sustain.tail;

      if ((downscroll && tail.y - tail.offset.y * tail.scale.y + tail.height < receptorCenter)
         || (!downscroll && tail.y + tail.offset.y * tail.scale.y > receptorCenter))
         return;

      var clipRect:FlxRect = (tail.clipRect ?? FlxRect.get()).set();
      clipRect.width = (downscroll) ? tail.frameWidth : (tail.width / tail.scale.x);

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

   public inline function findRating(ratings:Array<Rating>):Rating {
      var diff:Float = (Math.abs(Conductor.time - time) / Conductor.playbackRate);
      var rating:Rating = null;

      var i:Int = ratings.length - 1;

      while (i >= 0) {
         if (diff <= ratings[i].hitWindow)
            rating = ratings[i];

         i--;
      }

      return rating ?? ratings[ratings.length - 1];
   }

   public inline function resetPosition():Void {
      // making sure it goes off screen
      this.x = -FlxG.width;
      this.y = -FlxG.height;
   }

   public inline function resetTypeProps():Void {
      animSuffix = null;
   }

   override function update(elapsed:Float):Void {
      if (isSustainNote && sustain.exists && sustain.active)
         sustain.update(elapsed);

      super.update(elapsed);
   }

   override function draw():Void {
      if (isSustainNote && sustain.exists && sustain.visible && !holdBehindStrum)
         sustain.draw();

      if (baseVisible)
         super.draw();
   }

   override function destroy():Void {
      sustain = FlxDestroyUtil.destroy(sustain);
      parentStrumline = null;
      skin = null;
      type = null;

      super.destroy();
   }

   function set_length(v:Float):Float {
      if (v >= 100) {
         if (sustain == null)
            sustain = new Sustain(this);
      }
      else if (isSustainNote) {
         sustain.destroy();
         sustain = null;
      }

      return length = v;
   }

   function set_type(v:String):String {
      resetTypeProps();

      if (v != null) {
         switch (v) {
            case "Alt Animation":
               animSuffix = "-alt";
         }
      }

      return type = v;
   }

   function set_skin(v:String):String {
      if (v != null) {
         switch (v) {
            // case "name" to hardcode your noteskins
            case "default":
               // default noteskin
               var dir:String = directions[direction];

               frames = Assets.getSparrowAtlas("notes/notes");
               animation.addByPrefix(dir, '${dir}0', 0);
               animation.addByPrefix(dir + " hold", '${dir} hold piece', 0);
               animation.addByPrefix(dir + " end", '${dir} hold end', 0);
               playAnimation(dir, true);
         
               scale.set(0.7, 0.7);
               updateHitbox();
            default:
               // softcoded noteskin
               var config:NoteSkinConfig = NoteSkin.get(v);
               if (config == null || config.note == null)
                  return set_skin("default");

               var dir:String = directions[direction];
               NoteSkin.applyGenericSkin(this, config.note, dir, dir);
         }
      }

      return skin = v;
   }

   inline function get_distance():Float {
      return (autoDistance) ? (scrollMult * -((((Conductor.updateInterp) ? Conductor.interpTime : Conductor.time) - time) * scrollSpeed)) : this.distance;
   }

   inline function get_scrollSpeed():Float {
      var receptor:Receptor = parentStrumline?.receptors.members[direction];
      var speed:Float = Math.abs(((followSpeed && parentStrumline != null) ? (receptor.scrollSpeed ?? parentStrumline.scrollSpeed) : this.scrollSpeed) * 0.45);
      return speed * Math.abs(scrollMult);
   }

   inline function get_scrollMult():Float {
      var receptor:Receptor = parentStrumline?.receptors.members[direction];
      return (followSpeed && parentStrumline != null) ? (receptor?.scrollMult ?? parentStrumline.scrollMult) : this.scrollMult;
   }

   inline function get_sustainDecrease():Float {
      return (autoClipSustain) ? holdProgress : this.sustainDecrease;
   }

   inline function get_late():Bool {
      return this.late || (Conductor.time - time) > safeZoneOffset;
   }

   inline function get_downscroll():Bool
      return scrollMult < 0;

   inline function get_isSustainNote():Bool
      return sustain != null;

   inline function get_holdProgress():Float
      return FlxMath.bound(Conductor.time - time, 0, length);

   function get_canBeHit():Bool {
      if (goodHit || missed)
         return false;

      if (parentStrumline != null)
         return (parentStrumline.cpu && time <= Conductor.time) || (!parentStrumline.cpu && Math.abs(Conductor.time - time) <= safeZoneOffset);

      return this.canBeHit;
   }

   override function set_cameras(v:Array<FlxCamera>):Array<FlxCamera> {
      if (isSustainNote)
         sustain.cameras = v;
      return super.set_cameras(v);
   }

   override function set_camera(v:FlxCamera):FlxCamera {
      if (isSustainNote)
         sustain.camera = v;
      return super.set_camera(v);
   }
}

class Sustain extends TiledSprite {   
   public var tail(default, null):FlxSprite;
   public var parent:Note;

   public function new(parent:Note):Void {
      super(null, 0, 0, true, true);

      tail = new FlxSprite();
      alpha = 0.6;

      this.parent = parent;
      reloadGraphic();
   }

   override function update(elapsed:Float):Void {
      if (tail.exists && tail.active)
         tail.update(elapsed);

      super.update(elapsed);
   }

   override function draw():Void {
      if (!parent.overrideSustain)
         updateSustain();

      if (regen)
         regenGraphic();

      if (height > 0)
         super.draw();

      if (tail.exists && tail.visible)
         tail.draw();
   }

   override function destroy():Void {
      tail = FlxDestroyUtil.destroy(tail);
      parent = null;

      super.destroy();
   }

   inline function updateSustain():Void {
      height = ((parent.length - parent.sustainDecrease) * parent.scrollSpeed) - tail.height;

      setPosition(parent.x + ((parent.width - width) * 0.5), parent.y + (parent.height * 0.5));
      if (parent.downscroll)
         y -= height;

      tail.setPosition(x, (parent.downscroll) ? (y - tail.height) : (y + height));
      flipY = (parent.flipSustain && parent.downscroll);

      if (parent.autoClipSustain) {
         // clipRect-like effect
         scrollY = (parent.holdProgress * ((parent.downscroll) ? 0.001 : 0.3)) * parent.scrollSpeed;
      }
   }

   public inline function reloadGraphic():Void {
      var dir:String = Note.directions[parent.direction];

      // TODO: find a better solution (FlxTiledSprite does not support animations at the moment)
      frames = parent.frames;
      animation.copyFrom(parent.animation);
      animation.play(dir + " hold", true);
      loadFrame(frame ?? parent.frame);

      tail.frames = parent.frames;
      tail.animation.copyFrom(parent.animation);
      tail.animation.play(dir + " end", true);

      scale.set(parent.scale.x, parent.scale.y);
      tail.scale.set(scale.x, scale.y);
      updateHitbox();

      antialiasing = tail.antialiasing = parent.antialiasing;
   }

   override function updateHitbox():Void {
      width = graphic.width * scale.x;
      tail.updateHitbox();
   }

   override function set_height(v:Float):Float {
      if (!regen)
         regen = (v != height && v > 0);

      return height = v;
   }

   override function set_flipX(v:Bool):Bool {
      if (tail != null)
         tail.flipX = v;
      return super.set_flipX(v);
   }

   override function set_flipY(v:Bool):Bool {
      if (tail != null)
         tail.flipY = v;
      return super.set_flipY(v);
   }

   override function set_alpha(v:Float):Float {
      if (tail != null)
         tail.alpha = v;
      return super.set_alpha(v);
   }

   override function set_cameras(v:Array<FlxCamera>):Array<FlxCamera> {
      if (tail != null)
         tail.cameras = v;
      return super.set_cameras(v); 
   }

   override function set_camera(v:FlxCamera):FlxCamera {
      if (tail != null)
         tail.camera = v;
      return super.set_camera(v); 
   }
}