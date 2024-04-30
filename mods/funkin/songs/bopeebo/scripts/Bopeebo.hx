function onBeatHit(i) {
    if (i <= 0 || i % 8 != 7)
        return;

    if (StringTools.endsWith(player.animation.name, "miss")) {
        // health = Math.max(health, 1);
        return;
    }

    player.holding = false;
    player.holdTime = 0;

    for (character in [player, spectator]) {
        character.playAnimation("hey", true);
        character.animEndTime = Conductor.self.crochet * 0.001;
    }

    camGame.zoom += 0.12;
}