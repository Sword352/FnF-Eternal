package;

#if !macro
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxDestroyUtil;

import funkin.utils.*;
import funkin.utils.Logging.DefaultLogStyle;

import funkin.save.*;
import funkin.save.Options;
import funkin.core.Controls;

import funkin.core.modding.Mods;
import funkin.core.assets.Extensions;
import funkin.core.assets.*;

#if DISCORD_RPC
import funkin.core.DiscordRPC;
#end

import funkin.core.scripting.*;
import funkin.core.scripting.events.*;
import funkin.core.scripting.Events;

import funkin.music.Conductor;
import funkin.MusicBeatState;
import funkin.ui.Transition;
import funkin.gameplay.PlayState;

using funkin.utils.Tools;
using funkin.utils.FlxObjectTools;
using StringTools;
#end
