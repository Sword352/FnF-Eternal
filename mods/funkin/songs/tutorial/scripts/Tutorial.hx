function onCreatePost() {
    cameraZoomIntensity = 0;
    camGame.zoom = 1;
}

function onUpdate(elapsed) {
    cameraZoom = Tools.lerp(cameraZoom, (cameraFocus == spectator) ? 1.1 : 0.9, 5);
}

// no gameover on tutorial
function onGameOver() {
    return false;
}
