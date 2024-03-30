function onCountdownTick(_):Void {
    pixelize(countdownSprite);
}

function onNoteHitPost(_):Void {
    for (spr in ratingSprites) pixelize(spr);
    for (spr in comboSprites) pixelize(spr);
}

function pixelize(sprite:FlxSprite):Void {
    sprite.scale.set(6, 6);
    sprite.antialiasing = false;
}