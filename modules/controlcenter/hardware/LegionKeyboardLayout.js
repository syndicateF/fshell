// Legion keyboard layout data for 4-zone RGB
// Zone 0 = Left, Zone 1 = Center-Left, Zone 2 = Center-Right, Zone 3 = Right/Numpad

const layout = {
    name: "Legion 5 Pro",
    // Key shapes: normal, fn, tick, tab, caps, shift, control, space, expand, numpad, numwide, numtall
    mainBlock: [
        // F-row
        [
            { label: "Esc", shape: "deletes", zone: 0 },
            { label: "F1", shape: "fn", zone: 0 },
            { label: "F2", shape: "fn", zone: 0 },
            { label: "F3", shape: "fn", zone: 0 },
            { label: "F4", shape: "fn", zone: 0 },
            { label: "F5", shape: "fn", zone: 1 },
            { label: "F6", shape: "fn", zone: 1 },
            { label: "F7", shape: "fn", zone: 1 },
            { label: "F8", shape: "fn", zone: 1 },
            { label: "F9", shape: "fn", zone: 2 },
            { label: "F10", shape: "fn", zone: 2 },
            { label: "F11", shape: "fn", zone: 2 },
            { label: "F12", shape: "fn", zone: 2 },
            { label: "Ins", shape: "fn", zone: 2 },
            { label: "Prt", shape: "fn", zone: 2 },
            { label: "Del", shape: "deletes", zone: 2 }
        ],
        // Number row
        [
            { label: "`", shape: "tick", zone: 0 },
            { label: "1", shape: "normal", zone: 0 },
            { label: "2", shape: "normal", zone: 0 },
            { label: "3", shape: "normal", zone: 0 },
            { label: "4", shape: "normal", zone: 0 },
            { label: "5", shape: "normal", zone: 1 },
            { label: "6", shape: "normal", zone: 1 },
            { label: "7", shape: "normal", zone: 1 },
            { label: "8", shape: "normal", zone: 1 },
            { label: "9", shape: "normal", zone: 1 },
            { label: "0", shape: "normal", zone: 2 },
            { label: "-", shape: "normal", zone: 2 },
            { label: "=", shape: "normal", zone: 2 },
            { label: "⌫", shape: "backspace", zone: 2 }
        ],
        // QWERTY row
        [
            { label: "Tab", shape: "tab", zone: 0 },
            { label: "Q", shape: "normal", zone: 0 },
            { label: "W", shape: "normal", zone: 0 },
            { label: "E", shape: "normal", zone: 0 },
            { label: "R", shape: "normal", zone: 0 },
            { label: "T", shape: "normal", zone: 1 },
            { label: "Y", shape: "normal", zone: 1 },
            { label: "U", shape: "normal", zone: 1 },
            { label: "I", shape: "normal", zone: 1 },
            { label: "O", shape: "normal", zone: 2 },
            { label: "P", shape: "normal", zone: 2 },
            { label: "[", shape: "normal", zone: 2 },
            { label: "]", shape: "normal", zone: 2 },
            { label: "\\", shape: "slash", zone: 2 }
        ],
        // ASDF row
        [
            { label: "Caps", shape: "caps", zone: 0 },
            { label: "A", shape: "normal", zone: 0 },
            { label: "S", shape: "normal", zone: 0 },
            { label: "D", shape: "normal", zone: 0 },
            { label: "F", shape: "normal", zone: 0 },
            { label: "G", shape: "normal", zone: 1 },
            { label: "H", shape: "normal", zone: 1 },
            { label: "J", shape: "normal", zone: 1 },
            { label: "K", shape: "normal", zone: 1 },
            { label: "L", shape: "normal", zone: 2 },
            { label: ";", shape: "normal", zone: 2 },
            { label: "'", shape: "normal", zone: 2 },
            { label: "Enter", shape: "enter", zone: 2 }
        ],
        // Shift row
        [
            { label: "Shift", shape: "shifts", zone: 0 },
            { label: "Z", shape: "normal", zone: 0 },
            { label: "X", shape: "normal", zone: 0 },
            { label: "C", shape: "normal", zone: 0 },
            { label: "V", shape: "normal", zone: 1 },
            { label: "B", shape: "normal", zone: 1 },
            { label: "N", shape: "normal", zone: 1 },
            { label: "M", shape: "normal", zone: 1 },
            { label: ",", shape: "normal", zone: 2 },
            { label: ".", shape: "normal", zone: 2 },
            { label: "/", shape: "normal", zone: 2 },
            { label: "Shift", shape: "shifts", zone: 2 }
        ],
        // Space row - ends with invisible spacer then ↑ then invisible spacer (for arrow alignment)
        [
            { label: "Ctrl", shape: "control", zone: 0 },
            { label: "Fn", shape: "normal", zone: 0 },
            { label: "⊞", shape: "normal", zone: 0 },
            { label: "Alt", shape: "normal", zone: 0 },
            { label: "", shape: "spaces", zone: 1 },
            { label: "Alt", shape: "normal", zone: 2 },
            { label: "Ctrl", shape: "normal", zone: 2 },
            { label: "", shape: "arrowaligns", zone: -1 },
            { label: "↑", shape: "normal", zone: 3 },
            { label: "", shape: "arrowaligns", zone: -1 }
        ],
        // Arrow row - spacer fills, then ← ↓ → (↓ aligned under ↑)
        [
            { label: "", shape: "arrowspacers", zone: -1 },
            { label: "←", shape: "normal", zone: 3 },
            { label: "↓", shape: "normal", zone: 3 },
            { label: "→", shape: "normal", zone: 3 }
        ]
    ],
    numpad: [
        // F-row
        [
            { label: "Hm", shape: "nf", zone: 3 },
            { label: "End", shape: "nf", zone: 3 },
            { label: "PU", shape: "nf", zone: 3 },
            { label: "PD", shape: "nf", zone: 3 }
        ],
        // Numlock row
        [
            { label: "Num", shape: "numpad", zone: 3 },
            { label: "/", shape: "numpad", zone: 3 },
            { label: "*", shape: "numpad", zone: 3 },
            { label: "-", shape: "numpad", zone: 3 }
        ],
        // 789 row
        [
            { label: "7", shape: "numpad", zone: 3 },
            { label: "8", shape: "numpad", zone: 3 },
            { label: "9", shape: "numpad", zone: 3 },
            { label: "+", shape: "numtall", zone: 3 }
        ],
        // 456 row
        [
            { label: "4", shape: "numpad", zone: 3 },
            { label: "5", shape: "numpad", zone: 3 },
            { label: "6", shape: "numpad", zone: 3 }
        ],
        // 123 row
        [
            { label: "1", shape: "numpad", zone: 3 },
            { label: "2", shape: "numpad", zone: 3 },
            { label: "3", shape: "numpad", zone: 3 },
            { label: "↵", shape: "numtall", zone: 3 }
        ],
        // 0. row
        [
            { label: "0", shape: "numwide", zone: 3 },
            { label: ".", shape: "numpad", zone: 3 }
        ]
    ]
};
