package funkin.gameplay.events;

import funkin.core.macros.SongEventMacro;
import funkin.gameplay.events.EventTypes;

/**
 * Singleton containing event lists.
 */
class EventList {
    /**
     * Event list for builtin events.
     */
    public static final list:Map<String, Class<SongEvent>> = cast SongEventMacro.getList();

    /**
     * Metadata list for builtin events.
     */
    public static final metas:Map<String, EventMeta> = fixMacroMetas(SongEventMacro.getMetas());

    /**
     * Returns builtin and softcoded event metadatas.
     */
    public static function getMetas():Map<String, EventMeta> {
        var path:String = Assets.getPath("data/events", NONE);
        var output:Array<EventMeta> = [for (meta in metas) meta];

        if (FileTools.exists(path))
            output = output.concat(readEvents(path));

        return [for (ev in output) ev.type => ev];
    }

    /**
     * Method which looks for softcoded events from a path.
     * @param path The path to scan
     */
    static function readEvents(path:String):Array<EventMeta> {
        var exts:Array<String> = YAML.getExtensions();
        var output:Array<EventMeta> = [];

        for (file in FileTools.readDirectory(path)) {
            var point:Int = file.indexOf(".");
            if (!exts.contains(file.substring(point))) continue;

            var content:String = FileTools.getContent(path + "/" + file);
            var event:EventMeta = Tools.parseYAML(content);
            event.type = file.substring(0, point);

            if (event.name == null)
                event.name = event.type;

            if (event.arguments == null)
                event.arguments = [];

            /*
            // converts string type into int
            for (argument in event.arguments) {
                if (argument.type is String)
                    argument.type = EventArgumentType.fromString(cast argument.type);
            }
            */

            output.push(event);
        }

        return output;
    }

    /**
     * Temporary workaround.
     * To define the default value for arguments with the macro, you must define it as a string in "tempValue".
     * This method converts `tempValue`s into readable `defaultValue`s.
     */
    static function fixMacroMetas(metas:Map<String, EventMeta>):Map<String, EventMeta> {
        for (meta in metas) {
            for (argument in meta.arguments) {
                if (argument.tempValue == null)
                    continue;

                argument.defaultValue = EventMacroFixer.fixMacroValue(argument);
                Reflect.deleteField(argument, "tempValue");
            }
        }

        return metas;
    }
}
