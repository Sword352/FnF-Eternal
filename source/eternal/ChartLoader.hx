package eternal;

import funkin.objects.notes.Note;
import funkin.objects.notes.StrumLine;
import eternal.ChartFormat;
import haxe.Json;

class ChartLoader {
    public static inline function getEmptyMeta():SongMetadata
        return {
            name: null,
            rawName: null,
            player: null,
            opponent: null,
            spectator: null,
            stage: null,
            instFile: "Inst",
            voiceFiles: ["Voices"],
            scrollSpeed: 1,
            bpm: 100
        };

    public static inline function getEmptyChart():Chart
        return {
            notes: [],
            events: [],
            meta: getEmptyMeta()
        };

    public static inline function loadMetadata(song:String):SongMetadata {
        var path:String = Assets.json('songs/${song}/meta');
        if (!FileTools.exists(path)) {
            trace('Could not find meta file for song "${song}"!');
            return getEmptyMeta();
        }

        var data:SongMetadata = Json.parse(FileTools.getContent(path));

        if (data.rawName == null)
            data.rawName = song;

        if (data.name == null)
            data.name = data.rawName;

        return data;
    }

    public static inline function convertChart(data:BaseGameChart):Chart {
        var finalData:Chart = {
            meta: {
                name: data.song,
                rawName: data.song.toLowerCase().replace(" ", "-"),

                player: data.player1,
                opponent: data.player2,
                spectator: data.gfVersion ?? data.player3,
                stage: data.stage ?? "",

                instFile: "Inst",
                voiceFiles: (data.needsVoices) ? ["Voices"] : [],

                scrollSpeed: data.speed,
                bpm: data.bpm
            },

            notes: [],
            events: []
        }

        // Used to replace some section specific stuff with events
        var currentBPM:Float = data.bpm;
        var currentTarget:Int = -1;
        var time:Float = 0;

        for (section in cast(data.notes, Array<Dynamic>)) {
            for (noteData in cast(section.sectionNotes, Array<Dynamic>)) {
                var direction:Int = noteData[1];
                if (direction < 0) // ignore psych events
                    continue;

                var shouldHit:Bool = section.mustHitSection;
                if (direction > 3)
                    shouldHit = !shouldHit;

                var type:String = noteData[3];
                if (section.altAnim && type == null)
                    type = "Alt Animation";

                var data:ChartNote = {
                    time: noteData[0],
                    direction: Std.int(direction % 4),
                    strumline: (shouldHit) ? 1 : 0,
                    type: type
                };

                data.length = (noteData[2] != null && noteData[2] is Float) ? noteData[2] : 0;
                finalData.notes.push(data);
            }

            var intendedTarget:Int = (section.mustHitSection) ? 2 : 0;
            if (intendedTarget != currentTarget) {
                finalData.events.push({
                    event: "change camera target",
                    arguments: [intendedTarget],
                    time: time
                });
                currentTarget = intendedTarget;
            }

            var intendedBPM:Null<Float> = (section.changeBPM) ? section.bpm : null;
            if (intendedBPM != null && intendedBPM != currentBPM) {
                finalData.events.push({
                    event: "change bpm",
                    arguments: [intendedBPM],
                    time: time
                });
                currentBPM = intendedBPM;
            }

            time += ((60 / currentBPM) * 1000) * 4;
        }

        return finalData;
    }

    /*
        public static function convertToLegacy(chart:Chart):Dynamic {
            var output:Dynamic = {
                song: {
                    song: chart.meta.rawName,
                    speed: chart.meta.speed,
                    bpm: chart.meta.bpm,
                    notes: [],

                    player1: chart.meta.player,
                    player2: chart.meta.opponent,

                    needsVoices: (chart.meta.voiceFiles.length > 0),
                    validScore: true
                }
            };

            return output;
        }
    */
    
    public static inline function generateNotes(chart:Chart, minTime:Float = 0, ?strumLines:Array<StrumLine>, playerSkin:String = "default",
            oppSkin:String = "default"):Array<Note> {
        var notes:Array<Note> = [];

        for (noteData in chart.notes) {
            if (noteData.time < minTime) continue;

            var note:Note = new Note(noteData.time, noteData.direction, (noteData.strumline == 1) ? playerSkin : oppSkin);
            note.strumline = noteData.strumline;
            note.length = noteData.length;
            note.type = noteData.type;
            notes.push(note);

            if (strumLines != null)
                note.parentStrumline = strumLines[note.strumline];
        }

        notes.sort((n1, n2) -> Std.int(n1.time - n2.time));
        return notes;
    }

    public static function loadChart(song:String, ?difficulty:String):Chart {
        if (difficulty == null)
            difficulty = "normal";

        var path:String = Assets.json('songs/${song}/charts/${difficulty}');
        var data:Dynamic = Json.parse(FileTools.getContent(path));
        #if sys var overwrite:Bool = false; #end

        if (data.song != null) {
            data = convertChart(data.song); // conver charts that uses fnf legacy format
            #if sys overwrite = Settings.get("overwrite chart files"); #end
        }
        else if (data.meta == null)
            data.meta = loadMetadata(song);

        if (data.meta.stage == null)
            data.meta.stage = "";

        // check for events
        if (data.events == null) {
            var eventsPath:String = Assets.json('songs/${song}/events');
            if (FileTools.exists(eventsPath))
                data.events = Json.parse(FileTools.getContent(eventsPath));
            else
                data.events = [];
        }

        // backward compat
        if (data.speed != null) data.meta.scrollSpeed = data.speed;
        if (data.bpm != null) data.meta.bpm = data.bpm;

        #if sys
        if (overwrite)
            sys.io.File.saveContent(path, Json.stringify(data)); // overwrite the chart json
        #end

        return Chart.resolve(data);
    }
}
