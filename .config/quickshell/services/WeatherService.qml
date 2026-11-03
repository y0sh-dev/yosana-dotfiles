pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: weatherService

    property string scriptPath: "/home/yukkkk1/.config/quickshell/scripts/weather.py"
    property string cacheFile: "/home/yukkkk1/.config/quickshell/weather_cache.json"
    property string locationsFile: "/home/yukkkk1/.config/quickshell/weather_locations.json"

    // Active City Information
    property string currentCityName: "東京 (23区)"
    property string currentRomaji: "Tokyo"
    property string currentPref: "東京都"

    // Current Weather State
    property string temp: "--"
    property string desc: "Loading..."
    property string icon: "󰖐"
    property string maxTemp: "--"
    property string minTemp: "--"
    property string wind: "-- km/h"
    property string windDir: ""
    property string humidity: "--%"
    property string rainChance: "--%"
    property bool isLoading: false

    // 2-day forecast: [ { day: "TUE", icon: "󰖕", max: "19°", min: "11°", rainChance: "2%", windDir: "北", windSpeed: "4 km/h" }, ... ]
    property var forecast: []

    // 47 Prefectures Master Tree loaded from weather_locations.json
    property var locations: []

    // 30-minute Periodic Refresh Timer
    property var refreshTimer: Timer {
        interval: 1800000 // 30 minutes
        running: true
        repeat: true
        onTriggered: weatherService.refresh()
    }

    // Process to run python backend fetch
    property var fetchProc: Process {
        command: ["python3", weatherService.scriptPath, "--fetch"]
        onExited: function(exitCode, exitStatus) {
            weatherService.isLoading = false;
            weatherService.loadCache();
        }
    }

    // Process to execute --set-city and reliably react upon exit
    property var setCityProc: Process {
        id: setCityProcess
        onExited: function(exitCode, exitStatus) {
            weatherService.isLoading = false;
            // The python backend has finished writing fresh cache: reload instantly!
            weatherService.loadCache();
        }
    }

    // Process to read cache JSON into QML
    property var cacheProc: Process {
        id: cacheProcess
        command: ["cat", weatherService.cacheFile]
        stdout: StdioCollector {
            id: cacheCollector
            onDataChanged: {
                weatherService.applyWeatherData(data);
            }
        }
        onExited: function(exitCode, exitStatus) {
            weatherService.applyWeatherData(cacheCollector.data);
        }
    }

    // Process to read locations JSON into QML
    property var locationsProc: Process {
        command: ["cat", weatherService.locationsFile]
        stdout: StdioCollector {
            onDataChanged: {
                var raw = (data || "").toString().trim();
                if (raw.length > 0) {
                    try {
                        var locs = JSON.parse(raw);
                        weatherService.locations = locs;
                    } catch(e) {
                        console.log("WeatherService Locations parse error:", e);
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        loadLocations();
        loadCache();
        // Trigger background fresh fetch if needed
        refresh();
    }

    function applyWeatherData(raw) {
        var text = (raw || "").toString().trim();
        if (text.length === 0) return;
        try {
            var parsed = JSON.parse(text);
            if (parsed.city) {
                weatherService.currentCityName = parsed.city.name || weatherService.currentCityName;
                weatherService.currentRomaji = parsed.city.romaji || parsed.city.name || "Tokyo";
                weatherService.currentPref = parsed.city.pref || "";
            }
            if (parsed.current) {
                weatherService.temp = parsed.current.temp || "--";
                weatherService.desc = parsed.current.desc || "";
                weatherService.icon = parsed.current.icon || "󰖐";
                weatherService.maxTemp = parsed.current.maxTemp || "--";
                weatherService.minTemp = parsed.current.minTemp || "--";
                weatherService.rainChance = parsed.current.rainChance || "0%";
                weatherService.wind = parsed.current.wind || "-- km/h";
                weatherService.windDir = parsed.current.windDir || "";
                weatherService.humidity = parsed.current.humidity || "--%";
            }
            if (parsed.forecast) {
                weatherService.forecast = parsed.forecast;
            }
        } catch(e) {
            console.log("WeatherService JSON parse error:", e);
        }
    }

    function loadLocations() {
        if (!locationsProc.running) {
            locationsProc.running = true;
        }
    }

    function loadCache() {
        if (!cacheProcess.running) {
            cacheProcess.running = true;
        }
    }

    function refresh() {
        if (!fetchProc.running) {
            weatherService.isLoading = true;
            fetchProc.running = true;
        }
    }

    function setCity(cityObj, prefName) {
        var payload = {
            "name": cityObj.name,
            "romaji": cityObj.romaji || cityObj.name,
            "pref": prefName || "",
            "lat": cityObj.lat,
            "lon": cityObj.lon
        };
        weatherService.currentCityName = payload.name;
        weatherService.currentRomaji = payload.romaji;
        weatherService.currentPref = payload.pref;
        weatherService.isLoading = true;

        // Reliable synchronous trigger: python exits -> onExited fires -> loadCache executes
        setCityProcess.command = [
            "python3",
            weatherService.scriptPath,
            "--set-city",
            JSON.stringify(payload)
        ];
        setCityProcess.running = true;
    }
}
