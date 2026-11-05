import QtQuick
import QtQuick.Layouts
import QtQuick.Window

Item {
    id: root

    // Optional reference to the host page content Item to lift up when an input is occluded
    property Item pageContainer: null
    // Exposed lift offset (positive means lifted up by pageLiftOffset px)
    property real pageLiftOffset: 0
    // Whether the keyboard is currently popped up
    property bool keyboardVisible: false
    // Current active text input item
    property Item activeInputItem: null
    // Current panel: 0 = QWERTY, 1 = 123 & Industrial Symbols, 2 = Extended Symbols
    property int panelIndex: 0

    anchors.fill: parent
    z: 999

    readonly property bool darkTheme: InputEngine.darkTheme
    readonly property bool isZhLabel: InputEngine.globalLanguage.indexOf("zh") === 0
                                      && (InputEngine.passwordMode ? true : InputEngine.chineseMode)
    readonly property bool hasActivePinyin: InputEngine.chineseMode
                                            && !InputEngine.passwordMode
                                            && (InputEngine.pinyinDisplay.length > 0 || InputEngine.candidates.length > 0)

    // Constant key dock height (~39% of 7-inch screen) so keys never shift when candidate bar pops up
    readonly property real keyDockHeight: Math.round(Math.max(185, Math.min(220, root.height * 0.40)))
    readonly property real totalOccupiedHeight: keyDockHeight + (candidateBar.visible ? candidateBar.height : 0)

    // Apply smooth page lift directly to pageContainer if provided
    Binding {
        target: root.pageContainer
        property: "y"
        value: -root.pageLiftOffset
        when: root.pageContainer !== null
    }

    Behavior on pageLiftOffset {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    // Track Window.activeFocusItem automatically via attached property binding
    readonly property Item windowFocusItem: Window.activeFocusItem
    onWindowFocusItemChanged: {
        root.evaluateFocusItem(windowFocusItem)
    }

    Connections {
        target: InputEngine
        function onRequestShowKeyboard() {
            if (root.activeInputItem) {
                root.keyboardVisible = true
                root.updateGeometryAndLift()
            }
        }
        function onRequestHideKeyboard() {
            root.closeKeyboard()
        }
    }

    function evaluateFocusItem(item) {
        if (item && InputEngine.isTextInputItem(item) && InputEngine.isKeyboardEnabled(item)) {
            root.activeInputItem = item
            root.panelIndex = 0
            InputEngine.bindTargetItem(item)
            root.keyboardVisible = true
            liftUpdateTimer.restart()
        } else if (!item || !isDescendantOfKeyboard(item)) {
            root.activeInputItem = null
            InputEngine.bindTargetItem(null)
            root.closeKeyboard()
        }
    }

    function isDescendantOfKeyboard(item) {
        var cur = item
        while (cur) {
            if (cur === root)
                return true
            cur = cur.parent
        }
        return false
    }

    function closeKeyboard() {
        root.keyboardVisible = false
        root.pageLiftOffset = 0
        InputEngine.clearPinyinBuffer()
    }

    function langButtonRichText() {
        var dimColor = root.darkTheme ? "#64748B" : "#94A3B8"
        if (InputEngine.chineseMode && !InputEngine.passwordMode) {
            return "<b>\u4e2d</b><font color='" + dimColor + "'> / \u82f1</font>"
        } else {
            return "<font color='" + dimColor + "'>\u4e2d / </font><b>\u82f1</b>"
        }
    }

    // Calculate anti-occlusion lift offset
    function updateGeometryAndLift() {
        if (!root.keyboardVisible || !root.activeInputItem) {
            root.pageLiftOffset = 0
            return
        }

        var posInRoot = root.activeInputItem.mapToItem(root, 0, 0)
        var unliftedTopY = posInRoot.y + root.pageLiftOffset
        var unliftedBottomY = unliftedTopY + root.activeInputItem.height

        // Reserve space for potential candidate bar in Chinese mode so page doesn't bounce while typing
        var effectiveKbHeight = root.keyDockHeight + (InputEngine.chineseMode && !InputEngine.passwordMode ? 48 : 0)
        var kbTopY = root.height - effectiveKbHeight
        var safetyMargin = 12

        if (unliftedBottomY + safetyMargin > kbTopY) {
            root.pageLiftOffset = Math.min(kbTopY - 40, unliftedBottomY + safetyMargin - kbTopY)
        } else {
            root.pageLiftOffset = 0
        }
    }

    Timer {
        id: liftUpdateTimer
        interval: 16
        repeat: false
        onTriggered: root.updateGeometryAndLift()
    }

    // 1. Pinyin Candidate Bar (Docked directly above keyboardDock ONLY when active pinyin input exists)
    CandidateBar {
        id: candidateBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: keyboardDock.top
        showBar: root.keyboardVisible && root.hasActivePinyin
        darkTheme: root.darkTheme
        pinyinText: InputEngine.pinyinDisplay
        candidates: InputEngine.candidates
        hasPrevPage: InputEngine.hasPrevPage
        hasNextPage: InputEngine.hasNextPage

        onCandidateSelected: function(idx) {
            InputEngine.selectCandidate(idx)
        }
        onPrevPageClicked: InputEngine.prevCandidatePage()
        onNextPageClicked: InputEngine.nextCandidatePage()
    }

    // 2. Main Keyboard Bottom Dock
    Rectangle {
        id: keyboardDock
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.keyDockHeight
        y: root.keyboardVisible ? (root.height - height) : root.height
        visible: y < root.height
        color: root.darkTheme ? "#141A26" : "#E2E8F0"
        border.width: 1
        border.color: root.darkTheme ? "#2B374B" : "#CBD5E1"

        Behavior on y {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        // Prevent clicks on keyboard background from stealing focus or passing through
        MouseArea {
            anchors.fill: parent
            onPressed: function(mouse) { mouse.accepted = true }
        }

        // Key Rows Container
        Item {
            anchors.fill: parent

            // ============================================================
            // PANEL 0: QWERTY Letter Keyboard
            // ============================================================
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 4
                visible: root.panelIndex === 0

                // Row 1: Q W E R T Y U I O P
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    Repeater {
                        model: [
                            { k: "q", sub: "1" }, { k: "w", sub: "2" }, { k: "e", sub: "3" },
                            { k: "r", sub: "4" }, { k: "t", sub: "5" }, { k: "y", sub: "6" },
                            { k: "u", sub: "7" }, { k: "i", sub: "8" }, { k: "o", sub: "9" },
                            { k: "p", sub: "0" }
                        ]
                        delegate: KeyButton {
                            required property var modelData
                            text: InputEngine.capsLock ? modelData.k.toUpperCase() : modelData.k
                            subText: modelData.sub
                            darkTheme: root.darkTheme
                            onClicked: InputEngine.handleKeyPress(text)
                        }
                    }
                }

                // Row 2: A S D F G H J K L
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 22
                    Layout.rightMargin: 22
                    spacing: 4

                    Repeater {
                        model: ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
                        delegate: KeyButton {
                            required property string modelData
                            text: InputEngine.capsLock ? modelData.toUpperCase() : modelData
                            darkTheme: root.darkTheme
                            onClicked: InputEngine.handleKeyPress(text)
                        }
                    }
                }

                // Row 3: CapsLock + Z X C V B N M + Backspace (Long-press auto-repeat)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    KeyButton {
                        text: root.isZhLabel ? "\u21e7 \u5927\u5199" : "\u21e7 Caps"
                        isFunctionKey: true
                        isActiveState: InputEngine.capsLock
                        showStatusDot: true
                        statusActive: InputEngine.capsLock
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 74
                        onClicked: InputEngine.toggleCapsLock()
                    }

                    Repeater {
                        model: ["z", "x", "c", "v", "b", "n", "m"]
                        delegate: KeyButton {
                            required property string modelData
                            text: InputEngine.capsLock ? modelData.toUpperCase() : modelData
                            darkTheme: root.darkTheme
                            onClicked: InputEngine.handleKeyPress(text)
                        }
                    }

                    KeyButton {
                        text: root.isZhLabel ? "\u232b \u9000\u683c" : "\u232b Back"
                        isFunctionKey: true
                        autoRepeat: true
                        repeatDelay: 400
                        repeatInterval: 50
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 78
                        onClicked: InputEngine.handleBackspace()
                    }
                }

                // Row 4: 123 | 中/英 | _ | Space | . | 收起 | 确定(Enter)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    KeyButton {
                        text: root.isZhLabel ? "123/\u7b26" : "123/#"
                        isFunctionKey: true
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 68
                        onClicked: {
                            InputEngine.clearPinyinBuffer()
                            root.panelIndex = 1
                        }
                    }

                    KeyButton {
                        text: root.langButtonRichText()
                        richText: true
                        isFunctionKey: true
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 68
                        onClicked: InputEngine.toggleLanguageMode()
                    }

                    KeyButton {
                        text: "_"
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 46
                        onClicked: InputEngine.handleSymbolPress("_")
                    }

                    KeyButton {
                        text: root.isZhLabel ? "\u7a7a\u683c" : "Space"
                        isFunctionKey: true
                        fontPixelSize: 15
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 230
                        onClicked: InputEngine.handleSpace()
                    }

                    KeyButton {
                        text: "."
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 46
                        onClicked: InputEngine.handleSymbolPress(".")
                    }

                    KeyButton {
                        text: root.isZhLabel ? "\u25bc \u6536\u8d77" : "\u25bc Hide"
                        isFunctionKey: true
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 66
                        onClicked: root.closeKeyboard()
                    }

                    KeyButton {
                        text: root.isZhLabel ? "\u21b5 \u786e\u5b9a" : "\u21b5 Enter"
                        isFunctionKey: true
                        isPrimaryKey: true
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 82
                        onClicked: {
                            InputEngine.handleEnter()
                            root.closeKeyboard()
                        }
                    }
                }
            }

            // ============================================================
            // PANEL 1: 123 Numbers & High-Frequency Industrial Symbols
            // ============================================================
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 4
                visible: root.panelIndex === 1

                // Row 1: 1 2 3 4 5 6 7 8 9 0
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    Repeater {
                        model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
                        delegate: KeyButton {
                            required property string modelData
                            text: modelData
                            darkTheme: root.darkTheme
                            onClicked: InputEngine.handleSymbolPress(modelData)
                        }
                    }
                }

                // Row 2: Industrial Common Symbols (_ @ - . / # : + = *)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    Repeater {
                        model: ["_", "@", "-", ".", "/", "#", ":", "+", "=", "*"]
                        delegate: KeyButton {
                            required property string modelData
                            text: modelData
                            darkTheme: root.darkTheme
                            onClicked: InputEngine.handleSymbolPress(modelData)
                        }
                    }
                }

                // Row 3: More Symbols + ( ) [ ] % & ? ! + Backspace
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    KeyButton {
                        text: root.isZhLabel ? "#+= \u66f4\u591a" : "#+= More"
                        isFunctionKey: true
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 76
                        onClicked: root.panelIndex = 2
                    }

                    Repeater {
                        model: ["(", ")", "[", "]", "%", "&", "?", "!"]
                        delegate: KeyButton {
                            required property string modelData
                            text: modelData
                            darkTheme: root.darkTheme
                            onClicked: InputEngine.handleSymbolPress(modelData)
                        }
                    }

                    KeyButton {
                        text: root.isZhLabel ? "\u232b \u9000\u683c" : "\u232b Back"
                        isFunctionKey: true
                        autoRepeat: true
                        repeatDelay: 400
                        repeatInterval: 50
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 78
                        onClicked: InputEngine.handleBackspace()
                    }
                }

                // Row 4: ABC | 中/英 | , | Space | ; | 收起 | 确定
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    KeyButton {
                        text: root.isZhLabel ? "ABC \u8fd4\u56de" : "ABC"
                        isFunctionKey: true
                        isActiveState: true
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 76
                        onClicked: root.panelIndex = 0
                    }

                    KeyButton {
                        text: root.langButtonRichText()
                        richText: true
                        isFunctionKey: true
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 68
                        onClicked: {
                            root.panelIndex = 0
                            InputEngine.toggleLanguageMode()
                        }
                    }

                    KeyButton {
                        text: ","
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 46
                        onClicked: InputEngine.handleSymbolPress(",")
                    }

                    KeyButton {
                        text: root.isZhLabel ? "\u7a7a\u683c" : "Space"
                        isFunctionKey: true
                        fontPixelSize: 15
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 222
                        onClicked: InputEngine.handleSpace()
                    }

                    KeyButton {
                        text: ";"
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 46
                        onClicked: InputEngine.handleSymbolPress(";")
                    }

                    KeyButton {
                        text: root.isZhLabel ? "\u25bc \u6536\u8d77" : "\u25bc Hide"
                        isFunctionKey: true
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 66
                        onClicked: root.closeKeyboard()
                    }

                    KeyButton {
                        text: root.isZhLabel ? "\u21b5 \u786e\u5b9a" : "\u21b5 Enter"
                        isFunctionKey: true
                        isPrimaryKey: true
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 82
                        onClicked: {
                            InputEngine.handleEnter()
                            root.closeKeyboard()
                        }
                    }
                }
            }

            // ============================================================
            // PANEL 2: Extended Industrial Symbols Keyboard
            // ============================================================
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 4
                visible: root.panelIndex === 2

                // Row 1
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    Repeater {
                        model: ["~", "`", "!", "@", "#", "$", "%", "^", "&", "*"]
                        delegate: KeyButton {
                            required property string modelData
                            text: modelData
                            darkTheme: root.darkTheme
                            onClicked: InputEngine.handleSymbolPress(modelData)
                        }
                    }
                }

                // Row 2
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    Repeater {
                        model: ["{", "}", "[", "]", "<", ">", "|", "\\", "/", "?"]
                        delegate: KeyButton {
                            required property string modelData
                            text: modelData
                            darkTheme: root.darkTheme
                            onClicked: InputEngine.handleSymbolPress(modelData)
                        }
                    }
                }

                // Row 3
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    KeyButton {
                        text: root.isZhLabel ? "123 \u6570\u5b57" : "123 Num"
                        isFunctionKey: true
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 76
                        onClicked: root.panelIndex = 1
                    }

                    Repeater {
                        model: ["'", "\"", ":", ";", ",", ".", "-", "_"]
                        delegate: KeyButton {
                            required property string modelData
                            text: modelData
                            darkTheme: root.darkTheme
                            onClicked: InputEngine.handleSymbolPress(modelData)
                        }
                    }

                    KeyButton {
                        text: root.isZhLabel ? "\u232b \u9000\u683c" : "\u232b Back"
                        isFunctionKey: true
                        autoRepeat: true
                        repeatDelay: 400
                        repeatInterval: 50
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 78
                        onClicked: InputEngine.handleBackspace()
                    }
                }

                // Row 4
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    KeyButton {
                        text: root.isZhLabel ? "ABC \u8fd4\u56de" : "ABC"
                        isFunctionKey: true
                        isActiveState: true
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 76
                        onClicked: root.panelIndex = 0
                    }

                    KeyButton {
                        text: "+"
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 56
                        onClicked: InputEngine.handleSymbolPress("+")
                    }

                    KeyButton {
                        text: "="
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 56
                        onClicked: InputEngine.handleSymbolPress("=")
                    }

                    KeyButton {
                        text: root.isZhLabel ? "\u7a7a\u683c" : "Space"
                        isFunctionKey: true
                        fontPixelSize: 15
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 242
                        onClicked: InputEngine.handleSpace()
                    }

                    KeyButton {
                        text: "\u00b1"
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 46
                        onClicked: InputEngine.handleSymbolPress("\u00b1")
                    }

                    KeyButton {
                        text: root.isZhLabel ? "\u25bc \u6536\u8d77" : "\u25bc Hide"
                        isFunctionKey: true
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 66
                        onClicked: root.closeKeyboard()
                    }

                    KeyButton {
                        text: root.isZhLabel ? "\u21b5 \u786e\u5b9a" : "\u21b5 Enter"
                        isFunctionKey: true
                        isPrimaryKey: true
                        darkTheme: root.darkTheme
                        Layout.preferredWidth: 82
                        onClicked: {
                            InputEngine.handleEnter()
                            root.closeKeyboard()
                        }
                    }
                }
            }
        }
    }
}
