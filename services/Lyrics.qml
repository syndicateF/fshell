pragma Singleton

import qs.services
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * LyricsService - Fetch synced lyrics from LRCLIB API
 * 
 * Auto-syncs with Players.active - no manual binding needed.
 * Includes auto-retry, cancel, and proper status management.
 */
Singleton {
    id: root

    // ========== Status Enum ==========
    enum Status {
        Idle,       // No fetch in progress, no data
        Loading,    // Fetch in progress
        Success,    // Lyrics available
        Error,      // Network or parse error
        NoLyrics    // API returned no synced lyrics
    }
    
    // ========== Auto-sync with Players.active ==========
    readonly property string currentArtist: Players.active?.trackArtist ?? ""
    readonly property string currentTitle: Players.active?.trackTitle ?? ""
    readonly property real currentPosition: Players.active?.position ?? 0
    
    // ========== State ==========
    property int status: Lyrics.Status.Idle
    property var lines: []  // [{time: seconds, text: "lyric line"}]
    property string errorMessage: ""
    
    // Computed helpers for UI
    readonly property bool loading: status === Lyrics.Status.Loading
    readonly property bool available: status === Lyrics.Status.Success && lines.length > 0
    readonly property string error: status === Lyrics.Status.Error ? errorMessage : ""
    
    // Retry state
    property int retryCount: 0
    readonly property int maxRetries: 3
    readonly property int retryDelay: 2000  // 2 seconds
    
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
    
    // ========== Auto-fetch on track change ==========
    Connections {
        target: Players.active
        
        function onTrackTitleChanged() {
            root.fetchLyrics();
        }
        
        function onTrackArtistChanged() {
            root.fetchLyrics();
        }
    }
    
    Connections {
        target: Players
        
        function onActiveChanged() {
            root.fetchLyrics();
        }
    }
    
    // ========== Public API ==========
    function fetchLyrics(): void {
        if (!currentArtist || !currentTitle) {
            clear();
            return;
        }
        
        retryCount = 0;
        fetchTimer.restart();
    }
    
    function retry(): void {
        if (!currentArtist || !currentTitle) return;
        
        retryCount = 0;
        doFetch();
    }
    
    function cancel(): void {
        fetchTimer.stop();
        retryTimer.stop();
        lyricsRequest.running = false;
        
        if (status === Lyrics.Status.Loading) {
            status = Lyrics.Status.Idle;
        }
    }
    
    function clear(): void {
        cancel();
        lines = [];
        errorMessage = "";
        status = Lyrics.Status.Idle;
        retryCount = 0;
    }
    
    // ========== Internal ==========
    function doFetch(): void {
        status = Lyrics.Status.Loading;
        errorMessage = "";
        
        const artist = encodeURIComponent(currentArtist);
        const title = encodeURIComponent(currentTitle);
        const url = `https://lrclib.net/api/get?artist_name=${artist}&track_name=${title}`;
        lyricsRequest.lyricsCommand = ["curl", "-s", "-m", "10", "-H", "User-Agent: X-Shell/1.0", url];
        lyricsRequest.running = true;
    }
    
    function handleError(message: string): void {
        if (retryCount < maxRetries) {
            retryCount++;
            retryTimer.start();
        } else {
            status = Lyrics.Status.Error;
            errorMessage = message;
        }
    }
    
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
                
                if (text) {
                    result.push({ time: time, text: text });
                }
            }
        }
        
        return result;
    }
    
    // ========== Timers ==========
    Timer {
        id: fetchTimer
        interval: 100  // Debounce
        onTriggered: root.doFetch()
    }
    
    Timer {
        id: retryTimer
        interval: root.retryDelay
        onTriggered: root.doFetch()
    }
    
    // ========== Process ==========
    Process {
        id: lyricsRequest
        
        property var lyricsCommand: []
        command: lyricsCommand
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const response = JSON.parse(text);
                    
                    if (response.syncedLyrics) {
                        root.lines = root.parseLrc(response.syncedLyrics);
                        root.status = Lyrics.Status.Success;
                        root.errorMessage = "";
                        root.retryCount = 0;
                    } else {
                        root.lines = [];
                        root.status = Lyrics.Status.NoLyrics;
                        root.errorMessage = "";
                    }
                } catch (e) {
                    root.handleError("Failed to parse lyrics");
                }
            }
        }
        
        onExited: (code, status) => {
            if (code !== 0 && root.status === Lyrics.Status.Loading) {
                root.handleError("Network error");
            }
        }
    }
}
