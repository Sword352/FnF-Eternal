function onCreatePost():Void {
    playField.comboPopup.ratingSprites.group.memberAdded.add(pixelize);
    playField.comboPopup.comboSprites.group.memberAdded.add(pixelize);
}

function onCountdownTick(_):Void {
    pixelize(countdown.sprite);
}

function pixelize(sprite:FlxSprite):Void {
    sprite.antialiasing = false;
    sprite.scale.set(6, 6);
}
