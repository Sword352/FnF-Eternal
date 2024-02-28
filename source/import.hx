package eternal;

#if !macro
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxDestroyUtil;

import eternal.Controls;
import eternal.HighScore;
import eternal.Settings;
import eternal.core.Assets;
import eternal.tools.*;

#if ENGINE_MODDING import eternal.core.Mods; #end
#if ENGINE_DISCORD_RPC import eternal.core.DiscordPresence; #end

import funkin.music.Conductor;
import funkin.music.MusicBeatState;
import funkin.states.PlayState;
import funkin.states.Transition;

using eternal.tools.Tools;
using StringTools;
#end
