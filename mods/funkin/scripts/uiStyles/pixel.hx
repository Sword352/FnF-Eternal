function onCreatePost():Void {
    ratingSprites.group.memberAdded.add((sprite) -> pixelize(sprite));
    comboSprites.group.memberAdded.add((sprite) -> pixelize(sprite));
}

function onCountdownTick(_):Void {
    pixelize(countdownSprite);
}

function pixelize(sprite:FlxSprite):Void {
    sprite.antialiasing = false;
    sprite.scale.set(6, 6);
}
