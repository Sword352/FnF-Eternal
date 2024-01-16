package eternal;

import funkin.objects.notes.Note;
import eternal.ChartFormat.Chart;
import eternal.ChartFormat.ChartNote;
import eternal.ChartFormat.SongMetadata;

import tjson.TJSON as Json;

class ChartLoader {
    public static function getDefaultMeta():SongMetadata
        return {
            name: null,
            rawName: null,

            player: null,
            opponent: null,
            spectator: null,
            stage: null,

            instFile: "Inst",
            voiceFiles: ["Voices"]
        };
    
    public static function getDummyChart():Chart
        return {
            meta: getDefaultMeta(),

            notes: [],
            events: [],

            speed: 1,
            bpm: 100
        };

    public static function loadMetaData(song:String):SongMetadata {
        var path:String = Assets.json('songs/${Tools.formatSong(song)}/meta');
        if (!FileTools.exists(path)) {
            trace('Path to ${song} has not been found, returning default metadata');
            return getDefaultMeta();
        }

        var data:SongMetadata = Json.parse(FileTools.getContent(path));

        if (data.rawName == null)
            data.rawName = song;

        if (data.name == null)
            data.name = data.rawName;

        return data;
    }

    public static function convertChart(data:Dynamic):Chart {
        var finalData:Chart = getDummyChart();

        finalData.speed = data.speed;
        finalData.bpm = data.bpm;

        finalData.meta = {
            name: data.song,
            rawName: Tools.formatSong(data.song),

            player: data.player1,
            opponent: data.player2,
            spectator: data.gfVersion ?? data.player3,
            stage: data.stage ?? "",

            instFile: "Inst",
            voiceFiles: (data.needsVoices) ? ["Voices"] : []
        };

        // Used to replace some section specific stuff with events
        var currentBPM:Float = data.bpm;
        var currentTarget:Int = -1;
        var time:Float = 0;

        for (section in cast(data.notes, Array<Dynamic>)) {
            for (noteData in cast(section.sectionNotes, Array<Dynamic>)) {
                var direction:Int = noteData[1];
                if (direction < 0) // ignore psych events (TODO: perhaps convert those into actual events?)
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
                    time: time,
                    arguments: [intendedTarget]
                });
                currentTarget = intendedTarget;
            }

            var intendedBPM:Null<Float> = (section.changeBPM) ? section.bpm : null;
            if (intendedBPM != null && intendedBPM != currentBPM) {
                finalData.events.push({
                    event: "change bpm",
                    time: time,
                    arguments: [intendedBPM]
                });
                currentBPM = intendedBPM;
            }

            time += (((60 / currentBPM) * 1000) / 4) * 16;
        }

        return finalData;
    }

    public static function convertToLegacy(chart:Chart):Dynamic {
        var output:Dynamic = {
            song: {
                song: chart.meta.rawName,
                speed: chart.speed,
                bpm: chart.bpm,
                notes: [],

                player1: chart.meta.player,
                player2: chart.meta.opponent,

                needsVoices: (chart.meta.voiceFiles.length > 0),
                validScore: true
            }
        };

        return output;
    }

    public static function generateNotes(chart:Chart, minTime:Float = 0, playerSkin:String = "default", oppSkin:String = "default"):Array<Note> {
        var notes:Array<Note> = [];
        var i:Int = 0;

        for (noteData in chart.notes) {
            if (noteData.time < minTime)
                continue;
            
            var note:Note = new Note(noteData.time, noteData.direction, (noteData.strumline == 1) ? playerSkin : oppSkin);
            note.length = note.initialLength = noteData.length;
            note.strumline = noteData.strumline;
            note.type = noteData.type;
            note.ID = i++;
            notes.push(note);
        }

        notes.sort((n1, n2) -> FlxSort.byValues(FlxSort.ASCENDING, n1.time, n2.time));
        return notes;
    }

    public static function loadChart(song:String, ?difficulty:String):Chart {
        if (difficulty == null)
            difficulty = "normal";

        var path:String = Assets.json('songs/${song}/charts/${difficulty}');
        var data:Dynamic = Json.parse(FileTools.getContent(path));
        #if sys var overwrite:Bool = false; #end

        if (data.song != null) { // chart is from an engine using base game chart format
            data = convertChart(data.song);
            #if sys overwrite = Settings.get("overwrite chart files"); #end
        }
        else if (data.meta == null)
            data.meta = loadMetaData(song);

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

        #if sys
        if (overwrite)
            sys.io.File.saveContent(path, Json.encode(data, null, false)); // overwrite the chart json
        #end

        return Chart.resolve(data);
    }
}
