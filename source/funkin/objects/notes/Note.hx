package funkin.objects.notes;

import flixel.FlxCamera;
import flixel.math.FlxRect;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;

import funkin.objects.sprites.TiledSprite;

class Note extends OffsetSprite {
   public static final directions:Array<String> = ["left", "down", "up", "right"];
   public static final globalWidth:Float = 112;

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
   public var holdProgress:Float = 0;

   public var sustain(default, null):Sustain;
   public var isSustainNote(get, never):Bool;
   public var sustainDecrease(get, default):Float = 0;

   public var type(default, set):String = "";
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

   public var scrollMult(get, default):Float = ((Settings.get("downscroll")) ? -1 : 1);
   public var scrollSpeed(get, default):Float = 1;
   public var distance(get, default):Float = 0;

   public var downscroll(get, never):Bool;

   // not really useful in gameplay, just a helper boolean
   public var checked:Bool = false;

   public function new(time:Float = 0, direction:Int = 0):Void {
      super();

      this.time = time;
      this.direction = direction;

      var dir:String = directions[direction];

      frames = Assets.getSparrowAtlas("notes/notes");
		animation.addByPrefix(dir, '${dir}0');
      playAnimation(dir);

      scale.set(0.7, 0.7);
      updateHitbox();
      resetPosition();
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
            sustain.alpha = Math.min(alpha, sustainAlpha);
      }
   }

   public function clipSustain(elapsed:Float, receptor:FlxSprite):Void {
      sustain.scrollY += elapsed;

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
      type = null;

      super.destroy();
   }

   override function set_frames(v:FlxFramesCollection):FlxFramesCollection {
      super.set_frames(v);
      sustain?.reloadGraphic();
      return v;
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

   function set_length(v:Float):Float {
      if (v >= 100) {
         if (sustain == null) {
            sustain = new Sustain();
            sustain.parent = this;
         }
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

   inline function get_distance():Float {
      return (autoDistance) ? (scrollMult * -((((Conductor.updateInterp) ? Conductor.interpTime : Conductor.time) - time) * scrollSpeed)) : this.distance;
   }

   inline function get_scrollSpeed():Float {
      var receptor:Receptor = parentStrumline?.receptors.members[direction];
      var speed:Float = Math.abs(((followSpeed && parentStrumline != null) ? (receptor.scrollSpeed ?? parentStrumline.scrollSpeed) : this.scrollSpeed) * 0.45);
      return speed * Math.abs(scrollMult);
   }

   inline function get_scrollMult():Float {
      return (followSpeed && parentStrumline != null) ? (parentStrumline.scrollMult) : this.scrollMult;
   }

   inline function get_sustainDecrease():Float {
      return (autoClipSustain) ? holdProgress : this.sustainDecrease;
   }

   inline function get_late():Bool {
      return this.late || (Conductor.time - time) > safeZoneOffset;
   }

   inline function get_downscroll():Bool {
      return (followSpeed && parentStrumline?.downscroll) || (!followSpeed && scrollMult < 0);
   }

   inline function get_isSustainNote():Bool
      return sustain != null;

   function get_canBeHit():Bool {
      if (goodHit || missed)
         return false;

      if (parentStrumline != null)
         return (parentStrumline.cpu && time <= Conductor.time) || (!parentStrumline.cpu && Math.abs(Conductor.time - time) <= safeZoneOffset);

      return this.canBeHit;
   }
}

class Sustain extends TiledSprite {   
   public var tail(default, null):FlxSprite;
   public var parent(default, set):Note;

   public function new():Void {
      // TODO: make scaling not dependant of `repeatX`
      super(null, 0, 0, true, true);

      tail = new FlxSprite();
      alpha = 0.6;
   }

   override function update(elapsed:Float):Void {
      if (tail.exists && tail.active)
         tail.update(elapsed);

      super.update(elapsed);
   }

   override function draw():Void {
      updateSustain();

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

   public inline function updateSustain():Void {
      height = (parent.length - parent.sustainDecrease) * parent.scrollSpeed - tail.height;

      setPosition(parent.x + ((parent.width - width) * 0.5), parent.y + (parent.height * 0.5));
      if (parent.downscroll)
         y -= height;

      tail.setPosition(x, (parent.downscroll) ? (y - tail.height) : (y + height));
      flipY = (parent.flipSustain && parent.scrollMult < 0);

      if (height <= 0 && parent.baseVisible)
         tail.y += tail.height * _facingVerticalMult;
   }

   public function reloadGraphic():Void {
      if (parent == null)
         return;

      var dir:String = Note.directions[parent.direction];

      loadFrame(parent.frames.getByName('${dir} hold piece0000'));
      scale.x = 0.7;

      tail.loadGraphic(FlxGraphic.fromFrame(parent.frames.getByName('${dir} hold end0000')));
      tail.scale.set(0.7, 0.7);

      updateHitbox();
   }

   override function updateHitbox():Void {
      width = graphic.width * scale.x;
      tail.updateHitbox();
   }

   function set_parent(v:Note):Note {
      parent = v;
      reloadGraphic();
      return v;
   }

   override function set_height(v:Float):Float {
      regen = (v != height && v > 0) || regen;
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