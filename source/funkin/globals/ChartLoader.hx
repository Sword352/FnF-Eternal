package funkin.globals;

import funkin.gameplay.notes.Note;
import funkin.gameplay.notes.StrumLine;
import funkin.globals.ChartFormat;
import haxe.Json;

class ChartLoader {
    public static inline function getEmptyGameplay():GameplayInfo
        return {
            player: null,
            opponent: null,
            spectator: null,
            stage: null,
            instrumental: "Inst",
            voices: ["Voices"],
            scrollSpeed: 1,
            bpm: 100
        };

    public static inline function getEmptyMeta():SongMeta
        return {
            name: null,
            folder: null,
            difficulties: ["normal"],
            gameplayInfo: getEmptyGameplay(),
            freeplayInfo: null
        }

    public static inline function getEmptyChart():Chart
        return {
            gameplayInfo: getEmptyGameplay(),
            meta: getEmptyMeta(),
            events: [],
            notes: []
        };

    public static inline function loadMeta(song:String):SongMeta {
        var path:String = Assets.json('songs/${song}/meta');
        if (!FileTools.exists(path)) {
            trace('Could not find meta file for song "${song}"!');
            return getEmptyMeta();
        }

        var data:SongMeta = Json.parse(FileTools.getContent(path));
        data.folder = song;
        return data;
    }

    public static inline function resolveGameplayInfo(chart:Chart):GameplayInfo {
        var finalInfo:GameplayInfo = null;
        var meta:SongMeta = chart.meta;

        // if null, simply get one from the meta
        if (chart.gameplayInfo == null)
            finalInfo = meta.gameplayInfo;
        else {
            // otherwise get the one from the chart
            finalInfo = chart.gameplayInfo;

            // allows for overridable fields
            if (meta.gameplayInfo != null) {
                for (field in Reflect.fields(meta.gameplayInfo))
                    if (!Reflect.hasField(finalInfo, field))
                        Reflect.setField(finalInfo, field, Reflect.getProperty(meta.gameplayInfo, field));
            }
        }

        return finalInfo;
    }

    public static inline function exportMeta(meta:SongMeta):SongMeta {
        var output:SongMeta = Reflect.copy(meta);
        Reflect.deleteField(output, "folder");
        return output;
    }

    public static inline function convertChart(data:BaseGameChart):Chart {
        var gameplayInfo:GameplayInfo = {
            player: data.player1,
            opponent: data.player2,
            spectator: data.gfVersion ?? data.player3,
            stage: data.stage ?? "",

            instrumental: "Inst",
            voices: (data.needsVoices) ? ["Voices"] : [],

            scrollSpeed: data.speed,
            bpm: data.bpm
        };

        var finalData:Chart = {
            gameplayInfo: gameplayInfo,
            meta: {
                name: data.song,
                folder: data.song.toLowerCase().replace(" ", "-"),
                difficulties: ["easy", "normal", "hard"],
                gameplayInfo: gameplayInfo,
                freeplayInfo: null
            },

            events: [],
            notes: []
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
                    event: "Change Camera Target",
                    arguments: [intendedTarget],
                    time: time
                });
                currentTarget = intendedTarget;
            }

            var intendedBPM:Null<Float> = (section.changeBPM) ? section.bpm : null;
            if (intendedBPM != null && intendedBPM != currentBPM) {
                finalData.events.push({
                    event: "Change BPM",
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

                    needsVoices: (chart.meta.voices.length > 0),
                    validScore: true
                }
            };

            return output;
        }
    */
    
    // used for simple notes
    public static inline function generateNotes(chart:Chart, minTime:Float = 0, ?strumLines:Array<StrumLine>):Array<Note> {
        var notes:Array<Note> = [];

        for (data in chart.notes) {
            if (data.time < minTime) continue;

            var note:Note = new Note(data.time, data.direction);
            note.strumline = data.strumline;
            note.length = data.length;
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
        var finalChart:Chart = null;

        #if sys var overwrite:Bool = false; #end

        if (data.song != null) {
            data = convertChart(data.song); // convert charts that uses fnf legacy format
            #if sys overwrite = Options.chartOverwrite; #end
        }
        
        finalChart = Chart.resolve(data);
        finalChart.meta = loadMeta(song);
        finalChart.gameplayInfo = resolveGameplayInfo(finalChart);

        if (finalChart.gameplayInfo.stage == null)
            finalChart.gameplayInfo.stage = "";

        // check for events
        if (finalChart.events == null) {
            var eventsPath:String = Assets.json('songs/${song}/events');
            if (FileTools.exists(eventsPath))
                finalChart.events = Json.parse(FileTools.getContent(eventsPath));
            else
                finalChart.events = [];
        }

        #if sys
        if (overwrite)
            sys.io.File.saveContent(path, Json.stringify(finalChart.toStruct())); // overwrite the chart json
        #end

        return finalChart;
    }
}
