package core;

#if ENGINE_DISCORD_RPC
import hxdiscord_rpc.Types;
import hxdiscord_rpc.Discord;

import sys.thread.Thread;

class DiscordPresence {
    public static final DEFAULT_ID:String = "1147408113792725012";

    public static var username(default, null):String;
    public static var presence(default, null):RPCWrapper;

    #if ENGINE_MODDING
    static var lastClient:String;
    #end

    public static function init():Void {
        presence = new RPCWrapper();
        connect(DEFAULT_ID);

        Thread.create(() -> {
            while (true) {
                #if DISCORD_DISABLE_IO_THREAD
                Discord.UpdateConnection();
                #end
                Discord.RunCallbacks();

                Sys.sleep(0.5);
            }
        });

        FlxG.stage.application.onExit.add((_) -> shutdown());
    }

    public static function connect(id:String):Void {
        var handlers:DiscordEventHandlers = DiscordEventHandlers.create();
        handlers.ready = cpp.Function.fromStaticFunction(onReady);
        handlers.errored = cpp.Function.fromStaticFunction(onError);
        handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
        Discord.Initialize(id, cpp.RawPointer.addressOf(handlers), 1, null);

        #if ENGINE_MODDING
        lastClient = id;
        #end
    }

    #if ENGINE_MODDING
    public inline static function reconnect(id:String):Void {
        // TODO: connect to the default ID if `id` is invalid
        if (lastClient != null && lastClient == id)
            return;

        if (lastClient != null)
            shutdown();
        connect(id);
    }
    #end

    public static function shutdown():Void {
        Discord.Shutdown();
        username = null;

        #if ENGINE_MODDING
        lastClient = null;
        #end
    }

    static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void {
        username = cpp.ConstPointer.fromRaw(request).ptr.username;
        trace('Connected to Discord as ${username}.');

        presence.largeImageKey = "logo";
        presence.largeImageText = Tools.devState;
    }

    static inline function onError(errorCode:Int, message:cpp.ConstCharStar):Void {
        trace('An error has occured while connecting! [${message} (code: ${errorCode})]');
        shutdown();
    }

    static inline function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void {
        trace('Connection has been lost! [${message} (code: ${errorCode})]');
        shutdown();
    }
}

// wrapper used to automatically update the presence when something gets changed
private class RPCWrapper {
    public var state(default, set):String;
    public var details(default, set):String;

    public var startTimestamp(default, set):cpp.Int64;
    public var endTimestamp(default, set):cpp.Int64;

    public var largeImageKey(default, set):String;
    public var largeImageText(default, set):String;
    public var smallImageKey(default, set):String;
    public var smallImageText(default, set):String;

    var presence:DiscordRichPresence;
    var pointer:cpp.RawPointer<DiscordRichPresence>;

    var show:Bool = true;

    public function new():Void {
        presence = DiscordRichPresence.create();
        pointer = cpp.RawPointer.addressOf(presence);
    }

    public function hide(value:Bool = true):Void {
        show = !value;
        updateRPC();
    }

    function set_state(v:String):String {
        presence.state = state = v;
        updateRPC();
        return v;
    }

    function set_details(v:String):String {
        presence.details = details = v;
        updateRPC();
        return v;
    }

    function set_startTimestamp(v:cpp.Int64):cpp.Int64 {
        presence.startTimestamp = startTimestamp = v;
        updateRPC();
        return v;
    }

    function set_endTimestamp(v:cpp.Int64):cpp.Int64 {
        presence.endTimestamp = endTimestamp = v;
        updateRPC();
        return v;
    }

    function set_largeImageKey(v:String):String {
        presence.largeImageKey = largeImageKey = v;
        updateRPC();
        return v;
    }

    function set_largeImageText(v:String):String {
        presence.largeImageText = largeImageText = v;
        updateRPC();
        return v;
    }

    function set_smallImageKey(v:String):String {
        presence.smallImageKey = smallImageKey = v;
        updateRPC();
        return v;
    }

    function set_smallImageText(v:String):String {
        presence.smallImageText = smallImageText = v;
        updateRPC();
        return v;
    }

    inline function updateRPC():Void {
        Discord.UpdatePresence((show) ? pointer : null);
    }
}
#end
