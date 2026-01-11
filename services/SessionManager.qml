pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Session service - Direct systemctl wrapper using Config.session.commands
// All power actions read from user config, no x-session daemon dependency
Singleton {
    id: root

    // =====================================================
    // PROPERTIES
    // =====================================================
    
    property bool available: true  // Always available, uses systemctl directly
    property bool shutdownPending: false
    
    // =====================================================
    // SIGNALS (kept for compatibility)
    // =====================================================
    
    signal hookStarted(string name)
    signal hookCompleted(string name)
    signal shutdownProceed()

    // =====================================================
    // METHODS - All read from Config.session.commands
    // =====================================================
    
    function shutdown(force: bool): void {
        root.shutdownPending = true;
        root.shutdownProceed();
        Quickshell.execDetached(Config.session.commands.shutdown);
    }
    
    function reboot(force: bool): void {
        root.shutdownPending = true;
        root.shutdownProceed();
        Quickshell.execDetached(Config.session.commands.reboot);
    }
    
    function suspend(): void {
        // Uses Config.session.commands.sleep
        Quickshell.execDetached(Config.session.commands.sleep);
    }
    
    function hibernate(): void {
        Quickshell.execDetached(Config.session.commands.hibernate);
    }
    
    function logout(): void {
        Quickshell.execDetached(Config.session.commands.logout);
    }
    
    function cancel(): void {
        root.shutdownPending = false;
    }
}
