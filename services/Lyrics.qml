pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * LyricsService - Fetch synced lyrics from LRCLIB API
 * 
 * Usage:
 *   Lyrics.fetch(artist, title)
 *   Lyrics.currentLine  // Current lyric line based on position
 *   Lyrics.lines        // All parsed lyric lines [{time, text}]
 */
Singleton {
    id: root

    // Current track info (set by Media.qml when track changes)
    property string currentArtist: ""
    property string currentTitle: ""
    property real currentPosition: 0  // in seconds
    
    // Lyrics data
    property var lines: []  // [{time: seconds, text: "lyric line"}]
    property bool loading: false
    property bool available: lines.length > 0
    property string error: ""
    
    // Current line based on position
    readonly property int currentLineIndex: {
        if (!available || currentPosition < 0) return -1;
        
        let idx = -1;
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].time <= currentPosition) {
                idx = i;
            } else {
                break;
            }
        }
        return idx;
    }
    
    readonly property string currentLine: currentLineIndex >= 0 ? lines[currentLineIndex]?.text ?? "" : ""
    
    // Fetch lyrics when artist/title changes
    onCurrentArtistChanged: fetchLyrics()
    onCurrentTitleChanged: fetchLyrics()
    
    function fetchLyrics(): void {
        if (!currentArtist || !currentTitle) {
            clear();
            return;
        }
        
        // Debounce
        fetchTimer.restart();
    }
    
    function retry(): void {
        // Force re-fetch without debounce
        if (!currentArtist || !currentTitle) return;
        
        loading = true;
        error = "";
        
        const artist = encodeURIComponent(currentArtist);
        const title = encodeURIComponent(currentTitle);
        const url = `https://lrclib.net/api/get?artist_name=${artist}&track_name=${title}`;
        lyricsRequest.lyricsCommand = ["curl", "-s", "-H", "User-Agent: X-Shell/1.0", url];
        lyricsRequest.running = true;
    }
    
    function clear(): void {
        lines = [];
        error = "";
        loading = false;
    }
    
    // Parse LRC format: [mm:ss.xx] text
    function parseLrc(lrcText: string): var {
        const result = [];
        const lineRegex = /\[(\d{2}):(\d{2})\.(\d{2,3})\]\s*(.*)/;
        
        const lrcLines = lrcText.split("\n");
        for (const line of lrcLines) {
            const match = line.match(lineRegex);
            if (match) {
                const minutes = parseInt(match[1]);
                const seconds = parseInt(match[2]);
                const millis = parseInt(match[3].padEnd(3, '0'));
                const time = minutes * 60 + seconds + millis / 1000;
                const text = match[4].trim();
                
                if (text) {  // Skip empty lines
                    result.push({ time: time, text: text });
                }
            }
        }
        
        return result;
    }
    
    Timer {
        id: fetchTimer
        interval: 100  // Debounce 100ms
        onTriggered: {
            if (!root.currentArtist || !root.currentTitle) return;
            
            root.loading = true;
            root.error = "";
            
            // Build URL and set command
            const artist = encodeURIComponent(root.currentArtist);
            const title = encodeURIComponent(root.currentTitle);
            const url = `https://lrclib.net/api/get?artist_name=${artist}&track_name=${title}`;
            lyricsRequest.lyricsCommand = ["curl", "-s", "-H", "User-Agent: X-Shell/1.0", url];
            lyricsRequest.running = true;
        }
    }
    
    Process {
        id: lyricsRequest
        
        property var lyricsCommand: []
        
        command: lyricsCommand
        
        onRunningChanged: {
            console.log("[Lyrics] Process running:", running, "command:", lyricsCommand.join(" "));
        }
        
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("[Lyrics] Stream finished, text length:", text.length);
                root.loading = false;
                
                try {
                    const response = JSON.parse(text);
                    console.log("[Lyrics] Parsed response, has syncedLyrics:", !!response.syncedLyrics);
                    
                    if (response.syncedLyrics) {
                        root.lines = root.parseLrc(response.syncedLyrics);
                        root.error = "";
                        console.log("[Lyrics] Loaded", root.lines.length, "lines");
                    } else {
                        root.clear();
                        root.error = "No synced lyrics found";
                    }
                } catch (e) {
                    console.log("[Lyrics] Parse error:", e);
                    root.clear();
                    root.error = "Failed to parse lyrics";
                }
            }
        }
        
        onExited: (code, status) => {
            console.log("[Lyrics] Process exited, code:", code);
            if (code !== 0) {
                root.loading = false;
                root.error = "Network error";
            }
        }
    }
}
