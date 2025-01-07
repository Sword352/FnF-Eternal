package funkin.core;

#if DISCORD_RPC
import hxdiscord_rpc.Types;
import hxdiscord_rpc.Discord;
import sys.thread.Thread;
import sys.thread.Mutex;
import haxe.Int64;

/**
 * A simple object which allows to control the Discord Rich Presence (RPC).
 * The Rich Presence displays informations on the user's Discord profile about the game they're playing, such as the current state, elapsed time, and more.
 * This class provides a simple interface to interact with the integration.
 */
class DiscordRPC {
    /**
     * Global `DiscordRPC` instance.
     */
    public static var self:DiscordRPC;

    /**
     * Determines whether the presence is disabled.
     */
    public var hidden(default, set):Bool = Options.noDiscordRpc;

    /**
     * Determines the state shown in the Rich Presence.
     */
    public var state(default, set):String;

    /**
     * Determines the details shown in the Rich Presence.
     */
    public var details(default, set):String;

    /**
     * Object which controls the timestamp of the Rich Presence.
     */
    public var timestamp(default, null):DiscordTimestamp;

    /**
     * Object which controls the large image of the Rich Presence.
     */
    public var largeImage(default, null):IDiscordImage;

    /**
     * Object which controls the small image of the Rich Presence.
     */
    public var smallImage(default, null):IDiscordImage;

    /**
     * Object which controls the first button of the Rich Presence.
     */
    public var button1(default, null):DiscordRPCButton;

    /**
     * Object which controls the second button of the Rich Presence.
     */
    public var button2(default, null):DiscordRPCButton;

    /**
     * Internal object which stores methods to call whenever an event occurs.
     */
    var _connectionEvents:DiscordEventHandlers;

    /**
     * Internal object which stores data about the Rich Presence.
     */
    @:allow(funkin.core.DiscordRPC)
    var _presenceData:DiscordRichPresence;

    /**
     * Internal flag which determines whether the presence should be updated.
     */
    @:allow(funkin.core.DiscordRPC)
    var _presenceDirty:Bool = false;

    /**
     * Internal, stores the identifier of the application the Rich Presence should display.
     */
    var _currentAppID:String = null;

    /**
     * Internal reference to the Discord update thread.
     */
    var _updateThread:Thread;

    /**
     * Internal mutex used to make `_presenceDirty` safe to access by the update thread.
     */
    var _presenceMutex:Mutex;

    /**
     * Creates a new `DiscordRPC`.
     */
    public function new():Void {
        self = this;

        _connectionEvents = DiscordEventHandlers.create();
        _presenceData = DiscordRichPresence.create();

        _connectionEvents.ready = cpp.Function.fromStaticFunction(onReady);
        _connectionEvents.errored = cpp.Function.fromStaticFunction(onError);
        _connectionEvents.disconnected = cpp.Function.fromStaticFunction(onDisconnect);

        _presenceMutex = new Mutex();

        largeImage = new LargeDiscordImage();
        smallImage = new SmallDiscordImage();
        timestamp = new DiscordTimestamp();

        button1 = new DiscordRPCButton(0);
        button2 = new DiscordRPCButton(1);

        largeImage.text = Tools.devState;
        largeImage.key = "logo";
        
        FlxG.stage.application.onExit.add((_) -> shutdown());

        if (hidden) {
            _currentAppID = "1147408113792725012";
            _updateThread = Thread.createWithEventLoop(() -> Sys.sleep(0.001)); // make the thread sleep so that we get the time to call promise()
            _updateThread.events.promise();
            return;
        }

        _updateThread = Thread.createWithEventLoop(threadLoop);
        connect("1147408113792725012");
    }

    /**
     * Connects to a Discord application.
     * @param appID Application ID.
     */
    public function connect(appID:String):Void {
        if (appID == null)
            return;

        // make sure to shutdown any connections in order to connect into another app
        shutdown();

        Discord.Initialize(appID, cpp.RawPointer.addressOf(_connectionEvents), 1, null);
        _currentAppID = appID;
        _presenceDirty = true;
    }

    /**
     * Shutdowns the Discord Rich Presence.
     */
    inline function shutdown():Void {
        Discord.Shutdown();
    }

    /**
     * Update loop executed by the `_updateThread`, which updates the connection with Discord.
     */
    function threadLoop():Void {
        while (!hidden) {
            var updatePresence:Bool = false;

            _presenceMutex.acquire();
            if (_presenceDirty) {
                _presenceDirty = false;
                updatePresence = true;
            }
            _presenceMutex.release();

            if (updatePresence)
                Discord.UpdatePresence(cpp.RawConstPointer.addressOf(_presenceData));

            Discord.UpdateConnection();
            Discord.RunCallbacks();
            Sys.sleep(1);
        }
    }

    function set_state(v:String):String {
        if (state != v) {
            // state must be at least 2 characters long
            if (v != null)
                v = v.rpad(" ", 2);
            else
                v = "  ";

            _presenceData.state = v;
            _presenceDirty = true;
        }

        return state = v;
    }

