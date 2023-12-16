package funkin.objects.notes;

import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import funkin.objects.sprites.TiledSprite;
import flixel.graphics.frames.FlxFramesCollection;

class Note extends OffsetSprite {
   public static final directions:Array<String> = ["left", "down", "up", "right"];
   public static final safeZoneOffset:Float = 166.66;
   public static final globalWidth:Float = 112;

   public var canBeHit(get, never):Bool;
   public var late(get, never):Bool;
   public var goodHit:Bool = false;
   public var missed:Bool = false;

   public var isSustainNote(get, never):Bool;
   public var sustain(default, null):Sustain;

   public var holdBehindStrum:Bool = Settings.get("hold notes behind receptors");
   public var baseVisible:Bool = true;

   public var followX:Bool = true;
   public var followY:Bool = true;
   public var followSpeed:Bool = true;
   public var flipSustain:Bool = true;

   public var direction:Int = 0;
   public var strumline:Int = 0;

   public var length(default, set):Float = 0;
   public var time:Float = 0;

   public var scrollSpeed:Float = 0.45;
   public var scrollMult:Float = 1;
   public var distance:Float = 0;

   public var offsetX:Float = 0;
   public var offsetY:Float = 0;
   public var spawnTimeOffset:Float = 0;

   public var type:String = "";
   public var animSuffix:String;

   public function new(time:Float = 0, direction:Int = 0):Void {
      super();

      this.time = time;
      this.direction = direction;

      var dir:String = directions[direction];

      frames = AssetHelper.getSparrowAtlas("notes/notes");
		animation.addByPrefix(dir, '${dir}0');
      playAnimation(dir);

      scale.set(0.7, 0.7);
      updateHitbox();
      resetPosition();
   }

   public function resetPosition():Void {
      // making sure it goes off screen
      this.x = -FlxG.width;
      this.y = -FlxG.height;
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
      animSuffix = null;
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

         sustain.length = v;
         sustain.updateSustain();
      }
      else if (isSustainNote) {
         sustain.destroy();
         sustain = null;
      }

      return length = v;
   }

   inline function get_late():Bool {
      return (Conductor.position - time) > safeZoneOffset;
   }

   inline function get_isSustainNote():Bool
      return sustain != null;

   inline function get_canBeHit():Bool
      return !goodHit && !missed && Math.abs(Conductor.position - time) <= safeZoneOffset;
}

class Sustain extends TiledSprite {
   public var length:Float = Conductor.stepCrochet;
   public var scrollSpeed:Float = 0.45;
   public var downscroll:Bool = false;

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

   public function updateSustain():Void {
      var len:Float = length * scrollSpeed - tail.height;
      height = Math.max(0, len);

      if (parent != null) {
         setPosition(parent.x + ((parent.width - width) * 0.5), parent.y + (parent.height * 0.5));
         if (downscroll)
            y -= len;
      }

      tail.setPosition(x, (downscroll) ? (y - tail.height) : (y + len));

      if (height <= 0 && parent?.baseVisible)
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