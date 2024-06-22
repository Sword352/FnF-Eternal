var intendedZoom:Float = -1;

function onCreatePost():Void {
    camGame.zoom = 1;
}

function onUpdate(elapsed):Void {
    cameraZoom = Tools.lerp(cameraZoom, intendedZoom, 5);
}

function onCameraFocus(event):Void {
    intendedZoom = switch (event.character) {
        case spectator: 1.1;
        default: 0.9;
    }
}

function onBeatHit(event):Void {
    // disables camera bumping.
    event.cameraBump = false;
}

function onGameOver(event):Void {
    // no gameover in the tutorial!
    event.cancel();
}
