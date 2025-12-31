pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Session service - thin D-Bus wrapper for x-session daemon
// QuickShell handles UI only, all logic is in the daemon
Singleton {
    id: root

    // =====================================================
    // PROPERTIES (read from daemon)
    // =====================================================
    
    property bool available: false
    property bool shutdownPending: false
    
    // =====================================================
    // SIGNALS
    // =====================================================
    
    signal hookStarted(string name)
    signal hookCompleted(string name)
    signal shutdownProceed()

    // =====================================================
    // METHODS
    // =====================================================
    
    function shutdown(force: bool): void {
        // For confirmed user actions (from countdown), use force=true to proceed
        // This runs hooks but doesn't wait for blocker confirmation
        // Blockers should be checked BEFORE user confirms, not after
        
        // Check daemon availability synchronously via simple test
        shutdownProc.command = ["busctl", "--user", "call", 
            "org.xshell.Session", "/org/xshell/Session", "org.xshell.Session",
            "RequestShutdown", "b", force ? "true" : "false"];
        shutdownProc.running = true;
    }
    
    function reboot(force: bool): void {
        rebootProc.command = ["busctl", "--user", "call",
            "org.xshell.Session", "/org/xshell/Session", "org.xshell.Session",
            "RequestReboot", "b", force ? "true" : "false"];
        rebootProc.running = true;
    }
    
    function suspend(): void {
        suspendProc.running = true;
    }
    
    function hibernate(): void {
        hibernateProc.running = true;
    }
    
    function cancel(): void {
        cancelProc.running = true;
    }

    // =====================================================
    // INTERNAL PROCESSES
    // =====================================================
    
    // Check if daemon is available on startup
    Process {
        id: checkProc
        command: ["busctl", "--user", "status", "org.xshell.Session"]
        onExited: (exitCode, _) => {
            root.available = (exitCode === 0);
            if (root.available) {
                console.log("SessionManager: daemon connected");
            } else {
                console.warn("SessionManager: daemon not available");
            }
        }
        Component.onCompleted: running = true
    }
    
    Process {
        id: shutdownProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.includes("true")) {
                    root.shutdownPending = true;
                    console.log("SessionManager: shutdown accepted by daemon");
                } else {
                    // Daemon call failed, fallback to direct systemctl
                    console.warn("SessionManager: daemon rejected shutdown, falling back to systemctl");
                    Quickshell.execDetached(["systemctl", "poweroff"]);
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    // D-Bus error (daemon not running), fallback
                    console.warn("SessionManager: D-Bus error, falling back to systemctl");
                    Quickshell.execDetached(["systemctl", "poweroff"]);
                }
            }
        }
    }
    
    Process {
        id: rebootProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.includes("true")) {
                    root.shutdownPending = true;
                    console.log("SessionManager: reboot accepted by daemon");
                } else {
                    console.warn("SessionManager: daemon rejected reboot, falling back to systemctl");
                    Quickshell.execDetached(["systemctl", "reboot"]);
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.warn("SessionManager: D-Bus error, falling back to systemctl");
                    Quickshell.execDetached(["systemctl", "reboot"]);
                }
            }
        }
    }
    
    Process {
        id: suspendProc
        command: ["busctl", "--user", "call",
            "org.xshell.Session", "/org/xshell/Session", "org.xshell.Session",
            "RequestSuspend"]
    }
    
    Process {
        id: hibernateProc
        command: ["busctl", "--user", "call",
            "org.xshell.Session", "/org/xshell/Session", "org.xshell.Session",
            "RequestHibernate"]
    }
    
    Process {
        id: cancelProc
        command: ["busctl", "--user", "call",
            "org.xshell.Session", "/org/xshell/Session", "org.xshell.Session",
            "CancelPending"]
        onExited: {
            root.shutdownPending = false;
        }
    }
}
