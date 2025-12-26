pragma Singleton

import qs.config
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real cpuPerc
    property real cpuTemp
    
    // Dual GPU support: iGPU (integrated) and dGPU (discrete)
    property bool hasIGpu: false
    property bool hasDGpu: false
    property real iGpuPerc: 0
    property real iGpuTemp: 0
    property real dGpuPerc: 0
    property real dGpuTemp: 0
    
    // Legacy compatibility (uses primary GPU - prefers dGPU if available)
    readonly property real gpuPerc: hasDGpu ? dGpuPerc : iGpuPerc
    readonly property real gpuTemp: hasDGpu ? dGpuTemp : iGpuTemp
    property real memUsed
    property real memTotal
    readonly property real memPerc: memTotal > 0 ? memUsed / memTotal : 0
    property real storageUsed
    property real storageTotal
    property real storagePerc: storageTotal > 0 ? storageUsed / storageTotal : 0

    property real lastCpuIdle
    property real lastCpuTotal

    property int refCount

    function formatKib(kib: real): var {
        const mib = 1024;
        const gib = 1024 ** 2;
        const tib = 1024 ** 3;

        if (kib >= tib)
            return {
                value: kib / tib,
                unit: "TiB"
            };
        if (kib >= gib)
            return {
                value: kib / gib,
                unit: "GiB"
            };
        if (kib >= mib)
            return {
                value: kib / mib,
                unit: "MiB"
            };
        return {
            value: kib,
            unit: "KiB"
        };
    }

    Timer {
        running: root.refCount > 0
        interval: 3000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            storage.running = true;
            if (root.hasDGpu) dGpuUsage.running = true;
            if (root.hasIGpu) iGpuUsage.running = true;
            sensors.running = true;
        }
    }

    FileView {
        id: stat

        path: "/proc/stat"
        onLoaded: {
            const data = text().match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
            if (data) {
                const stats = data.slice(1).map(n => parseInt(n, 10));
                const total = stats.reduce((a, b) => a + b, 0);
                const idle = stats[3] + (stats[4] ?? 0);

                const totalDiff = total - root.lastCpuTotal;
                const idleDiff = idle - root.lastCpuIdle;
                root.cpuPerc = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0;

                root.lastCpuTotal = total;
                root.lastCpuIdle = idle;
            }
        }
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        onLoaded: {
            const data = text();
            root.memTotal = parseInt(data.match(/MemTotal: *(\d+)/)[1], 10) || 1;
            root.memUsed = (root.memTotal - parseInt(data.match(/MemAvailable: *(\d+)/)[1], 10)) || 0;
        }
    }

    Process {
        id: storage

        command: ["sh", "-c", "df | grep '^/dev/' | awk '{print $1, $3, $4}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const deviceMap = new Map();

                for (const line of text.trim().split("\n")) {
                    if (line.trim() === "")
                        continue;

                    const parts = line.trim().split(/\s+/);
                    if (parts.length >= 3) {
                        const device = parts[0];
                        const used = parseInt(parts[1], 10) || 0;
                        const avail = parseInt(parts[2], 10) || 0;

                        // Only keep the entry with the largest total space for each device
                        if (!deviceMap.has(device) || (used + avail) > (deviceMap.get(device).used + deviceMap.get(device).avail)) {
                            deviceMap.set(device, {
                                used: used,
                                avail: avail
                            });
                        }
                    }
                }

                let totalUsed = 0;
                let totalAvail = 0;

                for (const [device, stats] of deviceMap) {
                    totalUsed += stats.used;
                    totalAvail += stats.avail;
                }

                root.storageUsed = totalUsed;
                root.storageTotal = totalUsed + totalAvail;
            }
        }
    }

    // Detect available GPUs on startup
    Process {
        id: gpuDetect
        running: true
        command: ["sh", "-c", "echo \"NVIDIA:$(command -v nvidia-smi &>/dev/null && nvidia-smi -L &>/dev/null && echo 1 || echo 0)\"; echo \"AMD:$(ls /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1 | grep -q . && echo 1 || echo 0)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                for (const line of lines) {
                    if (line.startsWith("NVIDIA:")) root.hasDGpu = line.endsWith("1");
                    if (line.startsWith("AMD:")) root.hasIGpu = line.endsWith("1");
                }
            }
        }
    }

    // dGPU (NVIDIA discrete) polling
    Process {
        id: dGpuUsage
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",");
                if (parts.length >= 2) {
                    root.dGpuPerc = parseInt(parts[0], 10) / 100;
                    root.dGpuTemp = parseInt(parts[1], 10);
                }
            }
        }
    }

    // iGPU (AMD integrated) polling
    Process {
        id: iGpuUsage
        command: ["sh", "-c", "cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const perc = parseInt(text.trim(), 10);
                if (!isNaN(perc)) root.iGpuPerc = perc / 100;
            }
        }
    }

    Process {
        id: sensors

        command: ["sensors"]
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                let cpuTemp = text.match(/(?:Package id [0-9]+|Tdie):\s+((\+|-)[0-9.]+)(°| )C/);
                if (!cpuTemp)
                    // If AMD Tdie pattern failed, try fallback on Tctl
                    cpuTemp = text.match(/Tctl:\s+((\+|-)[0-9.]+)(°| )C/);

                if (cpuTemp)
                    root.cpuTemp = parseFloat(cpuTemp[1]);

                // Get iGPU temp from sensors (AMD)
                if (root.hasIGpu) {
                    let eligible = false;
                    let sum = 0;
                    let count = 0;

                    for (const line of text.trim().split("\n")) {
                        if (line === "Adapter: PCI adapter")
                            eligible = true;
                        else if (line === "")
                            eligible = false;
                        else if (eligible) {
                            let match = line.match(/^(temp[0-9]+|GPU core|edge)+:\s+\+([0-9]+\.[0-9]+)(°| )C/);
                            if (!match)
                                match = line.match(/^(junction|mem)+:\s+\+([0-9]+\.[0-9]+)(°| )C/);

                            if (match) {
                                sum += parseFloat(match[2]);
                                count++;
                            }
                        }
                    }

                    root.iGpuTemp = count > 0 ? sum / count : 0;
                }
            }
        }
    }
}
