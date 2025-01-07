package funkin.data;

import funkin.data.ChartFormat;

class ChartLoader {
    public static function getEmptyGameplay():GameplayInfo
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

    public static function getEmptyMeta():SongMeta
        return {
            name: null,
            folder: null,
            difficulties: ["normal"],
            gameplayInfo: getEmptyGameplay(),
            freeplayInfo: null
        }

    public static function getEmptyChart():Chart
        return {
            gameplayInfo: getEmptyGameplay(),
            meta: getEmptyMeta(),
            events: [],
            notes: []
        };

    public static function loadMeta(song:String):SongMeta {
        var data:SongMeta = Paths.json('songs/${song}/meta');
        if (data == null) {
            Logging.warning('Could not find meta file for song "${song}"!');
            return getEmptyMeta();
        }

        data.folder = song;
        return data;
    }

    public static function resolveGameplayInfo(chart:Chart):GameplayInfo {
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

    public static function exportMeta(meta:SongMeta):SongMeta {
        var output:SongMeta = Reflect.copy(meta);
        Reflect.deleteField(output, "folder");
        return output;
    }

    public static function convertChart(data:BaseGameChart):Chart {
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
                difficulties: ["Easy", "Normal", "Hard"],
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
                    length: 0,
                    type: type
                };

                if (noteData[2] != null && noteData[2] is Float) {
                    var startLength:Float = cast noteData[2];

                    if (startLength > 0) {
                        // since hold notes starts a step later in legacy fnf, we have to compensate by adding a step's duration to the length
                        data.length = startLength + ((60 / currentBPM) * 1000 / 4);
                    }
                }

                finalData.notes.push(data);
            }

            var intendedTarget:Int = (section.mustHitSection) ? 2 : 0;
            if (intendedTarget != currentTarget) {
                finalData.events.push({
                    type: "change camera target",
                    arguments: [intendedTarget, time <= 0],
                    time: time
                });
                currentTarget = intendedTarget;
            }

            var intendedBPM:Null<Float> = (section.changeBPM) ? section.bpm : null;
            if (intendedBPM != null && intendedBPM != currentBPM) {
                finalData.events.push({
                    type: "change bpm",
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

    public static function loadChart(song:String, ?difficulty:String):Chart {
        if (difficulty == null)
            difficulty = "normal";

        var data:Dynamic = Paths.json('songs/${song}/charts/${difficulty}');
        var finalChart:Chart = null;

        if (data.song != null)
            data = convertChart(data.song); // convert charts that uses fnf legacy format
        
        finalChart = Chart.resolve(data);
        finalChart.meta = loadMeta(song);
        finalChart.gameplayInfo = resolveGameplayInfo(finalChart);

        // check for events
        if (finalChart.events == null) {
            var events:Dynamic = Paths.json('songs/${song}/events');

            if (events != null)
                finalChart.events = cast events;
            else
                finalChart.events = [];
        }

        return finalChart;
    }
}