    function set_details(v:String):String {
        if (details != v) {
            _presenceData.details = v;
            _presenceDirty = true;
        }

        return details = v;
    }

    function set_hidden(v:Bool):Bool {
        var changed:Bool = (hidden != v);
        hidden = v;

        if (changed) {
            if (v) {
                _updateThread.events.promise();
                shutdown();
            }
            else {
                _updateThread.events.runPromised(threadLoop);
                connect(_currentAppID);
            }
        }

        return v;
    }

    /**
     * Method called whenever the connection with Discord has been established.
     */
    static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void {
        trace('Connected to Discord as "${cpp.ConstPointer.fromRaw(request).ptr.username}"');
    }

    /**
     * Method called whenever an error occurs.
     */
    static function onError(errorCode:Int, message:cpp.ConstCharStar):Void {
        Logging.error('An error has occured! (message: ${message}, error code: ${errorCode})');
    }

    /**
     * Method called whenever a disconnection occurs.
     */
    static function onDisconnect(errorCode:Int, message:cpp.ConstCharStar):Void {
        Logging.warning('Connection has been lost! (message: ${message}, error code: ${errorCode})');
    }
}

/**
 * Object controlling the Discord RPC timestamp.
 */
private class DiscordTimestamp {
    /**
     * Start of the timestamp.
     */
    public var start(default, set):Int64;

    /**
     * End of the timestamp.
     */
    public var end(default, set):Int64;

    public function new():Void {}

    /**
     * Resets and hides the timestamp.
     */
    public function reset():Void {
        start = 0;
        end = 0;
    }

    function set_start(v:Int64):Int64 {
        if (start != v) {
            DiscordRPC.self._presenceData.startTimestamp = v;
            DiscordRPC.self._presenceDirty = true;
        }

        return start = v;
    }

    function set_end(v:Int64):Int64 {
        if (end != v) {
            DiscordRPC.self._presenceData.endTimestamp = v;
            DiscordRPC.self._presenceDirty = true;
        }

        return end = v;
    }
}

/**
 * Object controlling a Discord RPC button.
 */
private class DiscordRPCButton {
    /**
     * Text displayed on top of the button.
     */
    public var label(default, set):String;

    /**
     * URL to open whenever the button has been clicked.
     */
    public var url(default, set):String;
    
    /**
     * ID of the button.
     */
    var id:Int;

    public function new(id:Int):Void {
        DiscordRPC.self._presenceData.buttons[id] = DiscordButton.create();
        this.id = id;
    }

    function set_label(v:String):String {
        if (label != v) {
            DiscordRPC.self._presenceData.buttons[id].label = formatString(v);
            DiscordRPC.self._presenceDirty = true;
        }

        return label = v;
    }

    function set_url(v:String):String {
        if (url != v) {
            DiscordRPC.self._presenceData.buttons[id].url = formatString(v);
            DiscordRPC.self._presenceDirty = true;
        }

        return url = v;
    }

    static function formatString(value:String):String {
        if (value == null)
            return value;

        // can't use a string with more than 32 characters, so trim it
        if (value.length > 32)
            return value.substring(0, 29) + "...";

        return value;
    }
}

/**
 * Object controlling the small Discord RPC image.
 */
private class SmallDiscordImage implements IDiscordImage {
    /**
     * Text displayed whenever the image is hovered.
     */
    public var text(default, set):String;

    /**
     * Image to be displayed. Can be an asset key or an URL.
     */
    public var key(default, set):String;

    public function new():Void {}

    function set_text(v:String):String {
        if (text != v) {
            DiscordRPC.self._presenceData.smallImageText = v;
            DiscordRPC.self._presenceDirty = true;
        }

        return text = v;
    }

    function set_key(v:String):String {
        if (key != v) {
            DiscordRPC.self._presenceData.smallImageKey = v;
            DiscordRPC.self._presenceDirty = true;
        }

        return key = v;
    }
}

/**
 * Object controlling the large Discord RPC image.
 */
private class LargeDiscordImage implements IDiscordImage {
    /**
     * Text displayed whenever the image is hovered.
     */
    public var text(default, set):String;

    /**
     * Image to be displayed. Can be an asset key or an URL.
     */
    public var key(default, set):String;

    public function new():Void {}

    function set_text(v:String):String {
        if (text != v) {
            DiscordRPC.self._presenceData.largeImageText = v;
            DiscordRPC.self._presenceDirty = true;
        }

        return text = v;
    }

    function set_key(v:String):String {
        if (key != v) {
            DiscordRPC.self._presenceData.largeImageKey = v;
            DiscordRPC.self._presenceDirty = true;
        }

        return key = v;
    }
}

/**
 * Represents a Discord RPC image.
 */
private interface IDiscordImage {
    /**
     * Text displayed whenever the image is hovered.
     */
    public var text(default, set):String;

    /**
     * Image to be displayed. Can be an asset key or an URL.
     */
    public var key(default, set):String;
}
#end
