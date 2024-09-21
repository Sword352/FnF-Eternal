function onBeatHit(event) {
    if (event.beat <= 0 || event.beat % 8 != 7)
        return;

    if (StringTools.endsWith(player.animation.name, "miss")) {
        // health = Math.max(health, 1);
        return;
    }

    spectator.playSpecialAnim("hey", Conductor.self.crotchet);
    player.playSpecialAnim("hey", Conductor.self.crotchet);

    camGame.zoom += 0.12;
}
