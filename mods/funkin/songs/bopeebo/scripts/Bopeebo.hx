function onBeatHit(event) {
    if (event.beat <= 0 || event.beat % 8 != 7)
        return;

    if (StringTools.endsWith(player.animation.name, "miss")) {
        // health = Math.max(health, 1);
        return;
    }

    for (character in [player, spectator])
        character.playSpecialAnim("hey", Conductor.self.crochet);

    camGame.zoom += 0.12;
}
