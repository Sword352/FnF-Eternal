package;

#if !macro
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxDestroyUtil;

import funkin.core.Controls;
import funkin.utils.*;

import funkin.save.*;
import funkin.save.Options;

import funkin.core.modding.Mods;
import funkin.core.assets.Assets;

#if DISCORD_RPC
import funkin.core.DiscordRPC;
#end

import funkin.core.scripting.*;
import funkin.core.scripting.events.*;

import funkin.Conductor;
import funkin.MusicBeatState;
import funkin.gameplay.PlayState;
import funkin.Transition;

using funkin.utils.Tools;
using StringTools;
#end
