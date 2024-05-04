package objects;

import flixel.math.FlxPoint;
import flixel.FlxObject;
import flixel.FlxCamera;

// Temporary until flixel 6.0.0, official target follow bug (on low framerates) fix
class Camera extends FlxCamera {
    public function new(x:Float = 0, y:Float = 0, width:Int = 0, height:Int = 0, zoom:Float = 0):Void {
        super(x, y, width, height, zoom);
        followLerp = 1.0;
    }

    override public function update(elapsed:Float):Void {
        // follow the target, if there is one
        if (target != null) {
            updateFollow();
            updateLerp(elapsed);
        }

        updateScroll();
        updateFlash(elapsed);
        updateFade(elapsed);

        flashSprite.filters = filtersEnabled ? filters : null;

        updateFlashSpritePosition();
        updateShake(elapsed);
    }

    override function updateFollow():Void {
        // Either follow the object closely,
        // or double check our deadzone and update accordingly.
        if (deadzone == null) {
            target.getMidpoint(_point);
            _point.addPoint(targetOffset);
            _scrollTarget.set(_point.x - width * 0.5, _point.y - height * 0.5);
        } else {
            var edge:Float;
            var targetX:Float = target.x + targetOffset.x;
            var targetY:Float = target.y + targetOffset.y;

            if (style == SCREEN_BY_SCREEN) {
                if (targetX >= viewRight) {
                    _scrollTarget.x += viewWidth;
                } else if (targetX + target.width < viewLeft) {
                    _scrollTarget.x -= viewWidth;
                }

                if (targetY >= viewBottom) {
                    _scrollTarget.y += viewHeight;
                } else if (targetY + target.height < viewTop) {
                    _scrollTarget.y -= viewHeight;
                }

                // without this we see weird behavior when switching to SCREEN_BY_SCREEN at arbitrary scroll positions
                bindScrollPos(_scrollTarget);
            } else {
                edge = targetX - deadzone.x;
                if (_scrollTarget.x > edge) {
                    _scrollTarget.x = edge;
                }
                edge = targetX + target.width - deadzone.x - deadzone.width;
                if (_scrollTarget.x < edge) {
                    _scrollTarget.x = edge;
                }

                edge = targetY - deadzone.y;
                if (_scrollTarget.y > edge) {
                    _scrollTarget.y = edge;
                }
                edge = targetY + target.height - deadzone.y - deadzone.height;
                if (_scrollTarget.y < edge) {
                    _scrollTarget.y = edge;
                }
            }

            if ((target is FlxSprite)) {
                if (_lastTargetPosition == null) {
                    _lastTargetPosition = FlxPoint.get(target.x, target.y); // Creates this point.
                }
                _scrollTarget.x += (target.x - _lastTargetPosition.x) * followLead.x;
                _scrollTarget.y += (target.y - _lastTargetPosition.y) * followLead.y;

                _lastTargetPosition.x = target.x;
                _lastTargetPosition.y = target.y;
            }
        }
    }

    inline function updateLerp(elapsed:Float) {
        // Adjust lerp based on the current frame rate so lerp is less framerate dependant
        final boundLerp = FlxMath.bound(followLerp, 0, 1);
        final adjustedLerp = 1.0 - Math.pow(1.0 - boundLerp, elapsed * 60);

        if (adjustedLerp >= 1) {
            scroll.copyFrom(_scrollTarget); // no easing
        } else {
            scroll.x += (_scrollTarget.x - scroll.x) * adjustedLerp;
            scroll.y += (_scrollTarget.y - scroll.y) * adjustedLerp;
        }
    }

    override function follow(Target:FlxObject, ?Style:FlxCameraFollowStyle, ?Lerp:Float):Void {
        if (Lerp == null)
            Lerp = 1.0;

        super.follow(Target, Style, Lerp);
    }

    override function set_followLerp(v:Float):Float
        return followLerp = v;
}
