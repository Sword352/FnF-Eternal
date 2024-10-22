function onCreatePost():Void {
    var speakers:FlxSprite = new FlxSprite();
    speakers.frames = this.frames;
    speakers.animation.addByPrefix("speakers", "speakers", 24, false);
    speakers.animation.play("speakers");
    speakers.animation.finish();

    speakers.x = this.x - this.width * 0.65;
    speakers.y = this.y + this.height * 0.7;
    insert(members.indexOf(this), speakers);

    conductor.onBeat.add((_) -> speakers.animation.play("speakers"));
    closeScript();
}
