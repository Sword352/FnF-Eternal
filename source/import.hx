package eternal;

#if !macro
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxDestroyUtil;

import eternal.tools.*;
import eternal.core.Assets;

import eternal.Controls;
import eternal.Settings;
import eternal.HighScore;

#if ENGINE_DISCORD_RPC
import eternal.core.DiscordPresence;
#end

#if ENGINE_MODDING
import eternal.core.Mods;
#end

import funkin.music.Conductor;
import funkin.objects.sprites.OffsetSprite;
import funkin.music.MusicBeat.MusicBeatState;
import funkin.music.MusicBeat.MusicBeatSubState;

import funkin.states.PlayState;
import funkin.states.Transition.TransitionState;
import funkin.states.Transition.TransitionSubState;

using eternal.tools.Tools;
using StringTools;
#end
